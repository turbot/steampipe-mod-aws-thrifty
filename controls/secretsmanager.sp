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
  title         = "Secrets Manager Cost Checks"
  description   = "Thrifty developers ensure their secretsmanager secret is in use."
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
  description = "Secrets Manager secrets should be accessed within a specified number of days. The default value is 90 days."
  sql         = query.secretsmanager_secret_unused.sql
  severity    = "low"

  param "secretsmanager_secret_last_used" {
    description = "The specified number of days since secrets manager secret last used."
    default     = var.secretsmanager_secret_last_used
  }

  tags = merge(local.secretsmanager_common_tags, {
    class = "unused"
  })
}
