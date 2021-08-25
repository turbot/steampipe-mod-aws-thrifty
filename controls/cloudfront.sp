locals {
  cloudfront_common_tags = merge(local.thrifty_common_tags, {
    service = "cloudfront"
  })
}

benchmark "cloudfront" {
  title         = "CloudFront Checks"
  description   = "Thrifty developers checks price class of cloudfront distribution for cost optimization."
  documentation = file("./controls/docs/cloudfront.md")
  tags          = local.cloudfront_common_tags
  children = [
    control.cloudfront_distribution_pricing_class
  ]
}

control "cloudfront_distribution_pricing_class" {
  title         = "CloudFront distribution pricing class should be reviewed"
  description   = "CloudFront distribution pricing class should be reviewed. Price Classes let you reduce your delivery prices by excluding Amazon CloudFront’s more expensive edge locations from your Amazon CloudFront distribution."
  sql           = query.cloudfront_distribution_pricing_class.sql
  severity      = "low"
  tags = merge(local.cloudfront_common_tags, {
    class = "managed"
  })
}
