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
    control.dynamodb_table_stale_data
  ]
}

control "dynamodb_table_stale_data" {
  title         = "What DynamoDB tables have stale data? (Not changed in last 90 days)"
  description   = "If the data has not changed in 90 days, is the table needed?"
  sql           = query.dynamodb_table_stale_data.sql
  severity      = "low"
  tags = merge(local.dynamodb_common_tags, {
    class = "unused"
  })
}
