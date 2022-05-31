variable "ec2_instance_allowed_types" {
  type        = list(string)
  description = "A list of allowed instance types. PostgreSQL wildcards are supported."
  default     = ["%.nano", "%.micro", "%.small", "%.medium", "%.large", "%.xlarge", "%._xlarge"]
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

locals {
  ec2_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EC2"
  })
}

benchmark "ec2" {
  title         = "EC2 Checks"
  description   = "Thrifty developers eliminate unused and under-utilized EC2 instances."
  documentation = file("./controls/docs/ec2.md")
  children = [
    control.ec2_application_lb_unused,
    control.ec2_classic_lb_unused,
    control.ec2_eips_unattached,
    control.ec2_gateway_lb_unused,
    control.ec2_instance_avg_cpu_utilization_low,
    control.ec2_instance_running_max_age,
    control.ec2_instances_large,
    control.ec2_network_lb_unused,
    control.ec2_reserved_instance_lease_expiration_days
  ]

  tags = merge(local.ec2_common_tags, {
    type = "Benchmark"
  })
}

control "ec2_application_lb_unused" {
  title         = "Application load balancers having no targets attached should be deleted"
  description   = "Application load balancers with no targets attached still cost money and should be deleted."
  sql           = query.ec2_application_lb_unused.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })
}

control "ec2_classic_lb_unused" {
  title         = "Classic load balancers having no instances attached should be deleted"
  description   = "Classic load balancers with no instances attached still cost money should be deleted."
  sql           = query.ec2_classic_lb_unused.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })
}

control "ec2_gateway_lb_unused" {
  title         = "Gateway load balancers having no targets attached should be deleted"
  description   = "Gateway load balancers with no targets attached still cost money and should be deleted."
  sql           = query.ec2_gateway_lb_unused.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })
}

control "ec2_network_lb_unused" {
  title         = "Network load balancers having no targets attached should be deleted"
  description   = "Network load balancers with no targets attached still cost money and should be deleted."
  sql           = query.ec2_network_lb_unused.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })
}

control "ec2_instances_large" {
  title         = "Large EC2 instances should be reviewed"
  description   = "Large EC2 instances are unusual, expensive and should be reviewed."
  sql           = query.ec2_instances_large.sql
  severity      = "low"

  param "ec2_instance_allowed_types" {
    description = "A list of allowed instance types. PostgreSQL wildcards are supported."
    default     = var.ec2_instance_allowed_types
  }

  tags = merge(local.ec2_common_tags, {
    class = "deprecated"
  })
}

control "ec2_instance_running_max_age" {
  title         = "Long running EC2 instances should be reviewed"
  description   = "Instances should ideally be ephemeral and rehydrated frequently, check why these instances have been running for so long."
  sql           = query.ec2_instance_running_max_age.sql
  severity      = "low"

  param "ec2_running_instance_age_max_days" {
    description = "The maximum number of days instances are allowed to run."
    default     = var.ec2_running_instance_age_max_days
  }

  tags = merge(local.ec2_common_tags, {
    class = "deprecated"
  })
}

control "ec2_instance_avg_cpu_utilization_low" {
  title         = "Which EC2 instances have very low CPU utilization?"
  description   = "Resize or eliminate under utilized instances."
  sql           = query.ec2_instance_avg_cpu_utilization_low.sql
  severity      = "low"

  param "ec2_instance_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for instances to be considered infrequently used. This value should be lower than ec2_instance_avg_cpu_utilization_high."
    default     = var.ec2_instance_avg_cpu_utilization_low
  }

  param "ec2_instance_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for instances to be considered frequently used. This value should be higher than ec2_instance_avg_cpu_utilization_low."
    default     = var.ec2_instance_avg_cpu_utilization_high
  }

  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })
}

control "ec2_reserved_instance_lease_expiration_days" {
  title         = "EC2 reserved instances scheduled for expiration should be reviewed"
  description   = "EC2 reserved instances that are scheduled for expiration or have expired in the preceding 30 days should be reviewed."
  sql           = query.ec2_reserved_instance_lease_expiration_days.sql
  severity      = "low"

  param "ec2_reserved_instance_expiration_warning_days" {
    description = "The number of days reserved instances can be running before sending a warning."
    default     = var.ec2_reserved_instance_expiration_warning_days
  }

  tags = merge(local.ec2_common_tags, {
    class = "managed"
  })
}

control "ec2_eips_unattached" {
  title         = "Unattached elastic IP addresses (EIPs) should be released"
  description   = "Unattached Elastic IPs are charged by AWS, they should be released."
  sql           = query.ec2_eips_unattached.sql
  severity      = "low"
  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })
}
