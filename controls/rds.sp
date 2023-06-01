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
  title         = "RDS Cost Checks"
  description   = "Thrifty developers eliminate unused and under-utilized RDS instances."
  documentation = file("./controls/docs/rds.md")
  children = [
    control.rds_db_instance_class_prev_gen,
    control.rds_db_instance_max_age,
    control.rds_db_instance_low_connections,
    control.rds_db_instance_low_usage
  ]

  tags = merge(local.rds_common_tags, {
    type = "Benchmark"
  })
}

control "rds_db_instance_max_age" {
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
    class = "capacity_planning"
  })

  sql = <<-EOQ
    with rds_instance as (
      select
        arn,
        class,
        create_time,
        region,
        multi_az,
        storage_type,
        engine,
        account_id,
        title
      from
        aws_rds_db_instance
    ), rds_instance_pricing as (
      select
        r.arn,
        r.region,
        r.account_id,
        r.title,
        r.create_time,
        case
          when date_part('day', now()-create_time) > $1 then ((p.price_per_unit::numeric)*24*30)::numeric(10,2) || ' ' || currency || '/month'
          else ''
        end as net_savings
      from
        aws_pricing_product as p
        join rds_instance as r on
        p.service_code = 'AmazonRDS'
        and p.attributes ->> 'regionCode' = r.region
        and p.term = 'OnDemand'
        and p.attributes ->> 'instanceType' = r.class
        and p.attributes ->> 'usagetype'  like 'InstanceUsage:%'
        and replace(r.engine, '-', ' ') = lower(p.attributes ->>  'databaseEngine')
      group by r.region, p.price_per_unit, r.arn, r.account_id, r.title, r.create_time, p.currency
    )
    select
      arn as resource,
      case
        when date_part('day', now()-create_time) > $1 then 'alarm'
        when date_part('day', now()-create_time) > $2 then 'info'
        else 'ok'
      end as status,
      title || ' has been in use for ' || date_part('day', now()-create_time) || ' days.' as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      rds_instance_pricing;
  EOQ
}

control "rds_db_instance_class_prev_gen" {
  title       = "RDS instances should use the latest generation instance types"
  description = "M5 and T3 instance types are less costly than previous generations."
  severity    = "low"

  tags = merge(local.rds_common_tags, {
    class = "generation_gaps"
  })

  sql = <<-EOQ
    with rds_instance as (
      select
        class,
        region,
        multi_az,
        engine,
        case
          when class like '%.t2.%' then replace(class, 't2', 't3')
          when class like '%.m3.%' then replace(class, 'm3', 'm5')
          when class like '%.m4.%' then replace(class, 'm4', 'm5')
        end as next_gen_class
      from
        aws_rds_db_instance
    ), rds_instance_pricing as (
      select
        r.region,
        p.price_per_unit::numeric as rds_instance_price_per_hour_old_gen
      from
        aws_pricing_product as p
        join rds_instance as r on
        p.service_code = 'AmazonRDS'
        and p.attributes ->> 'regionCode' = r.region
        and p.term = 'OnDemand'
        and p.attributes ->> 'instanceType' = r.class
        and replace(r.engine, '-', ' ') = lower(p.attributes ->>  'databaseEngine')
      group by r.region, p.price_per_unit
    ), rds_instance_pricing_next_gen as (
        select
          r.region,
          p.currency,
          p.price_per_unit::numeric as rds_instance_price_per_hour_next_gen
        from
          aws_pricing_product as p
          join rds_instance as r on
          p.service_code = 'AmazonRDS'
          and p.attributes ->> 'regionCode' = r.region
          and p.term = 'OnDemand'
          and next_gen_class = p.attributes ->> 'instanceType'
          and replace(r.engine, '-', ' ') = lower(p.attributes ->> 'databaseEngine')
          and p.attributes ->> 'storage' = 'EBS Only'
        group by r.region, p.price_per_unit, p.currency
    ), rds_instance_pricing_monthly as (
      select
        case
          when class like '%.t2.%' or class like '%.m3.%' or class like '%.m4.%' then ((30*24*rds_instance_price_per_hour_old_gen) - (30*24*rds_instance_price_per_hour_next_gen))::numeric(10,2) || ' ' || currency || '/month'
          else ''
        end as net_savings,
        currency,
        i.arn as arn,
        i.tags as tags,
        i.account_id,
        i.region,
        i.title as title,
        i.class as class
      from
        aws_rds_db_instance as i,
        rds_instance_pricing_next_gen,
        rds_instance_pricing
    )
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
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      rds_instance_pricing_monthly;
  EOQ
}

