variable "redshift_cluster_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than redshift_cluster_avg_cpu_utilization_low."
  default     = 35
}

variable "redshift_cluster_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than redshift_cluster_avg_cpu_utilization_high."
  default     = 20
}

variable "redshift_running_cluster_age_max_days" {
  type        = number
  description = "The maximum number of days clusters are allowed to run."
  default     = 90
}

variable "redshift_running_cluster_age_warning_days" {
  type        = number
  description = "The number of days clusters can be running before sending a warning."
  default     = 30
}

locals {
  redshift_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Redshift"
  })
}

benchmark "redshift" {
  title         = "Redshift Cost Checks"
  description   = "Thrifty developers check their long running Redshift clusters are associated with reserved nodes."
  documentation = file("./controls/docs/redshift.md")
  children = [
    control.redshift_cluster_low_utilization,
    control.redshift_cluster_max_age,
    control.redshift_cluster_schedule_pause_resume_enabled
  ]

  tags = merge(local.redshift_common_tags, {
    type = "Benchmark"
  })
}

control "redshift_cluster_max_age" {
  title       = "Long running Redshift clusters should have reserved nodes purchased for them"
  description = "Long running clusters should be associated with reserved nodes, which provide a significant discount."
  severity    = "low"

  param "redshift_running_cluster_age_max_days" {
    description = "The maximum number of days clusters are allowed to run."
    default     = var.redshift_running_cluster_age_max_days
  }

  param "redshift_running_cluster_age_warning_days" {
    description = "The number of days clusters can be running before sending a warning."
    default     = var.redshift_running_cluster_age_warning_days
  }

  tags = merge(local.redshift_common_tags, {
    class = "capacity_planning"
  })

  sql = <<-EOQ
    with redshift_cluster_list as (
      select
        arn,
        node_type,
        region,
        cluster_create_time,
        account_id,
        title,
        _ctx
      from
        aws_redshift_cluster
    ),redshift_reserved_pricing as (
      select
        r.arn,
        r.node_type,
        r.region,
        r.cluster_create_time,
        r.account_id,
        r.title,
        r._ctx,
        ((p.price_per_unit::numeric)*24*30)::numeric(10,2) as redshift_reserved_pricing
      from
        redshift_cluster_list as r
        left join aws_pricing_product as p on
          p.service_code = 'AmazonRedshift'
          and p.attributes ->> 'regionCode' = r.region
          and p.attributes ->> 'instanceType' = r.node_type
          and p.term = 'Reserved'
          and p.unit = 'Hrs'
          and p.lease_contract_length = '1yr'
          and purchase_option = 'No Upfront'
          and p.attributes ->> 'usagetype' like 'Node:%'
    ), redshift_pricing as (
      select
        r.arn,
        r.node_type,
        r.region,
        r.cluster_create_time,
        r.account_id,
        r.title,
        r._ctx,
        case
          when date_part('day', now() - cluster_create_time) > $1 then (((p.price_per_unit::numeric)*24*30)::numeric(10,2)- redshift_reserved_pricing) || ' ' || currency || ' savings/month'
          else ''
        end as net_savings,
        p.currency
      from
        redshift_reserved_pricing as r
        left join aws_pricing_product as p on
        p.service_code = 'AmazonRedshift'
        and p.attributes ->> 'regionCode' = r.region
        and p.attributes ->> 'instanceType' = r.node_type
        and p.term = 'OnDemand'
        and p.attributes ->> 'usagetype' like 'Node:%'
    )
    select
      arn as resource,
      case
        when date_part('day', now() - cluster_create_time) > $1 then 'alarm'
        when date_part('day', now() - cluster_create_time) > $2 then 'info'
        else 'ok'
      end as status,
      title || ' created on ' || cluster_create_time || ' (' || date_part('day', now() - cluster_create_time) || ' days).'
      as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      redshift_pricing;
  EOQ
}

