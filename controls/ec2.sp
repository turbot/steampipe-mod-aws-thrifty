locals {
  ec2_common_tags = merge(local.thrifty_common_tags, {
    service = "ec2"
  })
}

benchmark "ec2" {
  title         = "Thrifty EC2 Checks"
  description   = "Thrifty developers eliminate unused and under-utilized EC2 instances."
  documentation = file("./controls/docs/ec2.md") #TODO
  tags          = local.ec2_common_tags
  children = [
    control.large_ec2_instances,
    control.long_running_ec2_instances,
    control.old_snapshots,
    control.instances_with_low_utilization
  ]
}

control "large_ec2_instances" {
  title         = "Very high cost, running EC2 instances"
  description   = "Large EC2 instances are unusual, expensive and should be reviewed."
  documentation = file("./controls/docs/ec2-1.md") #TODO
  sql           = query.large_ec2_instances.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    code = "deprecated"
  })
}

control "long_running_ec2_instances" {
  title         = "Instances running for over 90 days"
  description   = "Instances should ideally be ephemeral and rehydrated frequently, check why these instances have been running for so long."
  documentation = file("./controls/docs/ec2-1.md") #TODO
  sql           = query.long_running_instances.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    code = "deprecated"
  })
}

control "old_snapshots" {
  title         = "EBS snapshots created over 90 days ago"
  description   = "Old EBS snapshots are likely uneeded and costly to maintain."
  documentation = file("./controls/docs/ec2-1.md") #TODO
  sql           = query.old_ebs_snapshots.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    code = "unused"
  })
}

control "instances_with_low_utilization" {
  title         = "EC2 Instances with low utilization"
  description   = "Resize or eliminate under utilized instances."
  documentation = file("./controls/docs/ec2-1.md") #TODO
  sql           = query.low_utilization_ec2_instance.sql
  severity      = "low"
  tags = merge(local.ec2_common_tags, {
    code = "unused"
  })
}


/// TODO - look for cost allocation tags
/// TOD0 - Newer instance sizes