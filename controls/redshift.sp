locals {
  redshift_common_tags = merge(local.thrifty_common_tags, {
    service = "redshift"
  })
}

benchmark "redshift" {
  title         = "Redshift Checks"
  description   = "Thrifty developers eliminate unused Redshift clusters."
  documentation = file("./controls/docs/redshift.md")
  tags          = local.redshift_common_tags
  children = [
    control.redshift_cluster_age_90_days,
  ]
}

control "redshift_cluster_age_90_days" {
  title         = "Clusters created over 90 days ago should be deleted if not required"
  description   = "Old clusters are likely unneeded and costly to maintain."
  sql           = query.redshift_cluster_age_90_days.sql
  severity      = "low"
  tags = merge(local.redshift_common_tags, {
    class = "unused"
  })
}