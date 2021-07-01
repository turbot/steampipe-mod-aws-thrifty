locals {
  ec2_common_tags = merge(local.thrifty_common_tags, {
    service = "ec2"
  })
}

benchmark "ec2" {
  title         = "EC2 Checks"
  description   = "Thrifty developers eliminate unused and under-utilized EC2 instances."
  documentation = file("./controls/docs/ec2.md") #TODO
  tags          = local.ec2_common_tags
  children = [
    control.ec2_application_lb_unused,
    control.ec2_instance_previous_generation,
    control.large_ec2_instances,
    control.long_running_ec2_instances,
    control.instances_with_low_utilization
  ]
}

control "ec2_application_lb_unused" {
  title         = "Unsued application load balancers should be removed"
  description   = "Applicaion load balancers with no services attached, or its attached services are unhealthy should be reviewed."
  sql           = query.ec2_application_lb_unused.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    class = "deprecated"
  })
}

control "ec2_instance_previous_generation" {
  title         = "EC2 instances of latest generation should be used for best performance"
  description   = "It is recommended to use the latest generation of instances to get the best performance."
  sql           = query.ec2_instance_previous_generation.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    class = "deprecated"
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