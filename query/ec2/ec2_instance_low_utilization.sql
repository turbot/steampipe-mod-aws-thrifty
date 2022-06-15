with ec2_instance_utilization as (
  select
    instance_id,
    max(average) as avg_max,
    count(average) days
  from
    aws_ec2_instance_metric_cpu_utilization_daily
  where
    date_part('day', now() - timestamp) <= 30
  group by
    instance_id
)
select
  arn as resource,
  case
    when avg_max is null then 'error'
    when avg_max < $1 then 'alarm'
    when avg_max < $2 then 'info'
    else 'ok'
  end as status,
  case
    when avg_max is null then 'CloudWatch metrics not available for ' || title || '.'
    else title || ' is averaging ' || avg_max || '% max utilization over the last ' || days || ' days.'
  end as reason,
  region,
  account_id
from
  aws_ec2_instance i
  left join ec2_instance_utilization as u on u.instance_id = i.instance_id;
