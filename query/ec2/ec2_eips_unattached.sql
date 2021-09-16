select
  'arn:' || partition || ':ec2:' || region || ':' || account_id || ':eip/' || allocation_id as resource,
  case
    when association_id is null then 'alarm'
    else 'ok'
  end as status,
  case
    when association_id is null then public_ip || ' has no association.'
    else public_ip || ' associated with ' || private_ip_address || '.'
  end as reason,
  region,
  account_id
from
  aws_vpc_eip;
