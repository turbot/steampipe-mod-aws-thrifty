locals {
  cloudwatch_common_tags = merge(local.thrifty_common_tags, {
    service = "cloudwatch"
  })
}

benchmark "cloudwatch" {
  title         = "Thrifty CloudWatch Checks"
  description   = "Thrifty developers actively manage the retention of their Cloudtrail logs."
  documentation = file("./controls/docs/cloudwatch.md") #TODO
  tags          = local.cloudwatch_common_tags
  children = [
    control.cw_log_group_retention,
    control.cw_log_stream_unused
  ]
}

control "cw_log_group_retention" {
  title         = "Cloudwatch Log Groups not configured for retention"
  description   = "All log groups should have a defined retention configuration."
  documentation = file("./controls/docs/cloudwatch-1.md") #TODO
  sql           = query.cw_log_group_without_retention.sql
  severity      = "low"
  tags = merge(local.cloudwatch_common_tags, {
    code = "managed"
  })
}

control "cw_log_stream_unused" {
  title         = "Cloudwatch Log Stream not written to in last 90 days"
  description   = "Uneeded log streams should be deleted for storage cost savings."
  documentation = file("./controls/docs/cloudwatch-1.md") #TODO
  sql           = query.stale_cw_log_stream.sql
  severity      = "low"
  tags = merge(local.cloudwatch_common_tags, {
    code = "unused"
  })
}
