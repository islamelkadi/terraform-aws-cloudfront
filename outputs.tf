# CloudFront Distribution Module Outputs

output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront distribution Route 53 hosted zone ID"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "distribution_status" {
  description = "CloudFront distribution status"
  value       = aws_cloudfront_distribution.this.status
}

output "origin_access_control_id" {
  description = "Origin Access Control ID (if created)"
  value       = var.use_origin_access_control ? aws_cloudfront_origin_access_control.this[0].id : null
}

output "tags" {
  description = "Tags applied to the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.tags
}
