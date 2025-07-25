## Thrifty DynamoDB Benchmark

Thrifty developers optimize their DynamoDB tables for cost efficiency. This benchmark focuses on identifying tables with stale data and those that could benefit from auto-scaling to reduce costs.

## Variables

| Variable | Description | Default |
| - | - | - |
| dynamodb_table_with_stale_data_max_days | The maximum number of days table data can be unchanged before it is considered stale. | 90 days |

