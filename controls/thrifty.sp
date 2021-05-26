locals {
  common_mod_tags = {
    plugin      = "aws"
  }
  required_aws_tags = [
    "aws:createdBy"
  ]
}

benchmark "thrifty_aws" {
  title         = "Thrifty Benchmark for AWS  <(ﾟ´(｡｡)`ﾟ)>"
  description   = "Find unused, under-utilized and over-priced resources in your AWS account."
  documentation = file("./controls/docs/thrifty_overview.md")
  children = [
    benchmark.cloudtrail,
    benchmark.cloudwatch,
    benchmark.cost_explorer,
    benchmark.dynamodb,
    benchmark.ebs,
    benchmark.ec2,
    benchmark.rds,
    benchmark.s3,
    benchmark.vpc
  ]
  tags = local.common_tags
}
