
control "stale_dynamodb_table_data" {
  title = "DynamoDB tables with stale data"
  description = "If the data has not changed in 90 days, is the table needed?"
  sql = query.dynamodb_stale_data.sql
  severity = "low"
  tags = {
    service = "dynamodb"
    code = "unused"
  }
}
