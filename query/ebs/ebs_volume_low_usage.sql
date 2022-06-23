with ebs_usage as (
  select
    partition,
    account_id,
    region,
    volume_id,
    round(avg(max)) as avg_max,
    count(max) as days
    from (
      (
        select 
          partition,
          account_id,
          region,
          volume_id,
          cast(maximum as numeric) as max
        from 
          aws_ebs_volume_metric_read_ops_daily
        where
          date_part('day', now() - timestamp) <= 30
      )
      UNION
      (
        select 
          partition,
          account_id,
          region,
          volume_id,
          cast(maximum as numeric) as max
        from 
          aws_ebs_volume_metric_write_ops_daily
        where
          date_part('day', now() - timestamp) <= 30
      ) 
    ) as read_and_write_ops
    group by 1,2,3,4
)
select
  'arn:' || partition || ':ec2:' || region || ':' || account_id || ':volume/' || volume_id as resource,
  case
    when avg_max <= $1 then 'alarm'
    when avg_max <= $2 then 'info'
    else 'ok'
  end as status,
  volume_id || ' is averaging ' || avg_max || ' read and write ops over the last ' || days || ' days.' as reason,
  region,
  account_id
from
  ebs_usage