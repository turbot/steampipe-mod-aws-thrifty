variable "ec2_reserved_instance_expiration_warning_days" {
  type        = number
  description = "The number of days reserved instances can be running before sending a warning."
  default     = 30
}

locals {
  capacity_planning_common_tags = merge(local.aws_thrifty_common_tags, {
    capacity_planning = "true"
  })
}

benchmark "capacity_planning" {
  title         = "Capacity Planning"
  description   = "Thrifty developers ensure that long running resources are strategically planned. If you have long-running resources, it's a good idea to prepurchase reserved instances at lower cost. This can apply to long-running resources including EC2 instances, RDS instances, and Redshift clusters. You should also keep an eye on EC2 reserved instances that are scheduled for expiration, or have expired in the preceding 30 days, to verify that these cost-savers are in fact no longer needed."
  documentation = file("./thrifty/docs/capacity_planning.md")
  children = [
    control.cloudwatch_log_group_no_retention,
    control.dynamodb_table_autoscaling_disabled,
    control.ebs_volume_low_iops,
    control.ec2_reserved_instance_lease_expiration_days,
    control.ecs_service_without_autoscaling,
    control.redshift_cluster_schedule_pause_resume_enabled,
    control.route53_record_higher_ttl
  ]

  tags = merge(local.capacity_planning_common_tags, {
    type = "Benchmark"
  })
}

control "cloudwatch_log_group_no_retention" {
  title       = "CloudWatch Log Groups retention should be enabled"
  description = "All log groups should have a defined retention configuration."
  sql         = query.cloudwatch_log_group_no_retention.sql
  severity    = "low"

  tags = merge(local.capacity_planning_common_tags, {
    service = "AWS/CloudWatch"
  })
}

control "ebs_volume_low_iops" {
  title       = "What provisioned IOPS volumes would be better as GP3?"
  description = "GP3 provides 3k base IOPS performance, don't use more costly io1 & io2 volumes."
  sql         = query.ebs_volume_low_iops.sql
  severity    = "low"
  tags = merge(local.capacity_planning_common_tags, {
    service = "AWS/EBS"
  })
}


control "ec2_reserved_instance_lease_expiration_days" {
  title       = "EC2 reserved instances scheduled for expiration should be reviewed"
  description = "EC2 reserved instances that are scheduled for expiration or have expired in the preceding 30 days should be reviewed."
  sql         = query.ec2_reserved_instance_lease_expiration_days.sql
  severity    = "low"

  param "ec2_reserved_instance_expiration_warning_days" {
    description = "The number of days reserved instances can be running before sending a warning."
    default     = var.ec2_reserved_instance_expiration_warning_days
  }

  tags = merge(local.capacity_planning_common_tags, {
    service = "AWS/EC2"
  })
}

control "redshift_cluster_schedule_pause_resume_enabled" {
  title       = "Redshift cluster paused resume should be enabled"
  description = "Redshift cluster paused resume should be enabled to easily suspend on-demand billing while the cluster is not being used."
  sql         = query.redshift_cluster_schedule_pause_resume_enabled.sql
  severity    = "low"
  tags = merge(local.capacity_planning_common_tags, {
    service = "AWS/Redshift"
  })
}

control "route53_record_higher_ttl" {
  title       = "Higher TTL should be configured"
  description = "If you configure a higher TTL for your records, the intermediate resolvers cache the records for longer time. As a result, there are fewer queries received by the name servers. This configuration reduces the charges corresponding to the DNS queries answered. A value between an hour (3600s) and a day (86,400s) is a common choice."
  sql         = query.route53_record_higher_ttl.sql
  severity    = "low"
  tags = merge(local.capacity_planning_common_tags, {
    service = "AWS/Route53"
  })
}

control "ecs_service_without_autoscaling" {
  title       = "ECS service should use autoscaling policy"
  description = "ECS service should use autoscaling policy to improve service performance in a cost-efficient way."
  sql         = query.ecs_service_without_autoscaling.sql
  severity    = "low"

  tags = merge(local.capacity_planning_common_tags, {
    service = "AWS/ECS"
  })
}

control "dynamodb_table_autoscaling_disabled" {
  title       = "DynamoDB tables should have auto scaling enabled"
  description = "Amazon DynamoDB auto scaling uses the AWS Application Auto Scaling service to adjust provisioned throughput capacity that automatically responds to actual traffic patterns. Turning on the auto scaling feature will help to improve service performance in a cost-efficient way."
  sql         = query.dynamodb_table_autoscaling_disabled.sql
  severity    = "low"

  tags = merge(local.capacity_planning_common_tags, {
    service = "AWS/DynamoDB"
  })
}
