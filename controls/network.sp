locals {
  vpc_common_tags = merge(local.thrifty_common_tags, {
    service = "vpc"
  })
}

benchmark "network" {
  title         = "Networking Checks"
  description   = "Thrifty developers ensure delete unused network resources."
  documentation = file("./controls/docs/network.md") #TODO
  tags          = local.vpc_common_tags
  children = [
    control.unattached_eips,
    control.vpc_nat_gateway_age_30
  ]
}

control "unattached_eips" {
  title         = "Are there any unattached Elastic IP addresses (EIP)?"
  description   = "Unattached Elastic IPs are charged by AWS, they should be released."
  sql           = query.unattached_eips.sql
  severity      = "low"
  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })
}

control "vpc_nat_gateway_age_30" {
  title         = "VPC NAT Gateway created over 30 days ago should be reviewed"
  description   = "NAT Gateway is charged on an hourly basis, check why these are available for so long."
  sql           = query.vpc_nat_gateway_age_30.sql
  severity      = "low"
  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })
}

//TODO Add unattached Gateways
