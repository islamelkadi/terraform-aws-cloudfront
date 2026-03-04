# CloudFront Distribution Examples

This directory demonstrates various CloudFront distribution configurations with security control overrides.

## Examples Included

### 1. Basic Static Website
Minimal configuration for static website hosting with fictitious S3 origin.

**Features:**
- S3 origin with Origin Access Control (OAC)
- HTTPS enforcement (redirect HTTP to HTTPS)
- Default CloudFront certificate (*.cloudfront.net domain)
- SPA-friendly error responses (404/403 → index.html)
- Optimized caching for static content
- Logging disabled for dev (security control override)

### 2. Production CloudFront
Full compliance configuration with all security controls enforced.

**Features:**
- HTTPS enforcement with TLS 1.2+
- Access logging enabled
- Optional WAF integration
- Long cache TTLs for production
- Custom domain support (commented out)
- Geo-restriction support

### 3. Multi-Behavior CloudFront
Demonstrates ordered cache behaviors for different content types.

**Features:**
- Default behavior for HTML (1 hour cache)
- Static assets path (/static/*) with long cache (24 hours)
- API endpoints path (/api/*) with no cache
- Different forwarding rules per path pattern

## Prerequisites

Before using these examples, you need:

1. **S3 Bucket** - Create an S3 bucket for your static website
2. **S3 Bucket Policy** - Configure bucket policy to allow CloudFront access via OAC
3. **Content** - Upload your website files to the S3 bucket
4. **(Optional) ACM Certificate** - For custom domain (must be in us-east-1)
5. **(Optional) Logging Bucket** - For CloudFront access logs (production example)

## Usage

### Step 1: Update Variables

Edit `params/input.tfvars`:

```hcl
namespace   = "your-org"
environment = "dev"
region      = "us-east-1"
```

### Step 2: Update Origin Domain Names

In `main.tf`, replace the fictitious bucket names with your actual S3 buckets:

```hcl
# Replace this:
origin_domain_name = "my-static-website-bucket.s3.us-east-1.amazonaws.com"

# With your actual bucket:
origin_domain_name = "your-bucket-name.s3.us-east-1.amazonaws.com"
```

### Step 3: Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file=params/input.tfvars

# Apply the configuration
terraform apply -var-file=params/input.tfvars
```

### Step 4: Configure S3 Bucket Policy

After creating the distribution, you need to update your S3 bucket policy to allow CloudFront access via Origin Access Control (OAC).

Get the distribution ARN from Terraform output, then add this policy to your S3 bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket-name/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/ABCDEFGHIJK"
        }
      }
    }
  ]
}
```

Replace:
- `your-bucket-name` with your actual S3 bucket name
- `123456789012` with your AWS account ID
- `ABCDEFGHIJK` with your CloudFront distribution ID

### Step 5: Test

Access your CloudFront distribution URL (e.g., `https://d1234567890abc.cloudfront.net`) to verify it's serving content from your S3 bucket.

## Security Control Overrides

These examples demonstrate the security control override system:

### Basic Example
```hcl
security_control_overrides = {
  disable_logging_requirement = true
  justification               = "Development environment - access logging disabled for cost optimization."
}
```

### Production Example
No overrides - all security controls enforced (HTTPS, logging, etc.)

## Outputs

Each module provides these outputs:

- `distribution_id` - CloudFront distribution ID
- `distribution_arn` - CloudFront distribution ARN
- `domain_name` - CloudFront domain name (e.g., d1234567890abc.cloudfront.net)
- `hosted_zone_id` - CloudFront hosted zone ID (for Route53 alias records)

## Cost Estimate

**CloudFront Pricing (US/Europe):**
- Data transfer: ~$0.085 per GB (first 10 TB/month)
- HTTP/HTTPS requests: ~$0.0075 per 10,000 requests
- No additional charges for HTTPS, OAC, or custom SSL certificates

**Example Monthly Costs:**
- Low traffic (10 GB, 100K requests): ~$1.60
- Medium traffic (100 GB, 1M requests): ~$9.25
- High traffic (1 TB, 10M requests): ~$92.50

**Access Logging:**
- S3 storage: ~$0.023 per GB/month
- S3 PUT requests: ~$0.005 per 1,000 requests
- Estimated: ~$1-5/month for typical sites

## Custom Domain Setup

To use a custom domain (e.g., www.example.com):

1. **Request ACM Certificate** in us-east-1 region:
   ```bash
   aws acm request-certificate \
     --domain-name www.example.com \
     --validation-method DNS \
     --region us-east-1
   ```

2. **Validate Certificate** via DNS records

3. **Update CloudFront Configuration**:
   ```hcl
   acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
   aliases             = ["www.example.com"]
   ```

4. **Create Route53 Alias Record**:
   ```hcl
   resource "aws_route53_record" "www" {
     zone_id = aws_route53_zone.main.zone_id
     name    = "www.example.com"
     type    = "A"
     
     alias {
       name                   = module.basic_cloudfront.domain_name
       zone_id                = module.basic_cloudfront.hosted_zone_id
       evaluate_target_health = false
     }
   }
   ```

## Troubleshooting

### 403 Forbidden Error

**Cause:** S3 bucket policy not configured or incorrect distribution ARN

**Solution:** 
1. Verify bucket policy includes CloudFront service principal
2. Check `AWS:SourceArn` condition matches your distribution ARN
3. Ensure OAC is enabled (`use_origin_access_control = true`)

### 404 Not Found Error

**Cause:** Object doesn't exist in S3 bucket

**Solution:**
1. Verify files are uploaded to S3 bucket
2. Check object key matches requested path
3. For SPAs, ensure custom error responses are configured (404 → index.html)

### Slow Initial Load

**Cause:** CloudFront cold start (cache miss)

**Solution:**
1. Wait a few minutes for CloudFront to propagate
2. Subsequent requests will be cached and faster
3. Consider using CloudFront invalidations to pre-warm cache

### Custom Domain Not Working

**Cause:** ACM certificate not in us-east-1 or DNS not configured

**Solution:**
1. Ensure ACM certificate is in us-east-1 region (CloudFront requirement)
2. Verify DNS CNAME or alias record points to CloudFront domain
3. Wait for DNS propagation (up to 48 hours)

## Clean Up

```bash
# Destroy all resources
terraform destroy -var-file=params/input.tfvars
```

**Note:** CloudFront distributions take 15-20 minutes to fully delete.

## References

- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Origin Access Control (OAC)](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [Terraform AWS CloudFront Distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution)

