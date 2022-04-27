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
    control.ebs_volumes_on_stopped_instances,
    control.ebs_with_low_usage,
    control.gp2_volumes,
    control.high_iops_ebs_volumes,
    control.io1_volumes,
    control.large_ebs_volumes,
    control.low_iops_ebs_volumes,
    control.unattached_ebs_volumes
  ]

  tags = merge(local.ebs_common_tags, {
    type = "Benchmark"
  })
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
  title         = "EBS volumes should be resized if too large"
  description   = "Large EBS volumes are unusual, expensive and should be reviewed."
  sql           = query.large_ebs_volumes.sql
  severity      = "low"

  param "ebs_volume_max_size_gb" {
    description = "The maximum size (GB) allowed for volumes."
    default     = var.ebs_volume_max_size_gb
  }

  tags = merge(local.ebs_common_tags, {
    class = "deprecated"
  })
}

control "high_iops_ebs_volumes" {
  title         = "EBS volumes with high IOPS should be resized if too large"
  description   = "High IOPS io1 and io2 volumes are costly and usage should be reviewed."
  sql           = query.high_iops_volumes.sql
  severity      = "low"

  param "ebs_volume_max_iops" {
    description = "The maximum IOPS allowed for volumes."
    default     = var.ebs_volume_max_iops
  }

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
  title         = "EBS volumes attached to stopped instances should be reviewed"
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

  param "ebs_volume_avg_read_write_ops_low" {
    description = "The number of average read/write ops required for volumes to be considered infrequently used. This value should be lower than ebs_volume_avg_read_write_ops_high."
    default     = var.ebs_volume_avg_read_write_ops_low
  }

  param "ebs_volume_avg_read_write_ops_high" {
    description = "The number of average read/write ops required for volumes to be considered frequently used. This value should be higher than ebs_volume_avg_read_write_ops_low."
    default     = var.ebs_volume_avg_read_write_ops_high
  }

  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}

control "ebs_snapshot_max_age" {
  title         = "Old EBS snapshots should be deleted if not required"
  description   = "Old EBS snapshots are likely unnecessary and costly to maintain."
  sql           = query.old_ebs_snapshots.sql
  severity      = "low"

  param "ebs_snapshot_age_max_days" {
    description = "The maximum number of days snapshots can be retained."
    default     = var.ebs_snapshot_age_max_days
  }

  tags = merge(local.ebs_common_tags, {
    class = "unused"
  })
}
