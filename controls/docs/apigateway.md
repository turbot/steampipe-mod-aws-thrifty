# API Gateway Controls

## Overview

API Gateway controls help you optimize your API Gateway configuration for cost and performance.

## Controls

### API Gateway Stage Cache Enabled

API Gateway stage caching improves the performance of your APIs by storing frequently accessed responses in memory. This reduces the number of calls made to your backend services and can significantly improve latency for your API consumers.

When caching is disabled:
- Each request must be processed by your backend
- Response times may be higher
- Backend services may experience higher load
- You may incur higher costs due to increased backend processing

To enable caching for a stage:
1. Go to the API Gateway console
2. Select your API and stage
3. Under "Settings", enable "Cache Settings"
4. Configure the cache size and other parameters as needed

Note that caching does incur additional costs, but these are often offset by reduced backend costs and improved performance.

### API Gateway Stage Low Usage

API Gateway stages that haven't been updated in over 90 days may indicate unused or underutilized resources. Identifying and removing these resources can help reduce costs.

When an API Gateway has low usage:
- You're paying for resources that aren't providing value
- The API may be obsolete or replaced by newer versions
- Associated resources (Lambda functions, VPC endpoints, etc.) may also be unused

To optimize costs:
1. Review the usage patterns of flagged APIs
2. Determine if the API is still needed
3. If not needed:
   - Back up any important configurations
   - Delete the API and associated resources
4. If needed but rarely used:
   - Consider consolidating with other APIs
   - Implement auto-scaling if appropriate 