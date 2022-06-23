## Thrifty ElastiCache Benchmark

Thrifty developers check their long-running ElastiCache clusters are associated with reserved nodes.

## Variables

| Variable | Description | Default |
| - | - | - |
| elasticache_redis_cluster_avg_cpu_utilization_high | The average CPU utilization required for clusters to be considered frequently used. This value should be higher than elasticache_redis_cluster_avg_cpu_utilization_low. | 35 |
| elasticache_redis_cluster_avg_cpu_utilization_low | The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than elasticache_redis_cluster_avg_cpu_utilization_high. | 20 |
| elasticache_running_cluster_age_max_days | The maximum number of days clusters are allowed to run. | 90 days |
| elasticache_running_cluster_age_warning_days | The number of days clusters can be running before sending a warning. | 30 days |
