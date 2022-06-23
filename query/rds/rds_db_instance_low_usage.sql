with rds_db_usage as (
  select 
    db_instance_identifier,
    round(cast(sum(maximum)/count(maximum) as numeric), 1) as avg_max,
    count(maximum) days
  from 
    aws_rds_db_instance_metric_cpu_utilization_daily
  where
    date_part('day', now() - timestamp) <= 30
  group by
    db_instance_identifier
)
select
  arn as resource,
  case
    when avg_max is null then 'error'
    when avg_max <= $1 then 'alarm'
    when avg_max <= $2 then 'info'
    else 'ok'
  end as status,
  case
    when avg_max is null then 'CloudWatch metrics not available for ' || title || '.'
    else title || ' is averaging ' || avg_max || '% max utilization over the last ' || days || ' days.'
  end as reason,
  region,
  account_id
from
  aws_rds_db_instance i
  left join rds_db_usage as u on u.db_instance_identifier = i.db_instance_identifier;
