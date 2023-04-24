dashboard "account_dashboard" {

  title = "AWS Account Dashboard"

  tags = merge(local.account_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.account_total_cost
      width = 2
    }

    # Total cost - Previous month
    card {
      query = query.account_previous_month_total_cost
      width = 2
    }

    # Account trend - increase / decrese amount percentage
    card {
      query = query.account_trend
      width = 2
    }

  }

  container {
    width = 12

    chart {
      title = "Cost by AWS account"
      query = query.aws_cost_by_aws_account
      type  = "pie"
      width = 6
    }

    table {
      title = "Cost Table"
      width = 6
      query = query.aws_account_cost_table

      column "account_id" {
        display = "none"
      }

      column "Account" {
        href = "${dashboard.account_cost_detail.url_path}?input.account_id={{.account_id | @uri}}"
      }
    }
  }
}

query "account_total_cost" {
  sql = <<-EOQ
    select
      'Current MTD' as label,
      round((sum(net_unblended_cost_amount))::numeric, 2) as value
    from
      aws_cost_by_account_monthly
    where
      date(period_end) = date(current_timestamp)
  EOQ
}

query "account_previous_month_total_cost" {
  sql = <<-EOQ
    select
      'Previous Month' as label,
      round((sum(net_unblended_cost_amount))::numeric, 2) as value
    from
      aws_cost_by_account_monthly
    where
      period_start >= (date_trunc('month', now()) -interval '1 month')
      and period_end <= date_trunc('month', now())
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
   ), forecast_daily as (
      select
        sum(mean_value) as mean_value
      from
        aws_account as c
        left join aws_cost_forecast_daily as d on d.account_id = c.account_id
      where
        date(d.period_start) = date(current_timestamp)
   )
    select
      'Trend' as label,
      concat(
        trunc(((sum(net_unblended_cost_amount)+ f.mean_value - p.previous_net_unblended_cost_amount) * 100 / p.previous_net_unblended_cost_amount)::numeric, 2),
        '%'
      ) as value,
      case
        when (sum(net_unblended_cost_amount)+ f.mean_value - p.previous_net_unblended_cost_amount)*100/p.previous_net_unblended_cost_amount < 0 then 'ok'
        else 'alert'
      end as type
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
      net_unblended_cost_amount
    from
      aws_account as c
      left join aws_cost_by_account_monthly as m on m.account_id = c.account_id
    where
      date(period_end) = date(current_timestamp)
  EOQ
}

query "aws_account_cost_table" {
  sql = <<-EOQ
   with previous_month as (
    select
      net_unblended_cost_amount,
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
      trunc(m.net_unblended_cost_amount::numeric, 2) as "Current MTD",
      trunc((m.net_unblended_cost_amount + mean_value)::numeric, 2) as "Forecast MTD",
      trunc(p.net_unblended_cost_amount::numeric, 2) as "Prevoius Month",
      case
        when ((m.net_unblended_cost_amount + mean_value - p.net_unblended_cost_amount)*100/p.net_unblended_cost_amount) > 0 then
          concat(trunc(((m.net_unblended_cost_amount + mean_value - p.net_unblended_cost_amount)*100/p.net_unblended_cost_amount)::numeric, 2), '%', '🔺')
        else
          concat(trunc(((m.net_unblended_cost_amount + mean_value - p.net_unblended_cost_amount)*100/p.net_unblended_cost_amount)::numeric, 2), '%', '🔻')
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

# Card Queries
