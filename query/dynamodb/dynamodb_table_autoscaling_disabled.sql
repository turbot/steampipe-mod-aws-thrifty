with table_with_autocaling as (
  select
    t.resource_id as resource_id,
    count(t.resource_id) as count
  from
    aws_appautoscaling_target as t where service_namespace = 'dynamodb'
    group by t.resource_id
)
select
  d.arn as resource,
  case
    when d.billing_mode = 'PAY_PER_REQUEST' then 'ok'
    when t.resource_id is null then 'alarm'
    when t.count < 2 then 'alarm'
    else 'ok'
  end as status,
  case
    when d.billing_mode = 'PAY_PER_REQUEST' then d.title || ' on-demand mode enabled.'
    when t.resource_id is null then d.title || ' auto scaling not enabled.'
    when t.count < 2 then d.title || ' auto scaling not enabled for both read and write capacity.'
    else d.title || ' auto scaling enabled for both read and write capacity.'
  end as reason,
  d.region,
  d.account_id
from
  aws_dynamodb_table as d
  left join table_with_autocaling as t on concat('table/', d.name) = t.resource_id;
