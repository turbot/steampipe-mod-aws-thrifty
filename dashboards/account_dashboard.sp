dashboard "account_dashboard" {

  title = "AWS Account Dashboard"

  tags = merge(local.account_common_tags, {
    type = "Dashboard"
  })

  # Cards
  container {

    # Total cost - Previous month
    card {
      query = query.account_previous_month_total_cost
      width = 2
    }

    card {
      query = query.account_agg_forecast_cost_mtd
      width = 2
    }

    # Analysis
    card {
      query = query.account_current_month_total_cost
      width = 2
    }

    # Account trend - increase / decrese amount percentage
    card {
      query = query.account_trend
      width = 2
    }

    card {
      query = query.account_currency
      width = 2
    }

  }

  container {
    title = "Cost by Account"

    table {
      width = 6
      query = query.aws_account_cost_table

      column "account_id" {
        display = "none"
      }

      column "Account" {
        href = "${dashboard.account_cost_detail.url_path}?input.account_id={{.account_id | @uri}}"
      }
    }

    chart {
      query = query.aws_cost_by_aws_account
      type  = "column"
      width = 6

      axes {
        y {
          title {
            value = "Cost"
          }
          labels {
            display = "always"
          }
        }
      }
    }
  }

  container {

    title = "Top 5 Services by Cost"

    table {
      width = 6
      query = query.account_top_5_service_by_usage_mtd
    }

    chart {
      width = 6
      query = query.account_top_5_service_by_usage_mtd_chart
      type  = "column"

      legend {
        position = "bottom"
      }
    }
  }
}

query "account_previous_month_total_cost" {
  sql = <<-EOQ
    select
      'Invoice Previous Month (' || net_unblended_cost_unit || ')' as label,
      cast(sum(net_unblended_cost_amount) as numeric(10,2))::text as value
    from
      aws_cost_by_account_monthly
    where
      period_start >= (date_trunc('month', now()) -interval '1 month')
      and period_end <= date_trunc('month', now())
    group by
      net_unblended_cost_unit;
  EOQ
}

query "account_agg_forecast_cost_mtd" {
  sql = <<-EOQ
    with forecast_cost_till_month_end as (
      select
        sum(mean_value) as forecast
      from
        aws_cost_forecast_daily
      where
        to_char(period_start, 'YYYY-MM') = to_char(now(), 'YYYY-MM')
    ), cost_till_date as (
      select
        sum(m.net_unblended_cost_amount) as cost_till_date,
        net_unblended_cost_unit
      from
        aws_cost_by_account_monthly as m
      where
        date(m.period_end) = date(current_timestamp)
      group by
        net_unblended_cost_unit
    )
    select
      'Month-End Forecast (' || net_unblended_cost_unit || ')' as label,
      cast((m.cost_till_date + forecast) as numeric(10,2))::text as value
    from
      cost_till_date as m,
      forecast_cost_till_month_end
  EOQ
}

query "account_current_month_total_cost" {
  sql = <<-EOQ
    with previous_month_cost as (
      select
         sum(net_unblended_cost_amount) as previous_month_cost
      from
        aws_cost_by_account_monthly
      where
        period_start >= (date_trunc('month', now()) -interval '1 month')
        and period_end <= date_trunc('month', now())
    )
    select
      'Current MTD (' || net_unblended_cost_unit || ')' as label,
      cast(sum(net_unblended_cost_amount) as numeric(10,2))::text as value,
      case when sum(net_unblended_cost_amount) > previous_month_cost then 'alert' else 'ok' end as type
    from
      aws_cost_by_account_monthly,
      previous_month_cost
    where
      date(period_end) = date(current_timestamp)
    group by
      net_unblended_cost_unit, previous_month_cost
  EOQ
}

query "account_top_5_service_by_usage_mtd" {
  sql = <<-EOQ
    with top_5_services_by_usage as (
      select
        service,
        sum(net_unblended_cost_amount) as current_month_cost
      from
        aws_cost_by_service_monthly
      where
        period_start >= date_trunc('month', now())
        and period_end <= now()
      group by service
      order by sum(net_unblended_cost_amount) desc
      limit 5
    ), previous_month_cost as (
      select
        service,
        sum(net_unblended_cost_amount) as previous_month_cost
      from
        aws_cost_by_service_monthly
      where
        period_start >= (date_trunc('month', now()) -interval '1 month')
        and period_end <= date_trunc('month', now())
        and service in ( select service from top_5_services_by_usage)
       group by service
       order by sum(net_unblended_cost_amount) desc
    )
    select
      s.service as "Service",
      (p.previous_month_cost::numeric(10,2)) "Previous Month",
      (s.current_month_cost::numeric(10,2)) "Current MTD",
      case
        when ((s.current_month_cost - p.previous_month_cost)*100/p.previous_month_cost) > 0 then
          concat(abs(cast(((s.current_month_cost - p.previous_month_cost)*100/p.previous_month_cost) as numeric(10,2)))::text, '%', ' 🔺')
        else
         concat(abs(cast(((s.current_month_cost - p.previous_month_cost)*100/p.previous_month_cost) as numeric(10,2)))::text, '%', ' ▼')
      end as "Trend"
    from
      top_5_services_by_usage as s
      left join previous_month_cost as p on p.service = s.service
  EOQ
}

