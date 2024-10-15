variable "ebs_snapshot_age_max_days" {
  type        = number
  description = "The maximum number of days snapshots can be retained."
  default     = 90
}

variable "ebs_volume_avg_read_write_ops_high" {
  type        = number
  description = "The number of average read/write ops required for volumes to be considered frequently used. This value should be higher than ebs_volume_avg_read_write_ops_low."
  default     = 500
}

variable "ebs_volume_avg_read_write_ops_low" {
  type        = number
  description = "The number of average read/write ops required for volumes to be considered infrequently used. This value should be lower than ebs_volume_avg_read_write_ops_high."
  default     = 100
}

variable "ebs_volume_max_iops" {
  type        = number
  description = "The maximum IOPS allowed for volumes."
  default     = 32000
}

variable "ebs_volume_max_size_gb" {
  type        = number
  description = "The maximum size (GB) allowed for volumes."
  default     = 100
}

locals {
  ebs_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EBS"
  })
}

benchmark "ebs" {
  title         = "EBS Checks"
  description   = "Thrifty developers keep a careful eye for unused and under-utilized EBS volumes."
  documentation = file("./controls/docs/ebs.md")
  children = [
    control.ebs_snapshot_max_age,
    control.ebs_volumes_on_stopped_instances,
    control.ebs_with_low_usage,
    control.gp2_volumes,
    control.high_iops_ebs_volumes,
    control.io1_volumes,
    control.large_ebs_volumes,
    control.low_iops_ebs_volumes,
    control.unattached_ebs_volumes
  ]

  tags = merge(local.ebs_common_tags, {
    type = "Benchmark"
  })
}

control "gp2_volumes" {
  title       = "Still using gp2 EBS volumes? Should use gp3 instead."
  description = "EBS gp2 volumes are more costly and lower performance than gp3."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when volume_type = 'gp2' then 'alarm'
        when volume_type = 'gp3' then 'ok'
        else 'skip'
      end as status,
      volume_id || ' type is ' || volume_type || '.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_volume;
  EOQ
}

control "io1_volumes" {
  title       = "Still using io1 EBS volumes? Should use io2 instead."
  description = "io1 Volumes are less reliable than io2 for same cost."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when volume_type = 'io1' then 'alarm'
        when volume_type = 'io2' then 'ok'
        else 'skip'
      end as status,
      volume_id || ' type is ' || volume_type || '.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_volume;
  EOQ
}

control "unattached_ebs_volumes" {
  title       = "Are there any unattached EBS volumes?"
  description = "Unattached EBS volumes render little usage, are expensive to maintain and should be reviewed."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
  sql = <<-EOQ
    select
      arn as resource,
      case
        when jsonb_array_length(attachments) > 0 then 'ok'
        else 'alarm'
      end as status,
      case
        when jsonb_array_length(attachments) > 0 then volume_id || ' has attachments.'
        else volume_id || ' has no attachments.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_volume;
  EOQ
}

control "large_ebs_volumes" {
  title       = "EBS volumes should be resized if too large"
  description = "Large EBS volumes are unusual, expensive and should be reviewed."
  severity    = "low"

  param "ebs_volume_max_size_gb" {
    description = "The maximum size (GB) allowed for volumes."
    default     = var.ebs_volume_max_size_gb
  }

  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when size <= $1 then 'ok'
        else 'alarm'
      end as status,
      volume_id || ' is ' || size || 'GB.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_volume;
  EOQ
}

control "high_iops_ebs_volumes" {
  title       = "EBS volumes with high IOPS should be resized if too large"
  description = "High IOPS io1 and io2 volumes are costly and usage should be reviewed."
  severity    = "low"

  param "ebs_volume_max_iops" {
    description = "The maximum IOPS allowed for volumes."
    default     = var.ebs_volume_max_iops
  }

  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when volume_type not in ('io1', 'io2') then 'skip'
        when iops > $1 then 'alarm'
        else 'ok'
      end as status,
      case
        when volume_type not in ('io1', 'io2') then volume_id || ' type is ' || volume_type || '.'
        else volume_id || ' has ' || iops || ' iops.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_volume;
  EOQ
}

