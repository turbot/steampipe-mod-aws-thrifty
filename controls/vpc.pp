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
  title       = "Unused VPC NAT gateways should be removed"
  description = "NAT gateways incur hourly charges as long as they are provisioned and available, regardless of actual usage. Unused NAT gateways can lead to unnecessary costs. Review and remove NAT gateways that are not actively in use to optimize network resources and reduce expenses."
  severity    = "low"

  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    select
      nat.arn as resource,
      case
        when nat.state <> 'available' then 'alarm'
        when nat.subnet_id is null then 'alarm'
        when instance_state <> 'running' then 'alarm'
        else 'ok'
      end as status,
      case
        when nat.state <> 'available' then nat.title || ' in ' || nat.state || ' state.'
        when nat.subnet_id is null then nat.title || ' not in-use.'
        when instance_state <> 'running' then nat.title || ' associated with ' || i.instance_id || ', which is in ' ||  instance_state || ' state.'
        else nat.title || ' in-use.'
      end as reason
      ${replace(local.tag_dimensions_qualifier_sql, "__QUALIFIER__", "nat.")}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "nat.")}
    from
      aws_vpc_nat_gateway as nat
      left join aws_ec2_instance as i on nat.subnet_id = i.subnet_id;
  EOQ
}
