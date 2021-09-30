## Thrifty EBS Benchmark

Thrifty developers keep a careful eye for unused and under-utilized EBS volumes. Elastic block store is a key component of hidden cost on AWS, and this benchmark looks for EBS volumes that are unused, under-utilized, out-dates and oversized.

## Variables

| Variable | Description | Default |
| - | - | - |
| ebs_snapshot_age_max_days | The maximum number of days snapshots can be retained. | 90 days |
| ebs_volume_avg_read_write_ops_high | The number of average read/write ops required for volumes to be considered frequently used. This value should be higher than `ebs_volume_avg_read_write_ops_low`. | 500 ops/min |
| ebs_volume_avg_read_write_ops_low | The number of average read/write ops required for volumes to be considered infrequently used. This value should be lower than `ebs_volume_avg_read_write_ops_high`. | 100 ops/min |
| ebs_volume_max_iops | The maximum IOPS allowed for volumes. | 32,000 IOPS |
| ebs_volume_max_size_gb | The maximum size (GB) allowed for volumes. | 100 GB |
