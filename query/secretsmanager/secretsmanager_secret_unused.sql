select
  arn as resource,
  case
    when last_accessed_date >= (current_date - interval '$1' day) then 'ok'
    else 'alarm'
  end as status,
  case
    when last_accessed_date is null then title || ' is never used.'
    else title || ' was last used ' || age(current_date, last_accessed_date) || ' ago.'
  end as reason,
  region,
  account_id
from
  aws_secretsmanager_secret;