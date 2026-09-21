output "hosted_zone_id" {
  description = "ID of the existing Route 53 hosted zone"
  value       = data.aws_route53_zone.this.zone_id
}

output "fqdn" {
  description = "Fully qualified domain name of the created record"
  value       = aws_route53_record.alb_alias.fqdn
}