variable "ec2_instance_allowed_types" {
  type        = list(string)
  description = "A list of allowed instance types. PostgreSQL wildcards are supported."
  default     = ["%.nano", "%.micro", "%.small", "%.medium", "%.large", "%.xlarge", "%._xlarge"]
}

variable "ec2_instance_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for instances to be considered frequently used. This value should be higher than ec2_instance_avg_cpu_utilization_low."
  default     = 35
}

variable "ec2_instance_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for instances to be considered infrequently used. This value should be lower than ec2_instance_avg_cpu_utilization_high."
  default     = 20
}

variable "ec2_reserved_instance_expiration_warning_days" {
  type        = number
  description = "The number of days reserved instances can be running before sending a warning."
  default     = 30
}

variable "ec2_running_instance_age_max_days" {
  type        = number
  description = "The maximum number of days instances are allowed to run."
  default     = 90
}

locals {
  ec2_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EC2"
  })
}

benchmark "ec2" {
  title         = "EC2 Checks"
  description   = "Thrifty developers eliminate unused and under-utilized EC2 instances."
  documentation = file("./controls/docs/ec2.md")
  children = [
    control.ec2_application_lb_unused,
    control.ec2_classic_lb_unused,
    control.ec2_gateway_lb_unused,
    control.ec2_instance_older_generation,
    control.ec2_network_lb_unused,
    control.ec2_reserved_instance_lease_expiration_days,
    control.instances_with_low_utilization,
    control.large_ec2_instances,
    control.long_running_ec2_instances
  ]

  tags = merge(local.ec2_common_tags, {
    type = "Benchmark"
  })
}

control "ec2_application_lb_unused" {
  title       = "Application load balancers having no targets attached should be deleted"
  description = "Application load balancers with no targets attached still cost money and should be deleted."
  severity    = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with alb_regions as (
      select
        distinct a.region
      from
        aws_ec2_application_load_balancer as a
    ),application_load_balancer_pricing as (
      select
        r.region,
        p.price_per_unit::numeric as alb_price_hrs,
        p.currency as currency
      from
        aws_pricing_product as p
        join alb_regions as r on
          p.service_code = 'AmazonEC2'
          and p.filters = '{
            "operation": "LoadBalancing:Application",
            "usagetype": "LoadBalancerUsage"
          }' :: jsonb
          and p.attributes ->> 'regionCode' = r.region
      group by r.region, p.price_per_unit, p.currency
    ) ,
    target_resource as (
      select
        load_balancer_arn,
        target_health_descriptions,
        target_type
      from
        aws_ec2_target_group,
        jsonb_array_elements_text(load_balancer_arns) as load_balancer_arn
    ), application_load_balancer_pricing_monthly as (
      select
        case when b.load_balancer_arn is null then 30*24*alb_price_hrs  else 0.0 end as net_savings,
        currency,
        a.arn as alb,
        b.load_balancer_arn as target_lb,
        b.target_type as target_type,
        a.tags as tags,
        a.account_id,
        a.region,
        a.title as title
      from
        aws_ec2_application_load_balancer a
        left join target_resource b on a.arn = b.load_balancer_arn,
        application_load_balancer_pricing
    )
    select
      distinct alb as resource,
      case
        when target_lb is null then 'alarm'
        else 'ok'
      end as status,
      case
        when target_lb is null then title || ' has no target registered.'
        else title || ' has registered target of type ' || target_type || '.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      application_load_balancer_pricing_monthly
  EOQ
}

control "ec2_classic_lb_unused" {
  title       = "Classic load balancers having no instances attached should be deleted"
  description = "Classic load balancers with no instances attached still cost money should be deleted."
  severity    = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with clb_regions as (
      select
        distinct region
      from
        aws_ec2_classic_load_balancer
    ),clb_pricing as (
      select
        r.region,
        p.currency,
        p.price_per_unit::numeric as clb_price_hrs
      from
        aws_pricing_product as p
        join clb_regions as r on
          p.service_code = 'AWSELB'
          and p.filters = '{
            "groupDescription" : "LoadBalancer hourly usage by Classic Load Balancer",
            "group": "ELB:Balancing"
          }' :: jsonb
          and p.attributes ->> 'regionCode' = r.region
      group by r.region, p.price_per_unit, p.currency
    ), clb_pricing_daily as (
      select
        case when jsonb_array_length(instances) > 0 then 0.0 else 30*24*clb_price_hrs end as net_savings,
        currency,
        arn,
        tags,
        account_id,
        a.region,
        instances,
        title
      from
        aws_ec2_classic_load_balancer as a,
        clb_pricing
    )
    select
      arn as resource,
      case
        when jsonb_array_length(instances) > 0 then 'ok'
        else 'alarm'
      end as status,
      case
        when jsonb_array_length(instances) > 0 then title || ' has registered instances.'
        else title || ' has no instances registered.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      clb_pricing_daily;
  EOQ
}

