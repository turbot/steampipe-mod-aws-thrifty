variable "ebs_snapshot_age_max_days" {
  type        = number
  description = "The maximum number of days snapshots can be retained."
  default     = 90
}

variable "ebs_volume_avg_read_write_ops_high" {
  type        = number
  description = "The number of average read/write ops required for volumes to be considered frequently used. This value should be higher than ebs_volume_avg_read_write_ops_low."
  default     = 500
}

variable "ebs_volume_avg_read_write_ops_low" {
  type        = number
  description = "The number of average read/write ops required for volumes to be considered infrequently used. This value should be lower than ebs_volume_avg_read_write_ops_high."
  default     = 100
}

variable "ebs_volume_max_iops" {
  type        = number
  description = "The maximum IOPS allowed for volumes."
  default     = 32000
}

variable "ebs_volume_max_size_gb" {
  type        = number
  description = "The maximum size (GB) allowed for volumes."
  default     = 100
}

locals {
  ebs_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EBS"
  })
}

benchmark "ebs" {
  title         = "EBS Checks"
  description   = "Thrifty developers keep a careful eye for unused and under-utilized EBS volumes."
  documentation = file("./controls/docs/ebs.md")
  children = [
    control.ebs_snapshot_max_age,
    control.ebs_volume_high_iops,
    control.ebs_volume_using_io1,
    control.ebs_volume_large,
    control.ebs_volume_low_iops,
    control.ebs_volume_low_usage,
    control.ebs_volume_on_stopped_instances,
    control.ebs_volume_unattached,
    control.ebs_volume_using_gp2
  ]

  tags = merge(local.ebs_common_tags, {
    type = "Benchmark"
  })
}

control "ebs_volume_using_gp2" {
  title       = "EBS gp3 volumes should be used instead of gp2"
  description = "EBS gp2 volumes are more costly and have a lower performance than gp3."
  sql         = query.ebs_volume_using_gp2.sql
  severity    = "low"

  tags = merge(local.ebs_common_tags, {
    class = "generation_gaps"
  })
}

control "ebs_volume_using_io1" {
  title       = "EBS io2 volumes should be used instead of io1"
  description = "EBS io1 volumes are less reliable than io2 for same cost."
  sql         = query.ebs_volume_using_io1.sql
  severity    = "low"

  tags = merge(local.ebs_common_tags, {
    class = "generation_gaps"
  })
}

control "ebs_volume_unattached" {
  title       = "Unattached EBS volumes should be reviewed"
  description = "Unattached EBS volumes render little usage, are expensive to maintain and should be reviewed."
  sql         = query.ebs_volume_unattached.sql
  severity    = "low"

  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}

control "ebs_volume_large" {
  title       = "EBS volumes should be resized if too large"
  description = "Large EBS volumes are unusual, costlier and their usage should be reviewed."
  sql         = query.ebs_volume_large.sql
  severity    = "low"

  param "ebs_volume_max_size_gb" {
    description = "The maximum size (GB) allowed for volumes."
    default     = var.ebs_volume_max_size_gb
  }

  tags = merge(local.ebs_common_tags, {
    class = "overused"
  })
}

control "ebs_volume_high_iops" {
  title       = "EBS volumes with high IOPS should be resized if too large"
  description = "High IOPS io1 and io2 volumes are costly and usage should be reviewed."
  sql         = query.ebs_volume_high_iops.sql
  severity    = "low"

  param "ebs_volume_max_iops" {
    description = "The maximum IOPS allowed for volumes."
    default     = var.ebs_volume_max_iops
  }

  tags = merge(local.ebs_common_tags, {
    class = "overused"
  })
}

control "ebs_volume_low_iops" {
  title       = "EBS volumes with lower IOPS should be reviewed"
  description = "EBS volumes with less than 3k base IOPS performance should use GP3 instead of io1 and io2 volumes."
  sql         = query.ebs_volume_low_iops.sql
  severity    = "low"

  tags = merge(local.ebs_common_tags, {
    class = "overused"
  })
}

control "ebs_volume_on_stopped_instances" {
  title       = "EBS volumes attached to stopped instances should be reviewed"
  description = "Instances that are stopped may no longer need any attached EBS volumes"
  sql         = query.ebs_volume_inactive.sql
  severity    = "low"

  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}

control "ebs_volume_low_usage" {
  title       = "EBS volumes with low usage should be reviewed"
  description = "Volumes that are underused should be archived and deleted."
  sql         = query.ebs_volume_low_usage.sql
  severity    = "low"

  param "ebs_volume_avg_read_write_ops_low" {
    description = "The number of average read/write ops required for volumes to be considered infrequently used. This value should be lower than ebs_volume_avg_read_write_ops_high."
    default     = var.ebs_volume_avg_read_write_ops_low
  }

  param "ebs_volume_avg_read_write_ops_high" {
    description = "The number of average read/write ops required for volumes to be considered frequently used. This value should be higher than ebs_volume_avg_read_write_ops_low."
    default     = var.ebs_volume_avg_read_write_ops_high
  }

  tags = merge(local.ebs_common_tags, {
    class = "underused"
  })
}

control "ebs_snapshot_max_age" {
  title       = "Old EBS snapshots should be deleted if not required"
  description = "Old EBS snapshots are likely unnecessary and costly to maintain."
  sql         = query.ebs_snapshot_max_age.sql
  severity    = "low"

  param "ebs_snapshot_age_max_days" {
    description = "The maximum number of days snapshots can be retained."
    default     = var.ebs_snapshot_age_max_days
  }

  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}
