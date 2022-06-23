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
  documentation = file("./thrifty/docs/cloudwatch.md")
  children = [
    control.cloudwatch_log_group_no_retention,
    control.cloudwatch_log_stream_unused,
  ]

  tags = merge(local.cloudwatch_common_tags, {
    type = "Benchmark"
  })
}

control "cloudwatch_log_group_no_retention" {
  title       = "CloudWatch log groups retention should be enabled"
  description = "All log groups should have a defined retention configuration."
  sql         = query.cloudwatch_log_group_no_retention.sql
  severity    = "low"

  tags = merge(local.cloudwatch_common_tags, {
    class = "managed"
  })
}

control "cloudwatch_log_stream_unused" {
  title       = "Unused CloudWatch log streams should be removed if not required"
  description = "Unnecessary CloudWatch log streams should be deleted for storage cost savings."
  sql         = query.cloudwatch_log_stream_unused.sql
  severity    = "low"

  param "cloudwatch_log_stream_age_max_days" {
    description = "The maximum number of days log streams are allowed without any log event written to them."
    default     = var.cloudwatch_log_stream_age_max_days
  }

  tags = merge(local.cloudwatch_common_tags, {
    class = "unused"
  })
}
