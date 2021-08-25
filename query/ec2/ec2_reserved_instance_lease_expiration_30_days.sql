select
  reserved_instance_id as resource,
  case
    when date_part('day', end_time - now()) <= 30 then 'alarm'
    else 'ok'
  end as status,
    title || ' lease expires in ' || date_part('day', end_time-now()) || ' days.' as reason,
  region,
  account_id
from
  aws_ec2_reserved_instance;