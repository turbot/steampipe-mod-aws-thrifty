select
  'arn:' || partition || ':dynamodb:' || region || ':' || account_id || ':table/' || name as resource,
  case
    when latest_stream_label is null then 'info'
    when date_part('day', now() - (latest_stream_label::timestamptz)) > $1 then 'alarm'
    else 'ok'
  end as status,
  case 
    when latest_stream_label is null then name || ' is not configured for change data capture.'
    else name || ' was changed ' || date_part('day', now() - (latest_stream_label::timestamptz)) || ' days ago.'
  end as reason,
  region,
  account_id
from
  aws_dynamodb_table;
