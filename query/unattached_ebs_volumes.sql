select
  arn as resource,
  case
    when attachments is null then 'alarm'
    else 'ok'
  end as status,
  case
    when attachments is null then volume_id || ' has no attachments.'
    else volume_id || ' has attachments.'
  end as reason,
  region,
  account_id
from
  aws_ebs_volume
