variable "rds_db_instance_avg_connections" {
  type        = number
  description = "The minimum number of average connections per day required for DB instances to be considered in-use."
  default     = 2
}

variable "rds_db_instance_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for DB instances to be considered frequently used. This value should be higher than rds_db_instance_avg_cpu_utilization_low."
  default     = 50
}

variable "rds_db_instance_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for DB instances to be considered infrequently used. This value should be lower than rds_db_instance_avg_cpu_utilization_high."
  default     = 25
}

variable "rds_running_db_instance_age_max_days" {
  type        = number
  description = "The maximum number of days DB instances are allowed to run."
  default     = 90
}

variable "rds_running_db_instance_age_warning_days" {
  type        = number
  description = "The number of days DB instances can be running before sending a warning."
  default     = 30
}

variable "rds_snapshot_unused_max_days" {
  type        = number
  description = "The maximum number of days an RDS snapshot can be retained after its source DB instance is deleted."
  default     = 30
}

locals {
  rds_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/RDS"
  })
}

benchmark "rds" {
  title         = "RDS Cost Controls"
  description   = "Thrifty developers eliminate unused and under-utilized RDS instances."
  documentation = file("./controls/docs/rds.md")
  children = [
    control.rds_db_instance_prev_gen_class,
    control.rds_db_instance_max_age,
    control.rds_db_instance_low_connection,
    control.rds_db_instance_low_cpu_utilization,
    control.rds_db_instance_without_graviton,
    control.rds_db_instance_unsupported_engine_version,
    control.rds_db_snapshot_unused
  ]

  tags = merge(local.rds_common_tags, {
    type = "Benchmark"
  })
}

