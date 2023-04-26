dashboard "account_dashboard" {

  title = "AWS Account Dashboard"

  tags = merge(local.account_common_tags, {
    type = "Dashboard"
  })

  # Cards
  container {

    # Analysis
    card {
      query = query.account_total_cost
      width = 3
    }

    card {
      query = query.account_dashboard_forecast_cost_mtd
      width = 3
    }

    # Total cost - Previous month
    card {
      query = query.account_previous_month_total_cost
      width = 3
    }

    # Account trend - increase / decrese amount percentage
    card {
      query = query.account_trend
      width = 3
    }
  }

  container {
    width = 6

    table {
      title = "Cost Table"
      width = 12
      query = query.aws_account_cost_table

      column "account_id" {
        display = "none"
      }

      column "Account" {
        href = "${dashboard.account_cost_detail.url_path}?input.account_id={{.account_id | @uri}}"
      }
    }
  }

  container {

    width = 6

    chart {
      title = "Cost by AWS account"
      query = query.aws_cost_by_aws_account
      type  = "column"

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
    table {
      title = "Top 5 services by spend"
      width = 6
      query = query.account_top_5_service_by_usage_mtd
    }

    chart {
      title = "Top 5 services by usage"
      width = 6
      query = query.account_top_5_service_by_usage_mtd_chart
      type  = "line"
    }
  }
}

query "account_top_5_service_by_usage_mtd" {
  sql = <<-EOQ
    select
      service as "Service",
      concat(cast(sum(net_unblended_cost_amount) as numeric(10,2))::text, ' ', net_unblended_cost_unit) as "Current month cost"
    from
      aws_cost_by_service_monthly
    where
      period_start >= date_trunc('month', now())
      and period_end <= now()
    group by service, net_unblended_cost_unit
    order by sum(net_unblended_cost_amount) desc
    limit 5
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
      aws_cost_by_service_monthly as m
      join top_5_services_per_usage as t on m.service = t.service
    group by
      m.period_start,
      m.service
  EOQ
}

query "account_total_cost" {
  sql = <<-EOQ
    select
      'Current MTD (' || ' ' || net_unblended_cost_unit || ')' as label,
      cast(sum(net_unblended_cost_amount) as numeric(10,2))::text as value
    from
      aws_cost_by_account_monthly
    where
      date(period_end) = date(current_timestamp)
    group by net_unblended_cost_unit;
  EOQ
}

query "account_previous_month_total_cost" {
  sql = <<-EOQ
    select
      'Invoice Previous Month (' || ' ' || net_unblended_cost_unit || ')' as label,
      cast(sum(net_unblended_cost_amount) as numeric(10,2))::text as value
    from
      aws_cost_by_account_monthly
    where
      period_start >= (date_trunc('month', now()) -interval '1 month')
      and period_end <= date_trunc('month', now())
    group by net_unblended_cost_unit;
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
        when ((sum(net_unblended_cost_amount) + f.mean_value - p.previous_net_unblended_cost_amount) * 100 / p.previous_net_unblended_cost_amount) > 0 then ' ▲'
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
      net_unblended_cost_amount,
      net_unblended_cost_unit,
      c.account_id
    from
      aws_account as c
      left join aws_cost_by_account_monthly as m on m.account_id = c.account_id
    where
      period_start >= (date_trunc('month', now()) -interval '1 month')
      and period_end <= date_trunc('month', now())
   )
    select
      c.title as "Account",
      c.account_id as account_id,
      concat(p.net_unblended_cost_amount::numeric(10,2), ' ', p.net_unblended_cost_unit) as "Previous Month",
      concat(m.net_unblended_cost_amount::numeric(10,2), ' ', m.net_unblended_cost_unit) as "Current MTD",
      concat((m.net_unblended_cost_amount + mean_value)::numeric(10,2), ' ', m.net_unblended_cost_unit) as "Forecast MTD",
      case
        when ((m.net_unblended_cost_amount + mean_value - p.net_unblended_cost_amount)*100/p.net_unblended_cost_amount) > 0 then
          concat(trunc(((m.net_unblended_cost_amount + mean_value - p.net_unblended_cost_amount)*100/p.net_unblended_cost_amount)::numeric, 2), '%', '▲')
        else
          concat(abs(cast(((m.net_unblended_cost_amount + mean_value - p.net_unblended_cost_amount)*100/p.net_unblended_cost_amount) as numeric(10,2)))::text, '%', ' ▼')
          -- concat(trunc(((m.net_unblended_cost_amount + mean_value - p.net_unblended_cost_amount)*100/p.net_unblended_cost_amount)::numeric, 2), '%', '▼')
      end as "Trend"
    from
      aws_account as c
      left join aws_cost_by_account_monthly as m on m.account_id = c.account_id
      left join aws_cost_forecast_daily as d on d.account_id = c.account_id
      left join previous_month as p on p.account_id = c.account_id
    where
      date(m.period_end) = date(current_timestamp)
      and date(d.period_start) = date(current_timestamp)
  EOQ
}

query "account_dashboard_forecast_cost_mtd" {
  sql = <<-EOQ
    select
      'Forecast MTD (' || net_unblended_cost_unit || ')' as label,
      cast(sum(m.net_unblended_cost_amount + d.mean_value) as numeric(10,2))::text as value
    from
      aws_cost_by_account_monthly as m
      join aws_cost_forecast_daily as d on m.account_id = d.account_id
    where
      date(m.period_end) = date(current_timestamp)
      and date(m.period_start) = date(date_trunc('month', now()))
      and date(d.period_start) = date(now())
      and date(d.period_end) = date(current_timestamp + interval '1 day')
    group by
      net_unblended_cost_unit
  EOQ
}

