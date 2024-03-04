# AWS Thrifty Mod for Powerpipe

An AWS cost savings and waste checking tool.

Run checks in a dashboard:

![image](https://raw.githubusercontent.com/turbot/steampipe-mod-aws-thrifty/main/docs/aws_thrifty_dashboard.png)

Or in a terminal:

![image](https://raw.githubusercontent.com/turbot/steampipe-mod-aws-thrifty/main/docs/aws_thrifty_mod_terminal.png)

## Documentation

- **[Benchmarks and controls →](https://hub.powerpipe.io/mods/turbot/aws_thrifty/controls)**
- **[Named queries →](https://hub.powerpipe.io/mods/turbot/aws_thrifty/queries)**

## Getting Started

### Installation

Install Powerpipe (https://powerpipe.io/downloads), or use Brew:

```sh
brew install turbot/tap/powerpipe
```

This mod also requires [Steampipe](https://steampipe.io) with the [AWS plugin](https://hub.steampipe.io/plugins/turbot/aws) as the data source. Install Steampipe (https://steampipe.io/downloads), or use Brew:

```sh
brew install turbot/tap/steampipe
steampipe plugin install aws
```

Steampipe will automatically use your default AWS credentials. Optionally, you can [setup multiple accounts](https://hub.steampipe.io/plugins/turbot/aws#multi-account-connections) or [customize AWS credentials](https://hub.steampipe.io/plugins/turbot/aws#configuring-aws-credentials).

Finally, install the mod:

```sh
mkdir dashboards
cd dashboards
powerpipe mod init
powerpipe mod install github.com/turbot/steampipe-mod-aws-thrifty
```

### Browsing Dashboards

Start Steampipe as the data source:

```sh
steampipe service start
```

Start the dashboard server:

```sh
powerpipe server
```

Browse and view your dashboards at **https://localhost:9033**.

### Running Checks in Your Terminal

Instead of running benchmarks in a dashboard, you can also run them within your
terminal with the `powerpipe benchmark` command:

List available benchmarks:

```sh
powerpipe benchmark list
```

Run a benchmark:

```sh
powerpipe benchmark run ec2
```

Different output formats are also available, for more information please see
[Output Formats](https://powerpipe.io/docs/reference/cli/benchmark#output-formats).

### Configuration

Several benchmarks have [input variables](https://powerpipe.io/docs/build/mod-variables#input-variables) that can be configured to better match your environment and requirements. Each variable has a default defined in its source file, e.g., `controls/rds.sp`, but these can be overwritten in several ways:

- Copy and rename the `powerpipe.ppvars.example` file to `powerpipe.ppvars`, and then modify the variable values inside that file
- Pass in a value on the command line:

  ```sh
  powerpipe benchmark run ec2 --var='trusted_accounts=["123456789012", "123123123123"]'
  ```

- Set an environment variable:

  ```sh
  PP_VAR_trusted_accounts='["123456789012", "123123123123"]' powerpipe control run large_ec2_instances
  ```

  - Note: When using environment variables, if the variable is defined in `powerpipe.ppvars` or passed in through the command line, either of those will take precedence over the environment variable value. For more information on variable definition precedence, please see the link below.

These are only some of the ways you can set variables. For a full list, please see [Passing Input Variables](https://powerpipe.io/docs/build/mod-variables#passing-input-variables).

### Common and Tag Dimensions

The benchmark queries use common properties (like `account_id`, `connection_name` and `region`) and tags that are defined in the form of a default list of strings in the `mod.sp` file. These properties can be overwritten in several ways:

- Copy and rename the `powerpipe.ppvars.example` file to `powerpipe.ppvars`, and then modify the variable values inside that file
- Pass in a value on the command line:

  ```sh
  powerpipe benchmark run lambda --var 'common_dimensions=["account_id", "connection_name", "region"]'
  ```

  ```sh
  powerpipe benchmark run lambda --var 'tag_dimensions=["Environment", "Owner"]'
  ```

- Set an environment variable:

  ```sh
  PP_VAR_common_dimensions='["account_id", "connection_name", "region"]' powerpipe control run long_running_ec2_instances
  ```

  ```sh
  PP_VAR_tag_dimensions='["Environment", "Owner"]' powerpipe control run long_running_ec2_instances
  ```

## Open Source & Contributing

This repository is published under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0). Please see our [code of conduct](https://github.com/turbot/.github/blob/main/CODE_OF_CONDUCT.md). We look forward to collaborating with you!

[Steampipe](https://steampipe.io) and [Powerpipe](https://powerpipe.io) are products produced from this open source software, exclusively by [Turbot HQ, Inc](https://turbot.com). They are distributed under our commercial terms. Others are allowed to make their own distribution of the software, but cannot use any of the Turbot trademarks, cloud services, etc. You can learn more in our [Open Source FAQ](https://turbot.com/open-source).

## Get Involved

**[Join #powerpipe on Slack →](https://turbot.com/community/join)**

Want to help but don't know where to start? Pick up one of the `help wanted` issues:

- [Powerpipe](https://github.com/turbot/powerpipe/labels/help%20wanted)
- [AWS Thrifty Mod](https://github.com/turbot/steampipe-mod-aws-thrifty/labels/help%20wanted)
