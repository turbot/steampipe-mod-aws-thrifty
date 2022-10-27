select
  arn as resource,
  case
    when jsonb_array_length(attachments) > 0 then 'ok'
    else 'alarm'
  end as status,
  case
    when jsonb_array_length(attachments) > 0 then volume_id || ' has attachments.'
    else volume_id || ' has no attachments.'
  end as reason,
  region,
  account_id
from
  aws_ebs_volume
