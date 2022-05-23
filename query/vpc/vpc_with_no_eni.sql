select
  -- Required Columns
  arn as resource,
  case
    when i.network_interface_id is null then 'alarm'
    else 'ok'
  end as status,
  case
    when i.network_interface_id is null then v.title || ' does not have ENI.'
    else v.title || ' does have ENI.'
  end as reason,
  -- Additional Dimensions
  v.region,
  v.account_id
from
  aws_vpc as v
  left join aws_ec2_network_interface as i on v.vpc_id = i.vpc_id;