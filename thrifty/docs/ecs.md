## Thrifty ECS Benchmark

Thrifty developers eliminate their underutilized ECS clusters and ECS services without an autoscaling policy. This benchmark focuses on finding ECS clusters that have low utilization and an ECS service without an autoscaling policy.

## Variables

| Variable | Description | Default |
| - | - | - |
| ecs_cluster_avg_cpu_utilization_high | The average CPU utilization required for clusters to be considered frequently used. This value should be higher than ecs_cluster_avg_cpu_utilization_low. | 35% |
| ecs_cluster_avg_cpu_utilization_low | The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than ecs_cluster_avg_cpu_utilization_high. | 20% |
