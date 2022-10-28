select
  arn as resource,
  case
    when jsonb_array_length(instances) > 0 then 'ok'
    else 'alarm'
  end as status,
  case
    when jsonb_array_length(instances) > 0 then title || ' has registered instances.'
    else title || ' has no instances registered.'
  end as reason,
  region,
  account_id
from
  aws_ec2_classic_load_balancer;
