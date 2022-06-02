variable "cloudwatch_log_stream_age_max_days" {
  type        = number
  description = "The maximum number of days log streams are allowed without any log event written to them."
  default     = 90
}

variable "secretsmanager_secret_last_used" {
  type        = number
  description = "The default number of days secrets manager secrets to be considered in-use."
  default     = 90
}

locals {
  unused_common_tags = merge(local.aws_thrifty_common_tags, {
    unused = "true"
  })
}

benchmark "unused" {
  title         = "Unused"
  description   = "."
  documentation = file("./thrifty/docs/unused.md")
  children = [
    control.cloudwatch_log_stream_unused,
    control.ebs_volume_unattached,
    control.ebs_volume_on_stopped_instances,
    control.ec2_application_lb_unused,
    control.ec2_classic_lb_unused,
    control.ec2_gateway_lb_unused,
    control.ec2_network_lb_unused,
    control.ec2_eips_unattached,
    control.emr_cluster_is_idle_30_minutes,
    control.route53_health_check_unused,
    control.secretsmanager_secret_unused,
    control.vpc_nat_gateway_unused
  ]

  tags = merge(local.unused_common_tags, {
    type = "Benchmark"
  })
}

control "cloudwatch_log_stream_unused" {
  title       = "Unused log streams should be removed if not required"
  description = "Unnecessary log streams should be deleted for storage cost savings."
  sql         = query.cloudwatch_log_stream_unused.sql
  severity    = "low"

  param "cloudwatch_log_stream_age_max_days" {
    description = "The maximum number of days log streams are allowed without any log event written to them."
    default     = var.cloudwatch_log_stream_age_max_days
  }

  tags = merge(local.unused_common_tags, {
    service = "AWS/CloudWatch"
  })
}

control "ebs_volume_unattached" {
  title       = "Unattached EBS volumes should be reviewed"
  description = "Unattached EBS volumes render little usage, are expensive to maintain and should be reviewed."
  sql         = query.ebs_volume_unattached.sql
  severity    = "low"
  tags = merge(local.unused_common_tags, {
    service = "AWS/EBS"
  })
}

control "ebs_volume_on_stopped_instances" {
  title       = "EBS volumes attached to stopped instances should be reviewed"
  description = "Instances that are stopped may no longer need any attached EBS volumes"
  sql         = query.ebs_volume_inactive.sql
  severity    = "low"
  tags = merge(local.unused_common_tags, {
    service = "AWS/EBS"
  })
}

control "ec2_application_lb_unused" {
  title       = "Application load balancers having no targets attached should be deleted"
  description = "Application load balancers with no targets attached still cost money and should be deleted."
  sql         = query.ec2_application_lb_unused.sql
  severity    = "low"
  tags = merge(local.unused_common_tags, {
    service = "AWS/EC2"
  })
}

control "ec2_classic_lb_unused" {
  title       = "Classic load balancers having no instances attached should be deleted"
  description = "Classic load balancers with no instances attached still cost money should be deleted."
  sql         = query.ec2_classic_lb_unused.sql
  severity    = "low"
  tags = merge(local.unused_common_tags, {
    service = "AWS/EC2"
  })
}

control "ec2_gateway_lb_unused" {
  title       = "Gateway load balancers having no targets attached should be deleted"
  description = "Gateway load balancers with no targets attached still cost money and should be deleted."
  sql         = query.ec2_gateway_lb_unused.sql
  severity    = "low"
  tags = merge(local.unused_common_tags, {
    service = "AWS/EC2"
  })
}

control "ec2_network_lb_unused" {
  title       = "Network load balancers having no targets attached should be deleted"
  description = "Network load balancers with no targets attached still cost money and should be deleted."
  sql         = query.ec2_network_lb_unused.sql
  severity    = "low"
  tags = merge(local.unused_common_tags, {
    service = "AWS/EC2"
  })
}

control "ec2_eips_unattached" {
  title       = "Unattached elastic IP addresses (EIPs) should be released"
  description = "Unattached Elastic IPs are charged by AWS, they should be released."
  sql         = query.ec2_eips_unattached.sql
  severity    = "low"
  tags = merge(local.unused_common_tags, {
    service = "AWS/EC2"
  })
}

control "emr_cluster_is_idle_30_minutes" {
  title       = "EMR clusters idle for more than 30 minutes should be reviewed"
  description = "EMR clusters which is live but not currently running tasks should be reviewed and checked whether the cluster has been idle for more than 30 minutes."
  sql         = query.emr_cluster_is_idle_30_minutes.sql
  severity    = "low"

  tags = merge(local.unused_common_tags, {
    service = "AWS/EMR"
  })
}

control "route53_health_check_unused" {
  title       = "Unnecessary health checks should be deleted"
  description = "When you associate health checks with an endpoint, health check requests are sent to the endpoint's IP address. These health check requests are sent to validate that the requests are operating as intended. Health check charges are incurred based on their associated endpoints. To avoid health check charges, delete any health checks that aren't used with an RRset record and are no longer required."
  sql         = query.route53_health_check_unused.sql
  severity    = "low"
  tags = merge(local.unused_common_tags, {
    service = "AWS/Route53"
  })
}

control "secretsmanager_secret_unused" {
  title       = "Unused secrets manager secret should be deleted"
  description = "AWS Secrets Manager secrets should have been accessed within a specified number of days. The default value is 90 days."
  sql         = query.secretsmanager_secret_unused.sql
  severity    = "low"

  param "secretsmanager_secret_last_used" {
    description = "The specified number of days since secrets manager secret last used."
    default     = var.secretsmanager_secret_last_used
  }

  tags = merge(local.unused_common_tags, {
    service = "AWS/SecretsManager"
  })
}

control "vpc_nat_gateway_unused" {
  title       = "Unused NAT gateways should be deleted"
  description = "NAT gateway are charged on an hourly basis once they are provisioned and available, so unused gateways should be deleted."
  sql         = query.vpc_nat_gateway_unused.sql
  severity    = "low"
  tags = merge(local.unused_common_tags, {
    service = "AWS/VPC"
  })
}
