locals {
  route53_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Route 53"
  })
}

benchmark "route53" {
  title         = "Route 53 Checks"
  description   = "Thrifty developers keep a careful eye on the actual usage of Route 53 service."
  documentation = file("./thrifty/docs/route53.md")
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
  sql         = query.route53_record_higher_ttl.sql
  severity    = "low"

  tags = merge(local.route53_common_tags, {
    class = "capacity_planning"
  })
}

control "route53_health_check_unused" {
  title       = "Unnecessary health checks should be deleted"
  description = "When you associate health checks with an endpoint, health check requests are sent to the endpoint's IP address. These health check requests are sent to validate that the requests are operating as intended. Health check charges are incurred based on their associated endpoints. To avoid health check charges, delete any health checks that aren't used with an RRset record and are no longer required."
  sql         = query.route53_health_check_unused.sql
  severity    = "low"
  
  tags = merge(local.route53_common_tags, {
    class = "unused"
  })
}

