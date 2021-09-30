locals {
  s3_common_tags = merge(local.thrifty_common_tags, {
    service = "s3"
  })
}

benchmark "s3" {
  title         = "S3 Checks"
  description   = "Thrifty developers ensure their S3 buckets have a managed lifecycle."
  documentation = file("./controls/docs/s3.md")
  tags          = local.s3_common_tags
  children = [
    control.buckets_with_no_lifecycle
  ]
}

control "buckets_with_no_lifecycle" {
  title         = "Buckets should have lifecycle policies"
  description   = "S3 Buckets should have a lifecycle policy associated for data retention."
  sql           = query.s3_bucket_without_lifecycle.sql
  severity      = "low"
  tags = merge(local.s3_common_tags, {
    class = "managed"
  })
}
