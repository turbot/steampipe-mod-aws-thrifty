locals {
  route53_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Route 53"
  })
}

benchmark "route53" {
  title         = "Route 53 Cost Controls"
  description   = "Thrifty developers keep a careful eye on the actual usage of Route 53 service."
  documentation = file("./controls/docs/route53.md")

  children = [
    control.route53_health_check_unused,
    control.route53_record_lower_ttl
  ]

  tags = merge(local.route53_common_tags, {
    type = "Benchmark"
  })
}

control "route53_record_lower_ttl" {
  title       = "Route 53 records with low TTL values should be reviewed"
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
  title       = "Unused Route 53 health checks should be removed"
  description = "Route 53 health checks that are not associated with any DNS records or endpoints may be obsolete and can incur unnecessary charges. Regularly review and delete unused health checks to optimize costs and maintain a clean DNS environment."
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
      'arn:' || partition || ':route53:::healthcheck/' || id as resource,
      case
        when health_check_id is null then 'alarm'
        else 'ok'
      end as status,
      case
        when health_check_id is null then title || ' is unnecessary.'
        else title || ' is necessary.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_route53_health_check as h
      left join health_check as c on h.id = c.health_check_id;
  EOQ
}
