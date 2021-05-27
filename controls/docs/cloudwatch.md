## CloudWatch Thrifty Benchmark

Thrifty developers actively manage the retention of their Cloudtrail logs. This benchmark focuses on finding log groups without retention and inactive log-streams.

### Default Thresholds
- [Log stream inactive threshold (90 Days)](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/1f71e77023825835770fd88d70e745c8379c68a5/query/cloudwatch/stale_cw_log_stream.sql#L4)
