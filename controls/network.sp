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
    ),
    eip_pricing_daily as (
      select
        24*eip_price_hrs as daily_price,
        currency
      from
        eip_pricing
    )
    select
      'arn:' || partition || ':ec2:' || region || ':' || account_id || ':eip/' || allocation_id as resource,
      case
        when association_id is null then 'alarm'
        else 'ok'
      end as status,
      case
        when association_id is null then public_ip || ' has no association ' || '(' || (daily_price) || ' ' || currency || '/day ▲).'
        else public_ip || ' associated with ' || private_ip_address || '.'
      end as reason
      ${local.common_dimensions_sql}
    from
      aws_vpc_eip,
      eip_pricing_daily
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
    ),nat_gateway_pricing as (
      select
        r.region,
        p.price_per_unit::numeric as alb_price_hrs
      from
        aws_pricing_product as p
        join nat_gateway_regions as r on
          p.service_code = 'AmazonEC2'
          and p.filters = '{
            "operation": "NatGateway",
            "usagetype": "NatGateway-Hours"
          }' :: jsonb
          and p.attributes ->> 'regionCode' = r.region
      group by r.region, p.price_per_unit
    ), nat_gateway_pricing_daily as (
      select
        24*alb_price_hrs as daily_price
      from
        nat_gateway_pricing
    ), target_resource as (
      select
        load_balancer_arn,
        target_health_descriptions,
        target_type
      from
        aws_ec2_target_group,
        jsonb_array_elements_text(load_balancer_arns) as load_balancer_arn
    ), instance_data as (
      select
        instance_id,
        subnet_id,
        instance_state
      from
        aws_ec2_instance
    )
    select
      nat.arn as resource,
      case
        when nat.state <> 'available' then 'alarm'
        when i.subnet_id is null then 'alarm'
        when i.instance_state <> 'running' then 'alarm'
        else 'ok'
      end as status,
      case
        when nat.state <> 'available' then nat.title || ' in ' || nat.state || ' state.'
        when i.subnet_id is null then nat.title || ' not in-use. You can save $' ||  (select daily_price from nat_gateway_pricing_daily) || ' daily by deleting it.'
        when i.instance_state <> 'running' then nat.title || ' associated with ' || i.instance_id || ', which is in ' || i.instance_state || ' state.'
        else nat.title || ' in-use.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "nat.")}
    from
      aws_vpc_nat_gateway as nat
      left join instance_data as i on nat.subnet_id = i.subnet_id;
  EOQ
}
