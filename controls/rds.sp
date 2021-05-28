locals {
  rds_common_tags = merge(local.thrifty_common_tags, {
    service = "rds"
  })
}

benchmark "rds" {
  title         = "RDS Checks"
  description   = "Thrifty developers eliminate unused and under-utilized RDS instances."
  documentation = file("./controls/docs/rds.md") #TODO
  tags          = local.rds_common_tags
  children = [
    control.long_running_rds_db_instances,
    control.latest_rds_instance_types,
    control.rds_db_low_connection_count,
    control.rds_db_low_utilization
  ]
}

control "long_running_rds_db_instances" {
  title         = "Which RDS DBs should have reserved instances purchased for them?"
  description   = "Long running database servers should be associated with a reserve instance."
  sql           = query.old_rds_db_instances.sql
  severity      = "low"
  tags = merge(local.rds_common_tags, {
    class = "managed"
  })
}


control "latest_rds_instance_types" {
  title         = "Are there RDS instances using previous gen instance types?"
  description   = "M5 and T3 instance types are less costly than previous generations"
  sql           = query.prev_gen_rds_instances.sql
  severity      = "low"
  tags = merge(local.rds_common_tags, {
    class = "managed"
  })
}

control "rds_db_low_connection_count" {
  title         = "Which RDS DBs have fewer than 2 connections per day?"
  description   = "These databases have very little usage in last 30 days. Should this instance be shutdown when not in use?"
  sql           = query.low_connections_rds_metrics.sql
  severity      = "high"
  tags = merge(local.rds_common_tags, {
    class = "unused"
  })
}

control "rds_db_low_utilization" {
  title         = "Which RDS DBs have less than 25% utilization for last 30 days?"
  description   = "These databases may be oversized for their usage."
  sql           = query.low_usage_rds_metrics.sql
  severity      = "low"
  tags = merge(local.rds_common_tags, {
    class = "managed"
  })
}
