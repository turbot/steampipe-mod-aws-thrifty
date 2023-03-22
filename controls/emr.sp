locals {
  emr_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EMR"
  })
}

benchmark "emr" {
  title         = "EMR Checks"
  description   = "Thrifty developers checks EMR clusters of previous generation instances and idle clusters."
  documentation = file("./controls/docs/emr.md")
  children = [
    control.emr_cluster_instance_prev_gen,
    control.emr_cluster_is_idle_30_minutes
  ]

  tags = merge(local.emr_common_tags, {
    type = "Benchmark"
  })
}

control "emr_cluster_instance_prev_gen" {
  title       = "EMR clusters of previous generation instances should be reviewed"
  description = "EMR clusters of previous generations instance types (c1,cc2,cr1,m2,g2,i2,m1) should be replaced by latest generation instance types for better hardware performance."
  severity    = "low"

  tags = merge(local.emr_common_tags, {
    class = "managed"
  })
  sql = <<-EOQ
    select
      ig.id as resource,
      case
        when ig.state = 'TERMINATED' then 'skip'
        when ig.instance_type like 'c1.%' then 'alarm'
        when ig.instance_type like 'cc2.%' then 'alarm'
        when ig.instance_type like 'cr1.%' then 'alarm'
        when ig.instance_type like 'm2.%' then 'alarm'
        when ig.instance_type like 'g2.%' then 'alarm'
        when ig.instance_type like 'i2,m1.%' then 'alarm'
        when ig.instance_type like 'c1.%' then 'alarm'
        else 'info'
      end as status,
      case
      when ig.state = 'TERMINATED' then ig.cluster_id || ' is ' || ig.state || '.'
      else ig.cluster_id || ' has ' || ig.instance_type || ' instance type.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "c.")}
    from
      aws_emr_instance_group as ig,
      aws_emr_cluster as c
    where
      ig.cluster_id = c.id
    and ig.instance_group_type = 'MASTER';
  EOQ
}

control "emr_cluster_is_idle_30_minutes" {
  title       = "EMR clusters idle for more than 30 minutes should be reviewed"
  description = "EMR clusters which is live but not currently running tasks should be reviewed and checked whether the cluster has been idle for more than 30 minutes."
  severity    = "low"

  tags = merge(local.emr_common_tags, {
    class = "unused"
  })
  sql = <<-EOQ
    with cluster_metrics as (
      select
        id,
        maximum,
        date(timestamp) as timestamp
      from
        aws_emr_cluster_metric_is_idle
      where
        timestamp >= current_timestamp - interval '40 minutes'
    ),
      emr_cluster_isidle as (
        select
          id,
          count(maximum) as count,
          sum(maximum)/count(maximum) as avagsum
        from
          cluster_metrics
        group by id, timestamp
      )
      select
        i.id as resource,
        case
          when u.id is null then 'error'
          when avagsum = 1 and count >= 7  then 'alarm'
          else 'ok'
        end as status,
        case
          when u.id is null then 'CloudWatch metrics not available for ' || i.title || '.'
          else i.title || ' is idle from last ' || (count*5 - 5) ||  ' minutes.'
        end as reason
        ${local.tag_dimensions_sql}
        ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "i.")}
      from
        aws_emr_cluster as i
        left join emr_cluster_isidle as u on u.id = i.id;
  EOQ
}
