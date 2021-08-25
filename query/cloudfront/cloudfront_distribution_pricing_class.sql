select
  id as resource,
  case
    when price_class = 'PriceClass_All' then 'info'
    else 'ok'
  end as status,
  title || ' has ' || price_class || '.'
  as reason,
  region,
  account_id
from
  aws_cloudfront_distribution;