select
  arn as resource,
  case
    when instance_type like 't2.%' or instance_type like 'm3.%' or instance_type like 'm4.%' then 'alarm'
    else 'ok'
  end as status,
  title || ' has used ' || instance_type || '.' as reason,
  region,
  account_id
from
  aws_ec2_instance;
