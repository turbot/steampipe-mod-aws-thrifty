locals {
  apigateway_common_tags = {
    service = "AWS/API Gateway"
  }
}

benchmark "apigateway" {
  title         = "API Gateway Cost Checks"
  description   = "Best practices for AWS API Gateway resources."
  documentation = file("./controls/docs/apigateway.md")

  children = [
    control.apigateway_stage_with_caching_disabled
  ]

  tags = merge(local.apigateway_common_tags, {
    type = "Benchmark"
  })
}

control "apigateway_stage_with_caching_disabled" {
  title       = "API Gateway stage with caching disabled"
  description = "API Gateway stages should have caching enabled to improve performance and reduce backend load. Stages without caching may experience higher latency and increased costs."
  severity    = "low"

  tags = merge(local.apigateway_common_tags, {
    class = "capacity_planning"
  })

  sql = <<-EOQ
    select
      rest_api_id as resource,
      case
        when not cache_cluster_enabled or cache_cluster_enabled is null then 'alarm'
        else 'ok'
      end as status,
      case
        when not cache_cluster_enabled or cache_cluster_enabled is null
          then name || ' stage in API Gateway ' || rest_api_id || ' has caching disabled which may impact performance.'
        else name || ' stage in API Gateway ' || rest_api_id || ' has caching enabled.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_api_gateway_stage;
  EOQ
}