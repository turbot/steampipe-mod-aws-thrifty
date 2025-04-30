# ECR Checks

Elastic Container Registry (ECR) is a fully managed container registry service. While it's relatively inexpensive, unused repositories and images still incur storage costs and can create clutter.

## Variables

This control uses the following variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ecr_unused_image_days` | The number of days an ECR repository can go without image pulls before being considered unused. | 90 |

## Unused ECR Repository Images Check

Identifies ECR repositories that may be unused based on image pull activity. A repository is considered potentially unused if:

- It has never had any images pulled
- No images have been pulled from it in the last 90 days (configurable via `ecr_unused_image_days`)

### Why This Matters

Unused ECR repositories:
- Incur storage costs for images that are no longer needed
- Create clutter that makes it harder to find active repositories
- May indicate abandoned projects or deprecated services
- Could contain outdated images with security vulnerabilities

### Resolution

For repositories flagged by this check:

1. Review if the repository and its images are still needed
2. If no longer needed:
   - Document the removal
   - Back up any images that need to be retained
   - Delete unused images
   - Delete the repository if empty
3. If still needed but inactive:
   - Consider implementing a lifecycle policy to clean up old images
   - Update documentation to indicate why the repository needs to be retained
   - Tag the repository appropriately 