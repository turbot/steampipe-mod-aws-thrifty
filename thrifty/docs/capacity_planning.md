## Thrifty Capacity Planning Benchmark

Thrifty developers ensure that long running resources are strategically planned. If you have long-running resources, it's a good idea to prepurchase reserved instances at lower cost. This can apply to long-running resources including EC2 instances, RDS instances, and Redshift clusters. You should also keep an eye on EC2 reserved instances that are scheduled for expiration, or have expired in the preceding 30 days, to verify that these cost-savers are in fact no longer needed.

## Variables

| Variable                                      | Description                                                                    | Default |
| --------------------------------------------- | ------------------------------------------------------------------------------ | ------- |
| ec2_reserved_instance_expiration_warning_days | The number of days reserved instances can be running before sending a warning. | 30 days |
| kinesis_stream_high_retention_period_days     | The number of days for the data retention period to be considered as maximum.  | 1 day   |
