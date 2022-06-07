variable "ec2_reserved_instance_expiration_warning_days" {
  type        = number
  description = "The number of days reserved instances can be running before sending a warning."
  default     = 30
}

variable "kinesis_stream_high_retention_period_days" {
  type        = number
  description = "The number of days for the data retention period to be considered as Maximum."
  default     = 1
}

locals {
  capacity_planning_common_tags = merge(local.aws_thrifty_common_tags, {
    capacity_planning = "true"
  })
}

benchmark "capacity_planning" {
  title         = "Capacity Planning"
  description   = "."
  documentation = file("./thrifty/docs/capacity_planning.md")
  children = [
    control.cloudwatch_log_group_no_retention,
    control.ebs_volume_low_iops,
    control.ec2_reserved_instance_lease_expiration_days,
    control.ecs_service_without_autoscaling,
    control.redshift_cluster_schedule_pause_resume_enabled,
    control.route53_record_higher_ttl,
    control.kinesis_stream_consumer_with_enhanced_fan_out,
    control.kinesis_stream_high_retention_period,

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

control "kinesis_stream_consumer_with_enhanced_fan_out" {
  title       = "Kinesis stream consumer with the enhanced_fan-out feature should be reviewed"
  description = "The enhanced_fan-out feature should be avoided. Enhanced fan-out shard hours cost $36.00 (USD) per day."
  sql         = query.kinesis_stream_consumer_with_enhanced_fan_out.sql
  severity    = "low"
  tags = merge(local.capacity_planning_common_tags, {
    service = "AWS/Kinesis"
  })
}

control "kinesis_stream_high_retention_period" {
  title       = "Kinesis stream high retention period should be reviewed"
  description = "Data retention period should not be high. Additional charges apply for data streams with a retention period over 24 hours."
  sql         = query.kinesis_stream_high_retention_period.sql
  severity    = "low"

  param "kinesis_stream_high_retention_period_days" {
    description = "The number of days for the data retention period to be considered as high."
    default     = var.kinesis_stream_high_retention_period_days
  }

  tags = merge(local.capacity_planning_common_tags, {
    service = "AWS/Kinesis"
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
