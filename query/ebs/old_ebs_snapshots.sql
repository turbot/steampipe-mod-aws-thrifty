select
  'arn:' || partition || ':ec2:' || region || ':' || account_id || ':snapshot/' || snapshot_id as resource,
  case
    when start_time > current_timestamp - interval '$1 days' then 'ok'
    else 'alarm'
  end as status,
  snapshot_id || ' created at ' || start_time || '.' as reason,
  region,
  account_id
from
  aws_ebs_snapshot
