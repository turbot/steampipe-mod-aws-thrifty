# AWS Thrifty

An AWS cost savings and waste checking tool.

Run checks in a dashboard:

![image](https://raw.githubusercontent.com/turbot/steampipe-mod-aws-thrifty/main/docs/aws_thrifty_dashboard.png)

Or in a terminal:

![image](https://raw.githubusercontent.com/turbot/steampipe-mod-aws-thrifty/main/docs/aws_thrifty_mod_terminal.png)

Includes checks for:

- [Capacity planning](https://hub.steampipe.io/mods/turbot/aws_thrifty/controls/benchmark.capacity_planning)
- [Cost variance](https://hub.steampipe.io/mods/turbot/aws_thrifty/controls/benchmark.cost_variance)
- [Generation gaps](https://hub.steampipe.io/mods/turbot/aws_thrifty/controls/benchmark.generation_gaps)
- [Overused](https://hub.steampipe.io/mods/turbot/aws_thrifty/controls/benchmark.overused)
- [Stale data](https://hub.steampipe.io/mods/turbot/aws_thrifty/controls/benchmark.stale_data)
- [Underused](https://hub.steampipe.io/mods/turbot/aws_thrifty/controls/benchmark.underused)
- [Unused](https://hub.steampipe.io/mods/turbot/aws_thrifty/controls/benchmark.unused)

## Getting started

### Installation

Download and install Steampipe (https://steampipe.io/downloads). Or use Brew:

```sh
brew tap turbot/tap
brew install steampipe
```

Install the AWS plugin with [Steampipe](https://steampipe.io):

```sh
steampipe plugin install aws
```

Clone:

```sh
git clone https://github.com/turbot/steampipe-mod-aws-thrifty.git
cd steampipe-mod-aws-thrifty
```

### Usage

Start your dashboard server to get started:

```sh
steampipe dashboard
```

By default, the dashboard interface will then be launched in a new browser
window at https://localhost:9194. From here, you can run benchmarks by
selecting one or searching for a specific one.

Instead of running benchmarks in a dashboard, you can also run them within your
terminal with the `steampipe check` command:

Run all benchmarks:

```sh
steampipe check all
```

Run a single benchmark:

```sh
steampipe check benchmark.underused
```

Run a specific control:

```sh
steampipe check control.ebs_volume_low_usage
```

Different output formats are also available, for more information please see
[Output Formats](https://steampipe.io/docs/reference/cli/check#output-formats).

### Credentials

This mod uses the credentials configured in the [Steampipe AWS plugin](https://hub.steampipe.io/plugins/turbot/aws).

### Configuration

Several benchmarks have [input variables](https://steampipe.io/docs/using-steampipe/mod-variables) that can be configured to better match your environment and requirements. Each variable has a default defined in its source file, e.g., `thrifty/capacity_planning.sp`, but these can be overwritten in several ways:

- Copy and rename the `steampipe.spvars.example` file to `steampipe.spvars`, and then modify the variable values inside that file
- Pass in a value on the command line:

  ```shell
  steampipe check benchmark.capacity_planning --var=ec2_running_instance_age_max_days=90
  ```

- Set an environment variable:

  ```shell
  SP_VAR_ec2_running_instance_age_max_days=90 steampipe check control.ec2_instance_running_max_age
  ```

  - Note: When using environment variables, if the variable is defined in `steampipe.spvars` or passed in through the command line, either of those will take precedence over the environment variable value. For more information on variable definition precedence, please see the link below.

These are only some of the ways you can set variables. For a full list, please see [Passing Input Variables](https://steampipe.io/docs/using-steampipe/mod-variables#passing-input-variables).

## Contributing

If you have an idea for additional controls or just want to help maintain and extend this mod ([or others](https://github.com/topics/steampipe-mod)) we would love you to join the community and start contributing.

- **[Join our Slack community →](https://steampipe.io/community/join)** and hang out with other Mod developers.

Please see the [contribution guidelines](https://github.com/turbot/steampipe/blob/main/CONTRIBUTING.md) and our [code of conduct](https://github.com/turbot/steampipe/blob/main/CODE_OF_CONDUCT.md). All contributions are subject to the [Apache 2.0 open source license](https://github.com/turbot/steampipe-mod-aws-thrifty/blob/main/LICENSE).

Want to help but not sure where to start? Pick up one of the `help wanted` issues:

- [Steampipe](https://github.com/turbot/steampipe/labels/help%20wanted)
- [AWS Thrifty Mod](https://github.com/turbot/steampipe-mod-aws-thrifty/labels/help%20wanted)
