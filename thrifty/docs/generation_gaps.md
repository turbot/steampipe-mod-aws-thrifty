
Thrifty developers prefer new generation of cloud resources to deliver better performance and capacity at a lower unit price. For instance by simply upgrading from `gp2` EBS volumes to `gp3` EBS volumes you can save up to 20% on your bills.

The same theme applies to EC2, RDS, and EMR instance types: older instance types should be replaced by latest instance types for better hardware performance. In the case of RDS instances, for example, switching from the M3 generation to M5 can save over 7% on your RDS bill.

Upgrading to the latest generation is often a quick configuration change, with little downtime impact, that yields a nice cost-saving benefit.

This dashboard answers the following questions:

- What EC2 instances are using older generation t2, m3, and m4 instance types?
- What EBS volumes are using gcp2 volumes instead of gp3?
- What EMR clusters, RDS DB instances and Redshift clusters are using previous generation instance and node types?
- What Lambda functions are not using the latest graviton2 processor?
