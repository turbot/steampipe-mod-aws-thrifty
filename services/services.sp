benchmark "foundational_services" {
  title         = "Foundational Services"
  description   = "AWS services."
  //documentation = file("./thrifty/docs/foundational_services.md")
  children = [
    benchmark.cloudfront,
    benchmark.cloudtrail,
    benchmark.cloudwatch,
    benchmark.cost_explorer,
    benchmark.dynamodb,
    benchmark.ebs,
    benchmark.ec2,
    benchmark.ecs,
    benchmark.elasticache,
    benchmark.emr,
    benchmark.lambda,
    benchmark.rds,
    benchmark.redshift,
    benchmark.route53,
    benchmark.s3,
    benchmark.secretsmanager,
    benchmark.vpc,
  ]

  tags = merge(local.aws_thrifty_common_tags, {
    type = "Benchmark"
  })
}
