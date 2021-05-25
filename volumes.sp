control "gp2_volumes" {
  title = "EBS gp2 usage is deprecated, use gp3"
  description = "EBS gp2 volumes are more costly and lower performance than gp3."
  sql = query.gp2_ebs_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}

control "io1_volumes" {
  title = "EBS io1 usage is deprecated, use io2"
  description = "io1 Volumes are less reliable than io2 for same cost."
  sql = query.io1_ebs_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}

control "unattached_ebs_volumes" {
  title = "Unattached EBS volumes"
  sql = query.unattached_ebs_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "unused"
  }
}

control "ebs_volumes_not_using_gp3" {
  title = "Use gp3 for EBS volumes"
  description = "gp3 volumes are cheaper and higher performance than all other types."
  sql = query.ebs_volumes_not_using_gp3.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}

control "large_ebs_volumes" {
  title = "EBS volumes over 100gb"
  description = "Large EBS volumes are unusual, high cost and usage should be reviewed."
  sql = query.large_ebs_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}

control "high_iops_ebs_volumes" {
  title = "EBS volumes with > 32k provisioned IOPS"
  description = "High IOPS io1 and io2 volumes are costly and usage should be reviewed."
  sql = query.high_iops_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}

control "low_iops_ebs_volumes" {
  title = "EBS volumes with < 3k provisioned IOPS"
  description = "GP3 provides 3k base IOPS performance, don't use more costly io1 & io2 volumes."
  sql = query.low_iops_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "management"
  }
}

control "ebs_volumes_on_stopped_instances" {
  title = "EBS volumes attached to stopped EC2 instances"
  description = "Instances that are stopped may no longer need any attached EBS volumes"
  sql = query.inactive_ebs_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}

// TODO - look for cost allocation tags

