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

locals {
  rds_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/RDS"
  })
}

benchmark "rds" {
  title         = "RDS Checks"
  description   = "Thrifty developers eliminate unused and under-utilized RDS instances."
  documentation = file("./controls/docs/rds.md")
  children = [
    control.latest_rds_instance_types,
    control.long_running_rds_db_instances,
    control.rds_db_instance_with_graviton,
    control.rds_db_low_connection_count,
    control.rds_db_low_utilization
  ]

  tags = merge(local.rds_common_tags, {
    type = "Benchmark"
  })
}

control "long_running_rds_db_instances" {
  title       = "Long running RDS DBs should have reserved instances purchased for them"
  description = "Long running database servers should be associated with a reserve instance."
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
    class = "managed"
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

control "latest_rds_instance_types" {
  title       = "Are there RDS instances using previous gen instance types?"
  description = "M5 and T3 instance types are less costly than previous generations"
  severity    = "low"
  tags = merge(local.rds_common_tags, {
    class = "managed"
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

control "rds_db_low_connection_count" {
  title       = "RDS DB instances with a low number connections per day should be reviewed"
  description = "DB instances having less usage in last 30 days should be reviewed."
  severity    = "high"

  param "rds_db_instance_avg_connections" {
    description = "The minimum number of average connections per day required for DB instances to be considered in-use."
    default     = var.rds_db_instance_avg_connections
  }

  tags = merge(local.rds_common_tags, {
    class = "unused"
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

control "rds_db_low_utilization" {
  title       = "RDS DB instance having low CPU utilization should be reviewed"
  description = "DB instances may be oversized for their usage."
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

control "rds_db_instance_with_graviton" {
  title       = "RDS DB instances without graviton processor should be reviewed"
  description = "With graviton processor (arm64 - 64-bit ARM architecture), you can save money in two ways. First, your functions run more efficiently due to the Graviton architecture. Second, you pay less for the time that they run. In fact, Lambda functions powered by Graviton are designed to deliver up to 19 percent better performance at 20 percent lower cost."
  severity    = "low"

  tags = merge(local.rds_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when class like 'db.%g%.%' then 'ok'
        else 'alarm'
      end as status,
      case
        when class like 'db.%g%.%' then title || ' is using Graviton processor.'
        else title || ' is not using Graviton processor.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_rds_db_instance;
  EOQ
}

