## Thrifty RDS Benchmark

Thrifty developers eliminate their unused and under-utilized RDS instances. This benchmark focuses on testing your RDS DB instances to ensure they are in-use, correctly-sized and using the latest cost-effective instance types.

### Default Thresholds
- [Low connection threshold (2 Max connections per min)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/rds/low_connections_rds_metrics.sql#L18)
- [Very long running be instance threshold (90 Days)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/rds/old_rds_db_instances.sql#L4)
- [Long running db instance threshold (30 Days)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/rds/old_rds_db_instances.sql#L5)
- [Previous generation db instance types (*t2*, *m3*, *m4*)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/rds/prev_gen_rds_instances.sql#L4-L6)
