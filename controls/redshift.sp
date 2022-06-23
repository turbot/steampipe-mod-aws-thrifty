variable "redshift_cluster_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than redshift_cluster_avg_cpu_utilization_low."
  default     = 35
}

variable "redshift_cluster_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than redshift_cluster_avg_cpu_utilization_high."
  default     = 20
}

variable "redshift_running_cluster_age_max_days" {
  type        = number
  description = "The maximum number of days clusters are allowed to run."
  default     = 90
}

variable "redshift_running_cluster_age_warning_days" {
  type        = number
  description = "The number of days clusters can be running before sending a warning."
  default     = 30
}

variable "redshift_snapshot_age_max_days" {
  type        = number
  description = "The maximum number of days redshift snapshots can be retained."
  default     = 90
}

locals {
  redshift_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Redshift"
  })
}

benchmark "redshift" {
  title         = "Redshift Checks"
  description   = "Thrifty developers check their long running Redshift clusters are associated with reserved nodes."
  documentation = file("./controls/docs/redshift.md")
  children = [
    control.redshift_cluster_low_utilization,
    control.redshift_cluster_max_age,
    control.redshift_cluster_node_type_prev_gen,
    control.redshift_cluster_schedule_pause_resume_enabled,
    control.redshift_snapshot_max_age
  ]

  tags = merge(local.redshift_common_tags, {
    type = "Benchmark"
  })
}
control "redshift_snapshot_max_age" {
  title       = "Old redshift snapshots should be deleted if not required"
  description = "Old redshift snapshots are likely unnecessary and costly to maintain."
  sql         = query.redshift_snapshot_max_age.sql
  severity    = "low"

  param "redshift_snapshot_age_max_days" {
    description = "The maximum number of days redshift snapshots can be retained."
    default     = var.redshift_snapshot_age_max_days
  }

  tags = merge(local.redshift_common_tags, {
    class = "stale_data"
  })
}

control "redshift_cluster_node_type_prev_gen" {
  title       = "Redshift clusters should use the latest generation node types"
  description = "Ensure that all Redshift clusters provisioned within your AWS account are using the latest generation of nodes (ds2.xlarge or ds2.8xlarge) in order to get higher performance with lower costs."
  sql         = query.redshift_cluster_node_type_prev_gen.sql
  severity    = "low"

  tags = merge(local.redshift_common_tags, {
    class = "generation_gaps"
  })
}

control "redshift_cluster_max_age" {
  title       = "Long running Redshift clusters should have reserved nodes purchased for them"
  description = "Long running clusters should be associated with reserved nodes, which provide a significant discount."
  sql         = query.redshift_cluster_max_age.sql
  severity    = "low"

  param "redshift_running_cluster_age_max_days" {
    description = "The maximum number of days clusters are allowed to run."
    default     = var.redshift_running_cluster_age_max_days
  }

  param "redshift_running_cluster_age_warning_days" {
    description = "The number of days clusters can be running before sending a warning."
    default     = var.redshift_running_cluster_age_warning_days
  }

  tags = merge(local.redshift_common_tags, {
    class = "capacity_planning"
  })
}

control "redshift_cluster_schedule_pause_resume_enabled" {
  title       = "Redshift clusters pause and resume feature should be enabled"
  description = "Redshift clusters should utilise the pause and resume actions to easily suspend on-demand billing while the cluster is not being used."
  sql         = query.redshift_cluster_schedule_pause_resume_enabled.sql
  severity    = "low"

  tags = merge(local.redshift_common_tags, {
    class = "overused"
  })
}

control "redshift_cluster_low_utilization" {
  title       = "Redshift clusters with low CPU utilization should be reviewed"
  description = "Resize or eliminate under utilized clusters."
  sql         = query.redshift_cluster_low_utilization.sql
  severity    = "low"

  param "redshift_cluster_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than redshift_cluster_avg_cpu_utilization_high."
    default     = var.redshift_cluster_avg_cpu_utilization_low
  }

  param "redshift_cluster_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than redshift_cluster_avg_cpu_utilization_low."
    default     = var.redshift_cluster_avg_cpu_utilization_high
  }

  tags = merge(local.redshift_common_tags, {
    class = "underused"
  })
}
