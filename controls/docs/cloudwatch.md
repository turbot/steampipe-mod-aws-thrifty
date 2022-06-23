## Thrifty CloudWatch Benchmark

Thrifty developers actively manage the retention of their Cloudtrail logs. This benchmark focuses on finding log groups without retention and inactive log-streams.

## Variables

| Variable | Description | Default |
| - | - | - |
| cloudwatch_log_stream_age_max_days | The maximum number of days log streams are allowed without any log event written to them. | 90 days |
