variable "cloudwatch_log_stream_age_max_days" {
  type        = number
  description = "The maximum number of days log streams are allowed without any log event written to them."
  default     = 90
}

locals {
  cloudwatch_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/CloudWatch"
  })
}

benchmark "cloudwatch" {
  title         = "CloudWatch Checks"
  description   = "Thrifty developers actively manage the retention of their Cloudtrail logs."
  documentation = file("./controls/docs/cloudwatch.md")
  children = [
    control.cloudwatch_log_group_retention_disabled,
    control.cloudwatch_log_stream_unused
  ]

  tags = merge(local.cloudwatch_common_tags, {
    type = "Benchmark"
  })
}

control "cloudwatch_log_group_retention_disabled" {
  title       = "CloudWatch log groups retention should be enabled"
  description = "CloudWatch log groups without a defined retention period will retain logs indefinitely, which can lead to unnecessary storage costs and potential compliance issues. AWS best practices recommend configuring a retention policy for all log groups to ensure logs are kept only as long as required for operational and compliance needs. Review and set appropriate retention periods for all CloudWatch log groups."
  severity    = "low"

  tags = merge(local.cloudwatch_common_tags, {
    class = "stale_data"
  })
  sql = <<-EOQ
    select
      arn as resource,
      case
        when retention_in_days is null then 'alarm'
        else 'ok'
      end as status,
      case
        when retention_in_days is null then name || ' does not have data retention enabled.'
        else name || ' is set to ' || retention_in_days || ' day retention.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_cloudwatch_log_group;
  EOQ
}

control "cloudwatch_log_stream_unused" {
  title       = "CloudWatch log streams not receiving log events should be reviewed"
  description = "Unused CloudWatch log streams can accumulate over time, increasing storage costs and making log management more difficult. Regularly review and remove log streams that have not received log events within your organization’s defined retention period."
  severity    = "low"

  param "cloudwatch_log_stream_age_max_days" {
    description = "The maximum number of days log streams are allowed without any log event written to them."
    default     = var.cloudwatch_log_stream_age_max_days
  }

  tags = merge(local.cloudwatch_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when last_ingestion_time is null then 'error'
        when date_part('day', now() - last_ingestion_time) > $1 then 'alarm'
        else 'ok'
      end as status,
      case
        when last_ingestion_time is null then name || ' is not reporting a last ingestion time.'
        else name || ' last log ingestion was ' || date_part('day', now() - last_ingestion_time) || ' days ago.'
      end as reason
      ${local.common_dimensions_sql}
    from
      aws_cloudwatch_log_stream;
  EOQ
}
