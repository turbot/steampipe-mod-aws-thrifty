select
  arn as resource,
  case
    when jsonb_array_length(instances) = 0 then 'alarm'
    else 'ok'
  end as status,
  case
    when jsonb_array_length(instances) = 0 then title || ' has no instances registered.'
    else title || ' has registered instances.'
  end as reason,
  region,
  account_id
from
  aws_ec2_classic_load_balancer;
