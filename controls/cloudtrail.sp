control "multiple_global_trails" {
  title = "Multiple Global CloudTrail Trails"
  description = "Your first cloudtrail in each account is free, additional trails are expensive."
  sql = query.multiple_cloudtrail_trails.sql
  severity = "low"
  tags = {
    service = "cloudtrail"
    code = "managed"
  }
}

control "multiple_regional_trails" {
  title = "Multiple Regional CloudTrail Trails"
  description = "Your first cloudtrail in each region is free, additional trails are expensive."
  sql = query.multiple_regional_trails.sql
  severity = "low"
  tags = {
    service = "cloudtrail"
    code = "managed"
  }
}
