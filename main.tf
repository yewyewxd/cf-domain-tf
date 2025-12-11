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

variable "zone_id" {
  description = "Your Cloudflare domain's Zone ID"
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


# 3. DNSSEC
resource "cloudflare_zone_dnssec" "main" {
  zone_id             = var.zone_id
  dnssec_multi_signer = true
  status              = "active"
}


# --- WAF Rules ---

# 4. Block Script Kiddies
resource "cloudflare_ruleset" "zone_waf" {
  zone_id = var.zone_id
  name    = "Custom rules"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = [{
    action      = "block"
    description = "Block script kiddie"
    enabled     = true
    expression  = "(http.request.uri.path contains \".php\") or (http.request.uri.path contains \".json\")"
    }
  ]
}

# 5. Rate Limiting
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
      characteristics     = ["ip.src", "cf.colo.id"]
      period              = 10
      requests_per_period = 25
      mitigation_timeout  = 10
    }
  }]
}
