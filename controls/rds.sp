variable "rds_db_instance_avg_connections" {
  type        = number
  description = "The minimum number of average connections per day required for DB instances to be considered in-use."
}

variable "rds_db_instance_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for DB instances to be considered frequently used. This value should be higher than rds_db_instance_avg_cpu_utilization_low."
}

variable "rds_db_instance_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for DB instances to be considered infrequently used. This value should be lower than rds_db_instance_avg_cpu_utilization_high."
}

variable "rds_running_db_instance_age_max_days" {
  type        = number
  description = "The maximum number of days DB instances are allowed to run."
}

variable "rds_running_db_instance_age_warning_days" {
  type        = number
  description = "The number of days DB instances can be running before sending a warning."
}

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
    control.latest_rds_instance_types,
    control.long_running_rds_db_instances,
    control.rds_db_low_connection_count,
    control.rds_db_low_utilization
  ]
}

control "long_running_rds_db_instances" {
  title         = "Long running RDS DBs should have reserved instances purchased for them"
  description   = "Long running database servers should be associated with a reserve instance."
  sql           = query.old_rds_db_instances.sql
  severity      = "low"

  param "rds_running_db_instance_age_max_days" {
    description = "The maximum number of days DB instances are allowed to run."
    default     = var.rds_running_db_instance_age_max_days
  }

  param "rds_running_db_instance_age_warning_days" {
    description = "The number of days DB instances can be running before sending a warning."
    default     = var.rds_running_db_instance_age_warning_days
  }

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
  title         = "RDS DB instances with a low number connections per day should be reviewed"
  description   = "DB instances having less usage in last 30 days should be reviewed."
  sql           = query.low_connections_rds_metrics.sql
  severity      = "high"

  param "rds_db_instance_avg_connections" {
    description = "The minimum number of average connections per day required for DB instances to be considered in-use."
    default     = var.rds_db_instance_avg_connections
  }

  tags = merge(local.rds_common_tags, {
    class = "unused"
  })
}

control "rds_db_low_utilization" {
  title         = "RDS DB instance having low CPU utilization should be reviewed"
  description   = "DB instances may be oversized for their usage."
  sql           = query.low_usage_rds_metrics.sql
  severity      = "low"

  param "rds_db_instance_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for DB instances to be considered infrequently used. This value should be lower than rds_db_instance_avg_cpu_utilization_high."
    default     = var.rds_db_instance_avg_cpu_utilization_low
  }

  param "rds_db_instance_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for DB instances to be considered frequently used. This value should be higher than rds_db_instance_avg_cpu_utilization_low."
    default     = var.rds_db_instance_avg_cpu_utilization_high
  }

  tags = merge(local.rds_common_tags, {
    class = "unused"
  })
}
