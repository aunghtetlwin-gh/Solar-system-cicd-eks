locals {
  app_domain_name = "${var.app_subdomain}.${var.root_domain_name}"
}

resource "aws_route53_zone" "app" {
  name    = local.app_domain_name
  comment = "Delegated hosted zone for the ${var.project_name} EKS application."

  tags = {
    Name = local.app_domain_name
  }
}

resource "aws_acm_certificate" "app" {
  domain_name       = local.app_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = local.app_domain_name
  }
}

resource "aws_route53_record" "app_certificate_validation" {
  for_each = {
    for option in aws_acm_certificate.app.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id = aws_route53_zone.app.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_route53_record" "app_alias" {
  count = var.app_alb_dns_name == "" || var.app_alb_zone_id == "" ? 0 : 1

  zone_id = aws_route53_zone.app.zone_id
  name    = local.app_domain_name
  type    = "A"

  alias {
    name                   = var.app_alb_dns_name
    zone_id                = var.app_alb_zone_id
    evaluate_target_health = true
  }
}
