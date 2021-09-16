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
    control.cloudwatch_log_group_no_retention,
    control.cloudwatch_log_stream_stale
  ]
}

control "cloudwatch_log_group_no_retention" {
  title         = "Is retention enabled for your CloudWatch Log Groups?"
  description   = "All log groups should have a defined retention configuration."
  sql           = query.cloudwatch_log_group_no_retention.sql
  severity      = "low"
  tags = merge(local.cloudwatch_common_tags, {
    class = "managed"
  })
}

control "cloudwatch_log_stream_stale" {
  title         = "Are CloudWatch log streams active? (i.e. written to in last 90 days)"
  description   = "Unnecessary log streams should be deleted for storage cost savings."
  sql           = query.cloudwatch_log_stream_stale.sql
  severity      = "low"
  tags = merge(local.cloudwatch_common_tags, {
    class = "unused"
  })
}
