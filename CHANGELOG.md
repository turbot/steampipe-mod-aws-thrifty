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
