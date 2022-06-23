variable "dynamodb_table_stale_data_max_days" {
  type        = number
  description = "The maximum number of days table data can be unchanged before it is considered stale."
  default     = 90
}

locals {
  dynamodb_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/DynamoDB"
  })
}

benchmark "dynamodb" {
  title         = "DynamoDB Checks"
  description   = "Thrifty developers delete DynamoDB tables with stale data."
  documentation = file("./thrifty/docs/dynamodb.md")
  children = [
    control.dynamodb_table_autoscaling_disabled,
    control.dynamodb_table_stale_data
  ]

  tags = merge(local.dynamodb_common_tags, {
    type = "Benchmark"
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

  tags = merge(local.dynamodb_common_tags, {
    class = "stale_data"
  })
}

control "dynamodb_table_autoscaling_disabled" {
  title       = "DynamoDB tables should have auto scaling enabled"
  description = "Amazon DynamoDB auto scaling uses the AWS Application Auto Scaling service to adjust provisioned throughput capacity that automatically responds to actual traffic patterns. Turning on the auto scaling feature will help to improve service performance in a cost-efficient way."
  sql         = query.dynamodb_table_autoscaling_disabled.sql
  severity    = "low"

  tags = merge(local.dynamodb_common_tags, {
    class = "overused"
  })
}
