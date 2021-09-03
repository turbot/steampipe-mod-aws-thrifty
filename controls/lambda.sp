locals {
  lambda_common_tags = merge(local.thrifty_common_tags, {
    service = "lambda"
  })
}

benchmark "lambda" {
  title         = "Lambda Checks"
  description   = "Thrifty developers ensure their Lambda functions are optimized."
  documentation = file("./controls/docs/lambda.md")
  tags          = local.lambda_common_tags
  children = [    
    control.lambda_excessive_timeout,
    control.lambda_high_error_rate
  ]
}

control "lambda_high_error_rate" {
  title         = "Are there any lambda functions with high error rate?"
  description   = "Function errors may result in retries that incur extra charges."
  sql           = query.high_error_rate.sql
  severity      = "low"
  tags = merge(local.lambda_common_tags, {
    class = "managed"
  })
}

control "lambda_excessive_timeout" {
  title         = "Are there any lambda functions with high timout?"
  description   = "Excessive timeouts result in retries and additional execution time for the function, incurring request charges and billed duration."
  sql           = query.excessive_timout.sql
  severity      = "low"
  tags = merge(local.lambda_common_tags, {
    class = "managed"
  })
}
