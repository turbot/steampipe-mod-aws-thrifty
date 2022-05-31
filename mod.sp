// Benchmarks and controls for specific services should override the "service" tag
locals {
  aws_thrifty_common_tags = {
    category = "Cost"
    plugin   = "aws"
    service  = "AWS"
  }
}

mod "aws_thrifty" {
  # hub metadata
  title         = "AWS Thrifty"
  description   = "Are you a Thrifty AWS developer? This Steampipe mod checks your AWS account(s) for unused and under utilized resources."
  color         = "#FF9900"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/aws-thrifty.svg"
  categories    = ["aws", "cost", "thrifty", "public cloud"]

  opengraph {
    title       = "Thrifty mod for AWS"
    description = "Are you a Thrifty AWS dev? This Steampipe mod checks your AWS account(s) for unused and under-utilized resources."
    image       = "/images/mods/turbot/aws-thrifty-social-graphic.png"
  }
}
