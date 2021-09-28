## Thrifty Redshift Benchmark

Thrifty developers check whether their long-running Redshift clusters are associated with reserved nodes.

## Variables

| Variable | Description | Default |
| - | - | - |
| redshift_running_cluster_age_max_days | The maximum number of days clusters are allowed to run. | 90 days |
| redshift_running_cluster_age_warning_days | The number of days after which a cluster set a warning. | 30 days |
| redshift_cluster_avg_cpu_utilization_low | The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than `redshift_cluster_avg_cpu_utilization_high`. | 20% |
| redshift_cluster_avg_cpu_utilization_high | The average CPU utilization required for clusters to be considered frequently used. This value should be higher than `redshift_cluster_avg_cpu_utilization_low`. | 35% |
