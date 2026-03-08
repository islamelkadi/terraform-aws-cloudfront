# Terraform AWS CloudFront Module

Creates an AWS CloudFront distribution for static website hosting with S3 origin, SSL/TLS support, and comprehensive security controls.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Security](#security)
- [Features](#features)
- [Usage](#usage)
- [Requirements](#requirements)
- [MCP Servers](#mcp-servers)

## Prerequisites

This module is designed for macOS. The following must already be installed on your machine:
- Python 3 and pip
- [Kiro](https://kiro.dev) and Kiro CLI
- [Homebrew](https://brew.sh)

To install the remaining development tools, run:

```bash
make bootstrap
```

This will install/upgrade: tfenv, Terraform (via tfenv), tflint, terraform-docs, checkov, and pre-commit.

## Security

### Security Controls

This module implements security controls to comply with:
- AWS Foundational Security Best Practices (FSBP)
- CIS AWS Foundations Benchmark
- NIST 800-53 Rev 5
- NIST 800-171 Rev 2
- PCI DSS v4.0

### Implemented Controls

- [x] **Encryption in Transit**: TLS 1.2+ minimum protocol version
- [x] **HTTPS Enforcement**: Redirect HTTP to HTTPS or HTTPS-only
- [x] **Access Logging**: S3 bucket logging for distribution access
- [x] **Origin Access Control**: Modern OAC for S3 bucket access
- [x] **ACM Certificates**: SSL/TLS certificates for custom domains
- [x] **Geo Restrictions**: Optional geographic access controls
- [x] **WAF Integration**: Web Application Firewall support
- [x] **Security Control Overrides**: Extensible override system with audit justification

### Security Best Practices

**Production Distributions:**
- Use TLS 1.2+ minimum protocol version
- Enable HTTPS-only or redirect-to-https
- Enable access logging to S3
- Use Origin Access Control (OAC) for S3 origins
- Use ACM certificates for custom domains
- Configure WAF for additional protection
- Monitor CloudWatch metrics

**Development Distributions:**
- TLS 1.2+ still required
- Access logging optional for cost savings
- OAC still recommended

For complete security standards and implementation details, see [AWS Security Standards](../../../.kiro/steering/aws/aws-security-standards.md).

### Environment-Based Security Controls

Security controls are automatically applied based on the environment through the [terraform-aws-metadata](https://github.com/islamelkadi/terraform-aws-metadata?tab=readme-ov-file#security-profiles) module's security profiles:

| Control | Dev | Staging | Prod |
|---------|-----|---------|------|
| TLS 1.2+ minimum | Required | Required | Required |
| HTTPS enforcement | Required | Required | Required |
| Access logging | Optional | Required | Required |
| WAF integration | Optional | Recommended | Required |
| Origin Access Control | Recommended | Required | Required |

For full details on security profiles and how controls vary by environment, see the [Security Profiles](https://github.com/islamelkadi/terraform-aws-metadata?tab=readme-ov-file#security-profiles) documentation.

## Features

- **S3 Origin Support**: Configure S3 bucket as origin with Origin Access Control (OAC) or legacy OAI
- **SSL/TLS**: HTTPS enforcement with ACM certificate support and TLS 1.2+ minimum
- **Caching**: Configurable cache behaviors with TTL settings and compression
- **Security**: Built-in security controls for HTTPS, logging, and WAF integration
- **Custom Errors**: SPA-friendly error responses (404/403 → index.html)
- **Logging**: Optional access logging to S3
- **Geo Restrictions**: Optional geographic restrictions
- **Metadata Integration**: Consistent naming and tagging via metadata module

## MCP Servers

This module includes two [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) servers configured in `.kiro/settings/mcp.json` for use with Kiro:

| Server | Package | Description |
|--------|---------|-------------|
| `aws-docs` | `awslabs.aws-documentation-mcp-server@latest` | Provides access to AWS documentation for contextual lookups of service features, API references, and best practices. |
| `terraform` | `awslabs.terraform-mcp-server@latest` | Enables Terraform operations (init, validate, plan, fmt, tflint) directly from the IDE with auto-approved commands for common workflows. |

Both servers run via `uvx` and require no additional installation beyond the [bootstrap](#prerequisites) step.

<!-- BEGIN_TF_DOCS -->

## Usage

```hcl
# CloudFront Distribution Examples
# Demonstrates various CloudFront configurations with security control overrides

# ============================================================================
# Example 1: Basic Static Website (Minimal Configuration)
# Uses a fictitious S3 bucket origin - replace with your actual bucket
# Override: Logging disabled for cost optimization in dev
# ============================================================================

module "basic_cloudfront" {
  source = "github.com/islamelkadi/terraform-aws-cloudfront"
  namespace   = var.namespace
  environment = var.environment
  name        = "static-website"
  region      = var.region

  # S3 origin configuration - replace with your actual bucket
  origin_domain_name        = "my-static-website-bucket.s3.us-east-1.amazonaws.com"
  use_origin_access_control = true

  # Use CloudFront default certificate (no custom domain)
  acm_certificate_arn = null

  # Default cache behavior (optimized for static content)
  default_cache_behavior = {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    forward_query_string   = false
    forward_headers        = []
    forward_cookies        = "none"
    min_ttl                = 0
    default_ttl            = 3600  # 1 hour
    max_ttl                = 86400 # 24 hours
    compress               = true
    function_associations  = []
  }

  # SPA-friendly error responses
  custom_error_responses = [
    {
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    },
    {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    }
  ]

  # Security Control Override: Logging disabled for dev
  security_control_overrides = {
    disable_logging_requirement = true
    justification               = "Development environment - access logging disabled for cost optimization. Production will enable logging to separate audit bucket."
  }

  tags = {
    Project = "static-website"
    Example = "basic"
  }
}

# ============================================================================
# Example 2: Production CloudFront with Full Compliance
# All security controls enforced (HTTPS, Logging, WAF)
# ============================================================================

module "production_cloudfront" {
  source = "github.com/islamelkadi/terraform-aws-cloudfront"
  namespace   = var.namespace
  environment = "prod"
  name        = "production-website"
  region      = var.region

  # S3 origin configuration - replace with your actual bucket
  origin_domain_name        = "my-production-bucket.s3.us-east-1.amazonaws.com"
  use_origin_access_control = true

  # Custom domain with ACM certificate (must be in us-east-1)
  # acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  # aliases             = ["www.example.com", "example.com"]

  # HTTPS enforcement
  minimum_protocol_version = "TLSv1.2_2021"

  # Access logging enabled - replace with your actual logging bucket
  enable_logging          = true
  logging_bucket          = "my-cloudfront-logs-bucket.s3.amazonaws.com"
  logging_prefix          = "cloudfront/"
  logging_include_cookies = false

  # WAF integration (optional)
  # web_acl_id = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/example/abc123"

  # Cache behavior optimized for production
  default_cache_behavior = {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    forward_query_string   = false
    forward_headers        = []
    forward_cookies        = "none"
    min_ttl                = 0
    default_ttl            = 86400    # 24 hours
    max_ttl                = 31536000 # 1 year
    compress               = true
    function_associations  = []
  }

  # Geo restrictions (optional)
  geo_restriction_type      = "none"
  geo_restriction_locations = []

  # Custom error responses
  custom_error_responses = [
    {
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    }
  ]

  tags = {
    Environment = "Production"
    Compliance  = "FullyCompliant"
    Example     = "production"
  }
}

# ============================================================================
# Example 3: CloudFront with Custom Cache Behaviors
# Multiple cache behaviors for different content types
# ============================================================================

module "multi_behavior_cloudfront" {
  source = "github.com/islamelkadi/terraform-aws-cloudfront"
  namespace   = var.namespace
  environment = var.environment
  name        = "multi-behavior"
  region      = var.region

  # S3 origin configuration - replace with your actual bucket
  origin_domain_name        = "my-app-bucket.s3.us-east-1.amazonaws.com"
  use_origin_access_control = true

  # Default cache behavior for HTML
  default_cache_behavior = {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    forward_query_string   = false
    forward_headers        = []
    forward_cookies        = "none"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    function_associations  = []
  }

  # Ordered cache behaviors for specific paths
  ordered_cache_behaviors = [
    # Static assets (CSS, JS, images) - long cache
    {
      path_pattern           = "/static/*"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      forward_query_string   = false
      forward_headers        = []
      forward_cookies        = "none"
      min_ttl                = 0
      default_ttl            = 86400    # 24 hours
      max_ttl                = 31536000 # 1 year
      compress               = true
    },
    # API endpoints - no cache
    {
      path_pattern           = "/api/*"
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "https-only"
      forward_query_string   = true
      forward_headers        = ["Authorization", "CloudFront-Forwarded-Proto"]
      forward_cookies        = "all"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
      compress               = false
    }
  ]

  # Security Control Override: Logging disabled for dev
  security_control_overrides = {
    disable_logging_requirement = true
    justification               = "Development environment - demonstrating cache behaviors. Production will enable logging."
  }

  tags = {
    Example = "multi-behavior"
  }
}

```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.34 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_metadata"></a> [metadata](#module\_metadata) | github.com/islamelkadi/terraform-aws-metadata | v1.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ARN of ACM certificate for custom domain. Must be in us-east-1 region | `string` | `null` | no |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | Alternate domain names (CNAMEs) for the distribution | `list(string)` | `[]` | no |
| <a name="input_comment"></a> [comment](#input\_comment) | Comment for the distribution | `string` | `""` | no |
| <a name="input_custom_error_responses"></a> [custom\_error\_responses](#input\_custom\_error\_responses) | Custom error response configuration | <pre>list(object({<br/>    error_code            = number<br/>    response_code         = number<br/>    response_page_path    = string<br/>    error_caching_min_ttl = number<br/>  }))</pre> | <pre>[<br/>  {<br/>    "error_caching_min_ttl": 300,<br/>    "error_code": 404,<br/>    "response_code": 200,<br/>    "response_page_path": "/index.html"<br/>  },<br/>  {<br/>    "error_caching_min_ttl": 300,<br/>    "error_code": 403,<br/>    "response_code": 200,<br/>    "response_page_path": "/index.html"<br/>  }<br/>]</pre> | no |
| <a name="input_default_cache_behavior"></a> [default\_cache\_behavior](#input\_default\_cache\_behavior) | Default cache behavior configuration | <pre>object({<br/>    allowed_methods        = list(string)<br/>    cached_methods         = list(string)<br/>    viewer_protocol_policy = string<br/>    forward_query_string   = bool<br/>    forward_headers        = list(string)<br/>    forward_cookies        = string<br/>    min_ttl                = number<br/>    default_ttl            = number<br/>    max_ttl                = number<br/>    compress               = bool<br/>    function_associations = list(object({<br/>      event_type   = string<br/>      function_arn = string<br/>    }))<br/>  })</pre> | <pre>{<br/>  "allowed_methods": [<br/>    "GET",<br/>    "HEAD",<br/>    "OPTIONS"<br/>  ],<br/>  "cached_methods": [<br/>    "GET",<br/>    "HEAD"<br/>  ],<br/>  "compress": true,<br/>  "default_ttl": 3600,<br/>  "forward_cookies": "none",<br/>  "forward_headers": [],<br/>  "forward_query_string": false,<br/>  "function_associations": [],<br/>  "max_ttl": 86400,<br/>  "min_ttl": 0,<br/>  "viewer_protocol_policy": "redirect-to-https"<br/>}</pre> | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | Object that CloudFront returns when a viewer requests the root URL | `string` | `"index.html"` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | Enable IPv6 for the distribution | `bool` | `true` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Enable access logging for the distribution | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether the distribution is enabled | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_geo_restriction_locations"></a> [geo\_restriction\_locations](#input\_geo\_restriction\_locations) | ISO 3166-1-alpha-2 country codes for geo restriction | `list(string)` | `[]` | no |
| <a name="input_geo_restriction_type"></a> [geo\_restriction\_type](#input\_geo\_restriction\_type) | Method to restrict distribution by geography (none, whitelist, blacklist) | `string` | `"none"` | no |
| <a name="input_logging_bucket"></a> [logging\_bucket](#input\_logging\_bucket) | S3 bucket for CloudFront access logs (must end with .s3.amazonaws.com). Required if enable\_logging is true | `string` | `null` | no |
| <a name="input_logging_include_cookies"></a> [logging\_include\_cookies](#input\_logging\_include\_cookies) | Include cookies in access logs | `bool` | `false` | no |
| <a name="input_logging_prefix"></a> [logging\_prefix](#input\_logging\_prefix) | Prefix for CloudFront access log objects | `string` | `"cloudfront/"` | no |
| <a name="input_minimum_protocol_version"></a> [minimum\_protocol\_version](#input\_minimum\_protocol\_version) | Minimum TLS protocol version | `string` | `"TLSv1.2_2021"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the CloudFront distribution | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace (organization/team name) | `string` | n/a | yes |
| <a name="input_ordered_cache_behaviors"></a> [ordered\_cache\_behaviors](#input\_ordered\_cache\_behaviors) | Ordered list of cache behaviors | <pre>list(object({<br/>    path_pattern           = string<br/>    allowed_methods        = list(string)<br/>    cached_methods         = list(string)<br/>    viewer_protocol_policy = string<br/>    forward_query_string   = bool<br/>    forward_headers        = list(string)<br/>    forward_cookies        = string<br/>    min_ttl                = number<br/>    default_ttl            = number<br/>    max_ttl                = number<br/>    compress               = bool<br/>  }))</pre> | `[]` | no |
| <a name="input_origin_access_identity_path"></a> [origin\_access\_identity\_path](#input\_origin\_access\_identity\_path) | CloudFront origin access identity path (legacy, use OAC instead). Required if use\_origin\_access\_control is false | `string` | `null` | no |
| <a name="input_origin_domain_name"></a> [origin\_domain\_name](#input\_origin\_domain\_name) | Domain name of the S3 bucket origin (e.g., bucket-name.s3.amazonaws.com or bucket-name.s3-website-region.amazonaws.com) | `string` | n/a | yes |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | Price class for the distribution (PriceClass\_All, PriceClass\_200, PriceClass\_100) | `string` | `"PriceClass_100"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where resources will be created | `string` | n/a | yes |
| <a name="input_security_control_overrides"></a> [security\_control\_overrides](#input\_security\_control\_overrides) | Override specific security controls for this CloudFront distribution.<br/>Only use when there's a documented business justification.<br/><br/>Example use cases:<br/>- disable\_https\_requirement: Internal testing (non-production only)<br/>- disable\_logging\_requirement: Low-traffic sites (cost optimization)<br/>- disable\_waf\_requirement: Non-sensitive content (public documentation)<br/><br/>IMPORTANT: Document the reason in the 'justification' field for audit purposes. | <pre>object({<br/>    disable_https_requirement   = optional(bool, false)<br/>    disable_logging_requirement = optional(bool, false)<br/>    disable_waf_requirement     = optional(bool, false)<br/><br/>    # Audit trail - document why controls are disabled<br/>    justification = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "disable_https_requirement": false,<br/>  "disable_logging_requirement": false,<br/>  "disable_waf_requirement": false,<br/>  "justification": ""<br/>}</pre> | no |
| <a name="input_security_controls"></a> [security\_controls](#input\_security\_controls) | Security controls configuration from metadata module. Used to enforce security standards | <pre>object({<br/>    encryption = object({<br/>      require_kms_customer_managed  = bool<br/>      require_encryption_at_rest    = bool<br/>      require_encryption_in_transit = bool<br/>      enable_kms_key_rotation       = bool<br/>    })<br/>    logging = object({<br/>      require_cloudwatch_logs = bool<br/>      min_log_retention_days  = number<br/>      require_access_logging  = bool<br/>      require_flow_logs       = bool<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_use_origin_access_control"></a> [use\_origin\_access\_control](#input\_use\_origin\_access\_control) | Use Origin Access Control (OAC) for S3 origin access. Recommended over OAI | `bool` | `true` | no |
| <a name="input_use_s3_website_endpoint"></a> [use\_s3\_website\_endpoint](#input\_use\_s3\_website\_endpoint) | Use S3 website endpoint as origin (for static website hosting with index.html support) | `bool` | `false` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | AWS WAF web ACL ID to associate with the distribution | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_distribution_arn"></a> [distribution\_arn](#output\_distribution\_arn) | CloudFront distribution ARN |
| <a name="output_distribution_domain_name"></a> [distribution\_domain\_name](#output\_distribution\_domain\_name) | CloudFront distribution domain name |
| <a name="output_distribution_hosted_zone_id"></a> [distribution\_hosted\_zone\_id](#output\_distribution\_hosted\_zone\_id) | CloudFront distribution Route 53 hosted zone ID |
| <a name="output_distribution_id"></a> [distribution\_id](#output\_distribution\_id) | CloudFront distribution ID |
| <a name="output_distribution_status"></a> [distribution\_status](#output\_distribution\_status) | CloudFront distribution status |
| <a name="output_origin_access_control_id"></a> [origin\_access\_control\_id](#output\_origin\_access\_control\_id) | Origin Access Control ID (if created) |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to the CloudFront distribution |

## Example

See [example/](example/) for a complete working example with all features.

<!-- END_TF_DOCS -->
