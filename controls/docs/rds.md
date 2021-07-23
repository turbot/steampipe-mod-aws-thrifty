## Thrifty RDS Benchmark

Thrifty developers eliminate their unused and under-utilized RDS instances. This benchmark focuses on testing your RDS DB instances to ensure they are in-use, correctly-sized and using the latest cost-effective instance types.

### Default Thresholds

- [Low connection threshold (2 Max connections per min)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/low_connections_rds_metrics)
- [Very long running be instance threshold (90 Days)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/old_rds_db_instances)
- [Long running db instance threshold (30 Days)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/old_rds_db_instances)
- [Previous generation db instance types (*t2*, *m3*, *m4*)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/prev_gen_rds_instances)
