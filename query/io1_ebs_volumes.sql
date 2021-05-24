select
  arn as resource,
  case
    when volume_type = 'io1' then 'alarm'
    when volume_type = 'io2' then 'ok'
    else 'skip'
  end as status,
  volume_id || ' type is ' || volume_type || '.' as reason,
  region,
  account_id
from
  aws_ebs_volume;
