locals {
  cloudtrail_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/CloudTrail"
  })
}

benchmark "cloudtrail" {
  title         = "CloudTrail Checks"
  description   = "Thrifty developers know that multiple active CloudTrail Trails can add significant costs. Be thrifty and eliminate the extra trails. One trail to rule them all."
  documentation = file("./controls/docs/cloudtrail.md")
  children = [
    control.multiple_global_trails,
    control.multiple_regional_trails
  ]

  tags = merge(local.cloudtrail_common_tags, {
    type = "Benchmark"
  })
}

control "multiple_global_trails" {
  title = "Are there redundant global CloudTrail trails?"
  description   = "Your first cloudtrail in each account is free, additional trails are expensive."
  sql           = query.multiple_cloudtrail_trails.sql
  severity      = "low"

  tags = merge(local.cloudtrail_common_tags, {
    class = "managed"
  })
}

control "multiple_regional_trails" {
  title         = "Are there redundant regional CloudTrail trails?"
  description   = "Your first cloudtrail in each region is free, additional trails are expensive."
  sql           = query.multiple_regional_trails.sql
  severity      = "low"

  tags = merge(local.cloudtrail_common_tags, {
    class = "managed"
  })
}