control "ec2_gateway_lb_unused" {
  title       = "Gateway load balancers having no targets attached should be deleted"
  description = "Gateway load balancers with no targets attached still cost money and should be deleted."
  severity    = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with glb_regions as (
      select
        distinct region
      from
        aws_ec2_gateway_load_balancer
    ),glb_pricing as (
      select
        r.region,
        p.currency,
        p.price_per_unit::numeric as clb_price_hrs
      from
        aws_pricing_product as p
        join glb_regions as r on
          p.service_code = 'AWSELB'
          and p.filters = '{
            "operation" : "LoadBalancing:Gateway",
            "group": "ELB:Balancing",
            "groupDescription" : "LoadBalancer hourly usage by Gateway Load Balancer"
          }' :: jsonb
          and p.attributes ->> 'regionCode' = r.region
      group by r.region, p.price_per_unit, p.currency
    ), target_resource as (
      select
        load_balancer_arn,
        target_health_descriptions,
        target_type
      from
        aws_ec2_target_group,
        jsonb_array_elements_text(load_balancer_arns) as load_balancer_arn
    ), glb_pricing_monthly as (
      select
        case when jsonb_array_length(b.target_health_descriptions) = 0 then 30*24*clb_price_hrs  else 0.0 end as net_savings,
        currency,
        g.arn as arn,
        b.load_balancer_arn as target_lb,
        b.target_health_descriptions as target_health_descriptions,
        b.target_type as target_type,
        g.tags as tags,
        g.account_id,
        g.region,
        g.title as title
      from
        aws_ec2_gateway_load_balancer as g
        left join target_resource b on g.arn = b.load_balancer_arn,
        glb_pricing
    )
    select
      arn as resource,
      target_type,
      case
        when jsonb_array_length(target_health_descriptions) = 0 then 'alarm'
        else 'ok'
      end as status,
      case
        when jsonb_array_length(target_health_descriptions) = 0 then title || ' has no target registered.'
        else title || ' has registered target.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      glb_pricing_monthly;
  EOQ

}

control "ec2_network_lb_unused" {
  title       = "Network load balancers having no targets attached should be deleted"
  description = "Network load balancers with no targets attached still cost money and should be deleted."
  severity    = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with network_regions as (
      select
        distinct region
      from
        aws_ec2_network_load_balancer
    ),network_load_balancer_pricing as (
      select
        r.region,
        p.price_per_unit::numeric as alb_price_hrs,
         p.currency as currency
      from
        aws_pricing_product as p
        join network_regions as r on
          p.service_code = 'AmazonEC2'
          and p.filters = '{
            "operation": "LoadBalancing:Network",
            "usagetype": "LoadBalancerUsage"
          }' :: jsonb
          and p.attributes ->> 'regionCode' = r.region
      group by r.region, p.price_per_unit, p.currency
    ),target_resource as (
      select
        load_balancer_arn,
        target_health_descriptions,
        target_type
      from
        aws_ec2_target_group,
        jsonb_array_elements_text(load_balancer_arns) as load_balancer_arn
    ),network_load_balancer_pricing_monthly as (
      select
        case when jsonb_array_length(b.target_health_descriptions) = 0  then 24*alb_price_hrs else 0.0 end as net_savings,
        currency,
        a.arn as arn,
        b.load_balancer_arn as target_lb,
        b.target_health_descriptions as target_health_descriptions,
        b.target_type as target_type,
        a.tags as tags,
        a.account_id,
        a.region,
        a.title as title
      from
        aws_ec2_network_load_balancer a
        left join target_resource b on a.arn = b.load_balancer_arn,
        network_load_balancer_pricing
    )
    select
      arn as resource,
      case
        when jsonb_array_length(target_health_descriptions) = 0 then 'alarm'
        else 'ok'
      end as status,
      case
        when jsonb_array_length(target_health_descriptions) = 0 then title || ' has no target registered.'
        else title || ' has registered target.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      network_load_balancer_pricing_monthly
  EOQ
}

