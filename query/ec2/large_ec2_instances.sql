select
  arn as resource,
  case
    when instance_state not in ('running', 'pending', 'rebooting') then 'info'
    when instance_type like '%.__xlarge' then 'alarm'
    when instance_type like '%.metal' then 'alarm'
    else 'ok'
  end as status,
  title || ' has type ' || instance_type || ' and is ' || instance_state || '.' as reason,
  region,
  account_id
from
  aws_ec2_instance
