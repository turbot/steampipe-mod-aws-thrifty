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
    control.ebs_snapshot_age_90,
    control.ebs_volume_high_iops,
    control.ebs_volume_io1,
    control.ebs_volume_large,
    control.ebs_volume_low_iops,
    control.ebs_volume_low_usage,
    control.ebs_volume_on_stopped_instances,
    control.ebs_volume_unattached,
    control.ebs_volume_using_gp2
  ]
}

control "ebs_volume_using_gp2" {
  title         = "Still using gp2 EBS volumes? Should use gp3 instead."
  description   = "EBS gp2 volumes are more costly and lower performance than gp3."
  sql           = query.ebs_volume_using_gp2.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "ebs_volume_io1" {
  title         = "Still using io1 EBS volumes? Should use io2 instead."
  description   = "io1 Volumes are less reliable than io2 for same cost."
  sql           = query.ebs_volume_io1.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "ebs_volume_unattached" {
  title         = "Are there any unattached EBS volumes?"
  description   = "Unattached EBS volumes render little usage, are expensive to maintain and should be reviewed."
  sql           = query.ebs_volume_unattached.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}

control "ebs_volume_large" {
  title         = "What EBS volumes are allocated over 100gb in storage?"
  description   = "Large EBS volumes are unusual, high cost and usage should be reviewed."
  sql           = query.ebs_volume_large.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "ebs_volume_high_iops" {
  title         = "Which EBS volumes are allocated for > 32k IOPS?"
  description   = "High IOPS io1 and io2 volumes are costly and usage should be reviewed."
  sql           = query.ebs_volume_high_iops.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "ebs_volume_low_iops" {
  title         = "What provisioned IOPS volumes would be better as GP3?"
  description   = "GP3 provides 3k base IOPS performance, don't use more costly io1 & io2 volumes."
  sql           = query.ebs_volume_low_iops.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "management"
  })
}

control "ebs_volume_on_stopped_instances" {
  title         = "Which EBS volumes are only attached to stopped EC2 instances?"
  description   = "Instances that are stopped may no longer need any attached EBS volumes"
  sql           = query.ebs_volume_inactive.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "ebs_volume_low_usage" {
  title         = "Are there any EBS volumes with low usage?"
  description   = "Volumes that are unused should be archived and deleted"
  sql           = query.ebs_volume_low_usage.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}

control "ebs_snapshot_age_90" {
  title         = "Which EBS snapshots were created over 90 days ago?"
  description   = "Old EBS snapshots are likely unnecessary and costly to maintain."
  sql           = query.ebs_snapshot_age_90.sql
  severity      = "low"
  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}
