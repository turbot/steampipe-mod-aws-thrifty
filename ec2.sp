
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

control "unattached_ebs_volumes" {
  title = "Unattached EBS volumes"
  sql = query.unattached_ebs_volumes.sql
  severity = "low"
  tags = {
    service = "ec2"
    code = "unused"
  }
}

control "ebs_volumes_not_using_gp3" {
  title = "Use GP3 for EBS volumes"
  description = "GP3 volumes are cheaper and higher performance than all other types."
  sql = query.ebs_volumes_not_using_gp3.sql
  severity = "low"
  tags = {
    service = "ec2"
    code = "deprecated"
  }
}

control "large_ebs_volumes" {
  title = "Large volumes"
  description = "Large EBS volumes are unusual, high cost and should be reviewed."
  sql = query.large_ebs_volumes.sql
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

// TODO - use GP3 instead of GP2 (not instead of IOPS)
// TODO - high IOPS
// TODO - attached to stopped EC2 instance
// TODO - long running instances (stop at night? why so old?)
// TODO - look for cost allocation tags
