variable "ebs_volume_avg_read_write_ops_high" {
  type        = number
  description = "The number of average read/write ops required for volumes to be considered frequently used. This value should be higher than ebs_volume_avg_read_write_ops_low."
  default     = 500
}

variable "ebs_volume_avg_read_write_ops_low" {
  type        = number
  description = "The number of average read/write ops required for volumes to be considered infrequently used. This value should be lower than ebs_volume_avg_read_write_ops_high."
  default     = 100
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

variable "redshift_cluster_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than redshift_cluster_avg_cpu_utilization_low."
  default     = 35
}

variable "redshift_cluster_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than redshift_cluster_avg_cpu_utilization_high."
  default     = 20
}

variable "elasticache_redis_cluster_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than elasticache_redis_cluster_avg_cpu_utilization_low."
  default     = 35
}

variable "elasticache_redis_cluster_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than elasticache_redis_cluster_avg_cpu_utilization_high."
  default     = 20
}

locals {
  underused_common_tags = merge(local.aws_thrifty_common_tags, {
    underused = "true"
  })
}

benchmark "underused" {
  title         = "Underused"
  description   = "Thrifty developers check underused AWS resources. Large EC2 (or RDS, Redshift, ECS, etc) instances may have been created and sized to handle peak utilization but never reviewed later to see how well the storage, compute, and/or memory is being utilized. Consider rightsizing the instance type if an application is overprovisioned in any of these ways. AWS has different pricing for resources that are compute-optimized or memory-optimized. Analyze your inventory and utilization metrics to find underused resources, and prune them as warranted."
  documentation = file("./thrifty/docs/underused.md")
  children = [
    control.ebs_volume_low_usage,
    control.ec2_instance_avg_cpu_utilization_low,
    control.ecs_cluster_low_utilization,
    control.elasticache_redis_cluster_low_utilization,
    control.rds_db_instance_low_connections,
    control.rds_db_instance_low_usage,
    control.redshift_cluster_low_utilization

  ]

  tags = merge(local.underused_common_tags, {
    type = "Benchmark"
  })
}

control "ebs_volume_low_usage" {
  title       = "EBS volumes with low usage should be reviewed"
  description = "Volumes that are underused should be archived and deleted"
  sql         = query.ebs_volume_low_usage.sql
  severity    = "low"

  param "ebs_volume_avg_read_write_ops_low" {
    description = "The number of average read/write ops required for volumes to be considered infrequently used. This value should be lower than ebs_volume_avg_read_write_ops_high."
    default     = var.ebs_volume_avg_read_write_ops_low
  }

  param "ebs_volume_avg_read_write_ops_high" {
    description = "The number of average read/write ops required for volumes to be considered frequently used. This value should be higher than ebs_volume_avg_read_write_ops_low."
    default     = var.ebs_volume_avg_read_write_ops_high
  }

  tags = merge(local.underused_common_tags, {
    service = "AWS/EBS"
  })
}

control "ec2_instance_avg_cpu_utilization_low" {
  title       = "EC2 instances with very low CPU utilization should be reviewed"
  description = "Resize or eliminate under utilized instances."
  sql         = query.ec2_instance_avg_cpu_utilization_low.sql
  severity    = "low"

  param "ec2_instance_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for instances to be considered infrequently used. This value should be lower than ec2_instance_avg_cpu_utilization_high."
    default     = var.ec2_instance_avg_cpu_utilization_low
  }

  param "ec2_instance_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for instances to be considered frequently used. This value should be higher than ec2_instance_avg_cpu_utilization_low."
    default     = var.ec2_instance_avg_cpu_utilization_high
  }

  tags = merge(local.underused_common_tags, {
    service = "AWS/EC2"
  })
}

control "ecs_cluster_low_utilization" {
  title       = "ECS clusters with low CPU utilization should be reviewed"
  description = "Resize or eliminate under utilized clusters."
  sql         = query.ecs_cluster_low_utilization.sql
  severity    = "low"

  param "ecs_cluster_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than ecs_cluster_avg_cpu_utilization_high."
    default     = var.ecs_cluster_avg_cpu_utilization_low
  }

  param "ecs_cluster_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than ecs_cluster_avg_cpu_utilization_low."
    default     = var.ecs_cluster_avg_cpu_utilization_high
  }

  tags = merge(local.underused_common_tags, {
    service = "AWS/ECS"
  })
}

control "elasticache_redis_cluster_low_utilization" {
  title       = "Elasticache Redis clusters with low CPU utilization should be reviewed"
  description = "Resize or eliminate under utilized clusters."
  sql         = query.elasticache_redis_cluster_low_utilization.sql
  severity    = "low"

  param "elasticache_redis_cluster_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than elasticache_redis_cluster_avg_cpu_utilization_high."
    default     = var.elasticache_redis_cluster_avg_cpu_utilization_low
  }

  param "elasticache_redis_cluster_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than elasticache_redis_cluster_avg_cpu_utilization_low."
    default     = var.elasticache_redis_cluster_avg_cpu_utilization_high
  }

  tags = merge(local.underused_common_tags, {
    service = "AWS/ElastiCache"
  })
}

control "rds_db_instance_low_connections" {
  title       = "RDS DB instances with a low number connections per day should be reviewed"
  description = "These databases have very little usage in last 30 days. Should this instance be shutdown when not in use?"
  sql         = query.rds_db_instance_low_connections.sql
  severity    = "high"

  param "rds_db_instance_avg_connections" {
    description = "The minimum number of average connections per day required for DB instances to be considered in-use."
    default     = var.rds_db_instance_avg_connections
  }

  tags = merge(local.underused_common_tags, {
    service = "AWS/RDS"
  })
}

control "rds_db_instance_low_usage" {
  title       = "RDS DB instance having low CPU utilization should be reviewed"
  description = "These databases may be oversized for their usage."
  sql         = query.rds_db_instance_low_usage.sql
  severity    = "low"

  param "rds_db_instance_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for DB instances to be considered infrequently used. This value should be lower than rds_db_instance_avg_cpu_utilization_high."
    default     = var.rds_db_instance_avg_cpu_utilization_low
  }

  param "rds_db_instance_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for DB instances to be considered frequently used. This value should be higher than rds_db_instance_avg_cpu_utilization_low."
    default     = var.rds_db_instance_avg_cpu_utilization_high
  }

  tags = merge(local.underused_common_tags, {
    service = "AWS/RDS"
  })
}

control "redshift_cluster_low_utilization" {
  title       = "Redshift clusters with low CPU utilization should be reviewed"
  description = "Resize or eliminate under utilized clusters."
  sql         = query.redshift_cluster_low_utilization.sql
  severity    = "low"

  param "redshift_cluster_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than redshift_cluster_avg_cpu_utilization_high."
    default     = var.redshift_cluster_avg_cpu_utilization_low
  }

  param "redshift_cluster_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than redshift_cluster_avg_cpu_utilization_low."
    default     = var.redshift_cluster_avg_cpu_utilization_high
  }

  tags = merge(local.underused_common_tags, {
    service = "AWS/Redshift"
  })
}

