with instance_data as (
  select
    instance_id,
    subnet_id,
    instance_state
  from
    aws_ec2_instance
)
select
  -- Required Columns
  nat.arn as resource,
  case
    when nat.state <> 'available' then 'alarm'
    when i.subnet_id is null then 'alarm'
    when i.instance_state <> 'running' then 'alarm'
    else 'ok'
  end as status,
  case
    when nat.state <> 'available' then nat.title || ' in ' || nat.state || ' state.'
    when i.subnet_id is null then nat.title || ' not in-use.'
    when i.instance_state <> 'running' then nat.title || ' associated with ' || i.instance_id || ', which is in ' || i.instance_state || ' state.'
    else nat.title || ' in-use.'
  end as reason,
  -- Additional Dimensions
  nat.region,
  nat.account_id
from
  aws_vpc_nat_gateway as nat
  left join instance_data as i on nat.subnet_id = i.subnet_id;