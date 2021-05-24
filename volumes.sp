control "gp2_volumes" {
  title = "GP2 Volumes"
  description = "GP2 Volumes are more costly and lower performance than GP3."
  sql = query.gp2_ebs_volumes.sql
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