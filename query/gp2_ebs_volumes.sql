select
  arn as resource,
  case
    when volume_type = 'gp2' then 'alarm'
    else 'ok'
  end as status,
  volume_id || ' type is ' || volume_type || '.' as reason,
  region,
  account_id
from
  aws_ebs_volume