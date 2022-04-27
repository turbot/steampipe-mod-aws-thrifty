locals {
  lambda_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Lambda"
  })
}

benchmark "lambda" {
  title         = "Lambda Checks"
  description   = "Thrifty developers ensure their Lambda functions are optimized."
  documentation = file("./controls/docs/lambda.md")
  children = [    
    control.lambda_function_excessive_timeout,
    control.lambda_function_high_error_rate
  ]

  tags = merge(local.lambda_common_tags, {
    type = "Benchmark"
  })
}

control "lambda_function_high_error_rate" {
  title         = "Are there any lambda functions with high error rate?"
  description   = "Function errors may result in retries that incur extra charges. The control checks for functions with an error rate of more than 10% a day in one of the last 7 days."
  sql           = query.lambda_function_high_error_rate.sql
  severity      = "low"
  tags = merge(local.lambda_common_tags, {
    class = "managed"
  })
}

control "lambda_function_excessive_timeout" {
  title         = "Are there any lambda functions with excessive timeout?"
  description   = "Excessive timeouts result in retries and additional execution time for the function, incurring request charges and billed duration. The control checks for functions with a timeout rate of more than 10% a day in one of the last 7 days."
  sql           = query.lambda_function_excessive_timeout.sql
  severity      = "low"
  tags = merge(local.lambda_common_tags, {
    class = "managed"
  })
}
