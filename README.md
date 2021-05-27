![image](https://hub.steampipe.io/images/mods/turbot/aws-thrifty-social-graphic.png)

# Thrifty Mod for AWS  |  powered by Steampipe 

Economy and good management checks for AWS.

Are you a **thrifty** AWS developer? Check your AWS account(s) for unused and under-utilized resources.

* **[Get started →](https://hub.steampipe.io/mods/turbot/aws_thrifty)**
* Documentation: [Controls](https://hub.steampipe.io/mods/turbot/aws_thrifty/controls)
* Community: [Slack Channel](https://join.slack.com/t/steampipe/shared_invite/zt-oij778tv-lYyRTWOTMQYBVAbtPSWs3g)
* Get involved: [Issues](https://github.com/turbot/steampipe-mod-aws-thrifty/issues)

## Quick start

Install the AWS plugin with [Steampipe](https://steampipe.io):
```shell
steampipe plugin install aws
```

Clone:
```sh
git clone git@github.com:turbot/steampipe-mod-aws-thrifty
cd steampipe-mod-aws-compliance
```

Run all benchmarks:
```shell
steampipe check all
```

Run a specific control:
```shell
steampipe check control.instances_with_low_utilization
```

## Developing

Have an idea for a thrifty check but aren't sure how to get started?
- **[Join our Slack community →](https://join.slack.com/t/steampipe/shared_invite/zt-oij778tv-lYyRTWOTMQYBVAbtPSWs3g)**
- **[Mod developer guide →](https://steampipe.io/docs/steampipe-mods/writing-mods.md)**

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
cd steampipe-mod-aws-compliance
```

**View controls and benchmarks**:
```
steampipe query "select resource_name from steampipe_control;"
```

```sql
steampipe query
> select
    resource_name
  from
    steampipe_benchmark
  order by
    resource_name;
```

## Contributing

Thanks for getting involved! We would love to have you [join our Slack community](https://join.slack.com/t/steampipe/shared_invite/zt-oij778tv-lYyRTWOTMQYBVAbtPSWs3g) and hang out with other Mod developers.

Please see the [contribution guidelines](https://github.com/turbot/steampipe/blob/main/CONTRIBUTING.md) and our [code of conduct](https://github.com/turbot/steampipe/blob/main/CODE_OF_CONDUCT.md). All contributions are subject to the [Apache 2.0 open source license](https://github.com/turbot/steampipe-mod-aws-compliance/blob/main/LICENSE).

`help wanted` issues:
- [Steampipe](https://github.com/turbot/steampipe/labels/help%20wanted)
- [AWS Thrifty Mod](https://github.com/turbot/steampipe-mod-aws-thrifty/labels/help%20wanted)
