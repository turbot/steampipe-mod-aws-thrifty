mod "aws_thrifty" {
  # Hub metadata
  title         = "AWS Thrifty "
  description   = "Are you a Thrifty AWS developer? This mod checks your AWS account(s) for unused and under utilized resources using Powerpipe and Steampipe."
  color         = "#FF9900"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/aws-thrifty.svg"
  categories    = ["aws", "cost", "thrifty", "public cloud"]

  opengraph {
    title       = "Powerpipe Mod for AWS Thrifty"
    description = "Are you a Thrifty AWS developer? This mod checks your AWS account(s) for unused and under utilized resources using Powerpipe and Steampipe."
    image       = "/images/mods/turbot/aws-thrifty-social-graphic.png"
  }

  require {
    plugin "aws" {
      min_version = "0.112.0"
    }
  }
}
