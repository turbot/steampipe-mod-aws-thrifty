locals {
  lambda_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Lambda"
  })
}

benchmark "lambda" {
  title         = "Lambda Cost Checks"
  description   = "Thrifty developers ensure their Lambda functions are optimized."
  documentation = file("./controls/docs/lambda.md")
  children = [
    control.lambda_function_excessive_timeout,
    control.lambda_function_high_error_rate,
    control.lambda_function_with_graviton2
  ]

  tags = merge(local.lambda_common_tags, {
    type = "Benchmark"
  })
}

control "lambda_function_high_error_rate" {
  title       = "Lambda functions with high error rate should be reviewed"
  description = "Function errors may result in retries that incur extra charges. The control checks for functions with an error rate of more than 10% a day in one of the last 7 days."
  sql         = query.lambda_function_high_error_rate.sql
  severity    = "low"

  tags = merge(local.lambda_common_tags, {
    class = "overused"
  })
}

control "lambda_function_excessive_timeout" {
  title       = "Lambda functions with excessive timeout should be reviewed"
  description = "Excessive timeouts result in retries and additional execution time for the function, incurring request charges and billed duration. The control checks for functions with a timeout rate of more than 10% a day in one of the last 7 days."
  sql         = query.lambda_function_excessive_timeout.sql
  severity    = "low"

  tags = merge(local.lambda_common_tags, {
    class = "overused"
  })
}

control "lambda_function_with_graviton2" {
  title       = "Lambda functions should use the graviton2 processor"
  description = "With graviton2 processor(arm64 – 64-bit ARM architecture), you can save money in two ways. First, your functions run more efficiently due to the Graviton2 architecture. Second, you pay less for the time that they run. In fact, Lambda functions powered by Graviton2 are designed to deliver up to 19 percent better performance at 20 percent lower cost."
  sql         = query.lambda_function_with_graviton2.sql
  severity    = "low"

  tags = merge(local.aws_thrifty_common_tags, {
    service = "generation_gaps"
  })
}
