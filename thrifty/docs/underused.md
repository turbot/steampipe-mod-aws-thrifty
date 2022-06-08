## Thrifty Underused Benchmark

Thrifty developers check underused AWS resources. Large EC2 (or RDS, Redshift, ECS, etc) instances may have been created and sized to handle peak utilization but never reviewed later to see how well the storage, compute, and/or memory is being utilized. Consider rightsizing the instance type if an application is overprovisioned in any of these ways. AWS has different pricing for resources that are compute-optimized or memory-optimized. Analyze your inventory and utilization metrics to find resources that are underused, and prune them as warranted.

## Variables

| Variable                                  | Description                                                                                                                                                           | Default           |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| ebs_volume_avg_read_write_ops_high        | The number of average read/write ops required for volumes to be considered frequently used. This value should be higher than `ebs_volume_avg_read_write_ops_low`.     | 500 ops/min       |
| ebs_volume_avg_read_write_ops_low         | The number of average read/write ops required for volumes to be considered infrequently used. This value should be lower than `ebs_volume_avg_read_write_ops_high`.   | 100 ops/min       |
| ec2_instance_avg_cpu_utilization_high     | The average CPU utilization required for instances to be considered frequently used. This value should be higher than `ec2_instance_avg_cpu_utilization_low`.         | 35%               |
| ec2_instance_avg_cpu_utilization_low      | The average CPU utilization required for instances to be considered infrequently used. This value should be lower than `ec2_instance_avg_cpu_utilization_high`.       | 20%               |
| ecs_cluster_avg_cpu_utilization_high      | The average CPU utilization required for clusters to be considered frequently used. This value should be higher than `ecs_cluster_avg_cpu_utilization_low`.           | 35%               |
| ecs_cluster_avg_cpu_utilization_low       | The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than `ecs_cluster_avg_cpu_utilization_high`.         | 20%               |
| elasticache_redis_cluster_avg_cpu_utilization_high       | The average CPU utilization required for clusters to be considered frequently used. This value should be higher than `elasticache_redis_cluster_avg_cpu_utilization_low`.         | 35%               |
| elasticache_redis_cluster_avg_cpu_utilization_low       | The average CPU utilization required for clusters to be considered frequently used. This value should be lower than `elasticache_redis_cluster_avg_cpu_utilization_high`.         | 20%               |
| rds_db_instance_avg_connections           | The minimum number of average connections per day required for DB instances to be considered in-use.                                                                  | 2 connections/day |
| rds_db_instance_avg_cpu_utilization_high  | The average CPU utilization required for DB instances to be considered frequently used. This value should be higher than `rds_db_instance_avg_cpu_utilization_low`.   | 50%               |
| rds_db_instance_avg_cpu_utilization_low   | The average CPU utilization required for DB instances to be considered infrequently used. This value should be lower than `rds_db_instance_avg_cpu_utilization_high`. | 25%               |
| redshift_cluster_avg_cpu_utilization_high | The average CPU utilization required for clusters to be considered frequently used. This value should be higher than `redshift_cluster_avg_cpu_utilization_low`.      | 35%               |
| redshift_cluster_avg_cpu_utilization_low  | The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than `redshift_cluster_avg_cpu_utilization_high`.    | 20%               |
