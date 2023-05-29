variable "ebs_snapshot_age_max_days" {
  type        = string
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
  default     = 7
}

locals {
  ebs_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EBS"
  })
}

benchmark "ebs" {
  title         = "EBS Cost Checks"
  description   = "Thrifty developers keep a careful eye for unused and under-utilized EBS volumes."
  documentation = file("./controls/docs/ebs.md")
  children = [
    control.ebs_snapshot_max_age,
    control.ebs_volume_on_stopped_instances,
    control.ebs_volume_low_usage,
    control.ebs_volume_using_gp2,
    control.ebs_volume_high_iops,
    control.ebs_volume_using_io1,
    control.ebs_volume_large,
    control.ebs_volume_low_iops,
    control.ebs_volume_unattached
  ]

  tags = merge(local.ebs_common_tags, {
    type = "Benchmark"
  })
}

control "ebs_volume_using_gp2" {
  title       = "Still using gp2 EBS volumes? Should use gp3 instead."
  description = "EBS gp2 volumes are more costly and lower performance than gp3."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "generation_gaps"
  })

  sql = <<-EOQ
    with volume_list as (
      select
        arn,
        volume_id,
        volume_type,
        size,
        region,
        account_id
      from
        aws_ebs_volume
    ),
    volume_regions as (
      select
        distinct region
      from
        aws_ebs_volume
    ),
    volume_pricing as (
      select
        r.region,
        p.currency,
        max(case when p.attributes ->> 'volumeApiName' = 'gp2' then  p.price_per_unit else null end) as gp2_price,
        max(case when p.attributes ->> 'volumeApiName' = 'gp3' then  p.price_per_unit else null end) as gp3_price
      from
        aws_pricing_product as p
        join volume_regions as r on
          p.service_code = 'AmazonEC2'
          and p.filters = '{
            "volumeType": "General Purpose"
          }' :: jsonb
          and p.attributes ->> 'regionCode' = r.region
      group by r.region, p.currency
    ),
    calculate_savings_per_volume as (
      select
        v.arn,
        v.volume_id,
        v.volume_type,
        v.region,
        v.account_id,
        case
          when v.volume_type = 'gp2' then ((p.gp2_price::float - p.gp3_price::float) * v.size)::numeric(10,2) || ' ' || currency || '/month'
          else ''
        end as net_savings,
        p.currency
      from
        volume_list as v
        join volume_pricing as p on v.region = p.region
    )
    select
      arn as resource,
      case
        when volume_type = 'gp2' then 'alarm'
        when volume_type = 'gp3' then 'ok'
        else 'skip'
      end as status,
      volume_id || ' type is ' || volume_type as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      calculate_savings_per_volume
  EOQ
}

