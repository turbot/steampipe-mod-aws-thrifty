locals {
  vpc_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/VPC"
  })
}

benchmark "vpc" {
  title         = "VPC Checks"
  description   = "Thrifty developers ensure that they delete unused network resources."
  documentation = file("./controls/docs/vpc.md")
  children = [
    control.vpc_nat_gateway_unused
  ]

  tags = merge(local.vpc_common_tags, {
    type = "Benchmark"
  })
}

control "vpc_nat_gateway_unused" {
  title       = "Unused NAT gateways should be deleted"
  description = "NAT gateways are charged on an hourly basis once they are provisioned and available, so unused gateways should be deleted."
  sql         = query.vpc_nat_gateway_unused.sql
  severity    = "low"

  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })
}
