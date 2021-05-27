## Thrifty DynamoDB Benchmark

Thrifty developers keep a careful eye for unused and under-utilized EBS volumes. Elastic block store is a key component of hidden cost on AWS, and this benchmark looks for EBS volumes that are unused, under-utilized, out-dates and over-sized.

### Default Thresholds
- [High IOPS threshold (32,000 IOPS)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/ebs/high_iops_volumes.sql#L5)
- [Low IOPS threshold (3,000 IOPS)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/ebs/low_iops_volumes.sql#L5)
- [Large EBS volume size threshold (100gb)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/ebs/large_ebs_volumes.sql#L4)
- [Very Low EBS usage threshold (100 Max Write Operations/min)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/ebs/low_usage_ebs_volumes.sql#L41)
- [Low EBS usage threshold (100 Max Write Operations/min)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/ebs/low_usage_ebs_volumes.sql#L42)
- [Old EBS Snapshots threshold (90 days)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/ebs/old_ebs_snapshots.sql#L4)
