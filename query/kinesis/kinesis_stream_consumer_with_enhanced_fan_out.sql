select
  stream_arn as resource,
  case
    when consumer_count > 0 then 'alarm'
    else 'ok'
  end as status,
  case
    when consumer_count > 0 then title || ' has '|| consumer_count || ' consumers using enhanced fan-out.'
    else 'No consumers using enhanced fan-out.'
  end as reason,
  region,
  account_id
from
  aws_kinesis_stream;