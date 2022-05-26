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
    control.longer_record_ttl,
    control.unnecessary_health_check,
    control.unhealthy_resolver_endpoint
  ]

  tags = merge(local.route53_common_tags, {
    type = "Benchmark"
  })
}

control "longer_record_ttl" {
  title       = "Higher TTL should be configured"
  description = "If you configure a higher TTL for your records, the intermediate resolvers cache the records for longer time. As a result, there are fewer queries received by the name servers. This configuration reduces the charges corresponding to the DNS queries answered."
  sql         = query.longer_record_ttl.sql
  severity    = "low"
  tags = merge(local.route53_common_tags, {
    class = "Higher"
  })
}

control "unnecessary_health_check" {
  title       = "Unnecessary health checks should be deleted"
  description = "When you associate health checks with an endpoint, health check requests are sent to the endpoint's IP address. These health check requests are sent to validate that the requests are operating as intended. Health check charges are incurred based on their associated endpoints. To avoid health check charges, delete any health checks that aren't used with an RRset record and are no longer required."
  sql         = query.unnecessary_health_check.sql
  severity    = "low"
  tags = merge(local.route53_common_tags, {
    class = "unused"
  })
}

control "unhealthy_resolver_endpoint" {
  title       = "Resolver endpoint should not be in unhealthy state"
  description = "A Route 53 Resolver endpoint requires two or more IP addresses. Each IP address corresponds with one elastic network interface. Elastic network interfaces are charged at a rate of $0.125 per hour, per interface."
  sql         = query.unhealthy_resolver_endpoint.sql
  severity    = "low"
  tags = merge(local.route53_common_tags, {
    class = "unhealthy"
  })
}
