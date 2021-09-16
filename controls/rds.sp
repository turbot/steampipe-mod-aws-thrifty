locals {
  rds_common_tags = merge(local.thrifty_common_tags, {
    service = "rds"
  })
}

benchmark "rds" {
  title         = "RDS Checks"
  description   = "Thrifty developers eliminate unused and under-utilized RDS instances."
  documentation = file("./controls/docs/rds.md")
  tags          = local.rds_common_tags
  children = [
    control.rds_db_instance_class_prev_gen,
    control.rds_db_instance_age_90,
    control.rds_db_instance_low_connections,
    control.rds_db_instance_low_usage
  ]
}

control "rds_db_instance_age_90" {
  title         = "Which RDS DBs should have reserved instances purchased for them?"
  description   = "Long running database servers should be associated with a reserve instance."
  sql           = query.rds_db_instance_age_90.sql
  severity      = "low"
  tags = merge(local.rds_common_tags, {
    class = "managed"
  })
}


control "rds_db_instance_class_prev_gen" {
  title         = "Are there RDS instances using previous gen instance types?"
  description   = "M5 and T3 instance types are less costly than previous generations"
  sql           = query.rds_db_instance_class_prev_gen.sql
  severity      = "low"
  tags = merge(local.rds_common_tags, {
    class = "managed"
  })
}

control "rds_db_instance_low_connections" {
  title         = "Which RDS DBs have fewer than 2 connections per day?"
  description   = "These databases have very little usage in last 30 days. Should this instance be shutdown when not in use?"
  sql           = query.rds_db_instance_low_connections.sql
  severity      = "high"
  tags = merge(local.rds_common_tags, {
    class = "unused"
  })
}

control "rds_db_instance_low_usage" {
  title         = "Which RDS DBs have less than 25% utilization for last 30 days?"
  description   = "These databases may be oversized for their usage."
  sql           = query.rds_db_instance_low_usage.sql
  severity      = "low"
  tags = merge(local.rds_common_tags, {
    class = "unused"
  })
}
