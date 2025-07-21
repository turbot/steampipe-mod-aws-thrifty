# Unused Resources

## Overview

Unused resources in AWS are those that are provisioned but not actively serving any purpose or workload. These resources continue to incur costs without providing value. Thrifty developers systematically identify and remove these resources to eliminate unnecessary expenses and improve operational efficiency.

## Purpose

The Unused Resources category helps organizations:
- Identify resources that are completely unused or orphaned
- Eliminate unnecessary costs by removing unused resources
- Improve operational efficiency through resource cleanup
- Reduce security risks associated with unmanaged resources
- Maintain a clean and organized AWS environment

## Key Principles

### Resource Lifecycle Management
- **Regular audits** identify unused resources across all AWS services
- **Automated detection** flags resources that haven't been accessed recently
- **Systematic cleanup** removes resources that are no longer needed

### Cost Elimination
- **Immediate savings** through removal of unused resources
- **Ongoing cost prevention** through better resource management
- **Operational efficiency** through reduced management overhead

### Security and Compliance
- **Reduced attack surface** by removing unmanaged resources
- **Compliance improvement** through better resource governance
- **Risk mitigation** through systematic resource cleanup

## Controls in This Category

### CloudWatch Log Streams
- **Control**: `cloudwatch_log_stream_unused`
- **Purpose**: Identifies CloudWatch log streams with no recent activity
- **Benefit**: Reduces storage costs and improves log management

### EBS Volumes
- **Control**: `ebs_volume_unattached`
- **Purpose**: Identifies EBS volumes not attached to any EC2 instances
- **Benefit**: Eliminates storage costs for unused volumes

### EBS Volumes on Stopped Instances
- **Control**: `ebs_volume_on_stopped_instances`
- **Purpose**: Identifies EBS volumes attached to stopped instances
- **Benefit**: Reduces costs by removing volumes from stopped instances

### Load Balancers
- **Control**: `ec2_application_lb_unused`
- **Purpose**: Identifies Application Load Balancers with no targets
- **Benefit**: Eliminates load balancer costs for unused services

### Classic Load Balancers
- **Control**: `ec2_classic_lb_unused`
- **Purpose**: Identifies Classic Load Balancers with no registered instances
- **Benefit**: Removes costs for unused load balancers

### Gateway Load Balancers
- **Control**: `ec2_gateway_lb_unused`
- **Purpose**: Identifies Gateway Load Balancers with no targets
- **Benefit**: Eliminates costs for unused gateway load balancers

### Network Load Balancers
- **Control**: `ec2_network_lb_unused`
- **Purpose**: Identifies Network Load Balancers with no targets
- **Benefit**: Removes costs for unused network load balancers

### Elastic IP Addresses
- **Control**: `ec2_eips_unattached`
- **Purpose**: Identifies unattached Elastic IP addresses
- **Benefit**: Eliminates charges for unused IP addresses

### EMR Clusters
- **Control**: `emr_cluster_idle_over_30_minutes`
- **Purpose**: Identifies EMR clusters that have been idle for extended periods
- **Benefit**: Reduces costs by terminating idle clusters

### Secrets Manager Secrets
- **Control**: `secretsmanager_secret_unused`
- **Purpose**: Identifies secrets that haven't been accessed recently
- **Benefit**: Reduces costs and improves security

### NAT Gateways
- **Control**: `vpc_nat_gateway_unused`
- **Purpose**: Identifies NAT gateways with no associated resources
- **Benefit**: Eliminates hourly charges for unused NAT gateways

### Route 53 Health Checks
- **Control**: `route53_health_check_unused`
- **Purpose**: Identifies Route 53 health checks not associated with records
- **Benefit**: Reduces DNS costs for unused health checks

### RDS Snapshots
- **Control**: `rds_db_snapshot_unused`
- **Purpose**: Identifies RDS snapshots that are no longer needed
- **Benefit**: Reduces storage costs for unnecessary snapshots

### ECR Repository Images
- **Control**: `ecr_repository_image_unused`
- **Purpose**: Identifies ECR repository images that haven't been pulled recently
- **Benefit**: Reduces storage costs for unused container images

### DynamoDB Tables
- **Control**: `dynamodb_table_zero_items`
- **Purpose**: Identifies DynamoDB tables with no data
- **Benefit**: Eliminates costs for empty tables

## Common Unused Resource Scenarios

### 1. Orphaned EBS Volumes
- **Scenario**: EBS volumes left behind after instance termination
- **Impact**: Ongoing storage costs without any value
- **Solution**: Regular cleanup of unattached volumes

