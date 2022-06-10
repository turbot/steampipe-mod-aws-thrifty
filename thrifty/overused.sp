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

variable "ec2_instance_allowed_types" {
  type        = list(string)
  description = "A list of allowed instance types. PostgreSQL wildcards are supported."
  default     = ["%.nano", "%.micro", "%.small", "%.medium", "%.large", "%.xlarge", "%._xlarge"]
}

benchmark "overused" {
  title         = "Overused"
  description   = "Thrifty developers check overused AWS resources. AWS resources can be overused in a few different ways. When you have long-running resources, consider if they can be stopped intermittently. In non-production environments, for example, it can make sense to spin up resources when needed, or only during working hours."
  documentation = file("./thrifty/docs/overused.md")
  children = [
    control.cloudfront_distribution_pricing_class,
    control.cloudtrail_trail_global_multiple,
    control.cloudtrail_trail_regional_multiple,
    control.ebs_volume_high_iops,
    control.ebs_volume_large,
    control.ec2_instances_large,
    control.lambda_function_excessive_timeout,
    control.lambda_function_high_error_rate
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

control "cloudfront_distribution_pricing_class" {
  title       = "CloudFront distribution pricing class should be reviewed"
  description = "CloudFront distribution pricing class should be reviewed. Price Classes let you reduce your delivery prices by excluding Amazon CloudFront’s more expensive edge locations from your Amazon CloudFront distribution."
  sql         = query.cloudfront_distribution_pricing_class.sql
  severity    = "low"

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/CloudFront"
  })
}

control "cloudtrail_trail_global_multiple" {
  title       = "Redundant global CloudTrail trails should be reviewed"
  description = "Your first cloudtrail in each account is free, additional trails are expensive."
  sql         = query.cloudtrail_trail_global_multiple.sql
  severity    = "low"

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/CloudTrail"
  })
}

control "cloudtrail_trail_regional_multiple" {
  title       = "Redundant regional CloudTrail trails should be reviewed"
  description = "Your first cloudtrail in each region is free, additional trails are expensive."
  sql         = query.cloudtrail_trail_regional_multiple.sql
  severity    = "low"

  tags = merge(local.aws_thrifty_common_tags, {
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

  tags = merge(local.aws_thrifty_common_tags, {
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

  tags = merge(local.aws_thrifty_common_tags, {
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

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EC2"
  })
}

control "lambda_function_high_error_rate" {
  title       = "Lambda functions with high error rate should be reviewed"
  description = "Function errors may result in retries that incur extra charges. The control checks for functions with an error rate of more than 10% a day in one of the last 7 days."
  sql         = query.lambda_function_high_error_rate.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Lamda"
  })
}

control "lambda_function_excessive_timeout" {
  title       = "Lambda functions with excessive timeout should be reviewed"
  description = "Excessive timeouts result in retries and additional execution time for the function, incurring request charges and billed duration. The control checks for functions with a timeout rate of more than 10% a day in one of the last 7 days."
  sql         = query.lambda_function_excessive_timeout.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Lamda"
  })
}
