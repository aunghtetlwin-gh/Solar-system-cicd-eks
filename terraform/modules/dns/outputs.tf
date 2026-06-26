output "app_domain_name" {
  description = "Application DNS name managed by the delegated Route 53 hosted zone."
  value       = local.app_domain_name
}

output "app_route53_zone_id" {
  description = "Route 53 hosted zone ID for the delegated application subdomain."
  value       = aws_route53_zone.app.zone_id
}

output "app_route53_name_servers" {
  description = "Nameservers to add as NS records in Cloudflare for the delegated subdomain."
  value       = aws_route53_zone.app.name_servers
}

output "app_acm_certificate_arn" {
  description = "ACM certificate ARN for the application domain."
  value       = aws_acm_certificate.app.arn
}

output "app_acm_validation_records" {
  description = "ACM DNS validation records created in the delegated Route 53 hosted zone."
  value = [
    for record in aws_route53_record.app_certificate_validation : {
      name    = record.name
      type    = record.type
      records = record.records
    }
  ]
}

output "app_dns_alias_record" {
  description = "Route 53 alias record for the prod app domain, if ALB variables are set."
  value       = length(aws_route53_record.app_alias) > 0 ? aws_route53_record.app_alias[0].fqdn : null
}

output "dev_app_dns_alias_record" {
  description = "Route 53 alias record for the dev app domain, if ALB variables are set."
  value       = length(aws_route53_record.dev_app_alias) > 0 ? aws_route53_record.dev_app_alias[0].fqdn : null
}
