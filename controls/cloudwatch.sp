variable "cloudwatch_log_stream_max_age" {
  type        = number
  description = "The maximum number of days log streams are allowed without any log event written to it."
}

locals {
  cloudwatch_common_tags = merge(local.thrifty_common_tags, {
    service = "cloudwatch"
  })
}

benchmark "cloudwatch" {
  title         = "CloudWatch Checks"
  description   = "Thrifty developers actively manage the retention of their Cloudtrail logs."
  documentation = file("./controls/docs/cloudwatch.md")
  tags          = local.cloudwatch_common_tags
  children = [
    control.cw_log_group_retention,
    control.cw_log_stream_unused
  ]
}

control "cw_log_group_retention" {
  title         = "CloudWatch Log Groups retention should be enabled"
  description   = "All log groups should have a defined retention configuration."
  sql           = query.cw_log_group_without_retention.sql
  severity      = "low"
  tags = merge(local.cloudwatch_common_tags, {
    class = "managed"
  })
}

control "cw_log_stream_unused" {
  title         = "Unused log streams should be removed if not required"
  description   = "Unnecessary log streams should be deleted for storage cost savings."
  sql           = query.stale_cw_log_stream.sql
  severity      = "low"

  param "cloudwatch_log_stream_max_age" {
    description = "The maximum number of days log streams are allowed without any log event written to it."
    default     = var.cloudwatch_log_stream_max_age
  }

  tags = merge(local.cloudwatch_common_tags, {
    class = "unused"
  })
}
