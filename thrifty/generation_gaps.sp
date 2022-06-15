benchmark "generation_gaps" {
  title         = "Generation Gaps"
  description   = "Thrifty developers prefer new generation of cloud resources to deliver better performance and capacity at a lower unit price. For instance by simply upgrading from `gp2` EBS volumes to `gp3` EBS volumes you can save up to 20% on your bills. The same theme applies to EC2, RDS, and EMR instance types: older instance types should be replaced by latest instance types for better hardware performance. In the case of RDS instances, for example, switching from the M3 generation to M5 can save over 7% on your RDS bill. Upgrading to the latest generation is often a quick configuration change, with little downtime impact, that yields a nice cost-saving benefit."
  documentation = file("./thrifty/docs/generation_gaps.md")
  children = [
    control.ebs_volume_using_gp2,
    control.ebs_volume_io1,
    control.ec2_instance_older_generation,
    control.emr_cluster_instance_prev_gen,
    control.lambda_function_with_graviton2,
    control.redshift_cluster_node_type_prev_gen,
    control.rds_db_instance_class_prev_gen
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

control "ec2_instance_older_generation" {
  title       = "EC2 instances should not use older generation t2, m3, and m4 instance types"
  description = "EC2 instances should not use older generation t2, m3, and m4 instance types as t3 and m5 are more cost effective."
  sql         = query.ec2_instance_older_generation.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EC2"
  })
}

control "ebs_volume_using_gp2" {
  title       = "EBS gp3 volumes should be used instead of gp2"
  description = "EBS gp2 volumes are more costly and have a lower performance than gp3."
  sql         = query.ebs_volume_using_gp2.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EBS"
  })
}

control "ebs_volume_io1" {
  title       = "EBS io2 volumes should be used instead of io1"
  description = "EBS io1 volumes are less reliable than io2 for same cost."
  sql         = query.ebs_volume_io1.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EBS"
  })
}

control "emr_cluster_instance_prev_gen" {
  title       = "EMR clusters of previous generation instances should be reviewed"
  description = "EMR clusters of previous generations instance types (c1,cc2,cr1,m2,g2,i2,m1) should be replaced by latest generation instance types for better hardware performance."
  sql         = query.emr_cluster_instance_prev_gen.sql
  severity    = "low"

  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EMR"
  })
}

control "lambda_function_with_graviton2" {
  title       = "Lambda functions should use the graviton2 processor"
  description = "With graviton2 processor(arm64 – 64-bit ARM architecture), you can save money in two ways. First, your functions run more efficiently due to the Graviton2 architecture. Second, you pay less for the time that they run. In fact, Lambda functions powered by Graviton2 are designed to deliver up to 19 percent better performance at 20 percent lower cost."
  sql         = query.lambda_function_with_graviton2.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Lambda"
  })
}

control "rds_db_instance_class_prev_gen" {
  title       = "RDS instances should use the latest generation instance types"
  description = "M5 and T3 instance types are less costly than previous generations."
  sql         = query.rds_db_instance_class_prev_gen.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/RDS"
  })
}

control "redshift_cluster_node_type_prev_gen" {
  title       = "Redshift clusters should use the latest generation node types"
  description = "Ensure that all Redshift clusters provisioned within your AWS account are using the latest generation of nodes (ds2.xlarge or ds2.8xlarge) in order to get higher performance with lower costs."
  sql         = query.redshift_cluster_node_type_prev_gen.sql
  severity    = "low"
  tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Redshift"
  })
}