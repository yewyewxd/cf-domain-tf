terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# --- VARIABLES ---
variable "api_token" {
  description = "Your Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "The domain name (e.g., example.com)"
  type        = string
}

variable "account_id" {
  description = "Your Cloudflare Account ID"
  type        = string
}

variable "zone_id" {
  description = "Your Cloudflare domain's Zone ID"
  type        = string
}

variable "forward_to_email" {
  description = "Destination email for routing"
  type        = string
}

# --- PROVIDER ---
provider "cloudflare" {
  api_token = var.api_token
}

# 1. SSL: Strict
resource "cloudflare_zone_setting" "ssl_strict" {
  zone_id    = var.zone_id
  setting_id = "ssl"
  value      = "strict"
}

# 2. HTTPS: Always On
resource "cloudflare_zone_setting" "https_always" {
  zone_id    = var.zone_id
  setting_id = "always_use_https"
  value      = "on"
}

# 3. Speed: Browser Insights (RUM)
resource "cloudflare_zone_setting" "rum" {
  zone_id    = var.zone_id
  setting_id = "browser_insights"
  value      = "on"
}

# 4. DNSSEC
resource "cloudflare_zone_dnssec" "main" {
  zone_id             = var.zone_id
  dnssec_multi_signer = true
  status              = "active"
}

# 5. Page Shield
# pass

# --- WAF Rules ---

# 6. Block Script Kiddies
resource "cloudflare_ruleset" "zone_waf" {
  zone_id = var.zone_id
  name    = "Custom rules"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = [{
    action      = "block"
    description = "Block script kiddie"
    enabled     = true
    expression  = "(http.request.uri.path contains \".php\") or (http.request.uri.path contains \".txt\") or (http.request.uri.path contains \".json\")"
    }
  ]
}

# 7. Rate Limiting
resource "cloudflare_ruleset" "rate_limiting" {
  zone_id = var.zone_id
  name    = "Rate limiting rules"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules = [{
    action      = "block"
    description = "API Rate Limiting"
    enabled     = true
    expression  = "(http.request.uri.path contains \"/api\")"
    ratelimit = {
      characteristics     = ["ip.src"]
      period              = 10
      requests_per_period = 25
      mitigation_timeout  = 10
    }
  }]
}

# 8. Email Routing

# A. Enable Email Routing
resource "cloudflare_email_routing_settings" "main" {
  zone_id = var.zone_id
}

# B. Create Routing Rule
resource "cloudflare_email_routing_rule" "hello_forwarding" {
  zone_id = var.zone_id
  name    = "Email routing from domain email to gmail"
  enabled = true

  matchers = [{
    type  = "literal"
    field = "to"
    value = "hello@${var.domain_name}"
    },
    {
      type  = "literal"
      field = "to"
      value = "support@${var.domain_name}"
  }]

  actions = [{
    type  = "forward"
    value = [var.forward_to_email]
  }]
}

# C. DNS Records
resource "cloudflare_dns_record" "email_mx_1" {
  zone_id  = var.zone_id
  name     = "@"
  type     = "MX"
  content  = "route1.mx.cloudflare.net"
  priority = 90
  ttl      = 3600
}

resource "cloudflare_dns_record" "email_mx_2" {
  zone_id  = var.zone_id
  name     = "@"
  type     = "MX"
  content  = "route2.mx.cloudflare.net"
  priority = 40
  ttl      = 3600
}

resource "cloudflare_dns_record" "email_mx_3" {
  zone_id  = var.zone_id
  name     = "@"
  type     = "MX"
  content  = "route3.mx.cloudflare.net"
  priority = 5
  ttl      = 3600
}

resource "cloudflare_dns_record" "email_spf" {
  zone_id = var.zone_id
  name    = "@"
  type    = "TXT"
  content = "v=spf1 include:_spf.mx.cloudflare.net ~all"
  ttl     = 3600
}
