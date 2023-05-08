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
  title       = "Unattached elastic IP addresses (EIPs) should be released"
  description = "Unattached Elastic IPs are charged by AWS, they should be released."
  severity    = "low"

  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with eip_regions as (
      select
        distinct region
      from
        aws_vpc_eip
    ),eip_pricing as (
      select
        r.region,
        p.currency as currency,
        p.price_per_unit::numeric as eip_price_hrs
      from
        aws_pricing_product as p
        join eip_regions as r on
          p.service_code = 'AmazonEC2'
          and p.filters = '{
            "group": "ElasticIP:Address",
            "usagetype": "ElasticIP:IdleAddress"
          }' :: jsonb
          and p.attributes ->> 'regionCode' = r.region
        where
        p.begin_range = '1'
      group by r.region, p.price_per_unit, p.currency
    ), eip_pricing_monthly as (
      select
        case when association_id is null then 30*24*eip_price_hrs else 0.0 end as net_savings,
        currency,
        e.arn,
        e.tags,
        e.account_id,
        e.region,
        e.association_id,
        e.title,
        e.private_ip_address,
        e.public_ip
      from
        aws_vpc_eip as e,
        eip_pricing
    )
    select
      arn as resource,
      case
        when association_id is null then 'alarm'
        else 'ok'
      end as status,
      case
        when association_id is null then public_ip || ' has no association.'
        else public_ip || ' associated with ' || private_ip_address || '.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.common_dimensions_sql}
    from
      eip_pricing_monthly
  EOQ

}

control "vpc_nat_gateway_unused" {
  title       = "Unused NAT gateways should be deleted"
  description = "NAT gateway are charged on an hourly basis once they are provisioned and available, so unused gateways should be deleted."
  severity    = "low"
  tags = merge(local.vpc_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with nat_gateway_regions as (
      select
        distinct region
      from
        aws_vpc_nat_gateway
    ),
    nat_gateway_pricing as (
      select
        r.region,
        p.price_per_unit::numeric as alb_price_hrs,
        p.currency
      from
        aws_pricing_product as p
        join nat_gateway_regions as r on
          p.service_code = 'AmazonEC2'
          and p.filters = '{
            "operation": "NatGateway",
            "usagetype": "NatGateway-Hours"
          }' :: jsonb
          and p.attributes ->> 'regionCode' = r.region
      group by r.region, p.price_per_unit, p.currency
    ), nat_gateway_pricing_monthly as (
      select
        case when nat.state = 'available' and i.subnet_id is null then  30*24*alb_price_hrs else 0.0 end as net_savings,
        instance_id,
        currency,
        i.subnet_id,
        i.instance_state,
        nat.arn,
        nat.region,
        nat.account_id,
        nat.title,
        nat.state
      from
        aws_vpc_nat_gateway as nat
        left join aws_ec2_instance as i on nat.subnet_id = i.subnet_id,
        nat_gateway_pricing
    )
    select
      arn as resource,
      case
        when state <> 'available' then 'alarm'
        when subnet_id is null then 'alarm'
        when instance_state <> 'running' then 'alarm'
        else 'ok'
      end as status,
      case
        when state <> 'available' then title || ' in ' || state || ' state.'
        when subnet_id is null then title || ' not in-use.'
        when instance_state <> 'running' then title || ' associated with ' || instance_id || ', which is in ' ||  instance_state || ' state.'
        else title || ' in-use.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      nat_gateway_pricing_monthly
  EOQ
}
