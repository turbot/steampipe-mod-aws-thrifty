variable "elasticache_running_cluster_age_max_days" {
  type        = number
  description = "The maximum number of days clusters are allowed to run."
}

variable "elasticache_running_cluster_age_warning_days" {
  type        = number
  description = "The maximum number of days after which cluster set a warning."
}

locals {
  elasticache_common_tags = merge(local.thrifty_common_tags, {
    service = "elasticache"
  })
}

benchmark "elasticache" {
  title         = "ElastiCache Checks"
  description   = "Thrifty developers check their long running ElastiCache clusters are associated with reserved nodes."
  documentation = file("./controls/docs/elasticache.md")
  tags          = local.elasticache_common_tags
  children = [
    control.elasticache_cluster_long_running,
  ]
}

control "elasticache_cluster_long_running" {
  title         = "Long running ElastiCache clusters should have reserved nodes purchased for them"
  description   = "Long running clusters should be associated with reserved nodes, which provide a significant discount."
  sql           = query.elasticache_cluster_age_90_days.sql
  severity      = "low"

  param "elasticache_running_cluster_age_max_days" {
    description = "The maximum number of days clusters are allowed to run."
    default     = var.elasticache_running_cluster_age_max_days
  }

  param "elasticache_running_cluster_age_warning_days" {
    description = "The maximum number of days clusters are allowed to run."
    default     = var.elasticache_running_cluster_age_warning_days
  }

  tags = merge(local.redshift_common_tags, {
    class = "managed"
  })
}
