## Thrifty EC2 Benchmark

Thrifty developers eliminate thier unused and under-utilized EC2 instances. This benchmark focuses on finding resources that have not been restarted recently, have low utilization and are using very large instance sizes.

### Default Thresholds
- [Instance types that are too big (> 12xlarge or Metal)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/ec2/large_ec2_instances.sql#L5-L6)
- [Long running instance threshold (90 Days)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/ec2/long_running_instances.sql#L4)
- [Very low utilization threshold (< 20%)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/ec2/low_utilization_ec2_instance.sql#L17)
- [Very low utilization threshold (< 35%)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/ec2/low_utilization_ec2_instance.sql#L18)
