locals {
  ecs_common_tags = merge(local.thrifty_common_tags, {
    service = "ecs"
  })
}

benchmark "ecs" {
  title         = "ECS Checks"
  description   = "Thrifty developers checks under-utilized ECS clusters and ECS service without autoscaling configuration."
  documentation = file("./controls/docs/ecs.md")
  tags          = local.ecs_common_tags
  children = [
    control.ecs_cluster_low_utilization,
    control.ecs_service_without_autoscaling
  ]
}

control "ecs_cluster_low_utilization" {
  title         = "ECS clusters with low CPU utilization should be reviewed"
  description   = "Resize or eliminate under utilized clusters."
  sql           = query.ecs_cluster_low_utilization.sql
  severity      = "low"

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