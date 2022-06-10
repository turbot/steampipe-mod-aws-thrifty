variable "dynamodb_table_stale_data_max_days" {
  type        = number
  description = "The maximum number of days table data can be unchanged before it is considered stale."
  default     = 90
}

variable "ebs_snapshot_age_max_days" {
  type        = number
  description = "The maximum number of days snapshots can be retained."
  default     = 90
}

variable "kinesis_stream_high_retention_period_days" {
  type        = number
  description = "The number of days for the data retention period to be considered as maximum."
  default     = 1
}

benchmark "stale_data" {
  title         = "Stale Data"
  description   = "Thrifty developers need to keep an eye on data which is no longer required. It's great to be able to programmatically create backups and snapshots, but these too can become a source of unchecked cost if not watched closely. It's easy to delete an individual snapshot with a few clicks, but challenging to manage snapshots programmatically across multiple accounts. Over time, dozens of snapshots can turn into hundreds or thousands."
  documentation = file("./thrifty/docs/stale_data.md")
  children = [
    control.cloudwatch_log_group_no_retention,
    control.dynamodb_table_stale_data,
    control.ebs_snapshot_age_90,
    control.kinesis_stream_high_retention_period,
    control.s3_bucket_with_no_lifecycle
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

control "cloudwatch_log_group_no_retention" {
  title       = "CloudWatch Log Groups retention should be enabled"
  description = "All log groups should have a defined retention configuration."
  sql         = query.cloudwatch_log_group_no_retention.sql
  severity    = "low"

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/CloudWatch"
  })
}

control "s3_bucket_with_no_lifecycle" {
  title       = "S3 buckets should have lifecycle policies"
  description = "S3 buckets should have a lifecycle policy associated for data retention."
  sql         = query.s3_bucket_without_lifecycle.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/S3"
  })
}

control "dynamodb_table_stale_data" {
  title       = "DynamoDB tables with stale data should be reviewed"
  description = "If the data has not changed recently and has become stale, the table should be reviewed."
  sql         = query.dynamodb_table_stale_data.sql
  severity    = "low"

  param "dynamodb_table_stale_data_max_days" {
    description = "The maximum number of days table data can be unchanged before it is considered stale."
    default     = var.dynamodb_table_stale_data_max_days
  }

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/DynamoDB"
  })
}

control "ebs_snapshot_age_90" {
  title       = "Old EBS snapshots should be deleted if not required"
  description = "Old EBS snapshots are likely unnecessary and costly to maintain."
  sql         = query.ebs_snapshot_age_90.sql
  severity    = "low"

  param "ebs_snapshot_age_max_days" {
    description = "The maximum number of days snapshots can be retained."
    default     = var.ebs_snapshot_age_max_days
  }

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EBS"
  })
}

control "kinesis_stream_high_retention_period" {
  title       = "Kinesis streams with high retention period should be reviewed"
  description = "Data retention period should not be high. Additional charges apply for data streams with a retention period of over 24 hours."
  sql         = query.kinesis_stream_high_retention_period.sql
  severity    = "low"

  param "kinesis_stream_high_retention_period_days" {
    description = "The number of days for the data retention period to be considered as maximum."
    default     = var.kinesis_stream_high_retention_period_days
  }

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Kinesis"
  })
}