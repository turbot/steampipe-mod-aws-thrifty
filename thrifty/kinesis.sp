variable "kinesis_stream_high_retention_period_days" {
  type        = number
  description = "The number of days for the data retention period to be considered as maximum."
  default     = 1
}

locals {
  kinesis_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Kinesis"
  })
}

benchmark "kinesis" {
  title         = "Kinesis Checks"
  description   = "Thrifty developers actively manage their Kinesis stream resources."
  documentation = file("./thrifty/docs/kinesis.md")
  children = [
    control.kinesis_stream_consumer_with_enhanced_fan_out,
    control.kinesis_stream_high_retention_period
  ]

  tags = merge(local.kinesis_common_tags, {
    type = "Benchmark"
  })
}

control "kinesis_stream_consumer_with_enhanced_fan_out" {
  title       = "Kinesis stream consumers with the enhanced fan-out feature should be reviewed"
  description = "The enhanced fan-out feature should be avoided. Enhanced fan-out shard hours cost $36.00 (USD) per day."
  sql         = query.kinesis_stream_consumer_with_enhanced_fan_out.sql
  severity    = "low"

  tags = merge(local.aws_thrifty_common_tags, {
    class = "capacity_planning"
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
    class = "stale_data"
  })
}
