locals {
  cloudtrail_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/CloudTrail"
  })
}

benchmark "cloudtrail" {
  title         = "CloudTrail Checks"
  description   = "Thrifty developers know that multiple active CloudTrail Trails can add significant costs. Be thrifty and eliminate the extra trails. One trail to rule them all."
  documentation = file("./controls/docs/cloudtrail.md")

  children = [
    control.multiple_global_trails,
    control.multiple_regional_trails
  ]

  tags = merge(local.cloudtrail_common_tags, {
    type = "Benchmark"
  })
}

control "multiple_global_trails" {
  title       = "Are there redundant global CloudTrail trails?"
  description = "Your first cloudtrail in each account is free, additional trails are expensive."
  severity    = "low"

  tags = merge(local.cloudtrail_common_tags, {
    class = "managed"
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

control "multiple_regional_trails" {
  title       = "Are there redundant regional CloudTrail trails?"
  description = "Your first cloudtrail in each region is free, additional trails are expensive."
  severity    = "low"

  tags = merge(local.cloudtrail_common_tags, {
    class = "managed"
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
