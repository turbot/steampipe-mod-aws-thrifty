Thrifty developers check overused AWS resources. AWS resources can be overused in a few different ways. When you have long-running resources, consider if they can be stopped intermittently. In non-production environments, for example, it can make sense to spin up resources when needed, or only during working hours.

This dashboard answers the following questions:

- What global and regional CloudTrail trails are redundant?
- What EC2 instances and EBS volumes are operating at higher than defined size limits?  

## Variables

| Variable                   | Description                                                           | Default                                                                          |
| -------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| ebs_volume_max_iops        | The maximum IOPS allowed for volumes.                                 | 32000 IOPS                                                                       |
| ebs_volume_max_size_gb     | The maximum size (GB) allowed for volumes.                            | 100 GB                                                                           |
| ec2_instance_allowed_types | A list of allowed instance types. PostgreSQL wildcards are supported. | ["%.nano", "%.micro", "%.small", "%.medium", "%.large", "%.xlarge", "%._xlarge"] |
