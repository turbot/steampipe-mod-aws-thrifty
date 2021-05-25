with vols_and_instances as (
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
      aws_ebs_volume as v
      left join jsonb_array_elements(v.attachments) as va on true
      left join aws_ec2_instance as i on va ->> 'InstanceId' = i.instance_id
    group by
      v.arn, 
      v.volume_id,
      i.instance_id,
      i.instance_id,
      v.region,
      v.account_id
)
select
  arn as resource,
  case
    when running_instances > 0 then 'ok'
    else 'alarm'
  end as status,
  volume_id || ' is attached to ' || running_instances || ' running instances.' as reason,
  region,
  account_id
from 
  vols_and_instances