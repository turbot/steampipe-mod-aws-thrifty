select
  stream_arn as resource,
  case
    when retention_period_hours > $1 * 24 then 'alarm'
    else 'ok'
  end as status,
  title || ' data retention period is ' || retention_period_hours/24 || ' day(s).' as reason,
  region,
  account_id
from
  aws_kinesis_stream;