locals {
  s3_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/S3"
  })
}

benchmark "s3" {
  title         = "S3 Checks"
  description   = "Thrifty developers ensure their S3 buckets have a managed lifecycle."
  documentation = file("./controls/docs/s3.md")
  children = [
    control.s3_bucket_without_lifecycle
  ]

  tags = merge(local.s3_common_tags, {
    type = "Benchmark"
  })
}

control "s3_bucket_without_lifecycle" {
  title       = "3 buckets without lifecycle policies should be reviewed"
  description = "S3 buckets without lifecycle policies may retain data indefinitely, leading to increased storage costs and potential compliance risks. AWS best practices recommend configuring lifecycle policies to manage object expiration and transitions, ensuring data is retained only as long as necessary. Review and apply appropriate lifecycle policies to all S3 buckets."
  severity    = "low"

  tags = merge(local.s3_common_tags, {
    class = "stale_data"
  })

  sql = <<-EOQ
    select
      arn as resource,
      case
        when lifecycle_rules is null then 'alarm'
        else 'ok'
      end as status,
      case
        when lifecycle_rules is null then name || ' does not have lifecycle policy.'
        else name || ' has a lifecycle policy.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_s3_bucket;
  EOQ
}
