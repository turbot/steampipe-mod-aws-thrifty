with ec2_network_lb_netflow as (
  select
    name,
    sum(maximum) as avg_max,
    count(maximum) days
  from
    aws_ec2_network_load_balancer_metric_net_flow_count_daily
  where
    date_part('day', now() - timestamp) <=7
  group by
    name
)
select
  arn as resource,
  case
    when u.name is null then 'error'
    when avg_max < 100 and days >= 7 then 'alarm'
    else 'ok'
  end as status,
  case
    when u.name is null then 'CloudWatch metrics not available for ' || title || '.'
    else title || ' is averaging ' || avg_max || ' max connections in the last ' || days || ' day(s).'
  end as reason,
  region,
  account_id
from
  aws_ec2_network_load_balancer as i
  left join ec2_network_lb_netflow as u on split_part(u.name, '/', 2) = i.name