query "account_top_5_service_by_usage_mtd_chart" {
  sql = <<-EOQ
    with top_5_services_per_usage as (
      select
        service
      from
        aws_cost_by_service_monthly
      where
        period_start >= date_trunc('month', now())
        and period_end <= now()
      group by service
      order by sum(net_unblended_cost_amount) desc
      limit 5
    )
    select
      m.period_start,
      m.service,
      sum(m.net_unblended_cost_amount)
    from
      aws_cost_by_service_daily as m
      join top_5_services_per_usage as t on m.service = t.service
    where
      m.period_start >= date_trunc('month', now())
      and m.period_end <= now()
    group by
      m.period_start,
      m.service
  EOQ
}

query "account_trend" {
  sql = <<-EOQ
    with previous_month as (
      select
        sum(net_unblended_cost_amount) as previous_net_unblended_cost_amount
      from
        aws_account as c
        left join aws_cost_by_account_monthly as m on m.account_id = c.account_id
      where
        period_start >= (date_trunc('month', now()) -interval '1 month')
        and period_end <= date_trunc('month', now())
    ),
    forecast_daily as (
      select
        sum(mean_value) as mean_value
      from
        aws_account as c
        left join aws_cost_forecast_daily as d on d.account_id = c.account_id
      where
        date(d.period_start) = date(current_timestamp)
    )
    select
      'Monthly Invoiced Spend Trend' as label,
      concat(abs(cast(((sum(net_unblended_cost_amount) + f.mean_value - p.previous_net_unblended_cost_amount) * 100 / p.previous_net_unblended_cost_amount) as numeric(10,2)))::text, '%') || case
        when ((sum(net_unblended_cost_amount) + f.mean_value - p.previous_net_unblended_cost_amount) * 100 / p.previous_net_unblended_cost_amount) > 0 then ' 🔺'
        else ' ▼'
      end as value
    from
      aws_cost_by_account_monthly as c,
      previous_month as p,
    forecast_daily as f
    where
      date(c.period_end) = date(current_timestamp)
    group by
      p.previous_net_unblended_cost_amount, f.mean_value
  EOQ
}

query "account_currency" {
  sql = <<-EOQ
    select
      'Currency' as label,
      unblended_cost_unit as value
    from
      aws_cost_by_account_monthly
    limit 1
  EOQ
}

query "aws_cost_by_aws_account" {
  sql = <<-EOQ
    select
      c.title,
      net_unblended_cost_amount::numeric(10,2)::text
    from
      aws_account as c
      left join aws_cost_by_account_monthly as m on m.account_id = c.account_id
    where
      date(period_end) = date(current_timestamp)
    order by
      net_unblended_cost_amount desc;
  EOQ
}

query "aws_account_cost_table" {
  sql = <<-EOQ
   with previous_month as (
  select
    net_unblended_cost_amount as previous_month_cost,
    c.account_id
  from
    aws_account as c
    left join aws_cost_by_account_monthly as m on m.account_id = c.account_id
  where
    period_start >= (date_trunc('month', now()) -interval '1 month')
    and period_end <= date_trunc('month', now())
), forecast_cost_till_month_end as (
   select
    sum(mean_value) as forecast,
    c.account_id
  from
    aws_account as c
    left join aws_cost_forecast_daily as f on f.account_id = c.account_id
  where
    to_char(period_start, 'YYYY-MM') = to_char(now(), 'YYYY-MM')
  group by
    c.account_id
),cost_till_date as (
  select
    sum(m.net_unblended_cost_amount) as cost_till_date,
    c.account_id
  from
    aws_account as c
    left join aws_cost_by_account_monthly as m on m.account_id = c.account_id
  where
    date(m.period_end) = date(current_timestamp)
  group by
    c.account_id
)
select
  c.title as "Account",
  c.account_id as account_id,
  (p.previous_month_cost::numeric(10,2)) as "Previous Month",
  ((t.cost_till_date + forecast)::numeric(10,2)) as "Month Forecast",
  (t.cost_till_date::numeric(10,2)) as "Current MTD",
  case
    when ((t.cost_till_date + forecast - p.previous_month_cost)*100/p.previous_month_cost) > 0 then
      concat(trunc(((t.cost_till_date + forecast - p.previous_month_cost)*100/p.previous_month_cost)::numeric, 2), '%', ' 🔺')
    else
      concat(abs(cast(((t.cost_till_date + forecast - p.previous_month_cost)*100/p.previous_month_cost) as numeric(10,2)))::text, '%', ' ▼')
  end as "Trend"
from
  aws_account as c
  left join previous_month as p on p.account_id = c.account_id
  left join forecast_cost_till_month_end as f on f.account_id = c.account_id
  left join cost_till_date as t on t.account_id = c.account_id

  EOQ
}



