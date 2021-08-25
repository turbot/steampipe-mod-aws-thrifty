select
  arn as resource,
  case
    when date_part('day', now()-launch_time) > 90 then 'alarm'
    else 'ok'
  end as status,
  title || ' has been running ' || date_part('day', now()-launch_time) || ' days.' as reason,
  region,
  account_id
from
  aws_ec2_instance
where
  -- Instance is running
  instance_state in ('running', 'pending', 'rebooting');
