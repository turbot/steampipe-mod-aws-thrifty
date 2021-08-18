with cluster_metrics as (
  select
    id,
    maximum,
    date(timestamp) as timestamp
  from
    aws_emr_cluster_metric_is_idle
  where
    timestamp >= current_timestamp - interval '40 minutes'
),
 emr_cluster_isidle as (
  select
    id,
    count(maximum) as count,
    sum(maximum)/count(maximum) as avagsum
  from
    cluster_metrics
  group by id, timestamp
)
select
  i.id as resource,
  case
    when u.id is null then 'error'
    when avagsum = 1 and count >=7  then 'alarm'
    else 'ok'
  end as status,
  case
    when u.id is null then 'CloudWatch metrics not available for ' || i.title || '.'
    else i.title || ' is idle from last ' || (count*5 -5) ||  ' minutes.'
   end as reason,
  i.region,
  i.account_id
from
  aws_emr_cluster as i
  left join emr_cluster_isidle as u on u.id = i.id;