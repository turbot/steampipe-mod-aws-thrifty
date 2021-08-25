with redshift_cluster_utilization as (
  select
    cluster_identifier,
    round(cast(sum(maximum)/count(maximum) as numeric), 1) as avg_max,
    count(maximum) days
  from
    aws_redshift_cluster_metric_cpu_utilization_daily
  where
    date_part('day', now() - timestamp) <= 30
  group by
    cluster_identifier
)
select
  i.cluster_identifier as resource,
  case
    when avg_max is null then 'error'
    when avg_max < 20 then 'alarm'
    when avg_max < 35 then 'info'
    else 'ok'
  end as status,
  case
    when avg_max is null then 'CloudWatch metrics not available for ' || title || '.'
    else title || ' is averaging ' || avg_max || '% max utilization over the last ' || days || ' days.'
  end as reason,
  region,
  account_id
from
  aws_redshift_cluster as i
  left join redshift_cluster_utilization as u on u.cluster_identifier = i.cluster_identifier;