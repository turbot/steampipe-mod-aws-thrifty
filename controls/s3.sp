locals {
  s3_common_tags = merge(local.thrifty_common_tags, {
    service = "s3"
  })
}

benchmark "s3" {
  title         = "Thrifty S3 Checks"
  description   = "Thrifty developers ensure their S3 buckets have managed life-cycles."
  documentation = file("./controls/docs/s3.md") #TODO
  tags          = local.s3_common_tags
  children = [
    control.buckets_with_no_life_cycle
  ]
}

control "buckets_with_no_life_cycle" {
  title         = "S3 Buckets with no life cycle policy"
  description   = "S3 Buckets should have a life cycle policy associated for data retention."
  documentation = file("./controls/docs/s3-1.md") #TODO
  sql           = query.s3_bucket_without_lifecycle.sql
  severity      = "low"
  tags = merge(local.s3_common_tags, {
    code = "managed"
  })
}
