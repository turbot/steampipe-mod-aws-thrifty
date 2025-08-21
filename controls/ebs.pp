variable "ebs_snapshot_age_max_days" {
  type        = number
  description = "The maximum number of days snapshots can be retained."
  default     = 90
}

variable "ebs_volume_io1_ops" {
  type        = number
  description = "The number of io1 iops"
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
  title         = "EBS Cost Controls"
  description   = "Thrifty developers keep a careful eye for unused and under-utilized EBS volumes."
  documentation = file("./controls/docs/ebs.md")
  children = [
    control.ebs_snapshot_max_age,
    control.ebs_volume_high_iops,
    control.ebs_volume_io1_io2_migrate_to_gp3,
    control.ebs_volume_large,
    control.ebs_volume_low_iops,
    control.ebs_volume_low_usage,
    control.ebs_volume_on_stopped_instances,
    control.ebs_volume_unattached,
    control.ebs_volume_using_gp2,
    control.ebs_volume_using_io1
  ]

  tags = merge(local.ebs_common_tags, {
    type = "Benchmark"
  })
}

control "ebs_snapshot_max_age" {
  title       = "Old EBS snapshots should be deleted if not required"
  description = "EBS snapshots that have been retained beyond the defined threshold may be unnecessary and can incur significant storage costs. Regularly review and delete old snapshots that are no longer required for backup or compliance purposes."
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
        when start_time > current_timestamp - ($1::int || ' days')::interval then 'ok'
        else 'alarm'
      end as status,
      snapshot_id || ' created at ' || start_time || '.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_snapshot;
  EOQ
}

control "ebs_volume_high_iops" {
  title       = "EBS volumes with high IOPS should be reviewed"
  description = "EBS volumes provisioned with high IOPS (io1 or io2) can be expensive. Review these volumes to ensure the provisioned IOPS matches actual workload requirements, and consider resizing or switching to a more cost-effective volume type if possible."
  severity    = "low"

  param "ebs_volume_max_iops" {
    description = "The maximum IOPS allowed for volumes."
    default     = var.ebs_volume_max_iops
  }

  tags = merge(local.ebs_common_tags, {
    class = "overused"
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

control "ebs_volume_large" {
  title       = "EBS volumes should be resized if too large"
  description = "EBS volumes with large capacity may be over-provisioned, leading to unnecessary costs. Review and resize large volumes to align with actual storage needs."
  severity    = "low"

  param "ebs_volume_max_size_gb" {
    description = "The maximum size (GB) allowed for volumes."
    default     = var.ebs_volume_max_size_gb
  }

  tags = merge(local.ebs_common_tags, {
    class = "overused"
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

control "ebs_volume_low_iops" {
  title       = "Provisioned IOPS volumes with low IOPS should be migrated to GP3"
  description = "Provisioned IOPS (io1/io2) volumes with low IOPS may be more cost-effectively served by GP3 volumes, which provide 3,000 base IOPS at a lower cost. Review and migrate eligible volumes to GP3 to optimize performance and reduce expenses."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "overused"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when volume_type not in ('io1', 'io2') then 'skip'
        when iops <= 3000 then 'alarm'
        else 'ok'
      end as status,
      case
        when volume_type not in ('io1', 'io2') then volume_id || ' type is ' || volume_type || '.'
        when iops <= 3000 then volume_id || ' only has ' || iops || ' iops.'
        else volume_id || ' has ' || iops || ' iops.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_volume;
  EOQ
}

control "ebs_volume_low_usage" {
  title       = "EBS volumes with low usage should be reviewed"
  description = "EBS volumes with consistently low read/write operations may be underutilized or obsolete. Review these volumes and consider archiving or deleting them to reduce storage costs."
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
    class = "underused"
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

control "ebs_volume_on_stopped_instances" {
  title       = "EBS volumes attached to stopped instances should be reviewed"
  description = "EBS volumes attached to stopped EC2 instances may not be needed and can incur unnecessary costs. Review and detach or delete these volumes if they are no longer required."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with vols_and_instances as (
      select
        v.arn,
        v._ctx,
        v.volume_id,
        v.size,
        i.instance_id,
        v.region,
        v.volume_type,
        v.account_id,
        v.tags,
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
        v.account_id,
        v.volume_type,
        v.size,
        v.tags
    )
    select
      arn as resource,
      case
        when running_instances > 0 then 'ok'
        else 'alarm'
      end as status,
      volume_id || ' is attached to ' || running_instances || ' running instances.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      vols_and_instances;
  EOQ
}

control "ebs_volume_unattached" {
  title       = "Unattached EBS volumes should be deleted"
  description = "EBS volumes that are not attached to any EC2 instance are likely unused and continue to incur storage charges. Regularly review and delete unattached volumes to optimize costs."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
  sql = <<-EOQ
    select
      arn as resource,
      case
        when volume_type = 'gp2' then 'alarm'
        when volume_type = 'gp3' then 'ok'
        else 'skip'
      end as status,
      volume_id || ' type is ' || volume_type as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_volume;
  EOQ
}

control "ebs_volume_using_io1" {
  title       = "EBS volumes using io1 should be migrated to io2"
  description = "IO2 volumes provide higher durability and reliability at the same cost as IO1. Review and migrate EBS volumes using IO1 to IO2 to improve data durability and optimize costs."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "outdated_resources"
  })

  param "ebs_volume_io1_ops" {
    description = "The number of io1 ops allowed"
    default     = var.ebs_volume_io1_ops
  }

  sql = <<-EOQ
    select
      arn as resource,
      case
        when volume_type not in ('io1', 'io2') then 'skip'
        when volume_type = 'io1' and iops > $1 then 'alarm'
        else 'skip'
      end as status,
      case
        when volume_type not in ('io1', 'io2') then volume_id || ' type is ' || volume_type || '.'
        else volume_id || ' type is ' || volume_type || ' using ' || iops || ' iops.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_volume;
  EOQ
}

control "ebs_volume_using_gp2" {
  title       = "EBS volumes using gp2 should be migrated to gp3"
  description = "GP3 volumes offer better performance and lower cost compared to GP2. Review and migrate EBS volumes using GP2 to GP3 to optimize storage performance and reduce expenses."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "outdated_resources"
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

control "ebs_volume_io1_io2_migrate_to_gp3" {
  title       = "EBS volumes using io1/io2 should be migrated to GP3 if IOPS ≤ 16,000"
  description = "EBS volumes using io1 or io2 storage types with IOPS ≤ 16,000 should be migrated to GP3 for better cost efficiency. GP3 provides up to 16,000 IOPS with improved price-performance ratio compared to io1/io2 volumes."

  sql = <<EOQ
    select
      volume_id as resource,
      case
        when volume_type in ('io1', 'io2') and iops <= 16000 then 'alarm'
        else 'ok'
      end as status,
      case
        when  volume_type in ('io1', 'io2') and iops <= 16000 then title || ' (' || volume_type || ') can be migrated to GP3. Current IOPS: ' || iops || '.'
        else title || ' (' || volume_type || ') should remain as current type. Current IOPS: ' || iops || '. '
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_volume;
  EOQ
}