# Metadata Module Integration
# Provides standardized naming, tagging, and security controls

module "metadata" {
  source = "github.com/islamelkadi/terraform-aws-metadata"

  namespace     = var.namespace
  project_name  = var.name
  environment   = var.environment
  resource_type = "cloudfront"
  region        = var.region
}
