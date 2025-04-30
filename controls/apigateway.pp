locals {
  apigateway_common_tags = {
    service = "AWS/API Gateway"
  }
}

benchmark "apigateway" {
  title         = "API Gateway Checks"
  description   = "Best practices for AWS API Gateway resources."
  documentation = file("./controls/docs/apigateway.md")

  children = [
    control.apigateway_stage_cache_enabled
  ]

  tags = merge(local.apigateway_common_tags, {
    type = "Benchmark"
  })
}

control "apigateway_stage_cache_enabled" {
  title       = "API Gateway stages should have caching enabled"
  description = "API Gateway stages should have caching enabled to improve performance and reduce backend load."
  severity    = "low"

  sql = <<-EOQ
    select 
      rest_api_id as resource,
      case
        when not cache_cluster_enabled or cache_cluster_enabled is null then 'alarm'
        else 'ok'
      end as status,
      case
        when not cache_cluster_enabled or cache_cluster_enabled is null 
          then name || ' stage in API Gateway ' || rest_api_id || ' has caching disabled.'
        else name || ' stage in API Gateway ' || rest_api_id || ' has caching enabled.'
      end as reason,
      region,
      account_id,
      arn,
      _ctx ->> 'connection_name' as connection_name
    from 
      aws_api_gateway_stage;
  EOQ

  tags = merge(local.apigateway_common_tags, {
    class = "managed"
    type  = "Performance"
  })
} 