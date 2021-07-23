## Thrifty EC2 Benchmark

Thrifty developers eliminate their unused and under-utilized EC2 instances. This benchmark focuses on finding resources that have not been restarted recently, have low utilization and are using very large instance sizes.

### Default Thresholds

- [Instance types that are too big (> 12xlarge or Metal)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/large_ec2_instances)
- [Long running instance threshold (90 Days)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/long_running_instances)
- [Very low utilization threshold (< 20%)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/low_utilization_ec2_instance)
- [Low utilization threshold (< 35%)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/low_utilization_ec2_instance)
