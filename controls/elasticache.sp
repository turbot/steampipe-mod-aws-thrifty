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
  title         = "ElastiCache Cost Checks"
  description   = "Thrifty developers check their long running ElastiCache clusters are associated with reserved nodes."
  documentation = file("./controls/docs/elasticache.md")
  children = [
    control.elasticache_cluster_running_max_age
  ]

  tags = merge(local.elasticache_common_tags, {
    type = "Benchmark"
  })
}

control "elasticache_cluster_running_max_age" {
  title       = "Long running ElastiCache clusters should be reviewed"
  description = "Long running clusters should be reviewed and if they are needed they should be associated with reserved nodes, which provide a significant discount."
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

  sql = <<-EOQ
    with elasticache_cluster_list as (
      select
        arn,
        cache_node_type,
        coalesce(replication_group_id,cache_cluster_id) as cache_cluster_id,
        engine,
        region,
        cache_cluster_create_time,
        account_id,
        title
      from
        aws_elasticache_cluster
    ), elasticache_cluster_reserved_pricing as (
      select
        p.description,
        p.attributes,
        p.price_per_unit,
        e.arn,
        e.cache_node_type,
        e.cache_cluster_id as cache_cluster_id,
        e.engine,
        e.region,
        e.account_id,
        e.cache_cluster_create_time,
        e.title,
        ((p.price_per_unit::numeric)*24*30)::numeric(10,2) as reserved_elasticache_cluster_price
      from
        elasticache_cluster_list as e
        left join aws_pricing_product as p on
        p.service_code = 'AmazonElastiCache'
        and p.attributes ->> 'regionCode' = e.region
        and p.attributes ->> 'instanceType' = e.cache_node_type
        and lower(p.attributes ->> 'cacheEngine') = lower(e.engine)
        and p.term = 'Reserved'
        and p.unit = 'Hrs'
        and p.purchase_option = 'No Upfront'
        and p.lease_contract_length = '1yr'
    ), elasticache_cluster_pricing as (
      select
        e.arn,
        e.cache_node_type,
        e.cache_cluster_id as cache_cluster_id,
        e.engine,
        e.region,
        e.account_id,
        e.title,
        case
          when date_part('day', now() - cache_cluster_create_time) > $1 then (((p.price_per_unit::numeric)*24*30)::numeric(10,2) - reserved_elasticache_cluster_price )|| ' ' || p.currency || ' /month'
          else ''
        end as net_savings,
        p.currency
      from
        elasticache_cluster_reserved_pricing as e
        left join aws_pricing_product as p on
        p.service_code = 'AmazonElastiCache'
        and p.attributes ->> 'regionCode' = e.region
        and p.attributes ->> 'instanceType' = e.cache_node_type
        and lower(p.attributes ->> 'cacheEngine') = lower(e.engine)
        and p.term = 'OnDemand'
    ), filter_clusters as (
    select
      distinct c.replication_group_id as name,
      c.arn,
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
      arn,
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
    c.arn as resource,
    case
      when date_part('day', now() - cache_cluster_create_time) > $1 then 'alarm'
      when date_part('day', now() - cache_cluster_create_time) > $2 then 'info'
      else 'ok'
    end as status,
    name || ' ' || c.engine || ' created on ' || cache_cluster_create_time || ' (' || date_part('day', now() - cache_cluster_create_time) || ' days).'
    as reason
    ${local.common_dimensions_cost_sql}
    ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "c.")}
  from
    filter_clusters as c
    left join elasticache_cluster_pricing as p on c.name =  p.cache_cluster_id
  EOQ
}
