select
  arn as resource,
  case
    when lifecycle_rules is null then 'alarm'
    else 'ok'
  end as status,
  case
    when lifecycle_rules is null then name || ' does not have life cyle policy.'
    else name || ' has a life cycle policy.'
  end as reason,
  region,
  account_id
from
  aws_s3_bucket
