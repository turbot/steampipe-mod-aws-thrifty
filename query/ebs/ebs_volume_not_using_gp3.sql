select
  arn as resource,
  case
    when volume_type = 'gp3' then 'ok'
    else 'alarm'
  end as status,
  volume_id || ' has type ' || volume_type || '.' as reason,
  region,
  account_id
from
  aws_ebs_volume
