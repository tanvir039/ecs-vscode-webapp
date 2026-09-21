variable "domain_name" {
  type        = string
  description = "The domain name for the existing Route 53 hosted zone and the A record to create (e.g. tm.tanvirahmed.uk)"
}

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the ALB to point the domain at"
}

variable "alb_zone_id" {
  type        = string
  description = "Hosted zone ID of the ALB (region-specific, from the ALB itself — not the domain's hosted zone)"
}