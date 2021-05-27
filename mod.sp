mod "aws_thrifty" {
  # hub metadata
  title         = "AWS Thrifty"
  description   = "Are you a Thrifty AWS developer? This Steampipe mod checks your AWS account(s) to check for unused and under utilized resources."
  color         = "#FF9900"
  documentation = file("./docs/index.md")
  #icon          = "/images/mods/turbot/aws-thrifty.svg"
  categories    = ["AWS", "Cost"]

  opengraph {
    title         = "AWS Thrifty"
    description   = "Economy and good management checks for AWS"
    image        = "/images/mods/turbot/aws-compliance-social-graphic.png"
  }
}
