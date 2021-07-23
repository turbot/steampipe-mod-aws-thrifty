locals {
  vpc_common_tags = merge(local.thrifty_common_tags, {
    service = "vpc"
  })
}

benchmark "network" {
  title         = "Networking Checks"
  description   = "Thrifty developers ensure delete unused network resources."
  documentation = file("./controls/docs/network.md")
  tags          = local.vpc_common_tags
  children = [
    control.unattached_eips,
    control.vpc_nat_gateway_unused
  ]
}

control "unattached_eips" {
  title         = "Unattached elastic IP addresses (EIPs) should be released"
  description   = "Unattached Elastic IPs are charged by AWS, they should be released."
  sql           = query.unattached_eips.sql
  severity      = "low"
  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })
}

control "vpc_nat_gateway_unused" {
  title         = "Unused NAT gateways should be deleted"
  description   = "NAT gateway are charged on an hourly basis once they are provisioned and available, so unused gateways should be deleted."
  sql           = query.vpc_nat_gateway_unused.sql
  severity      = "low"
  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })
}
