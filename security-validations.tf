# Security Controls Validations
# Enforces security standards based on metadata module security controls
# Supports selective overrides with documented justification

locals {
  # Use security controls if provided, otherwise use permissive defaults
  security_controls = var.security_controls != null ? var.security_controls : {
    encryption = {
      require_kms_customer_managed  = false
      require_encryption_at_rest    = false
      require_encryption_in_transit = false
      enable_kms_key_rotation       = false
    }
    logging = {
      require_cloudwatch_logs = false
      min_log_retention_days  = 1
      require_access_logging  = false
      require_flow_logs       = false
    }
  }

  # Apply overrides to security controls
  https_required          = local.security_controls.encryption.require_encryption_in_transit && !var.security_control_overrides.disable_https_requirement
  access_logging_required = local.security_controls.logging.require_access_logging && !var.security_control_overrides.disable_logging_requirement

  # Validation results
  https_validation_passed = !local.https_required || (
    var.default_cache_behavior.viewer_protocol_policy == "redirect-to-https" ||
    var.default_cache_behavior.viewer_protocol_policy == "https-only"
  )

  tls_version_validation_passed = !local.https_required || (
    var.minimum_protocol_version == "TLSv1.2_2021" ||
    var.minimum_protocol_version == "TLSv1.2_2019" ||
    var.minimum_protocol_version == "TLSv1.2_2018"
  )

  logging_validation_passed = !local.access_logging_required || (var.enable_logging && var.logging_bucket != null)

  # Audit trail for overrides
  has_overrides = (
    var.security_control_overrides.disable_https_requirement ||
    var.security_control_overrides.disable_logging_requirement ||
    var.security_control_overrides.disable_waf_requirement
  )

  justification_provided = var.security_control_overrides.justification != ""
  override_audit_passed  = !local.has_overrides || local.justification_provided
}

# Security Controls Check Block
check "security_controls_compliance" {
  assert {
    condition     = local.https_validation_passed
    error_message = "Security control violation: HTTPS is required but viewer_protocol_policy allows HTTP. Set viewer_protocol_policy to 'redirect-to-https' or 'https-only', or set security_control_overrides.disable_https_requirement=true with justification."
  }

  assert {
    condition     = local.tls_version_validation_passed
    error_message = "Security control violation: TLS 1.2 or higher is required. Set minimum_protocol_version to TLSv1.2_2021, TLSv1.2_2019, or TLSv1.2_2018."
  }

  assert {
    condition     = local.logging_validation_passed
    error_message = "Security control violation: Access logging is required but not configured. Set enable_logging=true and provide logging_bucket, or set security_control_overrides.disable_logging_requirement=true with justification."
  }

  assert {
    condition     = local.override_audit_passed
    error_message = "Security control overrides detected but no justification provided. Please document the business reason in security_control_overrides.justification for audit compliance."
  }
}
