select
  arn as resource,
  case
    when size <= $1 then 'ok'
    else 'alarm'
  end as status,
  volume_id || ' is ' || size || 'GB.' as reason,
  region,
  account_id
from
  aws_ebs_volume
