dashboard "account_cost_detail" {

  title = "AWS Account Detail"

  tags = merge(local.account_common_tags, {
    type = "Detail"
  })

  input "account_id" {
    title = "Select an account:"
    query = query.account_id_input
    width = 4
  }

  container {
    card {
      query = query.account_current_cost_mtd
      width = 3
      args  = [self.input.account_id.value]
    }

    card {
      query = query.account_forecast_cost_mtd
      width = 3
      args  = [self.input.account_id.value]
    }

    card {
      query = query.account_current_cost_ytd
      width = 3
      args  = [self.input.account_id.value]
    }

    card {
      query = query.account_forecast_cost_ytd
      width = 3
      args  = [self.input.account_id.value]
    }
  }

  container {

    chart {
      title = "Cost by Month"
      query = query.account_cost_last_twelve_months
      type = "line"
      args  = [self.input.account_id.value]

      axes {
        x {
          title {
           value  = "Month"
          }
          labels {
            display = "always"
          }
        }

        y {
          title {
           value  = "Cost($)"
          }
          labels {
            display = "always"
          }
        }
      }
    }
  }

}

# Input queries

query "account_id_input" {
  sql = <<-EOQ
    select
      title as label,
      account_id as value,
      json_build_object(
        'account_aliases', account_aliases
      ) as tags
    from
      aws_account
    order by
      title;
  EOQ
}

query "account_current_cost_mtd" {
  sql = <<-EOQ
    select
      'Current MTD' as label,
      net_unblended_cost_amount as value
    from
      aws_cost_by_account_monthly
   where
    date(period_end) = date(current_timestamp)
    and account_id = $1
  EOQ
}

query "account_forecast_cost_mtd" {
  sql = <<-EOQ
    select
      'Forecast MTD' as label,
      net_unblended_cost_amount + mean_value as value
    from
      aws_cost_by_account_monthly as m,
      aws_cost_forecast_daily as d
   where
    date(m.period_end) = date(current_timestamp)
    and date(d.period_start) = date(current_timestamp)
    and m.account_id = $1
    and d.account_id = $1
  EOQ
}

query "account_current_cost_ytd" {
  sql = <<-EOQ
    select
      'Current YTD' as label,
      sum(unblended_cost_amount) as value
    from
      aws_cost_by_account_monthly
    where
      period_start >= date_trunc('year', now())
      and period_end <= now()
      and linked_account_id = $1
    group by
      linked_account_id
  EOQ
}

query "account_forecast_cost_ytd" {
  sql = <<-EOQ
    select
      'Forecast YTD' as label,
      sum(unblended_cost_amount) + mean_value as value
    from
      aws_cost_by_account_monthly as m,
      aws_cost_forecast_daily as d
    where
      m.period_start >= date_trunc('year', now())
      and m.period_end <= now()
      and m.linked_account_id = $1
      and date(d.period_start) = date(current_timestamp)
      and d.account_id = $1
    group by
      linked_account_id,
      mean_value
  EOQ
}

query "account_cost_last_twelve_months" {
  sql = <<-EOQ
    select
      period_start as label,
      unblended_cost_amount as value
    from
      aws_cost_by_account_monthly
    where
      account_id = $1
    order by
      period_start
  EOQ
}

query "account_cost_by_service" {
  sql = <<-EOQ
    select
      period_start as label,
      unblended_cost_amount as value
    from
      aws_cost_by_account_monthly
    where
      account_id = $1
  EOQ
}