control "low_iops_ebs_volumes" {
  title       = "What provisioned IOPS volumes would be better as GP3?"
  description = "GP3 provides 16k base IOPS performance, don't use more costly io1 & io2 volumes."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "management"
  })

  sql = <<-EOQ
    select
    arn as resource,
    case
      when volume_type not in ('io1', 'io2') then 'skip'
      when iops <= 16000 then 'alarm'
      else 'ok'
    end as status,
    case
      when volume_type not in ('io1', 'io2') then volume_id || ' type is ' || volume_type || '.'
      when iops <= 16000 then volume_id || ' only has ' || iops || ' iops.'
      else volume_id || ' has ' || iops || ' iops.'
    end as reason
    ${local.tag_dimensions_sql}
    ${local.common_dimensions_sql}
  from
    aws_ebs_volume;
  EOQ
}

control "ebs_volumes_on_stopped_instances" {
  title       = "EBS volumes attached to stopped instances should be reviewed"
  description = "Instances that are stopped may no longer need any attached EBS volumes"
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
      with vols_and_instances as (
        select
          v.arn,
          v._ctx,
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
          v._ctx,
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
      volume_id || ' is attached to ' || running_instances || ' running instances.' as reason
      ${local.common_dimensions_sql}
    from
      vols_and_instances;
  EOQ
}

control "ebs_with_low_usage" {
  title       = "Are there any EBS volumes with low usage?"
  description = "Volumes that are unused should be archived and deleted"
  severity    = "low"

  param "ebs_volume_avg_read_write_ops_low" {
    description = "The number of average read/write ops required for volumes to be considered infrequently used. This value should be lower than ebs_volume_avg_read_write_ops_high."
    default     = var.ebs_volume_avg_read_write_ops_low
  }

  param "ebs_volume_avg_read_write_ops_high" {
    description = "The number of average read/write ops required for volumes to be considered frequently used. This value should be higher than ebs_volume_avg_read_write_ops_low."
    default     = var.ebs_volume_avg_read_write_ops_high
  }

  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with ebs_usage as (
      select
        partition,
        account_id,
        _ctx,
        region,
        volume_id,
        round(avg(max)) as avg_max,
        count(max) as days
        from (
          (
            select
              partition,
              account_id,
              _ctx,
              region,
              volume_id,
              cast(maximum as numeric) as max
            from
              aws_ebs_volume_metric_read_ops_daily
            where
              date_part('day', now() - timestamp) <= 30
          )
          UNION
          (
            select
              partition,
              account_id,
              _ctx,
              region,
              volume_id,
              cast(maximum as numeric) as max
            from
              aws_ebs_volume_metric_write_ops_daily
            where
              date_part('day', now() - timestamp) <= 30
          )
        ) as read_and_write_ops
        group by 1,2,3,4,5
    )
    select
      'arn:' || partition || ':ec2:' || region || ':' || account_id || ':volume/' || volume_id as resource,
      case
        when avg_max <= $1 then 'alarm'
        when avg_max <= $2 then 'info'
        else 'ok'
      end as status,
      volume_id || ' is averaging ' || avg_max || ' read and write ops over the last ' || days || ' days.' as reason
      ${local.common_dimensions_sql}
    from
      ebs_usage;
  EOQ
}

control "ebs_snapshot_max_age" {
  title       = "Old EBS snapshots should be deleted if not required"
  description = "Old EBS snapshots are likely unnecessary and costly to maintain."
  severity    = "low"

  param "ebs_snapshot_age_max_days" {
    description = "The maximum number of days snapshots can be retained."
    default     = var.ebs_snapshot_age_max_days
  }

  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when start_time > (current_timestamp - ($1::int || ' days')::interval) then 'ok'
        else 'alarm'
      end as status,
      snapshot_id || ' created at ' || start_time || '.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_snapshot;
  EOQ
}
