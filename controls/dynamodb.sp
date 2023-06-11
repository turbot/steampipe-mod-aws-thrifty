locals {
  dynamodb_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/DynamoDB"
  })
}

benchmark "dynamodb" {
  title         = "DynamoDB Cost Checks"
  description   = "Thrifty developers delete DynamoDB tables with stale data."
  documentation = file("./controls/docs/dynamodb.md")

  children = [
    control.dynamodb_table_no_data
  ]

  tags = merge(local.dynamodb_common_tags, {
    type = "Benchmark"
  })
}

control "dynamodb_table_no_data" {
  title       = "DynamoDB empty tables should be reviewed"
  description = "If the tables has not items then the table should be reviewed."
  severity    = "low"

  tags = merge(local.dynamodb_common_tags, {
    class = "stale_data"
  })

  sql = <<-EOQ
    with dynamodb_regions as (
      select
        distinct region
      from
        aws_dynamodb_table
    ), dynamodb_write_units_pricing as (
      select
        r.region,
        p.currency,
        p.price_per_unit::numeric as dynamodb_write_price
      from
        aws_pricing_product as p
        join dynamodb_regions as r on
        p.service_code = 'AmazonDynamoDB'
        and p.attributes ->> 'usagetype' like '%WriteCapacityUnit-Hrs'
        and p.attributes ->> 'regionCode' = r.region
        and p.begin_range = '18600'
        and p.attributes ->> 'groupDescription' = 'DynamoDB Provisioned Write Units'
        and term = 'OnDemand'
      group by r.region, p.price_per_unit, p.currency
    ), dynamodb_read_units_pricing as (
      select
        r.region,
        p.currency,
        p.price_per_unit::numeric as dynamodb_read_price
      from
        aws_pricing_product as p
        join dynamodb_regions as r on
        p.service_code = 'AmazonDynamoDB'
        and p.attributes ->> 'usagetype' like '%ReadCapacityUnit-Hrs'
        and p.attributes ->> 'regionCode' = r.region
        and p.attributes ->> 'groupDescription' = 'DynamoDB Provisioned Read Units'
        and p.begin_range = '18600'
        and term = 'OnDemand'
      group by r.region, p.price_per_unit, p.currency
    ), dynamodb_pricing_monthly as (
      select
        case
          when t.item_count = '0' then ((t.write_capacity*w.dynamodb_write_price) + (t.read_capacity*r.dynamodb_read_price))::numeric(10,2) || ' ' || w.currency || ' total cost/GB/month'
          else ''
        end as net_savings,
        w.currency,
        t.arn as arn,
        t.item_count,
        t.tags as tags,
        t.account_id,
        t.region,
        t.title as title
      from
        aws_dynamodb_table as t
        left join dynamodb_write_units_pricing as w on w.region = t.region
        left join dynamodb_read_units_pricing as r on r.region = t.region
    )
    select
      arn as resource,
      case
        when item_count = '0' then 'alarm'
        else 'ok'
      end as status,
      case
        when item_count = '0' then title || ' is empty table.'
        else title || ' has ' || item_count || ' items.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      dynamodb_pricing_monthly;
  EOQ
}
