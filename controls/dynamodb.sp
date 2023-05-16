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
    control.stale_dynamodb_table_data
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
    with dynamodb_regions as (
      select
        distinct region
      from
        aws_dynamodb_table
    ), dynamodb_pricing as (
      select
        r.region,
        p.currency,
        p.price_per_unit::numeric as dynamodb_price_gb_per_month
      from
        aws_pricing_product as p
        join dynamodb_regions as r on
          p.service_code = 'AmazonDynamoDB'
          and p.attributes ->> 'regionCode' = r.region
          and p.attributes ->> 'usagetype' = 'IA-TimedStorage-ByteHrs'
          and term = 'OnDemand'
      group by r.region, p.price_per_unit, p.currency
    ), dynamodb_pricing_monthly as (
      select
        case
          when latest_stream_label is null then ''
          else ((t.table_size_bytes/1024*1024*1024)*dynamodb_price_gb_per_month)::numeric(10,2) || ' ' || currency || 'GB/month'
        end as net_savings,
        currency,
        t.arn as arn,
        t.latest_stream_label as latest_stream_label,
        t.tags as tags,
        t.account_id,
        t.region,
        t.title as title, 1024*1024*1024
      from
        aws_dynamodb_table as t,
        dynamodb_pricing
    )
    select
      arn as resource,
      case
        when latest_stream_label is null then 'info'
        when date_part('day', now() - (latest_stream_label::timestamptz)) > $1 then 'alarm'
        else 'ok'
      end as status,
      case
        when latest_stream_label is null then title || ' is not configured for change data capture.'
        else title || ' was changed ' || date_part('day', now() - (latest_stream_label::timestamptz)) || ' days ago.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      dynamodb_pricing_monthly;
  EOQ
}
