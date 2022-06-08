variable "cost_explorer_service_cost_max_cost_units" {
  type        = number
  description = "The maximum difference in cost units allowed for service costs between the current and previous month."
  default     = 10
}

variable "cost_explorer_forecast_cost_max_cost_units" {
  type        = number
  description = "The maximum difference in cost units allowed between the current month's forecast and previous month's cost."
  default     = 10
}

locals {
  cost_variance_common_tags = merge(local.aws_thrifty_common_tags, {
    cost_variance = "true"
  })
}

benchmark "cost_variance" {
  title         = "Cost Variance"
  description   = "."
  documentation = file("./thrifty/docs/cost_variance.md")
  children = [
    control.cost_explorer_full_month_cost_changes,
    control.cost_explorer_full_month_forecast_cost_changes
  ]

  tags = merge(local.cost_variance_common_tags, {
    type = "Benchmark"
  })
}

control "cost_explorer_full_month_cost_changes" {
  title       = "What services have changed in cost over last two months?"
  description = "Compares the cost of services between the last two full months of AWS usage."
  sql         = query.cost_explorer_full_month_cost_changes.sql
  severity    = "low"

  param "cost_explorer_service_cost_max_cost_units" {
    description = "The maximum difference in cost units allowed for service costs between the current and previous month."
    default     = var.cost_explorer_service_cost_max_cost_units
  }

  tags = merge(local.cost_variance_common_tags, {
    service = "AWS/CostExplorer"
  })
}

control "cost_explorer_full_month_forecast_cost_changes" {
  title       = "What is the forecasted monthly cost compared to last month's cost?"
  description = "Compares the current month's forecasted cost with last month's cost."
  sql         = query.cost_explorer_full_month_forecast_cost_changes.sql
  severity    = "low"

  param "cost_explorer_forecast_cost_max_cost_units" {
    description = "The maximum difference in cost units allowed between the current month's forecast and previous month's cost."
    default     = var.cost_explorer_forecast_cost_max_cost_units
  }

  tags = merge(local.cost_variance_common_tags, {
    service = "AWS/CostExplorer"
  })
}
