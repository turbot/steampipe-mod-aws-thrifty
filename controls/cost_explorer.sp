
control "full_month_cost_changes" {
  title = "Services that have changed in cost over last two months."
  description = "Compares the cost of services between the last two full months of AWS usage."
  sql = query.monthly_service_cost_changes.sql
  severity = "low"
  tags = {
    service = "cost-explorer"
    code = "managed"
  }
}
