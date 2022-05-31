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

locals {
  elasticache_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/ElastiCache"
  })
}

benchmark "elasticache" {
  title         = "ElastiCache Checks"
  description   = "Thrifty developers check their long running ElastiCache clusters are associated with reserved nodes."
  documentation = file("./controls/docs/elasticache.md")
  children = [
    control.elasticache_cluster_long_running
  ]

  tags = merge(local.elasticache_common_tags, {
    type = "Benchmark"
  })
}

control "elasticache_cluster_long_running" {
  title         = "Long running ElastiCache clusters should have reserved nodes purchased for them"
  description   = "Long running clusters should be associated with reserved nodes, which provide a significant discount."
  sql           = query.elasticache_long_running_cluster.sql
  severity      = "low"

  param "elasticache_running_cluster_age_max_days" {
    description = "The maximum number of days clusters are allowed to run."
    default     = var.elasticache_running_cluster_age_max_days
  }

  param "elasticache_running_cluster_age_warning_days" {
    description = "The number of days clusters can be running before sending a warning."
    default     = var.elasticache_running_cluster_age_warning_days
  }

  tags = merge(local.redshift_common_tags, {
    class = "managed"
  })
}
