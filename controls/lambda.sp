locals {
  lambda_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Lambda"
  })
}

benchmark "lambda" {
  title         = "Lambda Cost Checks"
  description   = "Thrifty developers ensure their Lambda functions are optimized."
  documentation = file("./controls/docs/lambda.md")

  children = [
    control.lambda_function_excessive_timeout,
    control.lambda_function_high_error_rate,
    control.lambda_function_with_graviton2
  ]

  tags = merge(local.lambda_common_tags, {
    type = "Benchmark"
  })
}

control "lambda_function_high_error_rate" {
  title       = "Are there any Lambda functions with high error rate?"
  description = "Function errors may result in retries that incur extra charges. The control checks for functions with an error rate of more than 10% a day in one of the last 7 days."
  severity    = "low"
  tags = merge(local.lambda_common_tags, {
    class = "managed"
  })

  sql = <<-EOQ
    with error_rate as (
      select
        errors.name as name,
        sum(errors.sum)/sum(invocations.sum)*100 as error_rate
      from
        aws_lambda_function_metric_errors_daily as errors , aws_lambda_function_metric_invocations_daily as invocations
      where
        date_part('day', now() - errors.timestamp) <=7 and errors.name = invocations.name
      group by
        errors.name
    )
    select
      arn as resource,
      case
        when error_rate is null then 'error'
        when error_rate > 10 then 'alarm'
        else 'ok'
      end as status,
      case
        when error_rate is null then 'CloudWatch Lambda function metrics not available for ' || title || '.'
        else title || ' error rate is ' || error_rate || '% the last ' || '7  days.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_lambda_function f
      left join error_rate as er on f.name = er.name;
  EOQ
}

control "lambda_function_excessive_timeout" {
  title       = "Are there any Lambda functions with excessive timeout?"
  description = "Excessive timeouts result in retries and additional execution time for the function, incurring request charges and billed duration. The control checks for functions with a timeout rate of more than 10% a day in one of the last 7 days."
  severity    = "low"
  tags = merge(local.lambda_common_tags, {
    class = "managed"
  })

  sql = <<-EOQ
    with lambda_duration as (
      select
        name,
        avg(average:: numeric) as avg_duration
      from
        aws_lambda_function_metric_duration_daily
      where
        date_part('day', now() - timestamp) <=7
      group by
        name
    )
    select
      arn as resource,
      case
        when avg_duration is null then 'error'
        when ((timeout :: numeric*1000) - avg_duration)/(timeout :: numeric*1000) > 0.1 then 'alarm'
        else 'ok'
      end as status,
      case
        when avg_duration is null then 'CloudWatch Lambda metrics not available for ' || title || '.'
        else title || ' Timeout of ' || timeout::numeric*1000 || ' milliseconds is ' || round(((timeout :: numeric*1000)-avg_duration)/(timeout :: numeric*1000)*100,1) || '% more as compared to average of ' || round(avg_duration,0) || ' milliseconds.'
      end as reason
        ${local.tag_dimensions_sql}
        ${local.common_dimensions_sql}
    from
      aws_lambda_function f
      left join lambda_duration as d on f.name = d.name;
  EOQ
}

control "lambda_function_with_graviton2" {
  title       = "Are there any Lambda functions without graviton2 processor?"
  description = "With graviton2 processor (arm64 - 64-bit ARM architecture), you can save money in two ways. First, your functions run more efficiently due to the Graviton2 architecture. Second, you pay less for the time that they run. In fact, Lambda functions powered by Graviton2 are designed to deliver up to 19 percent better performance at 20 percent lower cost."
  severity    = "low"

  tags = merge(local.lambda_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    with lambda_function_list as (
      select
        title,
        arn,
        architecture,
        memory_size,
        region,
        account_id,
        _ctx
      from
        aws_lambda_function,
        jsonb_array_elements_text(architectures) as architecture
    ),
    lambda_function_regions as (
      select
        distinct region
      from
        aws_lambda_function
    ),
    lambda_pricing as (
      select
        r.region,
        p.currency,
        max(case when p.attributes ->> 'group' = 'AWS-Lambda-Duration-ARM' and p.begin_range = '0' then (p.price_per_unit)::numeric else null end) as arm_tier_1_price,
        max(case when p.attributes ->> 'group' = 'AWS-Lambda-Duration' and p.begin_range = '0' then  (p.price_per_unit)::numeric else null end) as x86_64_price
      from
        aws_pricing_product as p
        join lambda_function_regions as r on
          p.service_code = 'AWSLambda'
          and p.filters in (
            '{"group": "AWS-Lambda-Duration"}' :: jsonb,
            '{"group": "AWS-Lambda-Duration-ARM"}' :: jsonb
          )
          and p.attributes ->> 'regionCode' = r.region
          and p.begin_range = '0' -- calculating based on the Tier-1 price
      group by r.region, p.currency
    ) ,
    calculate_savings_per_function as (
      select
        l.title,
        l.arn,
        l.architecture,
        l.region,
        l.account_id,
        l._ctx,
        case
        when l.architecture = 'x86_64' then ((p.x86_64_price::float - p.arm_tier_1_price::float) * 3600 * (l.memory_size/1024.0) * 24 * 30)::numeric(10,2) || ' ' || currency || '/month'
          else ''
        end as net_savings,
        p.currency
      from
        lambda_function_list as l
        join lambda_pricing as p on l.region = p.region
    )
    select
      arn as resource,
      case
        when architecture = 'arm64' then 'ok'
        else 'alarm'
      end as status,
      case
        when architecture = 'arm64' then title || ' is using Graviton2 processor.'
        else title || ' is not using Graviton2 processor.'
      end as reason
      ${local.common_dimensions_savings_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      calculate_savings_per_function;
  EOQ
}
