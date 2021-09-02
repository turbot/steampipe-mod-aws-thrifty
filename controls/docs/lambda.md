## Thrifty S3 Benchmark

Timeout is the amount of time that Lambda allows a function to run before stopping it. Excessive timeouts result in retries and additional execution time for the function, incurring request charges and billed duration.

Lambda charges based on number of requests for your function. Function errors may result in retries that incur extra charges.

### Default Thresholds

- [Checks for functions with a timeout rate of more than 10% a day in one of the last 7 days](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/elasticache_cluster_age_90_days)


- [Checks for functions with an error rate of more than 10% a day in one of the last 7 days](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries/elasticache_cluster_age_90_days)

