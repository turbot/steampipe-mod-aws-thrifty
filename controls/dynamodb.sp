variable "dynamodb_table_stale_data_max_days" {
  type        = number
  description = "The maximum number of days table data can be unchanged before it is considered stale."
  default     = 90
}

locals {
  dynamodb_common_tags = merge(local.thrifty_common_tags, {
    service = "dynamodb"
  })
}

benchmark "dynamodb" {
  title         = "DynamoDB Checks"
  description   = "Thrifty developers delete DynamoDB tables with stale data."
  documentation = file("./controls/docs/dynamodb.md")
  tags          = local.dynamodb_common_tags
  children = [
    control.stale_dynamodb_table_data
  ]
}

control "stale_dynamodb_table_data" {
  title         = "Tables with stale data should be reviewed"
  description   = "If the data has not changed recently and has become stale, the table should be reviewed."
  sql           = query.dynamodb_stale_data.sql
  severity      = "low"

  param "dynamodb_table_stale_data_max_days" {
    description = "The maximum number of days table data can be unchanged before it is considered stale."
    default     = var.dynamodb_table_stale_data_max_days
  }

  tags = merge(local.dynamodb_common_tags, {
    class = "unused"
  })
}
