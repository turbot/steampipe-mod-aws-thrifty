dashboard "account_service_detail" {

  title = "AWS Account Service Detail"

  tags = merge(local.account_common_tags, {
    type = "Detail"
  })

  input "service" {
    title = "Select a service:"
    query = query.account_service_list
    width = 4
  }

  container {

    chart {

      query = query.account_per_service_by_usage_mtd
      type  = "column"
      args  = [self.input.service.value]

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


  container{

    input "period" {
      title = "Select a period:"
      width = 4
      option "Three Months" {}
      option "Six Months" {}
      option "One Year" {}
    }

    chart {

      query = query.aws_service_cost_by_account_chart
      type  = "column"
      args  = [self.input.service.value, self.input.period.value]

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

}

# Input queries

query "account_service_list" {
  sql = <<-EOQ
    select
      distinct service as label,
      service as value
    from
      aws_cost_by_service_monthly
    order by
      service;
  EOQ
}

query "aws_service_cost_by_account_chart" {
  sql = <<-EOQ
  select
    period_start,
    a.title,
    sum(net_unblended_cost_amount) as current_month_cost
  from
    aws_account as a
    left join aws_cost_by_service_monthly as m on m.account_id = a.account_id
  where
    1 = 1
    and service = $1
    and case
      when $2 = 'Three Months' then period_start >= (date_trunc('month', now()) -interval '2 month')
      when $2  = 'Six Months' then period_start >= (date_trunc('month', now()) -interval '4 month')
      when $2  = 'One Year' then period_start >= (date_trunc('month', now()) -interval '11 month') end
  group by a.account_id, period_start, a.title
  order by period_start asc
  EOQ
}

query "account_per_service_by_usage_mtd" {
  sql = <<-EOQ
    select
      period_start,
      a.title,
      unblended_cost_amount as value
    from
      aws_account as a
      left join aws_cost_by_service_daily as m on m.account_id = a.account_id
    where
      period_start >= date_trunc('month', now())
      and period_end <= now()
      and service = $1
    group by a.account_id, period_start, unblended_cost_amount, a.title
    order by
      period_start

  EOQ
}