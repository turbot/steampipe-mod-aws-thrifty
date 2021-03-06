variable "cost_explorer_service_cost_max_cost_units" {
  type        = number
  description = "The maximum difference in cost units allowed for service costs between the current and previous month."
  default     = 10
}

locals {
  cost_explorer_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/CostExplorer"
  })
}

benchmark "cost_explorer" {
  title         = "Cost Explorer Checks"
  description   = "Thrifty developers actively monitor their cloud usage and cost data."
  documentation = file("./controls/docs/cost-explorer.md")
  children = [
    control.full_month_cost_changes
  ]

  tags = merge(local.cost_explorer_common_tags, {
    type = "Benchmark"
  })
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

  tags = merge(local.cost_explorer_common_tags, {
    class = "managed"
  })
}
