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
    control.ecs_cluster_low_utilization,
    control.ecs_service_without_autoscaling
  ]

  tags = merge(local.ecs_common_tags, {
    type = "Benchmark"
  })
}

control "ecs_cluster_low_utilization" {
  title         = "ECS clusters with low CPU utilization should be reviewed"
  description   = "Resize or eliminate under utilized clusters."
  sql           = query.ecs_cluster_low_utilization.sql
  severity      = "low"

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
}

control "ecs_service_without_autoscaling" {
  title         = "ECS service should use autoscaling policy"
  description   = "ECS service should use autoscaling policy to improve service performance in a cost-efficient way."
  sql           = query.ecs_service_without_autoscaling.sql
  severity      = "low"

  tags = merge(local.ecs_common_tags, {
    class = "managed"
  })
}