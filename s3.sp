
control "buckets_with_no_life_cycle" {
  title = "S3 Buckets with no life cycle policy"
  description = "S3 Buckets should have a life cycle policy associated for data retention."
  sql = query.s3_bucket_without_lifecycle.sql
  severity = "low"
  tags = {
    service = "s3"
    code = "managed"
  }
}