control "rds_db_instance_max_age" {
  title       = "Long running RDS DB instances should use reserved instances"
  description = "DS DB instances that have been running for an extended period should be converted to reserved instances to take advantage of significant cost savings. Review long-running instances and consider purchasing reserved capacity for them."
  severity    = "low"

  param "rds_running_db_instance_age_max_days" {
    description = "The maximum number of days DB instances are allowed to run."
    default     = var.rds_running_db_instance_age_max_days
  }

  param "rds_running_db_instance_age_warning_days" {
    description = "The number of days DB instances can be running before sending a warning."
    default     = var.rds_running_db_instance_age_warning_days
  }

  tags = merge(local.rds_common_tags, {
    class = "capacity_planning"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when date_part('day', now()-create_time) > $1 then 'alarm'
        when date_part('day', now()-create_time) > $2 then 'info'
        else 'ok'
      end as status,
      title || ' has been in use for ' || date_part('day', now()-create_time) || ' days.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_rds_db_instance;
  EOQ
}

control "rds_db_instance_prev_gen_class" {
  title       = "RDS DB instances using previous generation instance types should be reviewed"
  description = "RDS DB instances running on previous generation instance types may have higher costs and lower performance. Review and migrate these instances to the latest generation types to optimize cost and performance."
  severity    = "low"

  tags = merge(local.rds_common_tags, {
    class = "outdated_resources"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when class like '%.t2.%' then 'alarm'
        when class like '%.m3.%' then 'alarm'
        when class like '%.m4.%' then 'alarm'
        when class like '%.m5.%' then 'ok'
        when class like '%.t3.%' then 'ok'
        else 'info'
      end as status,
      title || ' has a ' || class || ' instance class.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_rds_db_instance;
  EOQ
}

control "rds_db_instance_low_connection" {
  title       = "RDS DB instances with low connection counts should be reviewed"
  description = "RDS DB instances with consistently low connection counts may be underutilized or unnecessary. Review these instances and consider resizing or terminating them to reduce costs."
  severity    = "high"

  param "rds_db_instance_avg_connections" {
    description = "The minimum number of average connections per day required for DB instances to be considered in-use."
    default     = var.rds_db_instance_avg_connections
  }

  tags = merge(local.rds_common_tags, {
    class = "underused"
  })


  sql = <<-EOQ
    with rds_db_usage as (
      select
        db_instance_identifier,
        round(sum(maximum)/count(maximum)) as avg_max,
        count(maximum) days
      from
        aws_rds_db_instance_metric_connections_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        db_instance_identifier
    )
    select
      arn as resource,
      case
        when avg_max is null then 'error'
        when avg_max = 0 then 'alarm'
        when avg_max < $1 then 'info'
        else 'ok'
      end as status,
      case
        when avg_max is null then 'CloudWatch metrics not available for ' || title || '.'
        when avg_max = 0 then title || ' has not been connected to in the last ' || days || ' days.'
        else title || ' is averaging ' || avg_max || ' max connections/day in the last ' || days || ' days.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_rds_db_instance i
      left join rds_db_usage as u on u.db_instance_identifier = i.db_instance_identifier;
  EOQ
}

control "rds_db_instance_low_cpu_utilization" {
  title       = "RDS DB instances with low CPU utilization should be reviewed"
  description = "RDS DB instances with low CPU utilization may be over-provisioned. Review and resize or terminate these instances to optimize resource usage and reduce costs."
  severity    = "low"

  param "rds_db_instance_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for DB instances to be considered infrequently used. This value should be lower than rds_db_instance_avg_cpu_utilization_high."
    default     = var.rds_db_instance_avg_cpu_utilization_low
  }

  param "rds_db_instance_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for DB instances to be considered frequently used. This value should be higher than rds_db_instance_avg_cpu_utilization_low."
    default     = var.rds_db_instance_avg_cpu_utilization_high
  }

  tags = merge(local.rds_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with rds_db_usage as (
      select
        db_instance_identifier,
        round(cast(sum(maximum)/count(maximum) as numeric), 1) as avg_max,
        count(maximum) days
      from
        aws_rds_db_instance_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        db_instance_identifier
    )
    select
      arn as resource,
      case
        when avg_max is null then 'error'
        when avg_max <= $1 then 'alarm'
        when avg_max <= $2 then 'info'
        else 'ok'
      end as status,
      case
        when avg_max is null then 'CloudWatch metrics not available for ' || title || '.'
        else title || ' is averaging ' || avg_max || '% max utilization over the last ' || days || ' days.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_rds_db_instance i
      left join rds_db_usage as u on u.db_instance_identifier = i.db_instance_identifier;
  EOQ
}

control "rds_db_instance_without_graviton" {
  title       = "RDS DB instances not using graviton processor should be reviewed"
  description = "EC2 instances running on x86_64 architecture may incur higher costs compared to Graviton (arm64) instances. Review and migrate eligible workloads to Graviton-based instances to benefit from improved performance and reduced costs."
  severity    = "low"

  tags = merge(local.rds_common_tags, {
    class = "outdated_resources"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when class like 'db.%g%.%' then 'ok'
        else 'alarm'
      end as status,
      case
        when class like 'db.%g%.%' then title || ' is using graviton processor.'
        else title || ' is not using graviton processor.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_rds_db_instance;
  EOQ
}

control "rds_db_instance_unsupported_engine_version" {
  title       = "RDS MySQL and PostgreSQL DB instances with unsupported versions should be upgraded"
  description = "RDS MySQL and PostgreSQL DB instances running unsupported engine versions may incur higher charges and lack security updates. Upgrade these instances to supported versions to avoid extended support costs and maintain compliance."
  severity    = "low"

  tags = merge(local.rds_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    select
      arn as resource,
      engine_version,
      engine,
      case
        when not engine ilike any (array ['%mysql%', '%postgres%']) then 'skip'
        when
          (engine like '%mysql' and engine_version like '5.7.%' )
          or (engine like '%postgres%' and engine_version like '11.%') then 'alarm'
        else 'ok'
      end as status,
      case
        when not engine ilike any (array ['%mysql%', '%postgres%']) then title || ' is of ' || engine || ' engine type.'
        when
          (engine like '%mysql' and engine_version like '5.7.%' )
          or (engine like '%postgres%' and engine_version like '11.%') then title || ' is using RDS Extended Support.'
        else title || ' is not using RDS Extended Support.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_rds_db_instance;
  EOQ
}

control "rds_db_snapshot_unused" {
  title       = "RDS snapshots without source DB instances should be removed"
  description = "RDS snapshots whose source DB instances no longer exist may be obsolete and can incur unnecessary storage costs. Regularly review and delete unused snapshots to optimize storage usage and reduce costs."
  severity    = "low"

  param "rds_snapshot_unused_max_days" {
    description = "The maximum number of days an RDS snapshot can be retained after its source DB instance is deleted."
    default     = var.rds_snapshot_unused_max_days
  }

  tags = merge(local.rds_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with instance_exists as (
      select
        db_instance_identifier
      from
        aws_rds_db_instance
    )
    select
      s.arn as resource,
      s.title,
      case
        when s.status != 'available' then 'skip'
        when i.db_instance_identifier is null and date_part('day', now() - s.create_time) > $1 then 'alarm'
        when i.db_instance_identifier is null then 'info'
        else 'ok'
      end as status,
      case
        when s.status != 'available' then s.title || ' is in ' || s.status || ' status.'
        when i.db_instance_identifier is null and date_part('day', now() - s.create_time) > $1 then s.title || ' is ' || date_part('day', now() - s.create_time) || ' days old and its source DB instance no longer exists.'
        when i.db_instance_identifier is null then s.title || ' source DB instance no longer exists but snapshot is only ' || date_part('day', now() - s.create_time) || ' days old.'
        else s.title || ' has an existing source DB instance.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_rds_db_snapshot s
      left join instance_exists i on i.db_instance_identifier = s.db_instance_identifier;
  EOQ
}


