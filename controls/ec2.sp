locals {
  ec2_common_tags = merge(local.thrifty_common_tags, {
    service = "ec2"
  })
}

benchmark "ec2" {
  title         = "EC2 Checks"
  description   = "Thrifty developers eliminate unused and under-utilized EC2 instances."
  documentation = file("./controls/docs/ec2.md")
  tags          = local.ec2_common_tags
  children = [
    control.ec2_application_lb_unused,
    control.ec2_classic_lb_unused,
    control.ec2_gateway_lb_unused,
    control.ec2_network_lb_unused,
    control.ec2_reserved_instance_lease_expiration_30_days,
    control.instances_with_low_utilization,
    control.large_ec2_instances,
    control.long_running_ec2_instances
  ]
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

control "large_ec2_instances" {
  title         = "What running EC2 instances are huge? (e.g. > 12xlarge)"
  description   = "Large EC2 instances are unusual, expensive and should be reviewed."
  sql           = query.large_ec2_instances.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    class = "deprecated"
  })
}

control "long_running_ec2_instances" {
  title         = "What are my long running EC2 instances? (over 90 days?)"
  description   = "Instances should ideally be ephemeral and rehydrated frequently, check why these instances have been running for so long."
  sql           = query.long_running_instances.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    class = "deprecated"
  })
}

control "instances_with_low_utilization" {
  title         = "Which EC2 instances have very low CPU utilization?"
  description   = "Resize or eliminate under utilized instances."
  sql           = query.low_utilization_ec2_instance.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })
}

control "ec2_reserved_instance_lease_expiration_30_days" {
  title         = "EC2 reserved instances scheduled to expire within next 30 days should be reviewed"
  description   = "EC2 reserved instances that are scheduled to expire within the next 30 days or have expired in the preceding 30 days should be reviewed."
  sql           = query.ec2_reserved_instance_lease_expiration_30_days.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    class = "unused"
  })
}
