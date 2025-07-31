locals {
  all_controls_common_tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}

benchmark "all_controls" {
  title       = "All Controls"
  description = "This benchmark contains all controls grouped by service to help you detect resource configurations that do not meet best practices."
  children = [
    benchmark.apigateway,
    benchmark.cloudfront,
    benchmark.cloudtrail,
    benchmark.cloudwatch,
    benchmark.cost_explorer,
    benchmark.dynamodb,
    benchmark.ebs,
    benchmark.ec2,
    benchmark.ecr,
    benchmark.ecs,
    benchmark.eks,
    benchmark.elasticache,
    benchmark.emr,
    benchmark.lambda,
    benchmark.rds,
    benchmark.redshift,
    benchmark.route53,
    benchmark.s3,
    benchmark.secretsmanager,
    benchmark.vpc
  ]

  tags = local.all_controls_common_tags
}
