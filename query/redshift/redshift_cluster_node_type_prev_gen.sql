select
  arn as resource,
  case
    when node_type like 'dc1.%' then 'alarm'
    else 'ok'
  end as status,
  title || ' has ' || node_type || ' node type.' as reason,
  region,
  account_id
from
  aws_redshift_cluster;
