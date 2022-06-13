Thrifty developers ensure that long running resources are strategically planned. If you have long-running resources, it's a good idea to prepurchase reserved instances at lower cost. This can apply to long-running resources including EC2 instances, RDS instances, and Redshift clusters. You should also keep an eye on EC2 reserved instances that are scheduled for expiration, or have expired in the preceding 30 days, to verify that these cost-savers are in fact no longer needed.

This dashboard answers the following questions:

- What EC2 instances, Elasticache clusters, RDS DB instances, Redshift clusters have been running for a long time?
- What DynamoDB tables have auto scaling disabled?
- What EBS volumes have less than 3k base IOPS performance?

## Variables

| Variable                                      | Description                                                                    | Default |
| --------------------------------------------- | ------------------------------------------------------------------------------ | ------- |
| ec2_reserved_instance_expiration_warning_days | The number of days reserved instances can be running before sending a warning. | 30 days |
| ec2_running_instance_age_max_days             | The maximum number of days instances are allowed to run.                       | 90 days |
| elasticache_running_cluster_age_max_days      | The maximum number of days clusters are allowed to run.                        | 90 days |
| elasticache_running_cluster_age_warning_days  | The number of days clusters can be running before sending a warning.           | 30 days |
| rds_running_db_instance_age_max_days          | The maximum number of days DB instances are allowed to run.                    | 90 days |
| rds_running_db_instance_age_warning_days      | The number of days DB instances can be running before sending a warning.       | 30 days |
| redshift_running_cluster_age_max_days         | The maximum number of days clusters are allowed to run.                        | 90 days |
| redshift_running_cluster_age_warning_days     | The number of days clusters can be running before sending a warning.           | 30 days |
