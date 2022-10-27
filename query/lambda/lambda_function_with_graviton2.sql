select
  arn as resource,
  case
    when architecture = 'arm64' then 'ok'
    else 'alarm'
  end as status,
  case
    when architecture = 'arm64' then title || ' is using Graviton2 processor.'
    else title || ' is not using Graviton2 processor.'
  end as reason,
  region,
  account_id
from
  aws_lambda_function,
  jsonb_array_elements_text(architectures) as architecture;