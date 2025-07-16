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
  title         = "ECS Cost Checks"
  description   = "Thrifty developers checks under-utilized ECS clusters and ECS service without autoscaling configuration."
  documentation = file("./controls/docs/ecs.md")
  children = [
    control.ecs_cluster_container_instance_without_graviton,
    control.ecs_cluster_low_utilization,
    control.ecs_service_autoscaling_disabled
  ]

  tags = merge(local.ecs_common_tags, {
    type = "Benchmark"
  })
}

control "ecs_cluster_container_instance_without_graviton" {
  title       = "ECS cluster container instances without graviton processor should be reviewed"
  description = "ECS cluster container instances running on x86_64 architecture may incur higher costs and lower performance compared to those using Graviton (arm64) processors. Review and migrate eligible container instances to Graviton to benefit from improved performance and reduced costs, as recommended by AWS best practices."
  severity    = "low"

  tags = merge(local.ecs_common_tags, {
    class = "generation_gaps"
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
        when i.architecture = 'arm64' then i.title || ' is using graviton processor.'
        else i.title || ' is not using graviton processor.'
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
  description = "ECS clusters with consistently low CPU utilization may be over-provisioned or underused, resulting in unnecessary costs. Review clusters with low utilization and consider resizing, pausing, or terminating them to optimize resource usage and reduce expenses."
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

control "ecs_service_autoscaling_disabled" {
  title       = "ECS services autoscaling should be enabled"
  description = "ECS services without autoscaling enabled may not scale efficiently to meet demand, leading to performance issues or unnecessary costs. Enable autoscaling for ECS services to automatically adjust capacity based on actual usage, optimizing both performance and cost."
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
