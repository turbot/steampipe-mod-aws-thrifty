with 
  global_trails as (
    select
      count(*) as total
    from
      aws_cloudtrail_trail
    where
      is_multi_region_trail
  ),
    org_trails as (
    select
      count(*) as total
    from
      aws_cloudtrail_trail
    where
      is_organization_trail
  ),
    regional_trails as (
    select
      region,
      count(*) as total
    from
      aws_cloudtrail_trail
    where
      not is_multi_region_trail 
      and not is_organization_trail
    group by 
      region
  )
select
  arn as resource,
  case
    when global_trails.total > 0 then 'alarm'
    when org_trails.total > 0 then 'alarm'
    when regional_trails.total > 1 then 'alarm'
    else 'ok'
  end as status,
  case
    when global_trails.total > 0 then name || ' is redundant to a global trail.'
    when org_trails.total > 0 then name || ' is redundant to a organizational trail.'
    when regional_trails.total > 1 then name || ' is one of ' || regional_trails.total || ' trails in ' || t.region || '.'
    else name || ' is the only global trail.'
  end as reason,
  t.region,
  account_id
from 
  aws_cloudtrail_trail t,
  global_trails,
  org_trails,
  regional_trails
where 
  regional_trails.region = t.region
  and not is_multi_region_trail 
  and not is_organization_trail