select
  arn as resource,
  case
    when retention_in_days is null then 'alarm'
    else 'ok'
  end as status,
  case
    when retention_in_days is null then name || ' does not have data retention enabled.'
    else name || ' is set to ' || retention_in_days || ' day retention.'
  end as reason,
  region,
  account_id
from
  aws_cloudwatch_log_group;
