with error_rate as (
  select 
    errors.name as name,
    sum(errors.sum)/sum(invocations.sum)*100 as error_rate
  from 
    aws_lambda_function_metric_errors_daily as errors , aws_lambda_function_metric_invocations_daily as invocations
  where
    date_part('day', now() - errors.timestamp) <=7 and errors.name = invocations.name 
  group by
    errors.name
)
select
  arn as resource,
  case
    when error_rate is null then 'error'
    when error_rate > 10 then 'alarm'
    else 'ok'
  end as status,
  case
    when error_rate is null then 'CloudWatch Lambda function metrics not available for ' || title || '.'
    else title || ' error rate is ' || error_rate || '% the last ' || '7  days.'
  end as reason,
  region,
  account_id
from
  aws_lambda_function f
  left join error_rate as er on f.name = er.name
