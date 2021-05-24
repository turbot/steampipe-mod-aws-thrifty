select
  arn as resource,
    case
      when running_instances > 0 then 'ok'
    else 'alarm'
  end as status,
  volume_id || ' is attached to ' || running_instances || ' running instances.' as reason,
  region,
  account_id
from (
  select
    v.arn,
    v.volume_id,
    i.instance_id,
    v.region,
    v.account_id,
    sum(
      case 
        when i.instance_state = 'stopped' then 0
        else 1
      end
    ) as running_instances
  from
    aws_ebs_volume v,
    jsonb_array_elements(v.attachments) va, 
    aws_ec2_instance i
  where
    va ->> 'InstanceId' = i.instance_id
  group by
    v.arn, 
    v.volume_id,
    i.instance_id,
    i.instance_id,
    v.region,
    v.account_id
) as ebs_volumes
