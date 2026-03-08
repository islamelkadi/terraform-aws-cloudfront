# Primary Module Example - This demonstrates the terraform-aws-cloudfront module
# Supporting infrastructure (S3 buckets) is defined in separate files
# to keep this example focused on the module's core functionality.
#
# CloudFront Distribution Examples
# Demonstrates various CloudFront configurations with security control overrides

# ============================================================================
# Example 1: Basic Static Website (Minimal Configuration)
# Override: Logging disabled for cost optimization in dev
# ============================================================================

module "basic_cloudfront" {
  source = "../"

  namespace   = var.namespace
  environment = var.environment
  name        = "static-website"
  region      = var.region

  # Direct reference to s3.tf module output
  origin_domain_name        = module.origin_bucket.bucket_domain_name
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
  source = "../"

  namespace   = var.namespace
  environment = "prod"
  name        = "production-website"
  region      = var.region

  # Direct reference to s3.tf module output
  origin_domain_name        = module.origin_bucket.bucket_domain_name
  use_origin_access_control = true

  # Custom domain with ACM certificate (must be in us-east-1)
  # acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  # aliases             = ["www.example.com", "example.com"]

  # HTTPS enforcement
  minimum_protocol_version = "TLSv1.2_2021"

  # Direct reference to s3.tf module output
  enable_logging          = true
  logging_bucket          = module.logging_bucket.bucket_domain_name
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
  source = "../"

  namespace   = var.namespace
  environment = var.environment
  name        = "multi-behavior"
  region      = var.region

  # Direct reference to s3.tf module output
  origin_domain_name        = module.origin_bucket.bucket_domain_name
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


