locals {
  elasticache_common_tags = merge(local.thrifty_common_tags, {
    service = "elasticache"
  })
}

benchmark "elasticache" {
  title         = "ElastiCache Checks"
  description   = "Thrifty developers eliminate unused ElastiCache clusters."
  documentation = file("./controls/docs/elasticache.md")
  tags          = local.elasticache_common_tags
  children = [
    control.elasticache_cluster_age_90_days,
  ]
}

control "elasticache_cluster_age_90_days" {
  title         = "Clusters created over 90 days ago should be deleted if not required"
  description   = "Old clusters are likely unneeded and costly to maintain."
  sql           = query.elasticache_cluster_age_90_days.sql
  severity      = "low"
  tags = merge(local.redshift_common_tags, {
    class = "unused"
  })
}