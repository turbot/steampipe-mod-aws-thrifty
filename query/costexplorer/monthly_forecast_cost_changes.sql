with prev_month as (
    select
      sum(net_unblended_cost_amount) as cost,
      partition,
      account_id
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
      account_id,partition
  ),
  forecast_month as (
    select
      mean_value as cost,
      partition,
      account_id
    from
      aws_cost_forecast_monthly
    order by
      period_start limit 1
  )
select
  'arn:' || prev_month.partition || ':::' || prev_month.account_id as resource,
  case
    when (forecast_month.cost - prev_month.cost) > $1 then 'alarm'
    else 'ok'
  end as status,
  case
    when abs(prev_month.cost - forecast_month.cost) < 0.01 then prev_month.account_id || ' forecasted monthly cost has remained flat.'
    when forecast_month.cost > prev_month.cost then prev_month.account_id || ' forecasted monthly cost has increased by ' || round(cast((forecast_month.cost - prev_month.cost) as numeric), 2) || '.'
    else prev_month.account_id || ' forecasted monthly cost has decreased by ' || round(cast((prev_month.cost - forecast_month.cost) as numeric), 2) || '.'
  end as reason,
  prev_month.account_id
from
  prev_month,
  forecast_month
where
  forecast_month.account_id = prev_month.account_id;