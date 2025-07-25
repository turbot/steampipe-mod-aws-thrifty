# Outdated Resources

## Overview

AWS continuously releases new generations of cloud resources that deliver better performance, capacity, and cost efficiency. Thrifty developers prioritize upgrading to the latest resource generations to maximize value and minimize costs.

## Purpose

The Outdated Resources category helps organizations:
- Identify resources using older AWS resource generations
- Understand the cost and performance benefits of upgrading
- Prioritize upgrade efforts based on potential savings
- Maintain optimal resource configurations for cost efficiency

## Key Principles

### Performance and Cost Benefits
- **Newer generations** typically offer better performance at lower unit costs
- **Hardware improvements** provide better efficiency and reliability
- **Feature enhancements** enable new capabilities and optimizations

### Upgrade Strategy
- **Risk assessment** considers the impact of upgrades on production systems
- **Gradual migration** allows for testing and validation
- **Cost-benefit analysis** justifies upgrade investments

### Maintenance Best Practices
- **Regular evaluation** of resource generations ensures optimal configurations
- **Documentation** of upgrade procedures and rollback plans
- **Testing** in non-production environments before production deployment

## Controls in This Category

### EBS Volume Optimization
- **Control**: `ebs_volume_using_gp2`
- **Purpose**: Identifies EBS volumes using the older GP2 storage class
- **Benefit**: Upgrading to GP3 can save up to 20% on storage costs

### EBS IO1 Volume Review
- **Control**: `ebs_volume_using_io1`
- **Purpose**: Identifies EBS volumes using IO1 storage class
- **Benefit**: IO2 provides better performance and reliability at similar costs

### EC2 Instance Generation
- **Control**: `ec2_instance_older_generation`
- **Purpose**: Identifies EC2 instances using older instance types
- **Benefit**: Newer generations offer better performance and cost efficiency

### EMR Cluster Optimization
- **Control**: `emr_cluster_instance_prev_gen`
- **Purpose**: Identifies EMR clusters using previous generation instance types
- **Benefit**: Latest generations provide better hardware performance

### Lambda Graviton Migration
- **Control**: `lambda_function_with_graviton`
- **Purpose**: Identifies Lambda functions not using Graviton processors
- **Benefit**: Graviton provides up to 19% better performance at 20% lower cost

### RDS Graviton Migration
- **Control**: `rds_db_instance_without_graviton`
- **Purpose**: Identifies RDS instances not using Graviton processors
- **Benefit**: Graviton instances offer better performance and cost efficiency

### ECS Container Instance Optimization
- **Control**: `ecs_cluster_container_instance_without_graviton`
- **Purpose**: Identifies ECS container instances not using Graviton processors
- **Benefit**: Graviton provides better performance and cost efficiency

### RDS Instance Class Review
- **Control**: `rds_db_instance_prev_gen_class`
- **Purpose**: Identifies RDS instances using previous generation instance classes
- **Benefit**: Newer classes offer better performance and cost efficiency

### RDS Engine Version
- **Control**: `rds_db_instance_unsupported_engine_version`
- **Purpose**: Identifies RDS instances using unsupported engine versions
- **Benefit**: Supported versions receive security updates and performance improvements

### EKS Node Group Optimization
- **Control**: `eks_node_group_without_graviton`
- **Purpose**: Identifies EKS node groups not using Graviton processors
- **Benefit**: Graviton provides better performance and cost efficiency

### EC2 Graviton Migration
- **Control**: `ec2_instance_without_graviton`
- **Purpose**: Identifies EC2 instances not using Graviton processors
- **Benefit**: Graviton instances offer better performance and cost efficiency

## Upgrade Benefits by Resource Type

### EBS Volumes
- **GP2 to GP3**: Up to 20% cost savings with better performance
- **IO1 to IO2**: Better reliability and performance at similar costs
- **Standard to SSD**: Improved performance for frequently accessed data

### EC2 Instances
- **M3 to M5**: Over 7% cost savings with better performance
- **C4 to C5**: Improved compute performance and cost efficiency
- **R4 to R5**: Better memory performance and cost optimization

### RDS Instances
- **M3 to M5**: Over 7% cost savings with improved performance
- **Graviton Migration**: Up to 52% cost savings with better performance
- **Engine Updates**: Security improvements and new features

### Lambda Functions
- **Graviton Migration**: Up to 19% better performance at 20% lower cost
- **Runtime Updates**: Security patches and performance improvements

## Best Practices

### 1. Assessment and Planning
- **Inventory Analysis**: Identify all resources using older generations
- **Impact Assessment**: Evaluate the business impact of upgrades
- **Cost-Benefit Analysis**: Calculate potential savings and upgrade costs

### 2. Risk Management
- **Testing Strategy**: Test upgrades in non-production environments
- **Rollback Planning**: Prepare rollback procedures for each upgrade
- **Gradual Migration**: Implement upgrades incrementally to minimize risk

### 3. Implementation
- **Documentation**: Maintain detailed upgrade procedures and checklists
- **Monitoring**: Closely monitor performance during and after upgrades
- **Validation**: Verify that upgrades meet performance and cost expectations

### 4. Maintenance
- **Regular Reviews**: Schedule periodic reviews of resource generations
- **Automation**: Automate upgrade processes where possible
- **Training**: Ensure teams understand new features and capabilities

## Implementation Guidelines

### Step 1: Assessment
1. Run outdated resource controls to identify upgrade candidates
2. Prioritize resources based on potential savings and business impact
3. Assess compatibility and dependencies for each upgrade

### Step 2: Planning
1. Develop upgrade timelines and resource requirements
2. Create testing and validation procedures
3. Prepare rollback plans and emergency procedures

### Step 3: Testing
1. Test upgrades in non-production environments
2. Validate performance improvements and cost savings
3. Document lessons learned and best practices

### Step 4: Implementation
1. Execute upgrades during maintenance windows
2. Monitor performance and costs closely
3. Validate that business requirements are met

### Step 5: Optimization
1. Fine-tune configurations for optimal performance
2. Implement monitoring and alerting for new resources
3. Document new capabilities and optimization opportunities

## Expected Outcomes

By upgrading to newer resource generations, organizations can expect:
- **10-30% cost savings** across various resource types
- **Improved performance** and reliability
- **Enhanced security** through updated features and patches
- **Better scalability** and resource utilization

## Common Upgrade Scenarios

### 1. EBS Volume Migration
- **Scenario**: Migrating from GP2 to GP3 volumes
- **Process**: Create snapshots, create new volumes, attach and verify
- **Benefits**: Cost savings and improved performance

### 2. EC2 Instance Migration
- **Scenario**: Upgrading to newer instance generations
- **Process**: Launch new instances, migrate data, update DNS/load balancers
- **Benefits**: Better performance and cost efficiency

### 3. RDS Instance Migration
- **Scenario**: Upgrading instance classes or engine versions
- **Process**: Use AWS migration tools or create read replicas
- **Benefits**: Improved performance and security

### 4. Lambda Function Migration
- **Scenario**: Migrating to Graviton processors
- **Process**: Update function configuration and test thoroughly
- **Benefits**: Better performance and cost efficiency
