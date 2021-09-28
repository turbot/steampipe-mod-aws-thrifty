variable "redshift_running_cluster_age_max_days" {
  type        = number
  description = "The maximum number of days clusters are allowed to run."
}

variable "redshift_running_cluster_age_warning_days" {
  type        = number
  description = "The number of days after which a cluster set a warning."
}

variable "redshift_cluster_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than redshift_cluster_avg_cpu_utilization_high."
}

variable "redshift_cluster_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than redshift_cluster_avg_cpu_utilization_low."
}

locals {
  redshift_common_tags = merge(local.thrifty_common_tags, {
    service = "redshift"
  })
}

benchmark "redshift" {
  title         = "Redshift Checks"
  description   = "Thrifty developers check their long running Redshift clusters are associated with reserved nodes."
  documentation = file("./controls/docs/redshift.md")
  tags          = local.redshift_common_tags
  children = [
    control.redshift_cluster_max_age,
    control.redshift_cluster_low_utilization,
    control.redshift_cluster_schedule_pause_resume_enabled
  ]
}

control "redshift_cluster_max_age" {
  title         = "Long running Redshift clusters should have reserved nodes purchased for them"
  description   = "Long running clusters should be associated with reserved nodes, which provide a significant discount."
  sql           = query.redshift_cluster_age_90_days.sql
  severity      = "low"

  param "redshift_running_cluster_age_max_days" {
    description = "The maximum number of days clusters are allowed to run."
    default     = var.redshift_running_cluster_age_max_days
  }

  param "redshift_running_cluster_age_warning_days" {
    description = "The number of days after which clusters set a warning."
    default     = var.redshift_running_cluster_age_warning_days
  }

  tags = merge(local.redshift_common_tags, {
    class = "managed"
  })
}

control "redshift_cluster_schedule_pause_resume_enabled" {
  title         = "Redshift cluster paused resume should be enabled"
  description   = "Redshift cluster paused resume should be enabled to easily suspend on-demand billing while the cluster is not being used."
  sql           = query.redshift_cluster_schedule_pause_resume_enabled.sql
  severity      = "low"
  tags = merge(local.redshift_common_tags, {
    class = "managed"
  })
}

control "redshift_cluster_low_utilization" {
  title         = "Redshift cluster with low CPU utilization should be reviewed"
  description   = "Resize or eliminate under utilized clusters."
  sql           = query.redshift_cluster_low_utilization.sql
  severity      = "low"

  param "redshift_cluster_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than redshift_cluster_avg_cpu_utilization_high."
    default     = var.redshift_cluster_avg_cpu_utilization_low
  }

  param "redshift_cluster_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than redshift_cluster_avg_cpu_utilization_low."
    default     = var.redshift_cluster_avg_cpu_utilization_high
  }

  tags = merge(local.redshift_common_tags, {
    class = "unused"
  })
}
