# ECR Checks

Elastic Container Registry (ECR) is a fully managed container registry service. While it's relatively inexpensive, unused repositories and images still incur storage costs and can create clutter.

## Variables

This control uses the following variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ecr_repository_image_age_max_days` | The number of days an ECR repository can go without image pulls before being considered unused. | 90 |

