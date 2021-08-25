## Thrifty EC2 Benchmark

Thrifty developers eliminate their unused and underutilized EC2 instances. This benchmark focuses on finding resources that have not been restarted recently, have low utilization, using very large instance sizes, and reserved instances scheduled to expire within the next 30 days or have expired in the preceding 30 days.

### Default Thresholds

- [Instance types that are too big (> 12xlarge or Metal)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/large_ec2_instances)
- [Long running instance threshold (90 Days)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/long_running_instances)
- [Very low utilization threshold (< 20%)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/low_utilization_ec2_instance)
- [Low utilization threshold (< 35%)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/low_utilization_ec2_instance)
- [Reserved instance lease expire threshold (30 days)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/ec2_reserved_instance_lease_expiration_30_days)
