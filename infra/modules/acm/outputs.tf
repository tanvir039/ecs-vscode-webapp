output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "domain_name" {
  description = "Primary domain name covered by the certificate"
  value       = aws_acm_certificate.this.domain_name
}

output "validation_record_fqdns" {
  description = "DNS records used to validate the certificate"
  value = [
    for record in aws_route53_record.validation :
    record.fqdn
  ]
}