select
  arn as resource,
  case
    when date_part('day', now() - cluster_create_time) > 90 then 'alarm'
    when date_part('day', now() - cluster_create_time) > 30 then 'info'
    else 'ok'
  end as status,
  title || ' created on ' || cluster_create_time || ' (' || date_part('day', now() - cluster_create_time) || ' days).'
  as reason,
  region,
  account_id
from
  aws_redshift_cluster;