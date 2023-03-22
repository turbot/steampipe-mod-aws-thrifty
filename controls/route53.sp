locals {
  route53_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Route 53"
  })
}

benchmark "route53" {
  title         = "Route 53 Checks"
  description   = "Thrifty developers keep a careful eye on the actual usage of Route 53 service."
  documentation = file("./controls/docs/route53.md")

  children = [
    control.route53_health_check_unused,
    control.route53_record_higher_ttl
  ]

  tags = merge(local.route53_common_tags, {
    type = "Benchmark"
  })
}

control "route53_record_higher_ttl" {
  title       = "Route 53 records should have higher TTL configured"
  description = "If you configure a higher TTL for your records, the intermediate resolvers cache the records for longer time. As a result, there are fewer queries received by the name servers. This configuration reduces the charges corresponding to the DNS queries answered. A value between an hour (3600s) and a day (86,400s) is a common choice."
  severity    = "low"

  tags = merge(local.route53_common_tags, {
    class = "Higher"
  })

  sql = <<-EOQ
    select
      'arn:' || r.partition || ':route53:::hostedzone/' || r.zone_id || '/recordset/' || r.name || '/' || r.type as resource,
      case
        when ttl::int < 3600 then 'alarm'
        else 'ok'
      end as status,
      case
        when ttl::int < 3600 then r.title || ' TTL value is ' || ttl || 's.'
        else r.title || ' TTL value is ' || ttl || 's.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "r.")}
    from
      aws_route53_zone as z,
      aws_route53_record as r
    where
      r.zone_id = z.id;
  EOQ

}

control "route53_health_check_unused" {
  title       = "Unnecessary health checks should be deleted"
  description = "When you associate health checks with an endpoint, health check requests are sent to the endpoint's IP address. These health check requests are sent to validate that the requests are operating as intended. Health check charges are incurred based on their associated endpoints. To avoid health check charges, delete any health checks that aren't used with an RRset record and are no longer required."
  severity    = "low"

  tags = merge(local.route53_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with health_check as (
      select
        r.health_check_id as health_check_id
      from
        aws_route53_zone as z,
        aws_route53_record as r
      where
        r.zone_id = z.id
    )
    select
      'arn:' || h.partition || ':route53:::healthcheck/' || h.id as resource,
      case
        when c.health_check_id is null then 'alarm'
        else 'ok'
      end as status,
      case
        when c.health_check_id is null then h.title || ' is unnecessary.'
        else h.title || ' is necessary.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_route53_health_check as h
      left join health_check as c on h.id = c.health_check_id;
  EOQ
}
