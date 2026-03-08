# Supporting Infrastructure - Real S3 resources for testing
# This infrastructure is created from remote GitHub modules to provide
# realistic S3 origin dependencies for the primary module example.
# 
# Available module outputs (reference directly in main.tf):
# - module.origin_bucket.bucket_name
# - module.origin_bucket.bucket_domain_name
# - module.logging_bucket.bucket_name
# - module.logging_bucket.bucket_domain_name
#
# Example usage in main.tf:
#   origin_domain_name = module.origin_bucket.bucket_domain_name

module "kms_key" {
  source = "git::https://github.com/islamelkadi/terraform-aws-kms.git?ref=v1.0.0"

  namespace   = var.namespace
  environment = var.environment
  name        = "example-key"
  region      = var.region

  description             = "KMS key for example infrastructure"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Purpose = "example-supporting-infrastructure"
  }
}

module "origin_bucket" {
  source = "git::https://github.com/islamelkadi/terraform-aws-s3.git?ref=v1.0.0"

  namespace   = var.namespace
  environment = var.environment
  name        = "cloudfront-origin"
  region      = var.region

  kms_key_arn = module.kms_key.key_arn

  enable_versioning = true

  security_control_overrides = {
    disable_logging_requirement = true
    justification               = "Origin bucket for CloudFront - logging handled at CloudFront level"
  }

  tags = {
    Purpose = "example-supporting-infrastructure"
  }
}

module "logging_bucket" {
  source = "git::https://github.com/islamelkadi/terraform-aws-s3.git?ref=v1.0.0"

  namespace   = var.namespace
  environment = var.environment
  name        = "cloudfront-logs"
  region      = var.region

  kms_key_arn = module.kms_key.key_arn

  enable_lifecycle_policy = true
  glacier_transition_days = 90

  security_control_overrides = {
    disable_logging_requirement = true
    justification               = "This is a logging bucket - recursive logging not required"
  }

  tags = {
    Purpose = "example-supporting-infrastructure"
  }
}
