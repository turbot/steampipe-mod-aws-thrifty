locals {
  cloudfront_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/CloudFront"
  })
}

benchmark "cloudfront" {
  title         = "CloudFront Checks"
  description   = "Thrifty developers checks price class of cloudfront distribution for cost optimization."
  documentation = file("./thrifty/docs/cloudfront.md")
  children = [
    control.cloudfront_distribution_pricing_class
  ]

  tags = merge(local.cloudfront_common_tags, {
    type = "Benchmark"
  })
}

control "cloudfront_distribution_pricing_class" {
  title       = "CloudFront distribution pricing class should be reviewed"
  description = "CloudFront distribution pricing class should be reviewed. Price Classes let you reduce your delivery prices by excluding Amazon CloudFront’s more expensive edge locations from your Amazon CloudFront distribution."
  sql         = query.cloudfront_distribution_pricing_class.sql
  severity    = "low"

  tags = merge(local.cloudfront_common_tags, {
    class = "overused"
  })
}
