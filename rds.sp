
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

