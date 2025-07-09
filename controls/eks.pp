locals {
  eks_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EKS"
  })
}

benchmark "eks" {
  title         = "EKS Checks"
  description   = "Thrifty developers ensure their EKS resources are optimized."
  documentation = file("./controls/docs/eks.md")
  children = [
    control.eks_node_group_with_graviton
  ]

  tags = merge(local.eks_common_tags, {
    type = "Benchmark"
  })
}

control "eks_node_group_with_graviton" {
  title       = "EKS node groups without graviton processor should be reviewed"
  description = "With graviton processor (arm64 - 64-bit ARM architecture), you can save money in two ways. First, your functions run more efficiently due to the Graviton architecture. Second, you pay less for the time that they run. In fact, Lambda functions powered by Graviton are designed to deliver up to 19 percent better performance at 20 percent lower cost."
  severity    = "low"

  tags = merge(local.eks_common_tags, {
    class = "deprecated"
  })

  sql = <<-EOQ
    with node_group_using_launch_template_image_id as (
      select
        g.arn as node_group_arn,
        v.image_id as image_id
      from
        aws_eks_node_group as g
        left join aws_ec2_launch_template_version as v on v.launch_template_id = g.launch_template ->> 'Id' and v.version_number = (g.launch_template ->> 'Version')::int
      where
        g.launch_template is not null
    ), ami_architecture as (
      select
        node_group_arn,
        architecture,
        case when s.platform_details = 'Linux/UNIX' then 'linux' else platform_details end as platform
      from
        node_group_using_launch_template_image_id as i
        left join aws_ec2_ami_shared as s on s.image_id = i.image_id
      where
        architecture is not null
      union
      select
        node_group_arn,
        architecture,
        case when a.platform_details = 'Linux/UNIX' then 'linux' else platform_details end as platform
      from
        node_group_using_launch_template_image_id as i
        left join aws_ec2_ami as a on a.image_id = i.image_id
      where
        architecture is not null
  )
  select
    arn as resource,
    case
      when ami_type = 'CUSTOM%' and a.platform <> 'linux' then 'skip'
      when ami_type = 'CUSTOM%' and a.architecture = 'arm_64' and a.platform = 'linux' then 'ok'
      when ami_type = 'CUSTOM%' and a.architecture <> 'arm_64' and a.platform = 'linux' then 'alarm'
      when ami_type not like 'AL2_%' then 'skip'
      when ami_type = 'AL2_ARM_64' then 'ok'
      else 'alarm'
    end as status,
    case
      when ami_type = 'CUSTOM%' and a.platform <> 'linux' then title || ' is not using linux platform.'
      when ami_type = 'CUSTOM%' and a.architecture = 'x86_64' and a.platform = 'linux' then title || ' is using Graviton processor.'
      when ami_type = 'CUSTOM%' and a.architecture <> 'arm_64' and a.platform = 'linux' then title || ' is not using Graviton processor.'
      when ami_type not like 'AL2_%' then title || ' is not using linux platform.'
      when ami_type = 'AL2_ARM_64' then title || ' is using Graviton processor.'
      else title || ' is not using Graviton processor.'
    end as reason
    ${local.tag_dimensions_sql}
    ${local.common_dimensions_sql}
  from
    aws_eks_node_group as g
    left join ami_architecture as a on a.node_group_arn = g.arn;
  EOQ
}
