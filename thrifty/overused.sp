variable "ebs_volume_max_iops" {
  type        = number
  description = "The maximum IOPS allowed for volumes."
  default     = 32000
}

variable "ebs_volume_max_size_gb" {
  type        = number
  description = "The maximum size (GB) allowed for volumes."
  default     = 100
}

variable "ec2_running_instance_age_max_days" {
  type        = number
  description = "The maximum number of days instances are allowed to run."
  default     = 90
}

variable "ec2_instance_allowed_types" {
  type        = list(string)
  description = "A list of allowed instance types. PostgreSQL wildcards are supported."
  default     = ["%.nano", "%.micro", "%.small", "%.medium", "%.large", "%.xlarge", "%._xlarge"]
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

locals {
  overused_common_tags = merge(local.aws_thrifty_common_tags, {
    overused = "true"
  })
}

benchmark "overused" {
  title         = "Overused"
  description   = "Thrifty developers check overused AWS resources. AWS resources can be overused in a few different ways. When you have long-running resources, consider if they can be stopped intermittently. In non-production environments, for example, it can make sense to spin up resources when needed, or only during working hours."
  documentation = file("./thrifty/docs/overused.md")
  children = [
    control.cloudfront_distribution_pricing_class,
    control.cloudtrail_trail_global_multiple,
    control.cloudtrail_trail_regional_multiple,
    control.ebs_volume_large,
    control.ebs_volume_high_iops,
    control.ec2_instances_large,
    control.ec2_instance_running_max_age,
    control.elasticache_cluster_running_max_age,
    control.lambda_function_high_error_rate,
    control.lambda_function_excessive_timeout,
    control.rds_db_instance_age_90,
    control.redshift_cluster_max_age

  ]

  tags = merge(local.overused_common_tags, {
    type = "Benchmark"
  })
}

control "cloudfront_distribution_pricing_class" {
  title       = "CloudFront distribution pricing class should be reviewed"
  description = "CloudFront distribution pricing class should be reviewed. Price Classes let you reduce your delivery prices by excluding Amazon CloudFront’s more expensive edge locations from your Amazon CloudFront distribution."
  sql         = query.cloudfront_distribution_pricing_class.sql
  severity    = "low"

  tags = merge(local.overused_common_tags, {
    service = "AWS/CloudFront"
  })
}

control "cloudtrail_trail_global_multiple" {
  title       = "Redundant global CloudTrail trails should be reviewed"
  description = "Your first cloudtrail in each account is free, additional trails are expensive."
  sql         = query.cloudtrail_trail_global_multiple.sql
  severity    = "low"

  tags = merge(local.overused_common_tags, {
    service = "AWS/CloudTrail"
  })
}

control "cloudtrail_trail_regional_multiple" {
  title       = "ARedundant regional CloudTrail trails should be reviewed"
  description = "Your first cloudtrail in each region is free, additional trails are expensive."
  sql         = query.cloudtrail_trail_regional_multiple.sql
  severity    = "low"

  tags = merge(local.overused_common_tags, {
    service = "AWS/CloudTrail"
  })
}

control "ebs_volume_large" {
  title       = "EBS volumes should be resized if too large"
  description = "Large EBS volumes are unusual, high cost and usage should be reviewed."
  sql         = query.ebs_volume_large.sql
  severity    = "low"

  param "ebs_volume_max_size_gb" {
    description = "The maximum size (GB) allowed for volumes."
    default     = var.ebs_volume_max_size_gb
  }

  tags = merge(local.overused_common_tags, {
    service = "AWS/EBS"
  })
}

control "ebs_volume_high_iops" {
  title       = "EBS volumes with high IOPS should be resized if too large"
  description = "High IOPS io1 and io2 volumes are costly and usage should be reviewed."
  sql         = query.ebs_volume_high_iops.sql
  severity    = "low"

  param "ebs_volume_max_iops" {
    description = "The maximum IOPS allowed for volumes."
    default     = var.ebs_volume_max_iops
  }

  tags = merge(local.overused_common_tags, {
    service = "AWS/EBS"
  })
}

control "ec2_instances_large" {
  title       = "Large EC2 instances should be reviewed"
  description = "Large EC2 instances are unusual, expensive and should be reviewed."
  sql         = query.ec2_instances_large.sql
  severity    = "low"

  param "ec2_instance_allowed_types" {
    description = "A list of allowed instance types. PostgreSQL wildcards are supported."
    default     = var.ec2_instance_allowed_types
  }

  tags = merge(local.overused_common_tags, {
    service = "AWS/EC2"
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

  tags = merge(local.overused_common_tags, {
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

  tags = merge(local.overused_common_tags, {
    service = "AWS/ElastiCache"
  })
}

control "lambda_function_high_error_rate" {
  title       = "Lambda functions with high error rate should be reviewed"
  description = "Function errors may result in retries that incur extra charges. The control checks for functions with an error rate of more than 10% a day in one of the last 7 days."
  sql         = query.lambda_function_high_error_rate.sql
  severity    = "low"
  tags = merge(local.overused_common_tags, {
    service = "AWS/Lamda"
  })
}

control "lambda_function_excessive_timeout" {
  title       = "Lambda functions with excessive timeout should be reviewed"
  description = "Excessive timeouts result in retries and additional execution time for the function, incurring request charges and billed duration. The control checks for functions with a timeout rate of more than 10% a day in one of the last 7 days."
  sql         = query.lambda_function_excessive_timeout.sql
  severity    = "low"
  tags = merge(local.overused_common_tags, {
    service = "AWS/Lamda"
  })
}


control "rds_db_instance_age_90" {
  title       = "Long running RDS DBs should have reserved instances purchased for them"
  description = "Long running database servers should be associated with a reserve instance."
  sql         = query.rds_db_instance_age_90.sql
  severity    = "low"

  param "rds_running_db_instance_age_max_days" {
    description = "The maximum number of days DB instances are allowed to run."
    default     = var.rds_running_db_instance_age_max_days
  }

  param "rds_running_db_instance_age_warning_days" {
    description = "The number of days DB instances can be running before sending a warning."
    default     = var.rds_running_db_instance_age_warning_days
  }

  tags = merge(local.overused_common_tags, {
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

  tags = merge(local.overused_common_tags, {
    service = "AWS/Redshift"
  })
}
