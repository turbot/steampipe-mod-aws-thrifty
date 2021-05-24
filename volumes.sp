control "gp2_volumes" {
  title = "GP2 Volume Usage"
  description = "GP2 Volumes are more costly and lower performance than GP3."
  sql = query.gp2_ebs_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}

control "io1_volumes" {
  title = "IO1 Volume Usage"
  description = "IO1 Volumes are less reliable than IO2 for same cost."
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
  title = "Use GP3 for EBS volumes"
  description = "GP3 volumes are cheaper and higher performance than all other types."
  sql = query.ebs_volumes_not_using_gp3.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}

control "large_ebs_volumes" {
  title = "Large volumes"
  description = "Large EBS volumes are unusual, high cost and should be reviewed."
  sql = query.large_ebs_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}

control "high_iops_ebs_volumes" {
  title = "High IOPS volumes"
  description = "High IOPS volumes are rare, high cost and should be reviewed."
  sql = query.high_iops_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}

control "low_iops_ebs_volumes" {
  title = "Low IOPS volumes"
  description = "Low IOPS volumes should be replaced with cost effective GP3."
  sql = query.low_iops_volumes.sql
  severity = "low"
  tags = {
    service = "ebs"
    code = "deprecated"
  }
}
