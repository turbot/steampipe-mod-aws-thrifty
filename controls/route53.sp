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
    control.unused_hosted_zone,
    control.unnecessary_health_checks
  ]

  tags = merge(local.route53_common_tags, {
    type = "Benchmark"
  })
}

control "unused_hosted_zone" {
  title       = "Unused hosted zones should be deleted"
  description = "There's a monthly charge for each hosted zone created in Route 53. Be sure to delete only the hosted zones that you don't need."
  sql         = query.unused_hosted_zone.sql
  severity    = "low"
  tags = merge(local.route53_common_tags, {
    class = "unused"
  })
}

control "unnecessary_health_checks" {
  title       = "Unnecessary health checks should be deleted"
  description = "When you associate health checks with an endpoint, health check requests are sent to the endpoint's IP address. These health check requests are sent to validate that the requests are operating as intended. Health check charges are incurred based on their associated endpoints. To avoid health check charges, delete any health checks that aren't used with an RRset record and are no longer required."
  sql         = query.unnecessary_health_checks.sql
  severity    = "low"
  tags = merge(local.route53_common_tags, {
    class = "unused"
  })
}
