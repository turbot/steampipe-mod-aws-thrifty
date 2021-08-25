locals {
  redshift_common_tags = merge(local.thrifty_common_tags, {
    service = "redshift"
  })
}

benchmark "redshift" {
  title         = "Redshift Checks"
  description   = "Thrifty developers check their long running Redshift clusters are associated with reserved nodes."
  documentation = file("./controls/docs/redshift.md")
  tags          = local.redshift_common_tags
  children = [
    control.redshift_cluster_age_90_days,
    control.redshift_cluster_low_utilization,
    control.redshift_cluster_schedule_pause_resume_enabled
  ]
}

control "redshift_cluster_age_90_days" {
  title         = "Long running Redshift clusters should have reserved nodes purchased for them"
  description   = "Long running clusters should be associated with reserved nodes, which provide a significant discount."
  sql           = query.redshift_cluster_age_90_days.sql
  severity      = "low"
  tags = merge(local.redshift_common_tags, {
    class = "managed"
  })
}


control "redshift_cluster_schedule_pause_resume_enabled" {
  title         = "Redshift cluster paused resume should be enabled"
  description   = "Redshift cluster paused resume should be enabled to easily suspend on-demand billing while the cluster is not being used."
  sql           = query.redshift_cluster_schedule_pause_resume_enabled.sql
  severity      = "low"
  tags = merge(local.redshift_common_tags, {
    class = "managed"
  })
}

control "redshift_cluster_low_utilization" {
  title         = "Redshift cluster with low CPU utilization should be reviewed"
  description   = "Resize or eliminate under utilized clusters."
  sql           = query.redshift_cluster_low_utilization.sql
  severity      = "low"
  tags = merge(local.redshift_common_tags, {
    class = "managed"
  })
}
