with target_resource as (
  select
    load_balancer_arn,
    target_health_descriptions,
    target_type
  from
    aws_ec2_target_group,
    jsonb_array_elements_text(load_balancer_arns) as load_balancer_arn
)
select
  a.arn as resource,
  case
    when b.target_health_descriptions is null then 'alarm'
    else 'ok'
  end as status,
  case
    when b.target_health_descriptions is null then a.title || ' has no target registered.'
    else a.title || ' has registered target of type' || ' ' || b.target_type || '.'
  end as reason,
  a.region,
  a.account_id
from
  aws_ec2_network_load_balancer a
  left join target_resource b on a.arn = b.load_balancer_arn;