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
  documentation = file("./controls/docs/dynamodb.md")
  children = [
    control.dynamodb_table_stale_data
  ]

  tags = merge(local.dynamodb_common_tags, {
    type = "Benchmark"
  })
}

control "dynamodb_table_stale_data" {
  title         = "What DynamoDB tables have stale data? (Not changed in last 90 days)"
  description   = "If the data has not changed in 90 days, is the table needed?"
  sql           = query.dynamodb_table_stale_data.sql
  severity      = "low"

  param "dynamodb_table_stale_data_max_days" {
    description = "The maximum number of days table data can be unchanged before it is considered stale."
    default     = var.dynamodb_table_stale_data_max_days
  }

  tags = merge(local.dynamodb_common_tags, {
    class = "unused"
  })
}
