locals {
  emr_common_tags = merge(local.thrifty_common_tags, {
    service = "emr"
  })
}

benchmark "emr" {
  title         = "EMR Checks"
  description   = "Thrifty developers checks EMR clusters of previous generation instances."
  documentation = file("./controls/docs/emr.md")
  tags          = local.emr_common_tags
  children = [
    control.emr_cluster_instance_prev_gen
  ]
}

control "emr_cluster_instance_prev_gen" {
  title         = "EMR clusters of previous generation instances should be reviewed"
  description   = "EMR clusters of previous generations instance types (c1,cc2,cr1,m2,g2,i2,m1) should be replaced by latest generation instance types for better hardware performance."
  sql           = query.emr_cluster_instance_prev_gen.sql
  severity      = "low"

  tags = merge(local.emr_common_tags, {
    class = "unused"
  })
}