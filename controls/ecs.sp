variable "ecs_cluster_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than ecs_cluster_avg_cpu_utilization_low."
  default     = 35
}

variable "ecs_cluster_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than ecs_cluster_avg_cpu_utilization_high."
  default     = 20
}

locals {
  ecs_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/ECS"
  })
}

benchmark "ecs" {
  title         = "ECS Checks"
  description   = "Thrifty developers checks under-utilized ECS clusters and ECS service without autoscaling configuration."
  documentation = file("./controls/docs/ecs.md")
  children = [
    control.ecs_cluster_container_instance_with_graviton,
    control.ecs_cluster_low_utilization,
    control.ecs_service_without_autoscaling
  ]

  tags = merge(local.ecs_common_tags, {
    type = "Benchmark"
  })
}

control "ecs_cluster_container_instance_with_graviton" {
  title       = "ECS cluster container instances without graviton processor should be reviewed"
  description = "With graviton processor (arm64 - 64-bit ARM architecture), you can save money in two ways. First, your functions run more efficiently due to the Graviton architecture. Second, you pay less for the time that they run. In fact, Lambda functions powered by Graviton are designed to deliver up to 19 percent better performance at 20 percent lower cost."
  severity    = "low"

  tags = merge(local.ecs_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    select
      c.arn as resource,
      case
        when i.platform = 'windows' then 'skip'
        when i.architecture = 'arm64' then 'ok'
        else 'alarm'
      end as status,
      case
        when i.platform = 'windows' then i.title || ' is windows type machine.'
        when i.architecture = 'arm64' then i.title || ' is using Graviton processor.'
        else i.title || ' is not using Graviton processor.'
      end as reason
      ${replace(local.tag_dimensions_qualifier_sql, "__QUALIFIER__", "c.")}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "c.")}
    from
      aws_ecs_container_instance as c
      left join aws_ec2_instance as i on c.ec2_instance_id = i.instance_id;
  EOQ
}

control "ecs_cluster_low_utilization" {
  title       = "ECS clusters with low CPU utilization should be reviewed"
  description = "Resize or eliminate under utilized clusters."
  severity    = "low"

  param "ecs_cluster_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than ecs_cluster_avg_cpu_utilization_high."
    default     = var.ecs_cluster_avg_cpu_utilization_low
  }

  param "ecs_cluster_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than ecs_cluster_avg_cpu_utilization_low."
    default     = var.ecs_cluster_avg_cpu_utilization_high
  }

  tags = merge(local.ecs_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with ecs_cluster_utilization as (
    select
      cluster_name,
      round(cast(sum(maximum)/count(maximum) as numeric), 1) as avg_max,
      count(maximum) days
    from
      aws_ecs_cluster_metric_cpu_utilization_daily
    where
      date_part('day', now() - timestamp) <= 30
    group by
      cluster_name
  )
  select
    i.cluster_name as resource,
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
    aws_ecs_cluster as i
    left join ecs_cluster_utilization as u on u.cluster_name = i.cluster_name;
  EOQ
}

control "ecs_service_without_autoscaling" {
  title       = "ECS service should use autoscaling policy"
  description = "ECS service should use autoscaling policy to improve service performance in a cost-efficient way."
  severity    = "low"

  tags = merge(local.ecs_common_tags, {
    class = "managed"
  })

  sql = <<-EOQ
    with service_with_autoscaling as (
      select
        distinct split_part(t.resource_id, '/', 2) as cluster_name,
        split_part(t.resource_id, '/', 3) as service_name
      from
        aws_appautoscaling_target as t
      where
        t.service_namespace = 'ecs'
    )
    select
      s.arn as resource,
      case
        when s.launch_type != 'FARGATE' then 'skip'
        when a.service_name is null then 'alarm'
        else 'ok'
      end as status,
      case
        when s.launch_type != 'FARGATE' then s.title || ' task not running on FARGATE.'
        when a.service_name is null then s.title || ' autoscaling disabled.'
        else s.title || ' autoscaling enabled.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "s.")}
    from
      aws_ecs_service as s
      left join service_with_autoscaling as a on s.service_name = a.service_name and a.cluster_name = split_part(s.cluster_arn, '/', 2);
  EOQ
}
