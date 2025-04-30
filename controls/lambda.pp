locals {
  lambda_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Lambda"
  })
}

variable "lambda_memory_excessive_threshold" {
  type        = number
  description = "Memory threshold (in MB) above which Lambda functions are considered to have excessive allocation."
  default     = 1024
}

variable "lambda_memory_high_threshold" {
  type        = number
  description = "Memory threshold (in MB) above which Lambda functions are considered to have high allocation."
  default     = 512
}

benchmark "lambda" {
  title         = "Lambda Checks"
  description   = "Thrifty developers ensure their Lambda functions are optimized."
  documentation = file("./controls/docs/lambda.md")

  children = [
    control.lambda_function_excessive_timeout,
    control.lambda_function_high_error_rate,
    control.lambda_function_with_graviton,
    control.lambda_function_excessive_memory
  ]

  tags = merge(local.lambda_common_tags, {
    type = "Benchmark"
  })
}

control "lambda_function_high_error_rate" {
  title       = "Are there any lambda functions with high error rate?"
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
  title       = "Are there any lambda functions with excessive timeout?"
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
        when avg_duration is null then 'CloudWatch lambda metrics not available for ' || title || '.'
        else title || ' Timeout of ' || timeout::numeric*1000 || ' milliseconds is ' || round(((timeout :: numeric*1000)-avg_duration)/(timeout :: numeric*1000)*100,1) || '% more as compared to average of ' || round(avg_duration,0) || ' milliseconds.'
      end as reason
        ${local.tag_dimensions_sql}
        ${local.common_dimensions_sql}
    from
      aws_lambda_function f
      left join lambda_duration as d on f.name = d.name;
  EOQ
}

control "lambda_function_with_graviton" {
  title       = "Are there any lambda functions without graviton processor?"
  description = "With graviton processor (arm64 - 64-bit ARM architecture), you can save money in two ways. First, your functions run more efficiently due to the Graviton architecture. Second, you pay less for the time that they run. In fact, Lambda functions powered by Graviton are designed to deliver up to 19 percent better performance at 20 percent lower cost."
  severity    = "low"

  tags = merge(local.lambda_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when architecture = 'arm64' then 'ok'
        else 'alarm'
      end as status,
      case
        when architecture = 'arm64' then title || ' is using Graviton processor.'
        else title || ' is not using Graviton processor.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_lambda_function,
      jsonb_array_elements_text(architectures) as architecture;
  EOQ

}

control "lambda_function_excessive_memory" {
  title       = "Which lambda functions have excessive memory allocation?"
  description = "Lambda functions with excessive memory allocation can lead to unnecessary costs. Functions with more than ${var.lambda_memory_excessive_threshold}MB of memory should be reviewed for optimization opportunities."
  severity    = "low"

  tags = merge(local.lambda_common_tags, {
    class = "managed"
  })

  param "memory_excessive_threshold" {
    description = "Memory threshold (in MB) above which Lambda functions are considered to have excessive allocation."
    default     = var.lambda_memory_excessive_threshold
  }

  param "memory_high_threshold" {
    description = "Memory threshold (in MB) above which Lambda functions are considered to have high allocation."
    default     = var.lambda_memory_high_threshold
  }

  sql = <<-EOQ
    select
      f.arn as resource,
      case
        when f.memory_size >= ($1::int) then 'alarm'
        when f.memory_size >= ($2::int) then 'info'
        else 'ok'
      end as status,
      case
        when f.memory_size >= ($1::int) then title || ' has excessive memory allocation of ' || f.memory_size || ' MB.'
        when f.memory_size >= ($2::int) then title || ' has high memory allocation of ' || f.memory_size || ' MB.'
        else title || ' has reasonable memory allocation of ' || f.memory_size || ' MB.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_lambda_function f
    order by
      f.memory_size desc;
  EOQ
}
