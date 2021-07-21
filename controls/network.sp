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
    control.unused_vpc_nat_gateways
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

control "unused_vpc_nat_gateways" {
  title         = "Unused NAT gateways should be reviewed"
  description   = "NAT Gateway is charged on an hourly basis once it is provisioned and available, check why these are available but not used."
  sql           = query.vpc_nat_gateway_unused.sql
  severity      = "low"
  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })
}
