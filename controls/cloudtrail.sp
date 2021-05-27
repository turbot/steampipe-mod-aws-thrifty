locals {
  cloudtrail_common_tags = merge(local.thrifty_common_tags, {
    service = "cloudtrail"
  })
}

benchmark "cloudtrail" {
  title         = "Thrifty CloudTrail Checks"
  description   = "Thrifty developers know that multiple active CloudTrail Trails can add signifigant costs. Be thrifty and eliminate the extra trails."
  documentation = file("./controls/docs/cloudtrail.md") #TODO
  tags          = local.cloudtrail_common_tags
  children = [
    control.multiple_global_trails,
    control.multiple_regional_trails
  ]
}

control "multiple_global_trails" {
  title = "Multiple Global CloudTrail Trails"
  description   = "Your first cloudtrail in each account is free, additional trails are expensive."
  documentation = file("./controls/docs/cloudtrail-1.md") #TODO
  sql           = query.multiple_cloudtrail_trails.sql
  severity      = "low"
  tags = merge(local.cloudtrail_common_tags, {
    code = "managed"
  })
}

control "multiple_regional_trails" {
  title         = "Multiple Regional CloudTrail Trails"
  description   = "Your first cloudtrail in each region is free, additional trails are expensive."
  documentation = file("./controls/docs/cloudtrail-1.md") #TODO
  sql           = query.multiple_regional_trails.sql
  severity      = "low"
  tags = merge(local.cloudtrail_common_tags, {
    code = "managed"
  })
}
