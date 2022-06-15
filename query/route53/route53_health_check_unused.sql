with health_check as (
  select
    r.health_check_id as health_check_id
  from
    aws_route53_zone as z,
    aws_route53_record as r
  where
    r.zone_id = z.id
)
select
  'arn:' || h.partition || ':route53:::healthcheck/' || h.id as resource,
  case
    when c.health_check_id is null then 'alarm'
    else 'ok'
  end as status,
  case
    when c.health_check_id is null then h.title || ' is unnecessary.'
    else h.title || ' is necessary.'
  end as reason,
  h.region,
  h.account_id
from
  aws_route53_health_check as h
  left join health_check as c on h.id = c.health_check_id;
