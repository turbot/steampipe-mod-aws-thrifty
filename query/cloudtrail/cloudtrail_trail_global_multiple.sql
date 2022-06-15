with global_trails as (
    select
      count(*) as total
    from
      aws_cloudtrail_trail
    where
      is_multi_region_trail
)
select
  arn as resource,
  case
    when total > 1 then 'alarm'
    else 'ok'
  end as status,
  case
    when total > 1 then name || ' is one of ' || total || ' global trails.'
    else name || ' is the only global trail.'
  end as reason,
  region,
  account_id
from 
  aws_cloudtrail_trail,
  global_trails
where 
  is_multi_region_trail