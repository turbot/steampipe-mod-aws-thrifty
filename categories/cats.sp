benchmark "capacity_planning" {
  title         = "Capacity Planning"
  description   = "Thrifty developers ensure that long running resources are strategically planned. If you have long-running resources, it's a good idea to prepurchase reserved instances at lower cost. This can apply to long-running resources including EC2 instances, RDS instances, and Redshift clusters. You should also keep an eye on EC2 reserved instances that are scheduled for expiration, or have expired in the preceding 30 days, to verify that these cost-savers are in fact no longer needed."
  //documentation = file("./thrifty/docs/capacity_planning.md")
  children = [
    #control.dynamodb_table_autoscaling_disabled,
    control.ebs_volume_low_iops,
    control.ec2_instance_running_max_age,
    control.ec2_reserved_instance_lease_expiration_days,
    control.ecs_service_without_autoscaling,
    control.elasticache_cluster_running_max_age,
    #control.kinesis_stream_consumer_with_enhanced_fan_out,
    control.rds_db_instance_max_age,
    control.redshift_cluster_max_age,
    control.redshift_cluster_schedule_pause_resume_enabled,
    control.route53_record_higher_ttl
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

benchmark "cost_variance" {
  title         = "Cost Variance"
  description   = "Thrifty developers keep an eye on the service usage and the accompanied cost variance over a period of time. They pay close attention to the cost spikes and check if per-service costs have changed more than allowed between this month and last month. By asking the right questions one can often justify the cost or prompt review and optimization."
 // documentation = file("./thrifty/docs/cost_variance.md")
  children = [
    control.cost_explorer_full_month_cost_changes
    #control.cost_explorer_full_month_forecast_cost_changes
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

benchmark "generation_gaps" {
  title         = "Generation Gaps"
  description   = "Thrifty developers prefer new generation of cloud resources to deliver better performance and capacity at a lower unit price. For instance by simply upgrading from `gp2` EBS volumes to `gp3` EBS volumes you can save up to 20% on your bills. The same theme applies to EC2, RDS, and EMR instance types: older instance types should be replaced by latest instance types for better hardware performance. In the case of RDS instances, for example, switching from the M3 generation to M5 can save over 7% on your RDS bill. Upgrading to the latest generation is often a quick configuration change, with little downtime impact, that yields a nice cost-saving benefit."
 // documentation = file("./thrifty/docs/generation_gaps.md")
  children = [
    control.ebs_volume_using_gp2,
    control.ebs_volume_using_io1,
    control.ec2_instance_older_generation,
    control.emr_cluster_instance_prev_gen,
    control.lambda_function_with_graviton2,
    #control.redshift_cluster_node_type_prev_gen,
    control.rds_db_instance_class_prev_gen
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

benchmark "overused" {
  title         = "Overused"
  description   = "Thrifty developers check overused AWS resources. AWS resources can be overused in a few different ways. When you have long-running resources, consider if they can be stopped intermittently. In non-production environments, for example, it can make sense to spin up resources when needed, or only during working hours."
//  documentation = file("./thrifty/docs/overused.md")
  children = [
    control.cloudfront_distribution_pricing_class,
    control.cloudtrail_trail_global_multiple,
    control.cloudtrail_trail_regional_multiple,
    control.ebs_volume_high_iops,
    control.ebs_volume_large,
    control.ec2_instance_large,
    control.lambda_function_excessive_timeout,
    control.lambda_function_high_error_rate
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

benchmark "stale_data" {
  title         = "Stale Data"
  description   = "Thrifty developers need to keep an eye on data which is no longer required. It's great to be able to programmatically create backups and snapshots, but these too can become a source of unchecked cost if not watched closely. It's easy to delete an individual snapshot with a few clicks, but challenging to manage snapshots programmatically across multiple accounts. Over time, dozens of snapshots can turn into hundreds or thousands."
//  documentation = file("./thrifty/docs/stale_data.md")
  children = [
    control.cloudwatch_log_group_no_retention,
    control.dynamodb_table_stale_data,
    control.ebs_snapshot_max_age,
    #control.kinesis_stream_high_retention_period,
    #control.rds_db_cluster_snapshot_max_age,
    #control.rds_db_instance_snapshot_max_age,
    #control.redshift_snapshot_max_age,
    control.s3_bucket_without_lifecycle
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

benchmark "underused" {
  title         = "Underused"
  description   = "Thrifty developers check underused AWS resources. Large EC2 (or RDS, Redshift, ECS, etc) instances may have been created and sized to handle peak utilization but never reviewed later to see how well the storage, compute, and/or memory is being utilized. Consider rightsizing the instance type if an application is overprovisioned in any of these ways. AWS has different pricing for resources that are compute-optimized or memory-optimized. Analyze your inventory and utilization metrics to find underused resources, and prune them as warranted."
//  documentation = file("./thrifty/docs/underused.md")
  children = [
    control.ebs_volume_low_usage,
    control.ec2_instance_low_utilization,
    control.ecs_cluster_low_utilization,
    #control.elasticache_redis_cluster_low_utilization,
    control.rds_db_instance_low_connections,
    control.rds_db_instance_low_usage,
    control.redshift_cluster_low_utilization
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

benchmark "unused" {
  title         = "Unused"
  description   = "Thrifty developers need to pay close attention to unused resources. It’s possible to end up with resources that aren’t being used. Load balancers may not have associated resources or targets; RDS databases may have low or no connection counts; a NAT gateway may not have any resources routing to it. And most commonly, EBS volumes may not be attached to running instances. The ability to easily create, attach and unattached disk volumes is a key benefit of working in the cloud, but it can also become a source of unchecked cost if not watched closely. Even if an Amazon EBS volume is unattached, you are still billed for the provisioned storage."
//  documentation = file("./thrifty/docs/unused.md")
  children = [
    control.cloudwatch_log_stream_unused,
    control.ebs_volume_unattached,
    control.ebs_volume_on_stopped_instances,
    control.ec2_application_lb_unused,
    control.ec2_classic_lb_unused,
    control.ec2_gateway_lb_unused,
    control.ec2_network_lb_unused,
    control.ec2_eips_unattached,
    control.emr_cluster_is_idle_30_minutes,
    control.route53_health_check_unused,
    control.secretsmanager_secret_unused,
    control.vpc_nat_gateway_unused
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}
