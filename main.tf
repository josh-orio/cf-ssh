locals {
  hostname       = "${var.machine_name}.${var.domain}"
  allowed_emails = [for e in split(",", var.allowed_emails) : trimspace(e) if trimspace(e) != ""]
}

resource "random_id" "tunnel_secret" {
  byte_length = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "ssh" {
  account_id = var.account_id
  name       = "${var.machine_name}-ssh"
  secret     = random_id.tunnel_secret.b64_std
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "ssh" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.ssh.id

  config {
    ingress_rule {
      hostname = local.hostname
      service  = "ssh://localhost:${var.ssh_port}"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "ssh" {
  zone_id = var.zone_id
  name    = var.machine_name
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.ssh.id}.cfargotunnel.com"
  proxied = true
}

# Only the listed emails can reach SSH through the tunnel
resource "cloudflare_zero_trust_access_application" "ssh" {
  account_id       = var.account_id
  name             = "${var.machine_name} SSH"
  domain           = local.hostname
  type             = "ssh"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "ssh_allow" {
  account_id     = var.account_id
  application_id = cloudflare_zero_trust_access_application.ssh.id
  name           = "Allow owners"
  precedence     = 1
  decision       = "allow"

  include {
    email = local.allowed_emails
  }
}
