## Thrifty Stale Data Benchmark

Thrifty developers need to keep an eye on data which is no longer required. It's great to be able to programmatically create backups and snapshots, but these too can become a source of unchecked cost if not watched closely. It's easy to delete an individual snapshot with a few clicks, but challenging to manage snapshots programmatically across multiple accounts. Over time, dozens of snapshots can turn into hundreds or thousands.

## Variables

| Variable                           | Description                                                                           | Default |
| ---------------------------------- | ------------------------------------------------------------------------------------- | ------- |
| dynamodb_table_stale_data_max_days | The maximum number of days table data can be unchanged before it is considered stale. | 90 days |
| ebs_snapshot_age_max_days          | The maximum number of days snapshots can be retained.                                 | 90 days |
