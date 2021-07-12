select
  arn as resource,
  case
    when instances is null then 'alarm'
    else 'ok'
  end as status,
  case
    when instances is null then title || ' has no instance registered.'
    else title || ' has registered instance.'
  end as reason,
  region,
  account_id
from
  aws_ec2_classic_load_balancer;