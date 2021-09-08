## Thrifty Lambda Benchmark

Timeout is the amount of time that Lambda allows a function to run before stopping it. Excessive timeouts result in retries and additional execution time for the function, incurring request charges and billed duration.

Lambda charges based on number of requests for your function. Function errors may result in retries that incur extra charges.

### Default Thresholds

- [Lambda function timeout rate threshold (> 10%)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/lambda_function_excessive_timeout)
- [Lambda function error rate threshold (> 10%)](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/lambda_function_high_error_rate)
