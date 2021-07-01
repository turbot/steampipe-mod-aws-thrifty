select
  arn as resource,
  case
    when instance_type ilike any (array ['t2.%', 'm3.%', 'm4.%']) then 'alarm'
    else 'info'
  end as status,
  title || ' has ' || instance_type || ' instance class.'
  as reason,
  region,
  account_id
from
  aws_ec2_instance;