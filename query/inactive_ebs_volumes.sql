select
  vol.arn as resource,
  -- Everything passing the where clause is in alarm state
  'alarm' as status,
  vol.volume_id || ' is attached to ' || (att ->> 'InstanceId') || ' which is stopped.' as reason,
  vol.region,
  vol.account_id
from
  aws_ebs_volume vol,
  jsonb_array_elements(vol.attachments) as att
where 
  vol.arn not in (
    -- List of volumes attached to running instances
    select
      v.arn
    from 
      aws_ebs_volume v,
      jsonb_array_elements(v.attachments) as a,
      aws_ec2_instance i
    where
      i.instance_state in ('running', 'pending', 'rebooting')
      and i.instance_id = a ->> 'InstanceId'
  );
