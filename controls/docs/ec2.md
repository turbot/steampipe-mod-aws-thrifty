# Thrifty EC2 Benchmark

Thrifty developers eliminate thier unused and under-utilized EC2 instances. This benchmark focuses on finding resources that have not been restarted recently, have low utilization and are using very large instance sizes.

## Help wanted
- add checks for cost allocation tags
- add checkd for use of t2, m3 and m4 instances sizes (t3 and m5 are more cost effective)
- change logic for cpu utilization to check for max(average) instead of avg(max) utilization