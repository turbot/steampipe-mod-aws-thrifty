locals {
  vpc_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/VPC"
  })
}

benchmark "network" {
  title         = "Networking Checks"
  description   = "Thrifty developers ensure delete unused network resources."
  documentation = file("./controls/docs/network.md")

  children = [
    control.unattached_eips,
    control.vpc_nat_gateway_unused
  ]

  tags = merge(local.vpc_common_tags, {
    type = "Benchmark"
  })
}

control "unattached_eips" {
  title         = "Unattached elastic IP addresses (EIPs) should be released"
  description   = "Unattached Elastic IPs are charged by AWS, they should be released."
  severity      = "low"

  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    select
      'arn:' || partition || ':ec2:' || region || ':' || account_id || ':eip/' || allocation_id as resource,
      case
        when association_id is null then 'alarm'
        else 'ok'
      end as status,
      case
        when association_id is null then public_ip || ' has no association.'
        else public_ip || ' associated with ' || private_ip_address || '.'
      end as reason
      ${local.common_dimensions_sql}
    from
      aws_vpc_eip;
  EOQ

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
