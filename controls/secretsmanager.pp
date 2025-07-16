variable "secretsmanager_secret_last_used" {
  type        = number
  description = "The default number of days Secrets Manager secrets to be considered in-use."
  default     = 90
}

locals {
  secretsmanager_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Secrets Manager"
  })
}

benchmark "secretsmanager" {
  title         = "Secrets Manager Cost Checks"
  description   = "Thrifty developers ensure their Secrets Manager secret is in use."
  documentation = file("./controls/docs/secretsmanager.md")

  children = [
    control.secretsmanager_secret_unused
  ]

  tags = merge(local.secretsmanager_common_tags, {
    type = "Benchmark"
  })
}

control "secretsmanager_secret_unused" {
  title       = "Unused Secrets Manager secrets should be removed"
  description = "Secrets stored in AWS Secrets Manager that have not been accessed for an extended period may be obsolete or no longer required. Retaining unused secrets increases costs and the risk of credential sprawl. Review and remove secrets that have not been accessed within the defined threshold to optimize security and reduce unnecessary expenses."
  severity    = "low"

  tags = merge(local.secretsmanager_common_tags, {
    class = "unused"
  })

  param "secretsmanager_secret_last_used" {
    description = "The specified number of days since Secrets Manager secret last used."
    default     = var.secretsmanager_secret_last_used
  }

  sql = <<-EOQ
    with secret_pricing as (
      select
        arn,
        title,
        last_accessed_date,
        region,
        account_id,
        tags,
        _ctx,
        case
          when date_part('day', now()-last_accessed_date) < $1 then ''
          else '0.04 USD /month'
        end as net_savings
      from
        aws_secretsmanager_secret
    )
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
      ${local.common_dimensions_savings_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      secret_pricing;
  EOQ

}
