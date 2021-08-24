## v0.6 [2021-08-24]

_What's new?_

- Added initial CloudFront, ECS and EMR benchmarks and basic controls to provide additional monitoring of AWS resources

- New controls added:
  - cloudfront_distribution_pricing_class
  - ecs_cluster_low_utilization
  - ecs_service_without_autoscaling
  - emr_cluster_instance_prev_gen
  - emr_cluster_is_idle_30_minutes
  - redshift_cluster_low_utilization
  - redshift_cluster_paused_resume_enabled

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
