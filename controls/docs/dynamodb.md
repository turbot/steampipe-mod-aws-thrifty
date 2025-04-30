## Thrifty DynamoDB Benchmark

Thrifty developers optimize their DynamoDB tables for cost efficiency. This benchmark focuses on identifying tables with stale data and those that could benefit from auto-scaling to reduce costs.

## Variables

| Variable | Description | Default |
| - | - | - |
| dynamodb_table_stale_data_max_days | The maximum number of days table data can be unchanged before it is considered stale. | 90 days |
| dynamodb_table_max_provisioned_capacity | The maximum provisioned capacity (RCU/WCU) allowed before the table is considered over-provisioned. | 10 |

## Controls

### DynamoDB Tables with Stale Data

Tables with data that hasn't been modified recently may be candidates for archival or deletion to reduce storage costs.

### DynamoDB Tables without Auto-scaling

Tables using provisioned capacity mode without auto-scaling may be over-provisioned and incurring unnecessary costs. Auto-scaling helps optimize costs by automatically adjusting read and write capacity based on actual usage patterns. Tables should either:
- Use on-demand (PAY_PER_REQUEST) capacity mode for unpredictable workloads
- Enable auto-scaling for provisioned capacity mode to optimize costs based on actual usage

### DynamoDB Tables with High Provisioned Capacity

Tables with high provisioned capacity may be over-provisioned and incurring unnecessary costs. Consider:
- Using auto-scaling to automatically adjust capacity based on actual usage
- Switching to on-demand capacity mode for unpredictable workloads
- Reviewing and adjusting capacity if consistently under-utilized
