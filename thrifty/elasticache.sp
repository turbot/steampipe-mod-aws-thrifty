variable "elasticache_running_cluster_age_max_days" {
  type        = number
  description = "The maximum number of days clusters are allowed to run."
  default     = 90
}

variable "elasticache_running_cluster_age_warning_days" {
  type        = number
  description = "The number of days clusters can be running before sending a warning."
  default     = 30
}

variable "elasticache_redis_cluster_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than elasticache_redis_cluster_avg_cpu_utilization_low."
  default     = 35
}

variable "elasticache_redis_cluster_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than elasticache_redis_cluster_avg_cpu_utilization_high."
  default     = 20
}

locals {
  elasticache_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/ElastiCache"
  })
}

benchmark "elasticache" {
  title         = "ElastiCache Checks"
  description   = "Thrifty developers check their long running ElastiCache clusters are associated with reserved nodes."
  documentation = file("./thrifty/docs/elasticache.md")
  children = [
    control.elasticache_cluster_running_max_age,
    control.elasticache_redis_cluster_low_utilization
  ]

  tags = merge(local.elasticache_common_tags, {
    type = "Benchmark"
  })
}

control "elasticache_cluster_running_max_age" {
  title       = "Long running ElastiCache clusters should be reviewed"
  description = "Long running clusters should be reviewed and if they are needed they should be associated with reserved nodes, which provide a significant discount."
  sql         = query.elasticache_cluster_running_max_age.sql
  severity    = "low"

  param "elasticache_running_cluster_age_max_days" {
    description = "The maximum number of days clusters are allowed to run."
    default     = var.elasticache_running_cluster_age_max_days
  }

  param "elasticache_running_cluster_age_warning_days" {
    description = "The number of days clusters can be running before sending a warning."
    default     = var.elasticache_running_cluster_age_warning_days
  }

  tags = merge(local.redshift_common_tags, {
    class = "capacity_planning"
  })
}

control "elasticache_redis_cluster_low_utilization" {
  title       = "Elasticache Redis clusters with low CPU utilization should be reviewed"
  description = "Resize or eliminate under utilized clusters."
  sql         = query.elasticache_redis_cluster_low_utilization.sql
  severity    = "low"

  param "elasticache_redis_cluster_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than elasticache_redis_cluster_avg_cpu_utilization_high."
    default     = var.elasticache_redis_cluster_avg_cpu_utilization_low
  }

  param "elasticache_redis_cluster_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than elasticache_redis_cluster_avg_cpu_utilization_low."
    default     = var.elasticache_redis_cluster_avg_cpu_utilization_high
  }

  tags = merge(local.redshift_common_tags, {
    class = "underused"
  })
}