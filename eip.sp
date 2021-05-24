
control "unattached_eips" {
  title = "Unattached EIPs"
  description = "Unattached Elastic IPs are charged by AWS, they should be released."
  sql = query.unattached_eips.sql
  severity = "low"
  tags = {
    service = "vpc"
    code = "unused"
  }
}
