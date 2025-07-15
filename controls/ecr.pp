variable "ecr_repository_image_age_max_days" {
  type        = number
  description = "The number of days an ECR repository can go without image pulls before being considered unused."
  default     = 90
}

locals {
  ecr_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/ECR"
  })
}

benchmark "ecr" {
  title         = "ECR Checks"
  description   = "Thrifty developers eliminate unused ECR repository images."
  documentation = file("./controls/docs/ecr.md")
  children = [
    control.ecr_repository_image_unused
  ]

  tags = merge(local.ecr_common_tags, {
    type = "Benchmark"
  })
}

control "ecr_repository_image_unused" {
  title       = "ECR repositories with unused images should be reviewed"
  description = "ECR repositories containing images that have not been pulled for an extended period may indicate obsolete or unused resources. Retaining unused images increases storage costs and can lead to repository clutter. Regularly review and remove images that have not been pulled within the defined threshold to optimize storage usage and reduce costs."
  severity    = "low"

  tags = merge(local.ecr_common_tags, {
    class = "unused"
  })

  sql = <<-EOQ
    with latest_pulls as (
      select
        repository_name,
        max(last_recorded_pull_time) as last_pull
      from
        aws_ecr_image
      group by
        repository_name
    )
    select
      r.arn as resource,
      case
        when i.last_pull is null then 'alarm'
        when i.last_pull < (current_timestamp - interval '${var.ecr_repository_image_age_max_days} days') then 'alarm'
        else 'ok'
      end as status,
      case
        when i.last_pull is null then r.title || ' has no images that have ever been pulled.'
        when i.last_pull < (current_timestamp - interval '${var.ecr_repository_image_age_max_days} days') then r.title || ' has not had any images pulled in the last ${var.ecr_repository_image_age_max_days} days. Last pull was on ' || to_char(i.last_pull, 'YYYY-MM-DD')
        else r.title || ' has had images pulled within the last ${var.ecr_repository_image_age_max_days} days. Last pull was on ' || to_char(i.last_pull, 'YYYY-MM-DD')
      end as reason,
      r.region,
      r.account_id
    from
      aws_ecr_repository r
      left join latest_pulls i on r.repository_name = i.repository_name;
  EOQ
}