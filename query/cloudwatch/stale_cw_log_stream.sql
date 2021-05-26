select
  arn as resource,
  case 
    when date_part('day', now() - last_ingestion_time ) > 90 then 'alarm'
    else 'ok'
  end as status,
  name || ' last log ingestion was ' || date_part('day', now()-last_ingestion_time) || ' days ago.' as reason,
  region,
  account_id
from 
  aws_cloudwatch_log_stream
  