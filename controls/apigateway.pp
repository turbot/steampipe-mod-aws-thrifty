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
    control.apigateway_stage_cache_enabled,
    control.apigateway_stage_low_usage
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

control "apigateway_stage_low_usage" {
  title       = "API Gateway stages should be actively used"
  description = "API Gateway stages that haven't been updated in over 90 days may indicate unused resources that could be removed to reduce costs."
  severity    = "low"

  sql = <<-EOQ
    with api_stages as (
      select 
        s.rest_api_id,
        max(s.last_updated_date) as last_stage_update
      from 
        aws_api_gateway_stage s
      group by 
        s.rest_api_id
    )
    select
      a.api_id as resource,
      case
        when s.last_stage_update is null or current_date - s.last_stage_update::date > 90 then 'alarm'
        else 'ok'
      end as status,
      case
        when s.last_stage_update is null then a.name || ' API Gateway has no stages'
        when current_date - s.last_stage_update::date > 90 
          then a.name || ' API Gateway stages have not been updated in ' || (current_date - s.last_stage_update::date) || ' days'
        else a.name || ' API Gateway stages were updated ' || (current_date - s.last_stage_update::date) || ' days ago'
      end as reason,
      a.region,
      a.account_id,
      a._ctx ->> 'connection_name' as connection_name
    from
      aws_api_gateway_rest_api a
      left join api_stages s on a.api_id = s.rest_api_id;
  EOQ

  tags = merge(local.apigateway_common_tags, {
    class = "managed"
    type  = "Cost"
  })
} 