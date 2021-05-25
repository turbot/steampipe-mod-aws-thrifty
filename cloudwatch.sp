
control "cw_log_group_without_retention" {
  title = "Cloudwatch Log Groups not configured for retention"
  description = "All log groups should have a defined retention configuration."
  sql = query.cw_log_group_without_retention.sql
  severity = "low"
  tags = {
    service = "cloudwatch"
    code = "managed"
  }
}

control "unused_cw_log_stream" {
  title = "Cloudwatch Log Stream not written to in last 90 days"
  description = "Uneeded log streams should be deleted for storage cost savings."
  sql = query.stale_cw_log_stream.sql
  severity = "low"
  tags = {
    service = "cloudwatch"
    code = "unused"
  }
}
