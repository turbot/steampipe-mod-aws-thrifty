## Thrifty DynamoDB Benchmark

Thrifty developers archive DynamoDB tables with stale data. This benchmark focuses on finding tables where the data has not been changed recently.

## Variables

| Variable | Description | Default |
| - | - | - |
| dynamodb_table_stale_data_max_days | The maximum number of days table data can be unchanged before it is considered stale. | 90 days |
