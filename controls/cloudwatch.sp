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
    control.cw_log_group_retention,
    control.cw_log_stream_unused
  ]

  tags = merge(local.cloudwatch_common_tags, {
    type = "Benchmark"
  })
}

control "cw_log_group_retention" {
  title       = "CloudWatch Log Groups retention should be enabled"
  description = "All log groups should have a defined retention configuration."
  severity    = "low"

  tags = merge(local.cloudwatch_common_tags, {
    class = "managed"
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

control "cw_log_stream_unused" {
  title       = "Unused log streams should be removed if not required"
  description = "Unnecessary log streams should be deleted for storage cost savings."
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
