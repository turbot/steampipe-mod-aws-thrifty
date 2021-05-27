locals {
  vpc_common_tags = merge(local.thrifty_common_tags, {
    service = "vpc"
  })
}

benchmark "network" {
  title         = "Thrifty Networking Checks"
  description   = "Thrifty developers ensure delete unused network resources."
  documentation = file("./controls/docs/network.md") #TODO
  tags          = local.vpc_common_tags
  children = [
    control.unattached_eips
  ]
}

control "unattached_eips" {
  title         = "Unattached Elastic IP addresses (EIP)"
  description   = "Unattached Elastic IPs are charged by AWS, they should be released."
  sql           = query.unattached_eips.sql
  severity      = "low"
  tags = merge(local.vpc_common_tags, {
    code = "unused"
  })
}

//TODO Add unattached Gateways