control "large_ec2_instances" {
  title       = "Large EC2 instances should be reviewed"
  description = "Large EC2 instances are unusual, expensive and should be reviewed."
  severity    = "low"

  param "ec2_instance_allowed_types" {
    description = "A list of allowed instance types. PostgreSQL wildcards are supported."
    default     = var.ec2_instance_allowed_types
  }

  tags = merge(local.ec2_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when instance_state not in ('running', 'pending', 'rebooting') then 'info'
        when instance_type like any ($1) then 'ok'
        else 'alarm'
      end as status,
      title || ' has type ' || instance_type || ' and is ' || instance_state || '.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ec2_instance;
  EOQ
}

control "long_running_ec2_instances" {
  title       = "Long running EC2 instances should be reviewed"
  description = "Instances should ideally be ephemeral and rehydrated frequently, check why these instances have been running for so long."
  severity    = "low"

  param "ec2_running_instance_age_max_days" {
    description = "The maximum number of days instances are allowed to run."
    default     = var.ec2_running_instance_age_max_days
  }

  tags = merge(local.ec2_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when date_part('day', now()-launch_time) > $1 then 'alarm'
        else 'ok'
      end as status,
      title || ' has been running ' || date_part('day', now()-launch_time) || ' days.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ec2_instance
    where
      -- Instance is running
      instance_state in ('running', 'pending', 'rebooting');
  EOQ
}

control "instances_with_low_utilization" {
  title       = "Which EC2 instances have very low CPU utilization?"
  description = "Resize or eliminate under utilized instances."
  severity    = "low"

  param "ec2_instance_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for instances to be considered infrequently used. This value should be lower than ec2_instance_avg_cpu_utilization_high."
    default     = var.ec2_instance_avg_cpu_utilization_low
  }

  param "ec2_instance_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for instances to be considered frequently used. This value should be higher than ec2_instance_avg_cpu_utilization_low."
    default     = var.ec2_instance_avg_cpu_utilization_high
  }

  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with ec2_instance_utilization as (
      select
        instance_id,
        max(average) as avg_max,
        count(average) days
      from
        aws_ec2_instance_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        instance_id
    )
    select
      arn as resource,
      case
        when avg_max is null then 'error'
        when avg_max < $1 then 'alarm'
        when avg_max < $2 then 'info'
        else 'ok'
      end as status,
      case
        when avg_max is null then 'CloudWatch metrics not available for ' || title || '.'
        else title || ' is averaging ' || avg_max || '% max utilization over the last ' || days || ' days.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ec2_instance i
      left join ec2_instance_utilization as u on u.instance_id = i.instance_id;
  EOQ
}

control "ec2_reserved_instance_lease_expiration_days" {
  title       = "EC2 reserved instances scheduled for expiration should be reviewed"
  description = "EC2 reserved instances that are scheduled for expiration or have expired in the preceding 30 days should be reviewed."
  severity    = "low"

  param "ec2_reserved_instance_expiration_warning_days" {
    description = "The number of days reserved instances can be running before sending a warning."
    default     = var.ec2_reserved_instance_expiration_warning_days
  }

  tags = merge(local.ec2_common_tags, {
    class = "managed"
  })

  sql = <<-EOQ
    select
      reserved_instance_id as resource,
      case
        when date_part('day', end_time - now()) <= $1 then 'alarm'
        else 'ok'
      end as status,
      title || ' lease expires in ' || date_part('day', end_time-now()) || ' days.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ec2_reserved_instance;
  EOQ
}

control "ec2_instance_older_generation" {
  title       = "EC2 instances should not use older generation t2, m3, and m4 instance types"
  description = "EC2 instances should not use older generation t2, m3, and m4 instance types as t3 and m5 are more cost effective."
  severity    = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when instance_type like 't2.%' or instance_type like 'm3.%' or instance_type like 'm4.%' then 'alarm'
        else 'ok'
      end as status,
      title || ' has used ' || instance_type || '.' as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_ec2_instance;
  EOQ
}
