variable "cost_explorer_service_cost_max_cost_units" {
  type        = number
  description = "The maximum difference in cost units allowed for service costs between the current and previous month."
  default     = 10
}

locals {
  cost_explorer_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/CostExplorer"
  })
}

benchmark "cost_explorer" {
  title         = "Cost Explorer Checks"
  description   = "Thrifty developers actively monitor their cloud usage and cost data."
  documentation = file("./controls/docs/cost-explorer.md")
  children = [
    control.full_month_cost_changes
  ]

  tags = merge(local.cost_explorer_common_tags, {
    type = "Benchmark"
  })
}

control "full_month_cost_changes" {
  title       = "What services have changed in cost over last two months?"
  description = "Compares the cost of services between the last two full months of AWS usage."
  severity    = "low"

  param "cost_explorer_service_cost_max_cost_units" {
    description = "The maximum difference in cost units allowed for service costs between the current and previous month."
    default     = var.cost_explorer_service_cost_max_cost_units
  }

  tags = merge(local.cost_explorer_common_tags, {
    class = "managed"
  })
  sql = <<-EOQ
    with
    base_month as (
      select
        dimension_1 as service_name,
        replace(lower(trim(dimension_1)), ' ', '-') as service,
        partition,
        account_id,
        _ctx,
        net_unblended_cost_unit as unit,
        sum(net_unblended_cost_amount) as cost,
        region
      from
        aws_cost_usage
      where
        granularity = 'MONTHLY'
        and dimension_type_1 = 'SERVICE'
        and dimension_type_2 = 'RECORD_TYPE'
        and dimension_2 not in ('Credit')
        and period_start >= date_trunc('month', current_date - interval '2' month)
        and period_start < date_trunc('month', current_date - interval '1' month)
      group by
        1,2,3,4,5,unit,region
    ),
    prev_month as (
      select
        dimension_1 as service_name,
        replace(lower(trim(dimension_1)), ' ', '-') as service,
        partition,
        account_id,
        _ctx,
        net_unblended_cost_unit as unit,
        sum(net_unblended_cost_amount) as cost,
        region
      from
        aws_cost_usage
      where
        granularity = 'MONTHLY'
        and dimension_type_1 = 'SERVICE'
        and dimension_type_2 = 'RECORD_TYPE'
        and dimension_2 not in ('Credit')
        and period_start >= date_trunc('month', current_date - interval '1' month)
        and period_start < date_trunc('month', current_date )
      group by
        1,2,3,4,5,unit,region
    )
  select
    case
      when prev_month.service_name is null then 'arn:' || base_month.partition || ':::' || base_month.account_id || ':cost/' || base_month.service
      else 'arn:' || prev_month.partition || ':::' || prev_month.account_id || ':cost/' || prev_month.service
    end as resource,
    case
      when base_month.cost is null then 'info'
      when prev_month.cost is null then 'ok'
      -- adjust this value to change threshold for the alarm
      when (prev_month.cost - base_month.cost) > $1 then 'alarm'
      else 'ok'
    end as status,
    case
      when base_month.cost is null then prev_month.service_name || ' usage is new this month with a spend of ' || round(cast(prev_month.cost as numeric), 2) || ' ' || prev_month.unit
      when prev_month.cost is null then 'No usage billing for ' || base_month.service_name || ' in current month.'
      when abs(prev_month.cost - base_month.cost) < 0.01 then prev_month.service_name || ' has remained flat.'
      when prev_month.cost > base_month.cost then prev_month.service_name || ' usage has increased by ' || round(cast((prev_month.cost - base_month.cost) as numeric), 2)  || ' ' || prev_month.unit
      else prev_month.service_name || ' usage has decreased (' || round(cast((base_month.cost - prev_month.cost) as numeric), 2) || ') ' || prev_month.unit
    end as reason
    ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "prev_month.")}
  from
    base_month
    full outer join prev_month on base_month.service_name = prev_month.service_name
  where
    prev_month.cost != base_month.cost
  order by
    (prev_month.cost - base_month.cost) desc;
  EOQ
}
