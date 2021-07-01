locals {
  redshift_common_tags = merge(local.thrifty_common_tags, {
    service = "redshift"
  })
}

benchmark "redshift" {
  title         = "Redshift Checks"
  description   = "Thrifty developers checks long running Redshift clusters should be associated with reserved nodes."
  documentation = file("./controls/docs/redshift.md")
  tags          = local.redshift_common_tags
  children = [
    control.redshift_cluster_age_90_days,
  ]
}

control "redshift_cluster_age_90_days" {
  title         = "Redshift clusters should have reserved nodes purchased for them"
  description   = "Long running clusters should be associated with reserved nodes."
  sql           = query.redshift_cluster_age_90_days.sql
  severity      = "low"
  tags = merge(local.redshift_common_tags, {
    class = "unused"
  })
}