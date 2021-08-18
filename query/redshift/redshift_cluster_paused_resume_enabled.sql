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
both_enabled as (
  select
    p.arn
  from
    cluster_pause_enabled as p
    left join cluster_resume_enabled as r on r.arn =p.arn
  where
    p.pause_cluster = r.resume_cluster
)
select
  a.arn as resource,
  case
    when b.arn is not null then 'ok'
    else 'alarm'
  end as status,
  case
    when b.arn is not null then a.title || ' pause-resume action enabled.'
    else a.title || ' pause-resume action not enabled.'
  end as reason,
  a.region,
  a.account_id
from
  aws_redshift_cluster as a
  left join both_enabled as b on a.arn = b.arn;