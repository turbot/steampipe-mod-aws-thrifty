// Benchmarks and controls for specific services should override the "service" tag
locals {
  aws_thrifty_common_tags = {
    category = "Cost"
    plugin   = "aws"
    service  = "AWS"
  }
}

variable "common_dimensions" {
  type        = list(string)
  description = "A list of common dimensions to add to each control."
  # Define which common dimensions should be added to each control.
  # - account_id
  # - connection_name (_ctx ->> 'connection_name')
  # - region
  default = ["account_id", "region"]
}

variable "tag_dimensions" {
  type        = list(string)
  description = "A list of tags to add as dimensions to each control."
  # A list of tag names to include as dimensions for resources that support
  # tags (e.g. "Owner", "Environment"). Default to empty since tag names are
  # a personal choice - for commonly used tag names see
  # https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html#tag-categories
  default = []
}

locals {

  # Local internal variable to build the SQL select clause for common
  # dimensions using a table name qualifier if required. Do not edit directly.
  common_dimensions_qualifier_sql = <<-EOQ
  %{~if contains(var.common_dimensions, "connection_name")}, __QUALIFIER___ctx ->> 'connection_name' as connection_name%{endif~}
  %{~if contains(var.common_dimensions, "region")}, __QUALIFIER__region%{endif~}
  %{~if contains(var.common_dimensions, "account_id")}, __QUALIFIER__account_id%{endif~}
  EOQ

  # Local internal variable to build the SQL select clause for tag
  # dimensions. Do not edit directly.
  tag_dimensions_qualifier_sql = <<-EOQ
  %{~for dim in var.tag_dimensions},  __QUALIFIER__tags ->> '${dim}' as "${replace(dim, "\"", "\"\"")}"%{endfor~}
  EOQ

}

locals {

  # Local internal variable with the full SQL select clause for common
  # dimensions. Do not edit directly.
  common_dimensions_sql = replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "")
  tag_dimensions_sql    = replace(local.tag_dimensions_qualifier_sql, "__QUALIFIER__", "")

}

mod "aws_thrifty" {
  # hub metadata
  title         = "AWS Thrifty"
  description   = "Are you a Thrifty AWS developer? This Steampipe mod checks your AWS account(s) for unused and under utilized resources."
  color         = "#FF9900"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/aws-thrifty.svg"
  categories    = ["aws", "cost", "thrifty", "public cloud"]

  opengraph {
    title       = "Thrifty mod for AWS"
    description = "Are you a Thrifty AWS dev? This Steampipe mod checks your AWS account(s) for unused and under-utilized resources."
    image       = "/images/mods/turbot/aws-thrifty-social-graphic.png"
  }

  require {
    plugin "aws" {
      min_version = "0.112.0"
    }
  }
}
