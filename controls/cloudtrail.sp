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
    control.cloudtrail_trail_global_multiple,
    control.cloudtrail_trail_regional_multiple
  ]

  tags = merge(local.cloudtrail_common_tags, {
    type = "Benchmark"
  })
}

control "cloudtrail_trail_global_multiple" {
  title       = "Redundant global CloudTrail trails should be reviewed"
  description = "Your first cloudtrail in each account is free, additional trails are expensive."
  sql         = query.cloudtrail_trail_global_multiple.sql
  severity    = "low"

  tags = merge(local.cloudtrail_common_tags, {
    class = "overused"
  })
}

control "cloudtrail_trail_regional_multiple" {
  title       = "Redundant regional CloudTrail trails should be reviewed"
  description = "Your first cloudtrail in each region is free, additional trails are expensive."
  sql         = query.cloudtrail_trail_regional_multiple.sql
  severity    = "low"

  tags = merge(local.cloudtrail_common_tags, {
    class = "overused"
  })
}
