locals {
  emr_common_tags = merge(local.thrifty_common_tags, {
    service = "emr"
  })
}

benchmark "emr" {
  title         = "EMR Checks"
  description   = "Thrifty developers checks EMR clusters of previous generation instances and idle clusters."
  documentation = file("./controls/docs/emr.md")
  tags          = local.emr_common_tags
  children = [
    control.emr_cluster_instance_prev_gen,
    control.emr_cluster_is_idle_30_minutes
  ]
}

control "emr_cluster_instance_prev_gen" {
  title         = "EMR clusters of previous generation instances should be reviewed"
  description   = "EMR clusters of previous generations instance types (c1,cc2,cr1,m2,g2,i2,m1) should be replaced by latest generation instance types for better hardware performance."
  sql           = query.emr_cluster_instance_prev_gen.sql
  severity      = "low"

  tags = merge(local.emr_common_tags, {
    class = "managed"
  })
}

control "emr_cluster_is_idle_30_minutes" {
  title         = "EMR clusters idle for more than 30 minutes should be reviewed"
  description   = "EMR clusters which is live but not currently running tasks should be reviewed and checked whether the cluster has been idle for more than 30 minutes."
  sql           = query.emr_cluster_is_idle_30_minutes.sql
  severity      = "low"

  tags = merge(local.emr_common_tags, {
    class = "unused"
  })
}