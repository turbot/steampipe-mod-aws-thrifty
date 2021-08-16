with service_with_autoscaling as (
  select
    distinct split_part(t.resource_id, '/', 2) as cluster_name,
    split_part(t.resource_id, '/', 3) as service_name
  from
    aws_ecs_service as s
    left join aws_appautoscaling_target as t on t.service_namespace = 'ecs'
)
select
  s.arn as resource,
  case
    when s.launch_type != 'FARGATE' then 'skip'
    when a.service_name is null then 'alarm'
    else 'ok'
  end as status,
  case
    when s.launch_type != 'FARGATE' then s.title || ' task not running on FARGATE.'
    when a.service_name is null then s.title || ' autoscaling disabled.'
    else s.title || ' autoscaling enabled.'
  end as reason,
  s.region,
  s.account_id
from
  aws_ecs_service as s
  left join service_with_autoscaling as a on s.service_name = a.service_name and a.cluster_name = split_part(s.cluster_arn, '/', 2);