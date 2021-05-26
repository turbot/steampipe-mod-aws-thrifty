
control "large_ec2_instances" {
  title = "Very high cost, running EC2 instances"
  description = "Large EC2 instances are unusual, expensive and should be reviewed."
  sql = query.large_ec2_instances.sql
  severity = "low"
  tags = {
    service = "ec2"
    code = "deprecated"
  }
}

control "long_running_ec2_instances" {
  title = "Instances running for over 90 days"
  description = "Instances should ideally be ephemeral and rehydrated frequently, check why these instances have been running for so long."
  sql = query.long_running_instances.sql
  severity = "low"
  tags = {
    service = "ec2"
    code = "deprecated"
  }
}

control "old_snapshots" {
  title = "EBS snapshots created over 90 days ago"
  description = "Old EBS snapshots are likely uneeded and costly to maintain."
  sql = query.old_ebs_snapshots.sql
  severity = "low"
  tags = {
    service = "ec2"
    code = "unused"
  }
}

/// TODO - look for cost allocation tags
/// TOD0 - Newer instance sizes