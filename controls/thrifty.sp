locals {
  thrifty_common_tags = {
    plugin      = "aws"
  }
  required_aws_tags = [
    "aws:createdBy"
  ]
}

benchmark "thrifty_aws" {
  title         = "AWS Thrifty <(ﾟ´(｡｡)`ﾟ)>"
  description   = "Find unused, under-utilized and over-priced resources in your AWS account."
  documentation = file("./controls/docs/thrifty.md")
  children = [
    benchmark.cloudtrail,
    benchmark.cloudwatch,
    benchmark.cost-explorer,
    benchmark.dynamodb,
    benchmark.ebs,
    benchmark.ec2,
    benchmark.network,
    benchmark.rds,
    benchmark.s3
  ]
  tags = local.thrifty_common_tags
}
