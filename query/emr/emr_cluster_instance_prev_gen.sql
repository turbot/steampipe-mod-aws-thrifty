select
  ig.id as resource,
  case
    when ig.state = 'TERMINATED' then 'skip'
    when ig.instance_type like 'c1.%' then 'alarm'
    when ig.instance_type like 'cc2.%' then 'alarm'
    when ig.instance_type like 'cr1.%' then 'alarm'
    when ig.instance_type like 'm2.%' then 'alarm'
    when ig.instance_type like 'g2.%' then 'alarm'
    when ig.instance_type like 'i2,m1.%' then 'alarm'
    when ig.instance_type like 'c1.%' then 'alarm'
    else 'info'
  end as status,
  case
  when ig.state = 'TERMINATED' then ig.cluster_id || ' is ' || ig.state || '.'
  else ig.cluster_id || ' has ' || ig.instance_type || ' instance type.'
  end as reason,
  c.region,
  c.account_id
from
  aws_emr_instance_group as ig,
  aws_emr_cluster as c
where
  ig.cluster_id = c.id
  and ig.instance_group_type = 'MASTER';