### 2. Unused Load Balancers
- **Scenario**: Load balancers created for testing or temporary use
- **Impact**: Hourly charges for unused load balancer capacity
- **Solution**: Remove load balancers when no longer needed

### 3. Stale Elastic IPs
- **Scenario**: Elastic IPs allocated but not attached to instances
- **Impact**: Charges for unused IP addresses
- **Solution**: Release unattached Elastic IPs

### 4. Idle EMR Clusters
- **Scenario**: EMR clusters left running after job completion
- **Impact**: Ongoing compute and storage costs
- **Solution**: Implement auto-termination policies

### 5. Unused Secrets
- **Scenario**: Secrets stored but not accessed by applications
- **Impact**: Monthly charges for unused secrets
- **Solution**: Regular review and cleanup of unused secrets

## Best Practices

### 1. Regular Audits
- **Automated Scanning**: Use automated tools to identify unused resources
- **Manual Reviews**: Conduct periodic manual reviews of resource usage
- **Documentation**: Maintain records of cleanup activities

### 2. Resource Tagging
- **Purpose Tags**: Tag resources with their intended purpose
- **Owner Tags**: Assign ownership to resources for accountability
- **Expiration Tags**: Use tags to indicate when resources should be reviewed

### 3. Automated Cleanup
- **Lifecycle Policies**: Implement automated cleanup policies where possible
- **Scheduled Reviews**: Set up regular reviews of resource usage
- **Alerting**: Configure alerts for potential unused resources

### 4. Process Integration
- **Deployment Integration**: Include cleanup in deployment processes
- **Change Management**: Integrate resource cleanup into change management
- **Training**: Ensure teams understand resource lifecycle management

## Implementation Guidelines

### Step 1: Assessment
1. Run unused resource controls to identify cleanup candidates
2. Categorize resources by type and potential impact
3. Prioritize cleanup based on cost savings and risk

### Step 2: Planning
1. Develop cleanup procedures for each resource type
2. Create testing and validation procedures
3. Prepare rollback plans for critical resources

### Step 3: Execution
1. Start with low-risk, high-savings resources
2. Execute cleanup during maintenance windows
3. Monitor for any unexpected impacts

### Step 4: Validation
1. Verify that cleanup doesn't impact production services
2. Confirm cost savings are realized
3. Document lessons learned

### Step 5: Prevention
1. Implement automated detection and alerting
2. Establish regular review processes
3. Train teams on resource lifecycle management

## Expected Outcomes

By implementing effective unused resource management, organizations can expect:
- **5-15% reduction** in overall AWS costs
- **Improved operational efficiency** through reduced management overhead
- **Enhanced security** through reduced attack surface
- **Better resource governance** through systematic cleanup processes

## Resource-Specific Cleanup Strategies

### EBS Volumes
- **Snapshot Creation**: Create snapshots before deletion for backup
- **Verification**: Ensure volumes are truly unused before deletion
- **Automation**: Use AWS Lambda functions for automated cleanup

### Load Balancers
- **Target Verification**: Confirm no targets are using the load balancer
- **DNS Check**: Verify no DNS records point to the load balancer
- **Gradual Removal**: Remove targets first, then the load balancer

### Elastic IPs
- **Attachment Check**: Verify IPs are not attached to stopped instances
- **DNS Verification**: Check for DNS records using the IP
- **Release Process**: Use proper release procedures to avoid charges

### EMR Clusters
- **Job Completion**: Ensure all jobs are completed before termination
- **Data Preservation**: Verify data is saved before cluster termination
- **Auto-Termination**: Implement auto-termination policies

### Secrets Manager
- **Access Logs**: Review access logs to confirm unused status
- **Application Check**: Verify no applications are using the secrets
- **Backup**: Consider backing up secrets before deletion

## Metrics and KPIs

### Key Performance Indicators
- **Cost Savings**: Total cost reduction from unused resource cleanup
- **Resource Count**: Number of unused resources identified and removed
- **Cleanup Frequency**: Regular intervals for resource cleanup activities
- **Prevention Rate**: Reduction in new unused resources over time

### Monitoring Dashboards
- **Unused Resource Dashboard**: Real-time view of potentially unused resources
- **Cost Savings Dashboard**: Tracking of savings from cleanup activities
- **Resource Lifecycle Dashboard**: Monitoring of resource lifecycle management

## Related Resources

- [AWS Cost Optimization Best Practices](https://aws.amazon.com/cost-optimization/)
- [AWS Resource Groups](https://docs.aws.amazon.com/ARG/latest/userguide/welcome.html)
- [AWS Config](https://aws.amazon.com/config/)
- [AWS Systems Manager](https://aws.amazon.com/systems-manager/)
- [AWS Well-Architected Framework - Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)