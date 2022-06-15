select
  arn as resource,
  case
    when instance_state not in ('running', 'pending', 'rebooting') then 'info'
    when instance_type like any ($1) then 'ok'
    else 'alarm'
  end as status,
  title || ' has type ' || instance_type || ' and is ' || instance_state || '.' as reason,
  region,
  account_id
from
  aws_ec2_instance;
