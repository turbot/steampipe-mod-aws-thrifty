select
  arn as resource,
  case
    when volume_type not in ('io1', 'io2') then 'skip'
    when iops <= 3000 then 'alarm'
    else 'ok'
  end as status,
  case
    when volume_type not in ('io1', 'io2') then volume_id || ' type is ' || volume_type || '.'
    when iops <= 3000 then volume_id || ' only has ' || iops || ' iops.'
    else volume_id || ' has ' || iops || ' iops.'
  end as reason,
  region,
  account_id
from
  aws_ebs_volume;