control "redshift_cluster_schedule_pause_resume_enabled" {
  title       = "Redshift clusters pause and resume feature should be enabled"
  description = "Redshift clusters should utilise the pause and resume actions to easily suspend on-demand billing while the cluster is not being used."
  severity    = "low"
  tags = merge(local.redshift_common_tags, {
    class = "overused"
  })

  sql = <<-EOQ
    with cluster_pause_enabled as (
    select
      arn,
      s -> 'TargetAction' -> 'PauseCluster' ->> 'ClusterIdentifier' as pause_cluster
    from
      aws_redshift_cluster,
      jsonb_array_elements(scheduled_actions) as s
    where
      s -> 'TargetAction' -> 'PauseCluster' ->> 'ClusterIdentifier' is not null
  ),
  cluster_resume_enabled as (
    select
      arn,
      s -> 'TargetAction' -> 'ResumeCluster' ->> 'ClusterIdentifier' as resume_cluster
    from
      aws_redshift_cluster,
      jsonb_array_elements(scheduled_actions) as s
    where
      s -> 'TargetAction' -> 'ResumeCluster' ->> 'ClusterIdentifier' is not null
  ),
  pause_and_resume_enabled as (
    select
      p.arn
    from
      cluster_pause_enabled as p
      left join cluster_resume_enabled as r on r.arn = p.arn
    where
      p.pause_cluster = r.resume_cluster
  )
  select
    a.arn as resource,
    case
      when b.arn is not null then 'ok'
      else 'info'
    end as status,
    case
      when b.arn is not null then a.title || ' pause-resume action enabled.'
      else a.title || ' pause-resume action not enabled.'
    end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "a.")}
  from
    aws_redshift_cluster as a
    left join pause_and_resume_enabled as b on a.arn = b.arn;
  EOQ
}

control "redshift_cluster_low_utilization" {
  title       = "Redshift clusters with low CPU utilization should be reviewed"
  description = "Resize or eliminate under utilized clusters."
  severity    = "low"

  param "redshift_cluster_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for clusters to be considered infrequently used. This value should be lower than redshift_cluster_avg_cpu_utilization_high."
    default     = var.redshift_cluster_avg_cpu_utilization_low
  }

  param "redshift_cluster_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for clusters to be considered frequently used. This value should be higher than redshift_cluster_avg_cpu_utilization_low."
    default     = var.redshift_cluster_avg_cpu_utilization_high
  }

  tags = merge(local.redshift_common_tags, {
    class = "underused"
  })

  sql = <<-EOQ
    with redshift_cluster_utilization as (
      select
        cluster_identifier,
        round(cast(sum(maximum)/count(maximum) as numeric), 1) as avg_max,
        count(maximum) days
      from
        aws_redshift_cluster_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        cluster_identifier
    ), redshift_cluster_list as (
      select
        arn,
        cluster_identifier,
        node_type,
        region,
        _ctx,
        cluster_create_time,
        account_id,
        title
      from
        aws_redshift_cluster
    ), redshift_pricing as (
      select
        r.arn,
        r.cluster_identifier,
        r.node_type,
        r.region,
        r._ctx,
        r.cluster_create_time,
        r.account_id,
        r.title,
        case
          when u.avg_max < $1 then ((p.price_per_unit::numeric)*24*30)::numeric(10,2) || ' ' || currency || '/month'
          else ''
        end as net_savings,
        p.currency
      from
        redshift_cluster_list as r
        left join redshift_cluster_utilization as u on u.cluster_identifier = r.cluster_identifier
        left join aws_pricing_product as p on
        p.service_code = 'AmazonRedshift'
        and p.attributes ->> 'regionCode' = r.region
        and p.attributes ->> 'instanceType' = r.node_type
        and p.term = 'OnDemand'
        and p.attributes ->> 'usagetype' like 'Node:%'
    )
    select
      i.cluster_identifier as resource,
      case
        when avg_max is null then 'error'
        when avg_max < $1 then 'alarm'
        when avg_max < $2 then 'info'
        else 'ok'
      end as status,
      case
        when avg_max is null then 'CloudWatch metrics not available for ' || title || '.'
        else title || ' is averaging ' || avg_max || '% max utilization over the last ' || days || ' days.'
      end as reason
      ${local.common_dimensions_cost_sql}
      ${local.tag_dimensions_sql}
      ${local.common_dimensions_sql}
    from
      redshift_pricing as i
      left join redshift_cluster_utilization as u on u.cluster_identifier = i.cluster_identifier;
  EOQ
}
