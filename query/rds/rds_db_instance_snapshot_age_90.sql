select
  arn as resource,
  case
    when create_time > current_timestamp - ($1 || ' days')::interval then 'ok'
    else 'alarm'
  end as status,
  db_snapshot_identifier || ' created at ' || create_time || '.' as reason,
  region,
  account_id
from
  aws_rds_db_snapshot;