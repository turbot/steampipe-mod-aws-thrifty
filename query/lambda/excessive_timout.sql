with lambda_duration as (
  select 
    name,
    avg(average:: numeric) as avg_duration
  from 
    aws_lambda_function_metric_duration_daily
  where
    date_part('day', now() - timestamp) <=7
  group by
    name
)
select
  arn as resource,
  case
    when avg_duration is null then 'error'
    when ((timeout :: numeric*1000)-avg_duration)/(timeout :: numeric*1000) > 0.1 then 'alarm'
    else 'ok'
  end as status,
  case
    when avg_duration is null then 'CloudWatch metrics not available for ' || title || '.'
    else title || ' Timeout of ' || timeout::numeric*1000 || ' milliseconds is ' || round(((timeout :: numeric*1000)-avg_duration)/(timeout :: numeric*1000)*100,1) || '% more as compared to average of ' || round(avg_duration,0) || ' milliseconds.'
  end as reason,
  region,
  account_id
from
  aws_lambda_function f
  left join lambda_duration as d on f.name = d.name
