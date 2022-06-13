Thrifty developers need to keep an eye on data which is no longer required. It's great to be able to programmatically create backups and snapshots, but these too can become a source of unchecked cost if not watched closely. It's easy to delete an individual snapshot with a few clicks, but challenging to manage snapshots programmatically across multiple accounts. Over time, dozens of snapshots can turn into hundreds or thousands.

This dashboard answers the following questions:

- What CloudWatch log groups do not have any retention period enabled?
- What DynamoDB tables have stale data?
- What EBS snapshots, RDS snapshots and Redshift snapshots are no longer required? 
- What S3 buckets do not have any associated lifecycle policies?

## Variables

| Variable                                  | Description                                                                           | Default |
| ----------------------------------------- | ------------------------------------------------------------------------------------- | ------- |
| dynamodb_table_stale_data_max_days        | The maximum number of days table data can be unchanged before it is considered stale. | 90 days |
| ebs_snapshot_age_max_days                 | The maximum number of days EBS snapshots can be retained.                             | 90 days |
| rds_db_instance_snapshot_age_max_days     | The maximum number of days RDS DB instance snapshots can be retained.                 | 90 days |
| rds_db_cluster_snapshot_age_max_days      | The maximum number of days RDS DB cluster snapshots can be retained.                  | 90 days |
| redshift_snapshot_age_max_days            | The maximum number of days redshift snapshots can be retained.                        | 90 days |
| kinesis_stream_high_retention_period_days | The number of days for the data retention period to be considered as maximum.         | 1 day   |
