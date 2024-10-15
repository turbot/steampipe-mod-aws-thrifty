variable "secretsmanager_secret_last_used" {
  type        = number
  description = "The default number of days secrets manager secrets to be considered in-use."
  default     = 90
}

locals {
  secretsmanager_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Secrets Manager"
  })
}

benchmark "secretsmanager" {
  title         = "Secrets Manager Checks"
  description   = "Thrifty developers ensure their secrets manager secret is in use."
  documentation = file("./controls/docs/secretsmanager.md")

  children = [
    control.secretsmanager_secret_unused
  ]

  tags = merge(local.secretsmanager_common_tags, {
    type = "Benchmark"
  })
}

control "secretsmanager_secret_unused" {
  title       = "Unused Secrets Manager secrets should be deleted"
  description = "AWS Secrets Manager secrets should be accessed within a specified number of days. The default value is 90 days."
  severity    = "low"

  tags = merge(local.secretsmanager_common_tags, {
    class = "unused"
  })

  param "secretsmanager_secret_last_used" {
    description = "The specified number of days since secrets manager secret last used."
    default     = var.secretsmanager_secret_last_used
  }

  sql = <<-EOQ
    select
      arn as resource,
      case
        when date_part('day', now()-last_accessed_date) < $1 then 'ok'
        else 'alarm'
      end as status,
      case
        when last_accessed_date is null then title || ' is never used.'
        else title || ' is last used ' || age(current_date, last_accessed_date) || ' ago.'
      end as reason
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      aws_secretsmanager_secret;
  EOQ

}