control "rds_db_instance_low_connections" {
  title       = "RDS DB instances with a low number connections per day should be reviewed"
  description = "These databases have very little usage in last 30 days. Should this instance be shutdown when not in use?"
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
    ), rds_instance as (
      select
        region,
        class,
        engine,
        db_instance_identifier
      from
        aws_rds_db_instance
    ), rds_instance_pricing as (
      select
        r.db_instance_identifier,
        u.avg_max,
        u.days,
        case
          when u.avg_max is null or u.avg_max = 0 then ((p.price_per_unit::numeric)*24*30)::numeric(10,2) || ' ' || currency || '/month'
          else ''
        end as net_savings
      from
        rds_instance as r
        join rds_db_usage as u on u.db_instance_identifier = r.db_instance_identifier
        join aws_pricing_product as p on
        p.service_code = 'AmazonRDS'
        and p.attributes ->> 'regionCode' = r.region
        and p.term = 'OnDemand'
        and p.attributes ->> 'instanceType' = r.class
        and p.attributes ->> 'usagetype'  like 'InstanceUsage:%'
        and replace(r.engine, '-', ' ') = lower(p.attributes ->>  'databaseEngine')
      group by r.region, p.price_per_unit, r.db_instance_identifier, u.avg_max, u.days, p.currency
    )
    select
      i.arn as resource,
      case
        when avg_max is null then 'error'
        when avg_max = 0 then 'alarm'
        when avg_max < $1 then 'info'
        else 'ok'
      end as status,
      case
        when avg_max is null then 'CloudWatch metrics not available for ' || i.title || '.'
        when avg_max = 0 then title || ' has not been connected to in the last ' || days || ' days.'
        else i.title || ' is averaging ' || avg_max || ' max connections/day in the last ' || days || ' days.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_rds_db_instance as i
      left join rds_instance_pricing as u on u.db_instance_identifier = i.db_instance_identifier;
  EOQ
}

control "rds_db_instance_low_usage" {
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
    ), rds_instance as (
      select
        db_instance_identifier,
        arn,
        class,
        create_time,
        region,
        multi_az,
        storage_type,
        engine,
        account_id,
        title
      from
        aws_rds_db_instance
    ), rds_instance_pricing as (
      select
        r.arn,
        r.region,
        r.account_id,
        r.title,
        r.create_time,
        u.db_instance_identifier,
        u.avg_max,
        u.days,
        case
          when u.avg_max is null or u.avg_max <= $1 then ((p.price_per_unit::numeric)*24*30)::numeric(10,2) || ' ' || currency || '/month'
          else ''
        end as net_savings
      from
        rds_instance as r
        join rds_db_usage as u on u.db_instance_identifier = r.db_instance_identifier
        join aws_pricing_product as p on
        p.service_code = 'AmazonRDS'
        and p.attributes ->> 'regionCode' = r.region
        and p.term = 'OnDemand'
        and p.attributes ->> 'instanceType' = r.class
        and p.attributes ->> 'usagetype'  like 'InstanceUsage:%'
        and replace(r.engine, '-', ' ') = lower(p.attributes ->>  'databaseEngine')
      group by r.region, p.price_per_unit, r.arn, r.account_id, r.title, r.create_time, u.db_instance_identifier, u.avg_max, p.currency, u.days
    )
    select
      i.arn as resource,
      case
        when avg_max is null then 'error'
        when avg_max <= $1 then 'alarm'
        when avg_max <= $2 then 'info'
        else 'ok'
      end as status,
      case
        when avg_max is null then 'CloudWatch metrics not available for ' || i.title || '.'
        else i.title || ' is averaging ' || avg_max || '% max utilization over the last ' || days || ' days.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "i.")}
    from
      aws_rds_db_instance i
      left join rds_instance_pricing as u on u.db_instance_identifier = i.db_instance_identifier;
  EOQ
}
