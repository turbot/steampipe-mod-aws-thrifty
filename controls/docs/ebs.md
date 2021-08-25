## Thrifty EBS Benchmark

Thrifty developers keep a careful eye for unused and under-utilized EBS volumes. Elastic block store is a key component of hidden cost on AWS, and this benchmark looks for EBS volumes that are unused, under-utilized, out-dates and oversized.

### Default Thresholds

- [High IOPS threshold (32,000 IOPS)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/high_iops_volumes)
- [Low IOPS threshold (3,000 IOPS)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/low_iops_volumes)
- [Large EBS volume size threshold (100gb)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/large_ebs_volumes)
- [Very Low EBS usage threshold (100 Max Write Operations/min)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/low_usage_ebs_volumes)
- [Low EBS usage threshold (100 Max Write Operations/min)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/low_usage_ebs_volumes)
- [Old EBS Snapshots threshold (90 days)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/old_ebs_snapshots)
