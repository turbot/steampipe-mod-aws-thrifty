select
  'arn:' || partition || ':ec2:' || region || ':' || account_id || ':natgateway/' || nat_gateway_id as resource,
  case
    when date_part('day', now() - create_time) > 30 then 'alarm'
    else 'ok'
  end as status,
  title || ' is available for ' || date_part('day', now() - create_time) || ' days.' as reason,
  region,
  account_id
from
  aws_vpc_nat_gateway
where
  state in ('available', 'pending');