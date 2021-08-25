locals {
  ebs_common_tags = merge(local.thrifty_common_tags, {
    service = "ebs"
  })
}

benchmark "ebs" {
  title         = "EBS Checks"
  description   = "Thrifty developers keep a careful eye for unused and under-utilized EBS volumes."
  documentation = file("./controls/docs/ebs.md")
  tags          = local.ebs_common_tags
  children = [
    control.ebs_volumes_on_stopped_instances,
    control.ebs_with_low_usage,
    control.gp2_volumes,
    control.high_iops_ebs_volumes,
    control.io1_volumes,
    control.large_ebs_volumes,
    control.low_iops_ebs_volumes,
    control.old_snapshots,
    control.unattached_ebs_volumes
  ]
}

control "gp2_volumes" {
  title         = "Still using gp2 EBS volumes? Should use gp3 instead."
  description   = "EBS gp2 volumes are more costly and lower performance than gp3."
  sql           = query.gp2_ebs_volumes.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "io1_volumes" {
  title         = "Still using io1 EBS volumes? Should use io2 instead."
  description   = "io1 Volumes are less reliable than io2 for same cost."
  sql           = query.io1_ebs_volumes.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "unattached_ebs_volumes" {
  title         = "Are there any unattached EBS volumes?"
  description   = "Unattached EBS volumes render little usage, are expensive to maintain and should be reviewed."
  sql           = query.unattached_ebs_volumes.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}

control "large_ebs_volumes" {
  title         = "What EBS volumes are allocated over 100gb in storage?"
  description   = "Large EBS volumes are unusual, high cost and usage should be reviewed."
  sql           = query.large_ebs_volumes.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "high_iops_ebs_volumes" {
  title         = "Which EBS volumes are allocated for > 32k IOPS?"
  description   = "High IOPS io1 and io2 volumes are costly and usage should be reviewed."
  sql           = query.high_iops_volumes.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "low_iops_ebs_volumes" {
  title         = "What provisioned IOPS volumes would be better as GP3?"
  description   = "GP3 provides 3k base IOPS performance, don't use more costly io1 & io2 volumes."
  sql           = query.low_iops_volumes.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "management"
  })
}

control "ebs_volumes_on_stopped_instances" {
  title         = "Which EBS volumes are only attached to stopped EC2 instances?"
  description   = "Instances that are stopped may no longer need any attached EBS volumes"
  sql           = query.inactive_ebs_volumes.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "ebs_with_low_usage" {
  title         = "Are there any EBS volumes with low usage?"
  description   = "Volumes that are unused should be archived and deleted"
  sql           = query.low_usage_ebs_volumes.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}

control "old_snapshots" {
  title         = "Which EBS snapshots were created over 90 days ago?"
  description   = "Old EBS snapshots are likely unnecessary and costly to maintain."
  sql           = query.old_ebs_snapshots.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}
