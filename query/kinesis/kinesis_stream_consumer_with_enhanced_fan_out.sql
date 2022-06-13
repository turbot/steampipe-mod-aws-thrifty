select
  stream_arn as resource,
  case
    when consumer_count > 0 then 'alarm'
    else 'ok'
  end as status,
  title || ' has ' || consumer_count || ' consumers using enhanced fan-out.' as reason,
  region,
  account_id
from
  aws_kinesis_stream;