control "ebs_volume_using_io1" {
  title       = "Still using io1 EBS volumes? Should use io2 instead."
  description = "io1 Volumes are less reliable than io2 for same cost."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "generation_gaps"
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

control "ebs_volume_unattached" {
  title       = "Are there any unattached EBS volumes?"
  description = "Unattached EBS volumes render little usage, are expensive to maintain and should be reviewed."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
  sql = <<-EOQ
    with volume_list as (
      select
        arn,
        volume_id,
        volume_type,
        size,
        attachments,
        region,
        account_id
      from
        aws_ebs_volume
    ),
    volume_pricing as (
      select
        v.arn,
        v.volume_id,
        v.size,
        v.region,
        v.account_id,
        v.attachments,
        case when jsonb_array_length(attachments) > 0 then '' else
        (p.price_per_unit::numeric * v.size)::numeric(10,2) || ' ' || currency || '/month' end as net_savings,
        p.currency
      from
        volume_list as v
        left join aws_pricing_product as p on
          p.service_code = 'AmazonEC2'
          and p.filters in (
            '{"volumeType": "General Purpose"}' :: jsonb,
            '{"volumeType": "Provisioned IOPS"}' :: jsonb,
            '{"volumeType": "Throughput Optimized HDD"}' :: jsonb,
            '{"volumeType": "Cold HDD"}' :: jsonb
          )
          and p.attributes ->> 'regionCode' = v.region
          and p.attributes ->> 'volumeApiName' = v.volume_type
    )
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
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      volume_pricing;
  EOQ
}

control "ebs_volume_large" {
  title       = "EBS volumes should be resized if too large"
  description = "Large EBS volumes are unusual, expensive and should be reviewed."
  severity    = "low"

  param "ebs_volume_max_size_gb" {
    description = "The maximum size (GB) allowed for volumes."
    default     = var.ebs_volume_max_size_gb
  }

  tags = merge(local.ebs_common_tags, {
    class = "overused"
  })

  sql = <<-EOQ
    with volume_list as (
      select
        arn,
        volume_id,
        volume_type,
        size,
        attachments,
        region,
        account_id
      from
        aws_ebs_volume
    ),
    volume_pricing as (
      select
        v.arn,
        v.volume_id,
        v.size,
        v.region,
        v.account_id,
        (p.price_per_unit::numeric * v.size)::numeric(10,2) || ' ' || currency || '/month' as net_savings,
        p.currency
      from
        volume_list as v
        left join aws_pricing_product as p on
          p.service_code = 'AmazonEC2'
          and p.filters in (
            '{"volumeType": "General Purpose"}' :: jsonb,
            '{"volumeType": "Provisioned IOPS"}' :: jsonb,
            '{"volumeType": "Throughput Optimized HDD"}' :: jsonb,
            '{"volumeType": "Cold HDD"}' :: jsonb
          )
          and p.attributes ->> 'regionCode' = v.region
          and p.attributes ->> 'volumeApiName' = v.volume_type
    )
    select
      arn as resource,
      case
        when size <= $1 then 'ok'
        else 'alarm'
      end as status,
      volume_id || ' is ' || size || 'GB.' as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      volume_pricing;
  EOQ
}

control "ebs_volume_high_iops" {
  title       = "EBS volumes with high IOPS should be resized if too large"
  description = "High IOPS io1 and io2 volumes are costly and usage should be reviewed."
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

control "ebs_volume_low_iops" {
  title       = "What provisioned IOPS volumes would be better as GP3?"
  description = "GP3 provides 3k base IOPS performance, don't use more costly io1 & io2 volumes."
  severity    = "low"
  tags = merge(local.ebs_common_tags, {
    class = "overused"
  })

  sql = <<-EOQ
    with volume_list as (
      select
        arn,
        volume_id,
        volume_type,
        size,
        iops,
        region,
        account_id
      from
        aws_ebs_volume
    ),
    volume_pricing as (
      select
        v.arn,
        v.volume_id,
        v.volume_type,
        v.size,
        v.iops,
        v.region,
        v.account_id,
        case
          when v.volume_type not in ('io1', 'io2') then ''
          when v.iops <= 3000 then (p.price_per_unit::numeric * v.size)::numeric(10,2) || ' ' || currency || '/month'
          else ''
        end as net_savings,
        p.currency
      from
        volume_list as v
        left join aws_pricing_product as p on
          p.service_code = 'AmazonEC2'
          and p.filters in (
            '{"volumeType": "General Purpose"}' :: jsonb,
            '{"volumeType": "Provisioned IOPS"}' :: jsonb,
            '{"volumeType": "Throughput Optimized HDD"}' :: jsonb,
            '{"volumeType": "Cold HDD"}' :: jsonb
          )
          and p.attributes ->> 'regionCode' = v.region
          and p.attributes ->> 'volumeApiName' = v.volume_type
    )
    select
      arn as resource,
      case
        when volume_type not in ('io1', 'io2') then 'skip'
        when iops <= 3000 then 'alarm'
        else 'ok'
      end as status,
      case
        when volume_type not in ('io1', 'io2') then volume_id || ' type is ' || volume_type || '.'
        when iops <= 3000 then volume_id || ' only has ' || iops || ' iops .'
        else volume_id || ' has ' || iops || ' iops.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      volume_pricing;
  EOQ
}

control "ebs_volume_on_stopped_instances" {
  title       = "EBS volumes attached to stopped instances should be reviewed"
  description = "Instances that are stopped may no longer need any attached EBS volumes"
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

control "ebs_volume_low_usage" {
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
        when start_time > current_timestamp - ($1 || ' days')::interval then 'ok'
        else 'alarm'
      end as status,
      snapshot_id || ' created at ' || start_time || '.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ebs_snapshot;
  EOQ
}
