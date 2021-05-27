locals {
  dynamodb_common_tags = merge(local.thrifty_common_tags, {
    service = "dynamodb"
  })
}

benchmark "dynamodb" {
  title         = "Thrifty DynamoDB Checks"
  description   = "Thrifty developers delete DynamoDB tables with stale data."
  documentation = file("./controls/docs/dynamodb.md") #TODO
  tags          = local.dynamodb_common_tags
  children = [
    control.stale_dynamodb_table_data
  ]
}

control "stale_dynamodb_table_data" {
  title         = "DynamoDB tables with stale data"
  description   = "If the data has not changed in 90 days, is the table needed?"
  documentation = file("./controls/docs/dynamodb-1.md") #TODO
  sql           = query.dynamodb_stale_data.sql
  severity      = "low"
  tags = merge(local.dynamodb_common_tags, {
    code = "unused"
  })
}
