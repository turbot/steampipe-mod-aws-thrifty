---
repository: "https://github.com/turbot/steampipe-mod-aws-thrifty"
---

# AWS Thrifty Mod

Be Thrifty on AWS! This mod checks for unused resources and opportunities to optimize your spend on AWS.

![image](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/main/docs/thrifty-output.png)

## References

[AWS](https://aws.amazon.com) provides on-demand cloud computing platforms and APIs to authenticated customers on a metered pay-as-you-go basis.

[Steampipe](https://steampipe.io) is an open source CLI to instantly query cloud APIs using SQL.

[Steampipe Mods](https://steampipe.io/docs/reference/mod-resources#mod) are collections of `named queries`, and codified `controls` that can be used to test current configuration of your cloud resources against a desired configuration.

## Documentation

- **[Benchmarks and controls →](https://hub.steampipe.io/mods/turbot/aws_thrifty/controls)**
- **[Named queries →](https://hub.steampipe.io/mods/turbot/aws_thrifty/queries)**

## Get started

Install the AWS plugin with [Steampipe](https://steampipe.io):

```shell
steampipe plugin install aws
```

Clone:

```sh
git clone https://github.com/turbot/steampipe-mod-aws-thrifty.git
cd steampipe-mod-aws-thrifty
```

Run all benchmarks:

```shell
steampipe check all
```

Run a specific control:

```shell
steampipe check control.instances_with_low_utilization
```

### Credentials

This mod uses the credentials configured in the [Steampipe AWS plugin](https://hub.steampipe.io/plugins/turbot/aws).

### Configuration

Several benchmarks have [input variables](https://steampipe.io/docs/using-steampipe/mod-variables) that can be configured to better match your environment and requirements. Each variable has a default defined in `steampipe.spvars`, but these can be overwritten in several ways:

- Modify the `steampipe.spvars` file
- Remove or comment out the value in `steampipe.spvars`, after which Steampipe will prompt you for a value when running a query or check
- Pass in a value on the command line:

  ```shell
  steampipe check benchmark.ec2 --var=ec2_running_instance_age_max_days=90
  ```

- Set an environment variable:

  ```shell
  SP_VAR_ec2_running_instance_age_max_days=90 steampipe check control.long_running_ec2_instances
  ```

  - Note: When using environment variables, if the variable is defined in `steampipe.spvars` or passed in through the command line, either of those will take precedence over the environment variable value. For more information on variable definition precedence, please see the link below.

These are only some of the ways you can set variables. For a full list, please see [Passing Input Variables](https://steampipe.io/docs/using-steampipe/mod-variables#passing-input-variables).

## Get involved

- Contribute: [Help wanted issues](https://github.com/turbot/steampipe-mod-aws-thrifty/labels/help%20wanted)
- Community: [Slack channel](https://join.slack.com/t/steampipe/shared_invite/zt-oij778tv-lYyRTWOTMQYBVAbtPSWs3g)
