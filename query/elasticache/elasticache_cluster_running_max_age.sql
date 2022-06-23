with filter_clusters as (
  select
    distinct c.replication_group_id as name,
    c.cache_cluster_create_time,
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
  as reason,
  region,
  account_id
from
  filter_clusters;