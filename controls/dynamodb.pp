variable "dynamodb_table_with_stale_data_max_days" {
  type        = number
  description = "The maximum number of days table data can be unchanged before it is considered stale."
  default     = 90
}

locals {
  dynamodb_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/DynamoDB"
  })
}

benchmark "dynamodb" {
  title         = "DynamoDB Cost Controls"
  description   = "Thrifty developers delete DynamoDB tables with stale or empty data."
  documentation = file("./controls/docs/dynamodb.md")

  children = [
    control.dynamodb_table_zero_items,
    control.dynamodb_table_with_stale_data,
    control.dynamodb_table_with_autoscaling_disabled
  ]

  tags = merge(local.dynamodb_common_tags, {
    type = "Benchmark"
  })
}

control "dynamodb_table_zero_items" {
  title       = "DynamoDB tables with zero items should be reviewed"
  description = "DynamoDB tables that contain no items may indicate unused or obsolete resources. Retaining empty tables can lead to unnecessary costs and clutter. Review and delete tables with zero items unless they are required for future use or compliance purposes."
  severity    = "low"

  tags = merge(local.dynamodb_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when item_count = '0' and write_capacity = '0' and read_capacity = '0' then 'info'
        when item_count = '0' then 'alarm'
        else 'ok'
      end as status,
      case
        when item_count = '0' and write_capacity = '0' and read_capacity = '0' then title || ' is on demand table with zero items.'
        else title || ' has ' || item_count || ' items.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_dynamodb_table;
  EOQ
}

control "dynamodb_table_with_stale_data" {
  title       = "DynamoDB tables with stale data should be reviewed"
  description = "DynamoDB tables that have not been updated for an extended period may be underutilized or obsolete. Retaining tables with stale data can increase costs and complicate data management. Review tables that have not changed recently and consider archiving or deleting them if they are no longer needed."
  severity    = "low"

  param "dynamodb_table_with_stale_data_max_days" {
    description = "The maximum number of days table data can be unchanged before it is considered stale."
    default     = var.dynamodb_table_with_stale_data_max_days
  }

  tags = merge(local.dynamodb_common_tags, {
    class = "stale_data"
  })

  sql = <<-EOQ
    select
      arn as resource,
    case
      when latest_stream_label is null then 'info'
      when date_part('day', now() - (latest_stream_label::timestamptz)) > $1 then 'alarm'
      else 'ok'
    end as status,
    case
      when latest_stream_label is null then name || ' is not configured for change data capture.'
      else name || ' was changed ' || date_part('day', now() - (latest_stream_label::timestamptz)) || ' days ago.'
    end as reason
    ${local.tag_dimensions_sql}
    ${local.common_dimensions_sql}
  from
    aws_dynamodb_table;
  EOQ
}

control "dynamodb_table_with_autoscaling_disabled" {
  title       = "DynamoDB tables auto scaling should be enabled"
  description = "DynamoDB tables with provisioned capacity mode should use auto-scaling to optimize costs. Auto-scaling automatically adjusts read and write capacity based on actual usage patterns, helping to avoid over-provisioning and reduce costs."
  severity    = "low"

  tags = merge(local.dynamodb_common_tags, {
    class = "capacity_planning"
  })

  sql = <<-EOQ
    with dynamodb_autoscaling as (
      select
        split_part(resource_id, '/', 2) as table_name,
        count(*) as scaling_configs
      from
        aws_appautoscaling_target
      where
        service_namespace = 'dynamodb'
      group by
        split_part(resource_id, '/', 2)
    )
    select
      'arn:' || t.partition || ':dynamodb:' || t.region || ':' || t.account_id || ':table/' || t.name as resource,
      case
        when t.billing_mode = 'PAY_PER_REQUEST' then 'ok'
        when coalesce(a.scaling_configs, 0) > 0 then 'ok'
        else 'alarm'
      end as status,
      case
        when t.billing_mode = 'PAY_PER_REQUEST' then t.name || ' uses on-demand capacity mode.'
        when coalesce(a.scaling_configs, 0) > 0 then t.name || ' has auto-scaling configured.'
        else t.name || ' uses provisioned capacity without auto-scaling.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_dynamodb_table as t
      left join dynamodb_autoscaling as a on t.name = a.table_name;
  EOQ
}
