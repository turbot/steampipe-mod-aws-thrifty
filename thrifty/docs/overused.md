## Thrifty Overused Benchmark

Thrifty developers check overused AWS resources.

## Variables

| Variable                                     | Description                                                              | Default                                                                          |
| -------------------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| ebs_volume_max_iops                          | The maximum IOPS allowed for volumes.                                    | 32000 IOPS                                                                       |
| ebs_volume_max_size_gb                       | The maximum size (GB) allowed for volumes.                               | 100 GB                                                                           |
| ec2_running_instance_age_max_days            | The maximum number of days instances are allowed to run.                 | 90 days                                                                          |
| ec2_instance_allowed_types                   | A list of allowed instance types. PostgreSQL wildcards are supported.    | ["%.nano", "%.micro", "%.small", "%.medium", "%.large", "%.xlarge", "%._xlarge"] |
| elasticache_running_cluster_age_max_days     | The maximum number of days clusters are allowed to run.                  | 90 days                                                                          |
| elasticache_running_cluster_age_warning_days | The number of days clusters can be running before sending a warning.     | 30 days                                                                          |
| rds_running_db_instance_age_max_days         | The maximum number of days DB instances are allowed to run.              | 90 days                                                                          |
| rds_running_db_instance_age_warning_days     | The number of days DB instances can be running before sending a warning. | 30 days                                                                          |
| redshift_running_cluster_age_max_days        | The maximum number of days clusters are allowed to run.                  | 90 days                                                                          |
| redshift_running_cluster_age_warning_days    | The number of days clusters can be running before sending a warning.     | 30 days                                                                          |
