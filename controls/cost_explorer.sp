variable "cost_explorer_service_cost_max_cost_units" {
  type        = number
  description = "The maximum difference in cost units allowed for service costs between the current and previous month."
  default     = 10
}

locals {
  cost-explorer_common_tags = merge(local.thrifty_common_tags, {
    service = "cost-explorer"
  })
}

benchmark "cost-explorer" {
  title         = "Cost Explorer Checks"
  description   = "Thrifty developers actively monitor their cloud usage and cost data."
  documentation = file("./controls/docs/cost-explorer.md")
  tags          = local.cost-explorer_common_tags
  children = [
    control.full_month_cost_changes
  ]
}

control "full_month_cost_changes" {
  title         = "What services have changed in cost over last two months?"
  description   = "Compares the cost of services between the last two full months of AWS usage."
  sql           = query.monthly_service_cost_changes.sql
  severity      = "low"

  param "cost_explorer_service_cost_max_cost_units" {
    description = "The maximum difference in cost units allowed for service costs between the current and previous month."
    default     = var.cost_explorer_service_cost_max_cost_units
  }

  tags = merge(local.cost-explorer_common_tags, {
    class = "managed"
  })
}
