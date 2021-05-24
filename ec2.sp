
control "large_ec2_instances" {
  title = "Large EC2 instances"
  description = "Large EC2 instances are unusual, expensive and should be reviewed."
  sql = query.large_ec2_instances.sql
  severity = "low"
  tags = {
    service = "ec2"
    code = "deprecated"
  }
}

control "old_snapshots" {
  title = "Old EBS snapshots"
  description = "Old EBS snapshots are "
  sql = query.old_ebs_snapshots.sql
  severity = "low"
  tags = {
    service = "ec2"
    code = "unused"
  }
}

// TODO - high IOPS
// TODO - attached to stopped EC2 instance
// TODO - long running instances (stop at night? why so old?)
// TODO - look for cost allocation tags
