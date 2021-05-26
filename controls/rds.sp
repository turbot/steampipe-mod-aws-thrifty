
control "on_demand_rds_db_instances" {
  title = "RDS DBs that should have reserved instances purchased"
  description = "Long running database servers should be associated with a reserve instance."
  sql = query.old_rds_db_instances.sql
  severity = "low"
  tags = {
    service = "rds"
    code = "managed"
  }
}


control "latest_rds_instance_types" {
  title = "RDS instances using previous gen instance types"
  description = "M5 and T3 instance types are less costly than previous generations"
  sql = query.prev_gen_rds_instances.sql
  severity = "low"
  tags = {
    service = "rds"
    code = "managed"
  }
}

control "rds_db_low_connection_count" {
  title = "Databases with less than 2 connections per day"
  description = "These databases have very little usage in last 30 days. Should this instance be shutdown when not in use?"
  sql = query.low_connections_rds_metrics.sql
  severity = "high"
  tags = {
    service = "rds"
    code = "unused"
  }
}

control "rds_db_low_utilization" {
  title = "Databases with less than 25% utilization for last 30 days"
  description = "These databases may be oversized for their usage."
  sql = query.low_usage_rds_metrics.sql
  severity = "low"
  tags = {
    service = "rds"
    code = "managed"
  }
}
