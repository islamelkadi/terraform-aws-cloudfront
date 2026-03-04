# Local values for CloudFront module

locals {
  # Use metadata module for consistent naming
  # CloudFront OAC name has max length of 64 characters
  distribution_name = substr(module.metadata.resource_prefix, 0, min(64, length(module.metadata.resource_prefix)))
  origin_id         = "${local.distribution_name}-origin"

  # Merge tags from metadata module with user-provided tags
  tags = merge(
    var.tags,
    module.metadata.security_tags,
    {
      Module = "terraform-aws-cloudfront"
    }
  )
}
