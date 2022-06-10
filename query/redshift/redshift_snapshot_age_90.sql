select
  'arn:' || partition || ':redshift:' || region || ':' || account_id || ':snapshot:' || cluster_identifier || '/' || snapshot_identifier as resource,
  case
    when snapshot_create_time > current_timestamp - ($1 || ' days')::interval then 'ok'
    else 'alarm'
  end as status,
  snapshot_identifier || ' created at ' || snapshot_create_time || '.' as reason,
  region,
  account_id
from
  aws_redshift_snapshot;