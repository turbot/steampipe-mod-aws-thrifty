select
  arn as resource,
  case
    when class like '%.t2.%' then 'alarm'
    when class like '%.m3.%' then 'alarm'
    when class like '%.m4.%' then 'alarm'
    when class like '%.m5.%' then 'ok'
    when class like '%.t3.%' then 'ok'
    else 'info'
  end as status,
  title || ' has a ' || class || ' instance class.' as reason,
  region,
  account_id
from
  aws_rds_db_instance;
