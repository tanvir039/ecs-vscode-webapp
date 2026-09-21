variable "domain_name" {
  description = "Primary domain name for the ACM certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names covered by the certificate"
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "ID of the Route 53 hosted zone used for DNS validation"
  type        = string
}

variable "tags" {
  description = "Common tags applied to ACM resources"
  type        = map(string)
  default     = {}
}