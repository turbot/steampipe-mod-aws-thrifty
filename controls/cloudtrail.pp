locals {
  cloudtrail_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/CloudTrail"
  })
}

benchmark "cloudtrail" {
  title         = "CloudTrail Cost Checks"
  description   = "Thrifty developers know that multiple active CloudTrail Trails can add significant costs. Be thrifty and eliminate the extra trails. One trail to rule them all."
  documentation = file("./controls/docs/cloudtrail.md")

  children = [
    control.cloudtrail_trail_global_multiple,
    control.cloudtrail_trail_regional_multiple
  ]

  tags = merge(local.cloudtrail_common_tags, {
    type = "Benchmark"
  })
}

control "cloudtrail_trail_global_multiple" {
  title       = "Multiple global CloudTrail trails should not exist"
  description = "AWS best practices recommend having only one global CloudTrail trail per account. Additional global trails can increase costs and may lead to redundant or conflicting logging configurations. Ensure that only a single global trail is enabled unless there is a specific compliance or operational requirement for more."
  severity    = "low"

  tags = merge(local.cloudtrail_common_tags, {
    class = "overused"
  })

  sql = <<-EOQ
    with global_trails as (
      select
        account_id,
        count(*) as total
      from
        aws_cloudtrail_trail
      where
        is_multi_region_trail and region = home_region
      group by
        account_id,
        is_multi_region_trail
    )
    select
      arn as resource,
      case
        when total > 1 then 'alarm'
        else 'ok'
      end as status,
      case
        when total > 1 then name || ' is one of ' || total || ' global trails.'
        else name || ' is the only global trail.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "t.")}
    from
      aws_cloudtrail_trail as t,
      global_trails
    where
      is_multi_region_trail
      and region = home_region;
  EOQ
}

control "cloudtrail_trail_regional_multiple" {
  title       = "ultiple regional CloudTrail trails should not exist"
  description = "AWS best practices recommend having only one regional CloudTrail trail per region. Additional regional trails can increase costs and may result in redundant or conflicting logging configurations. Ensure that only a single regional trail is enabled in each region unless there is a specific compliance or operational requirement for more."
  severity    = "low"

  tags = merge(local.cloudtrail_common_tags, {
    class = "overused"
  })

  sql = <<-EOQ
    with
      global_trails as (
        select
          count(*) as total
        from
          aws_cloudtrail_trail
        where
          is_multi_region_trail
      ),
      org_trails as (
        select
          count(*) as total
        from
          aws_cloudtrail_trail
        where
          is_organization_trail
      ),
      regional_trails as (
        select
          region,
          count(*) as total
        from
          aws_cloudtrail_trail
        where
          not is_multi_region_trail
          and not is_organization_trail
        group by
          region
      )
    select
      arn as resource,
      case
        when global_trails.total > 0 then 'alarm'
        when org_trails.total > 0 then 'alarm'
        when regional_trails.total > 1 then 'alarm'
        else 'ok'
      end as status,
      case
        when global_trails.total > 0 then name || ' is redundant to a global trail.'
        when org_trails.total > 0 then name || ' is redundant to a organizational trail.'
        when regional_trails.total > 1 then name || ' is one of ' || regional_trails.total || ' trails in ' || t.region || '.'
        else name || ' is the only global trail.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "t.")}
    from
      aws_cloudtrail_trail t,
      global_trails,
      org_trails,
      regional_trails
    where
      regional_trails.region = t.region
      and not is_multi_region_trail
      and not is_organization_trail;
  EOQ
}
