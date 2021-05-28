select
  arn as resource,
  case 
    when last_ingestion_time is null then 'error'
    when date_part('day', now() - last_ingestion_time ) > 90 then 'alarm'
    else 'ok'
  end as status,
  case
    when last_ingestion_time is null then name || ' is not reporting a last ingestion time.'
    else name || ' last log ingestion was ' || date_part('day', now()-last_ingestion_time) || ' days ago.' 
  end as reason,
  region,
  account_id
from 
  aws_cloudwatch_log_stream
  