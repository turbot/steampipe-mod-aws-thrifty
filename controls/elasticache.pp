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
  title       = "Long running ElastiCache clusters should have reserved nodes purchased for them"
  description = "Long running clusters should be associated with reserved nodes, which provide a significant discount."
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
    class = "managed"
  })
  sql = <<-EOQ
    with filter_clusters as (
    select
      distinct c.replication_group_id as name,
      c.cache_cluster_create_time,
      c._ctx,
      c.region,
      c.account_id,
      'redis' as engine,
      c.partition
    from
      aws_elasticache_replication_group as rg
      left join aws_elasticache_cluster as c on rg.replication_group_id = c.replication_group_id
    union
    select
      cache_cluster_id as name,
      cache_cluster_create_time,
      _ctx,
      region,
      account_id,
      engine,
      partition
    from
      aws_elasticache_cluster
    where
      engine = 'memcached'
  )
  select
    'arn:' || partition || ':elasticache:' || region || ':' || account_id || ':cluster:' || name as resource,
    case
      when date_part('day', now() - cache_cluster_create_time) > $1 then 'alarm'
      when date_part('day', now() - cache_cluster_create_time) > $2 then 'info'
      else 'ok'
    end as status,
    name || ' ' || engine || ' created on ' || cache_cluster_create_time || ' (' || date_part('day', now() - cache_cluster_create_time) || ' days).'
    as reason
    ${local.common_dimensions_sql}
  from
    filter_clusters;
  EOQ
}
