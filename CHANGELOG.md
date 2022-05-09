## v0.14 [2022-05-10]

- Updated docs/index.md and README with new dashboard screenshots and latest format. ([#75](https://github.com/turbot/steampipe-mod-aws-thrifty/pull/75))

## v0.13 [2022-04-27]

_Enhancements_

- Added `category`, `service`, and `type` tags to benchmarks and controls. ([#72](https://github.com/turbot/steampipe-mod-aws-thrifty/pull/72))

## v0.12 [2022-04-06]

_Bug fixes_

- Fixed the `old_ebs_snapshots` query to correctly evaluate the age of the snapshots ([#69](https://github.com/turbot/steampipe-mod-aws-thrifty/pull/69))

## v0.11 [2022-03-29]

_What's new?_

- Added default values to all variables (set to the same values in `steampipe.spvars.example`)
- Added `*.spvars` and `*.auto.spvars` files to `.gitignore`
- Renamed `steampipe.spvars` to `steampipe.spvars.example`, so the variable default values will be used initially. To use this example file instead, copy `steampipe.spvars.example` as a new file `steampipe.spvars`, and then modify the variable values in it. For more information on how to set variable values, please see [Input Variable Configuration](https://hub.steampipe.io/mods/turbot/aws_thrifty#configuration).

## v0.10 [2021-11-15]

_Enhancements_

- `docs/index.md` file now includes the console output image

## v0.9 [2021-09-30]

_What's new?_

- Added: Input variables have been added to CloudWatch, Cost Explorer, DynamoDB, EBS, EC2, ECS, ElastiCache, RDS, and Redshift controls to allow different thresholds to be passed in. To get started, please see [AWS Thrifty Configuration](https://hub.steampipe.io/mods/turbot/aws_thrifty#configuration). For a list of variables and their default values, please see [steampipe.spvars](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/main/steampipe.spvars).

## v0.8 [2021-09-09]

_Enhancements_

- Lambda benchmark control and query names have been updated to maintain consistency

_Bug fixes_

- The broken reference links in the Lambda benchmark document have been removed

## v0.7 [2021-09-07]

_What's new?_

- Added initial Lambda benchmark and controls

- New controls added:
  - lambda_excessive_timeout
  - lambda_high_error_rate

## v0.6 [2021-08-25]

_What's new?_

- Added initial CloudFront, ECS and EMR benchmarks and controls along with new controls for the Redshift and the EC2 benchmarks

- New controls added:
  - cloudfront_distribution_pricing_class
  - ec2_reserved_instance_lease_expiration_30_days
  - ecs_cluster_low_utilization
  - ecs_service_without_autoscaling
  - emr_cluster_instance_prev_gen
  - emr_cluster_is_idle_30_minutes
  - redshift_cluster_low_utilization
  - redshift_cluster_schedule_pause_resume_enabled

## v0.5 [2021-07-23]

_What's new?_

- New controls added:
  - ec2_application_lb_unused
  - ec2_classic_lb_unused
  - ec2_gateway_lb_unused
  - ec2_network_lb_unused
  - elasticache_cluster_age_90_days
  - redshift_cluster_age_90_days
  - vpc_nat_gateway_unused

_Enhancements_

- Updated: Service benchmark docs now link to query pages instead of the GitHub repository code for default thresholds for more reliable linking

## v0.4 [2021-05-28]

_Bug fixes_

- Minor fixes in the docs
