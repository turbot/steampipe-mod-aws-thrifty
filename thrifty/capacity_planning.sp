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

variable "elasticache_running_cluster_age_max_days" {
  type        = number
  description = "The maximum number of days clusters are allowed to run."
  default     = 90
}

variable "elasticache_running_cluster_age_warning_days" {
  type        = number
  description = "The number of days clusters can be running before sending a warning."
  default     = 30
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

variable "redshift_running_cluster_age_max_days" {
  type        = number
  description = "The maximum number of days clusters are allowed to run."
  default     = 90
}

variable "redshift_running_cluster_age_warning_days" {
  type        = number
  description = "The number of days clusters can be running before sending a warning."
  default     = 30
}

benchmark "capacity_planning" {
  title         = "Capacity Planning"
  description   = "Thrifty developers ensure that long running resources are strategically planned. If you have long-running resources, it's a good idea to prepurchase reserved instances at lower cost. This can apply to long-running resources including EC2 instances, RDS instances, and Redshift clusters. You should also keep an eye on EC2 reserved instances that are scheduled for expiration, or have expired in the preceding 30 days, to verify that these cost-savers are in fact no longer needed."
  documentation = file("./thrifty/docs/capacity_planning.md")
  children = [  
    control.dynamodb_table_autoscaling_disabled,
    control.ebs_volume_low_iops,
    control.ec2_instance_running_max_age,
    control.ec2_reserved_instance_lease_expiration_days,
    control.ecs_service_without_autoscaling,
    control.elasticache_cluster_running_max_age,
    control.kinesis_stream_consumer_with_enhanced_fan_out,
    control.rds_db_instance_max_age,
    control.redshift_cluster_max_age,
    control.redshift_cluster_schedule_pause_resume_enabled,
    control.route53_record_higher_ttl
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

control "ebs_volume_low_iops" {
  title       = "EBS volumes with lower IOPS should be reviewed"
  description = "EBS volumes with less than 3k base IOPS performance should use GP3 instead of io1 and io2 volumes."
  sql         = query.ebs_volume_low_iops.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
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

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EC2"
  })
}

control "redshift_cluster_schedule_pause_resume_enabled" {
  title       = "Redshift clusters pause and resume feature should be enabled"
  description = "Redshift clusters should utilise the pause and resume actions to easily suspend on-demand billing while the cluster is not being used."
  sql         = query.redshift_cluster_schedule_pause_resume_enabled.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Redshift"
  })
}

control "kinesis_stream_consumer_with_enhanced_fan_out" {
  title       = "Kinesis stream consumers with the enhanced fan-out feature should be reviewed"
  description = "The enhanced fan-out feature should be avoided. Enhanced fan-out shard hours cost $36.00 (USD) per day."
  sql         = query.kinesis_stream_consumer_with_enhanced_fan_out.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Kinesis"
  })
}

control "route53_record_higher_ttl" {
  title       = "Route 53 records should have higher TTL configured"
  description = "If you configure a higher TTL for your records, the intermediate resolvers cache the records for longer time. As a result, there are fewer queries received by the name servers. This configuration reduces the charges corresponding to the DNS queries answered. A value between an hour (3600s) and a day (86,400s) is a common choice."
  sql         = query.route53_record_higher_ttl.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Route53"
  })
}

control "ecs_service_without_autoscaling" {
  title       = "ECS services should use auto scaling policy"
  description = "ECS services should use auto scaling policies to improve service performance in a cost-efficient way."
  sql         = query.ecs_service_without_autoscaling.sql
  severity    = "low"

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/ECS"
  })
}

control "dynamodb_table_autoscaling_disabled" {
  title       = "DynamoDB tables should have auto scaling enabled"
  description = "Amazon DynamoDB auto scaling uses the AWS Application Auto Scaling service to adjust provisioned throughput capacity that automatically responds to actual traffic patterns. Turning on the auto scaling feature will help to improve service performance in a cost-efficient way."
  sql         = query.dynamodb_table_autoscaling_disabled.sql
  severity    = "low"

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/DynamoDB"
  })
}

control "ec2_instance_running_max_age" {
  title       = "Long running EC2 instances should be reviewed"
  description = "Instances should ideally be ephemeral and rehydrated frequently, check why these instances have been running for so long. Long running instances should be replaced with reserved instances, which provide a significant discount."
  sql         = query.ec2_instance_running_max_age.sql
  severity    = "low"

  param "ec2_running_instance_age_max_days" {
    description = "The maximum number of days instances are allowed to run."
    default     = var.ec2_running_instance_age_max_days
  }

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EC2"
  })
}

control "elasticache_cluster_running_max_age" {
  title       = "Long running ElastiCache clusters should be reviewed"
  description = "Long running clusters should be reviewed and if they are needed they should be associated with reserved nodes, which provide a significant discount."
  sql         = query.elasticache_cluster_running_max_age.sql
  severity    = "low"

  param "elasticache_running_cluster_age_max_days" {
    description = "The maximum number of days clusters are allowed to run."
    default     = var.elasticache_running_cluster_age_max_days
  }

  param "elasticache_running_cluster_age_warning_days" {
    description = "The number of days clusters can be running before sending a warning."
    default     = var.elasticache_running_cluster_age_warning_days
  }

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/ElastiCache"
  })
}

control "rds_db_instance_max_age" {
  title       = "Long running RDS DB instances should have reserved instances purchased for them"
  description = "Long running RDS DB instances servers should be associated with a reserve instance."
  sql         = query.rds_db_instance_max_age.sql
  severity    = "low"

  param "rds_running_db_instance_age_max_days" {
    description = "The maximum number of days DB instances are allowed to run."
    default     = var.rds_running_db_instance_age_max_days
  }

  param "rds_running_db_instance_age_warning_days" {
    description = "The number of days DB instances can be running before sending a warning."
    default     = var.rds_running_db_instance_age_warning_days
  }

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/RDS"
  })
}

control "redshift_cluster_max_age" {
  title       = "Long running Redshift clusters should have reserved nodes purchased for them"
  description = "Long running clusters should be associated with reserved nodes, which provide a significant discount."
  sql         = query.redshift_cluster_max_age.sql
  severity    = "low"

  param "redshift_running_cluster_age_max_days" {
    description = "The maximum number of days clusters are allowed to run."
    default     = var.redshift_running_cluster_age_max_days
  }

  param "redshift_running_cluster_age_warning_days" {
    description = "The number of days clusters can be running before sending a warning."
    default     = var.redshift_running_cluster_age_warning_days
  }

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Redshift"
  })
}