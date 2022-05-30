select
   'arn:' || r.partition || ':route53:::hostedzone/' || r.zone_id || '/recordset/' || r.name || '/' || r.type as resource,
  case
    when ttl::int < 3600 then 'alarm'
    else 'ok'
  end as status,
  case
    when ttl::int < 3600 then r.title || ' TTL value is ' || ttl || 's.'
    else r.title || ' TTL value is ' || ttl || 's.'
  end as reason,
  r.region,
  r.account_id
from
  aws_route53_zone as z,
  aws_route53_record as r
where
  r.zone_id = z.id;