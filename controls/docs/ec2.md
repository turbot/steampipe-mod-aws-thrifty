## Thrifty EC2 Benchmark

Thrifty developers eliminate their unused and underutilized EC2 instances. This benchmark focuses on finding resources that have not been restarted recently, have low utilization, using very large instance sizes, and reserved instances scheduled to expire within the next 30 days or have expired in the preceding 30 days.

## Variables

| Variable | Description | Default |
| - | - | - |
| ec2_running_instance_age_max_days | The maximum number of days instances are allowed to run. | 90 days |
| ec2_instance_avg_cpu_utilization_low | The average CPU utilization required for instances to be considered infrequently used. This value should be lower than `ec2_instance_avg_cpu_utilization_high`. | 20% |
| ec2_instance_avg_cpu_utilization_high | The average CPU utilization required for instances to be considered frequently used. This value should be higher than `ec2_instance_avg_cpu_utilization_low`. | 35% |
| ec2_reserved_instance_expiration_warning_days | The number of days configured to set an expiration alert for a reserved instance. | 30 days |
