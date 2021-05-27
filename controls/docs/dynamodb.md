# Thrifty DynamoDB Benchmark

Thrifty developers archive DynamoDB tables with stale data. This benchmark focuses on finding tables where the data has not changed recently.

## Default Thresholds
- [Stale table data threshold (90 Days)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/dynamodb_stale_data.sql#L5)

## Help wanted
- add checks for cost allocation tags