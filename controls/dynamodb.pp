variable "dynamodb_table_stale_data_max_days" {
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
  title         = "DynamoDB Checks"
  description   = "Thrifty developers delete DynamoDB tables with stale data."
  documentation = file("./controls/docs/dynamodb.md")

  children = [
    control.stale_dynamodb_table_data,
    control.dynamodb_table_without_autoscaling
  ]

  tags = merge(local.dynamodb_common_tags, {
    type = "Benchmark"
  })
}

control "stale_dynamodb_table_data" {
  title       = "Tables with stale data should be reviewed"
  description = "If the data has not changed recently and has become stale, the table should be reviewed."
  severity    = "low"

  param "dynamodb_table_stale_data_max_days" {
    description = "The maximum number of days table data can be unchanged before it is considered stale."
    default     = var.dynamodb_table_stale_data_max_days
  }

  tags = merge(local.dynamodb_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    select
      'arn:' || partition || ':dynamodb:' || region || ':' || account_id || ':table/' || name as resource,
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

control "dynamodb_table_without_autoscaling" {
  title       = "DynamoDB tables without auto-scaling should be reviewed"
  description = "DynamoDB tables with provisioned capacity mode should use auto-scaling to optimize costs. Auto-scaling automatically adjusts read and write capacity based on actual usage patterns, helping to avoid over-provisioning and reduce costs."
  severity    = "low"

  tags = merge(local.dynamodb_common_tags, {
    class = "cost"
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
