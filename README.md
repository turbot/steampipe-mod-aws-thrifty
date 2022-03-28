# AWS Thrifty

An AWS cost savings and waste checking tool.

![image](https://raw.githubusercontent.com/turbot/steampipe-mod-aws-thrifty/main/docs/aws_thrifty_mod_terminal.png)

## Quick start

1) Download and install Steampipe (https://steampipe.io/downloads). Or use Brew:

```shell
brew tap turbot/tap
brew install steampipe

steampipe -v 
steampipe version 0.9.1
```

Install the AWS plugin

```shell
steampipe plugin install aws
```

Clone this repo and move into the directory:

```sh
git clone https://github.com/turbot/steampipe-mod-aws-thrifty.git
cd steampipe-mod-aws-thrifty
```

Run all benchmarks:

```shell
steampipe check all
```

Your can also run a specific controls:

```shell
steampipe check control.instances_with_low_utilization
```

### Credentials

This mod uses the credentials configured in the [Steampipe AWS plugin](https://hub.steampipe.io/plugins/turbot/aws).

### Configuration

Several benchmarks have [input variables](https://steampipe.io/docs/using-steampipe/mod-variables) that can be configured to better match your environment and requirements. Each variable has a default defined in its source file, e.g., `controls/rds.sp`, but these can be overwritten in several ways:

- Copy and rename the `steampipe.spvars.example` file to `steampipe.spvars`, and then modify the variable values inside that file
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

## Current Thrifty Checks

- Month to month swings in service cost from **AWS Cost Explorer**
- Underused and oversized **RDS** Databases
- Unused, underused and oversized **EC2 Instances**
- Unused, underused and oversized **EBS Volumes** and **Snapshots**
- **CloudWatch Log Groups** without retention policies
- **CloudWatch Log Streams** with stale data
- **CloudFront Distribution** pricing classes
- Unused **EMR Clusters** with previous generation instances
- Unused **ECS Clusters**
- Stale **DynamoDB** Tables
- Unused and underused **Redshift Clusters**
- **S3 Buckets** without lifecycle policies
- Unattached **Elastic IPs**
- [#TODO List](https://github.com/turbot/steampipe-mod-aws-thrifty/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

**Use introspection to view the available controls:**:

```shell
steampipe query "select resource_name from steampipe_control;"
```

## Contributing

Have an idea for a thrifty check but aren't sure how to get started?

- **[Join our Slack community →](https://join.slack.com/t/steampipe/shared_invite/zt-oij778tv-lYyRTWOTMQYBVAbtPSWs3g)**
- **[Mod developer guide →](https://steampipe.io/docs/using-steampipe/writing-controls)**

**Prerequisites**:

- [Steampipe installed](https://steampipe.io/downloads)
- Steampipe AWS plugin installed (see above)

**Fork**:
Click on the GitHub Fork Widget. (Don't forget to :star: the repo!)

**Clone**:

1. Change the current working directory to the location where you want to put the cloned directory on your local filesystem.
2. Type the clone command below inserting your GitHub username instead of `YOUR-USERNAME`:

```sh
git clone git@github.com:YOUR-USERNAME/steampipe-mod-aws-thrifty
cd steampipe-mod-aws-thrifty
```

Thanks for getting involved! We would love to have you [join our Slack community](https://join.slack.com/t/steampipe/shared_invite/zt-oij778tv-lYyRTWOTMQYBVAbtPSWs3g) and hang out with other Mod developers.

Please see the [contribution guidelines](https://github.com/turbot/steampipe/blob/main/CONTRIBUTING.md) and our [code of conduct](https://github.com/turbot/steampipe/blob/main/CODE_OF_CONDUCT.md). All contributions are subject to the [Apache 2.0 open source license](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/main/LICENSE).

`help wanted` issues:

- [Steampipe](https://github.com/turbot/steampipe/labels/help%20wanted)
- [AWS Thrifty Mod](https://github.com/turbot/steampipe-mod-aws-thrifty/labels/help%20wanted)
