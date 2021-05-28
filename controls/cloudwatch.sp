locals {
  cloudwatch_common_tags = merge(local.thrifty_common_tags, {
    service = "cloudwatch"
  })
}

benchmark "cloudwatch" {
  title         = "CloudWatch Checks"
  description   = "Thrifty developers actively manage the retention of their Cloudtrail logs."
  documentation = file("./controls/docs/cloudwatch.md") #TODO
  tags          = local.cloudwatch_common_tags
  children = [
    control.cw_log_group_retention,
    control.cw_log_stream_unused
  ]
}

control "cw_log_group_retention" {
  title         = "Is retention enabled for your CloudWatch Log Groups?"
  description   = "All log groups should have a defined retention configuration."
  sql           = query.cw_log_group_without_retention.sql
  severity      = "low"
  tags = merge(local.cloudwatch_common_tags, {
    class = "managed"
  })
}

control "cw_log_stream_unused" {
  title         = "Are CloudWatch log streams active? (i.e. written to in last 90 days)"
  description   = "Uneeded log streams should be deleted for storage cost savings."
  sql           = query.stale_cw_log_stream.sql
  severity      = "low"
  tags = merge(local.cloudwatch_common_tags, {
    class = "unused"
  })
}
