## Thrifty Lambda Benchmark

Timeout is the amount of time that Lambda allows a function to run before stopping it. Excessive timeouts result in retries and additional execution time for the function, incurring request charges and billed duration.

Lambda charges based on number of requests for your function. Function errors may result in retries that incur extra charges.

Memory allocation directly affects the cost of Lambda functions. Over-provisioning memory results in unnecessary costs, as you pay for the configured memory whether the function uses it or not. By default, functions with more than 1024MB of allocated memory are flagged as excessive, and those with more than 512MB are flagged as high. These thresholds can be configured through the `lambda_memory_excessive_threshold` and `lambda_memory_high_threshold` variables.
