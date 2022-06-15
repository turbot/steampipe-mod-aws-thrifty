
Thrifty developers need to pay close attention to unused resources. It’s possible to end up with resources that aren’t being used. Load balancers may not have associated resources or targets; RDS databases may have low or no connection counts; a NAT gateway may not have any resources routing to it. And most commonly, EBS volumes may not be attached to running instances. The ability to easily create, attach and unattached disk volumes is a key benefit of working in the cloud, but it can also become a source of unchecked cost if not watched closely. Even if an Amazon EBS volume is unattached, you are still billed for the provisioned storage.

This dashboard answers the following questions:

- What resources are no longer being used?
- What resources do not have any attachments or associations?

## Variables

| Variable                           | Description                                                                               | Default |
| ---------------------------------- | ----------------------------------------------------------------------------------------- | ------- |
| cloudwatch_log_stream_age_max_days | The maximum number of days log streams are allowed without any log event written to them. | 90 days |
| secretsmanager_secret_last_used    | The default number of days secrets manager secrets to be considered in-use.               | 90 days |
