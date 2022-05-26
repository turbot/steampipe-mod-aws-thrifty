select
  arn as resource,
  case
    when status = 'ACTION_NEEDED' then 'alarm'
    else 'ok'
  end as status,
  case
    when status = 'ACTION_NEEDED' then title || ' not in healthy state.'
    else title || ' is in healthy state.'
  end as reason,
  region,
  account_id
from
  aws_route53_resolver_endpoint;
