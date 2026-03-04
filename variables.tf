# CloudFront Distribution Module Variables

# Metadata variables for consistent naming
variable "namespace" {
  description = "Namespace (organization/team name)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "name" {
  description = "Name of the CloudFront distribution"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

# CloudFront Distribution Configuration
variable "enabled" {
  description = "Whether the distribution is enabled"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 for the distribution"
  type        = bool
  default     = true
}

variable "comment" {
  description = "Comment for the distribution"
  type        = string
  default     = ""
}

variable "default_root_object" {
  description = "Object that CloudFront returns when a viewer requests the root URL"
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "Price class for the distribution (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be PriceClass_All, PriceClass_200, or PriceClass_100"
  }
}

variable "aliases" {
  description = "Alternate domain names (CNAMEs) for the distribution"
  type        = list(string)
  default     = []
}

variable "web_acl_id" {
  description = "AWS WAF web ACL ID to associate with the distribution"
  type        = string
  default     = null
}

# S3 Origin Configuration
variable "origin_domain_name" {
  description = "Domain name of the S3 bucket origin (e.g., bucket-name.s3.amazonaws.com or bucket-name.s3-website-region.amazonaws.com)"
  type        = string
}

variable "use_s3_website_endpoint" {
  description = "Use S3 website endpoint as origin (for static website hosting with index.html support)"
  type        = bool
  default     = false
}

variable "use_origin_access_control" {
  description = "Use Origin Access Control (OAC) for S3 origin access. Recommended over OAI"
  type        = bool
  default     = true
}

variable "origin_access_identity_path" {
  description = "CloudFront origin access identity path (legacy, use OAC instead). Required if use_origin_access_control is false"
  type        = string
  default     = null
}

# Cache Behavior Configuration
variable "default_cache_behavior" {
  description = "Default cache behavior configuration"
  type = object({
    allowed_methods        = list(string)
    cached_methods         = list(string)
    viewer_protocol_policy = string
    forward_query_string   = bool
    forward_headers        = list(string)
    forward_cookies        = string
    min_ttl                = number
    default_ttl            = number
    max_ttl                = number
    compress               = bool
    function_associations = list(object({
      event_type   = string
      function_arn = string
    }))
  })
  default = {
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
}

variable "ordered_cache_behaviors" {
  description = "Ordered list of cache behaviors"
  type = list(object({
    path_pattern           = string
    allowed_methods        = list(string)
    cached_methods         = list(string)
    viewer_protocol_policy = string
    forward_query_string   = bool
    forward_headers        = list(string)
    forward_cookies        = string
    min_ttl                = number
    default_ttl            = number
    max_ttl                = number
    compress               = bool
  }))
  default = []
}

# SSL/TLS Configuration
variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for custom domain. Must be in us-east-1 region"
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version"
  type        = string
  default     = "TLSv1.2_2021"

  validation {
    condition     = contains(["TLSv1.2_2021", "TLSv1.2_2019", "TLSv1.2_2018", "TLSv1.1_2016", "TLSv1_2016"], var.minimum_protocol_version)
    error_message = "Minimum protocol version must be TLSv1.2 or higher for security compliance"
  }
}

# Geo Restrictions
variable "geo_restriction_type" {
  description = "Method to restrict distribution by geography (none, whitelist, blacklist)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be none, whitelist, or blacklist"
  }
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1-alpha-2 country codes for geo restriction"
  type        = list(string)
  default     = []
}

# Custom Error Responses
variable "custom_error_responses" {
  description = "Custom error response configuration"
  type = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  default = [
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
}

# Logging Configuration
variable "enable_logging" {
  description = "Enable access logging for the distribution"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "S3 bucket for CloudFront access logs (must end with .s3.amazonaws.com). Required if enable_logging is true"
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefix for CloudFront access log objects"
  type        = string
  default     = "cloudfront/"
}

variable "logging_include_cookies" {
  description = "Include cookies in access logs"
  type        = bool
  default     = false
}

# Security Controls
variable "security_controls" {
  description = "Security controls configuration from metadata module. Used to enforce security standards"
  type = object({
    encryption = object({
      require_kms_customer_managed  = bool
      require_encryption_at_rest    = bool
      require_encryption_in_transit = bool
      enable_kms_key_rotation       = bool
    })
    logging = object({
      require_cloudwatch_logs = bool
      min_log_retention_days  = number
      require_access_logging  = bool
      require_flow_logs       = bool
    })
  })
  default = null
}

# Security Control Overrides
variable "security_control_overrides" {
  description = <<-EOT
    Override specific security controls for this CloudFront distribution.
    Only use when there's a documented business justification.
    
    Example use cases:
    - disable_https_requirement: Internal testing (non-production only)
    - disable_logging_requirement: Low-traffic sites (cost optimization)
    - disable_waf_requirement: Non-sensitive content (public documentation)
    
    IMPORTANT: Document the reason in the 'justification' field for audit purposes.
  EOT

  type = object({
    disable_https_requirement   = optional(bool, false)
    disable_logging_requirement = optional(bool, false)
    disable_waf_requirement     = optional(bool, false)

    # Audit trail - document why controls are disabled
    justification = optional(string, "")
  })

  default = {
    disable_https_requirement   = false
    disable_logging_requirement = false
    disable_waf_requirement     = false
    justification               = ""
  }
}
