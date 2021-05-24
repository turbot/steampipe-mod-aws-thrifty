select
  arn as resource,
  case
    when instance_type like 'm%.%' then 'ok'
    when instance_state in ('running') then 'alarm'
    else 'info'
  end as status,
  title || ' has type ' || instance_type || ' and is ' || instance_state || '.' as reason,
  region,
  account_id
from
  aws_ec2_instance
