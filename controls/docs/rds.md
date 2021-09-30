## Thrifty RDS Benchmark

Thrifty developers eliminate their unused and under-utilized RDS instances. This benchmark focuses on testing your RDS DB instances to ensure they are in-use, correctly-sized and using the latest cost-effective instance types.

## Variables

| Variable | Description | Default |
| - | - | - |
| rds_db_instance_avg_connections | The minimum number of average connections per day required for DB instances to be considered in-use. | 2 connections/day |
| rds_db_instance_avg_cpu_utilization_high | The average CPU utilization required for DB instances to be considered frequently used. This value should be higher than rds_db_instance_avg_cpu_utilization_low. | 50% |
| rds_db_instance_avg_cpu_utilization_low | The average CPU utilization required for DB instances to be considered infrequently used. This value should be lower than rds_db_instance_avg_cpu_utilization_high. | 25% |
| rds_running_db_instance_age_max_days | The maximum number of days DB instances are allowed to run. | 90 days |
| rds_running_db_instance_age_warning_days | The number of days DB instances can be running before sending a warning. | 30 days |
