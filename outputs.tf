output "hostname" {
  value = local.hostname
}

output "tunnel_token" {
  description = "Run on the home machine: sudo cloudflared service install <token>"
  value       = cloudflare_zero_trust_tunnel_cloudflared.ssh.tunnel_token
  sensitive   = true
}

output "ssh_config_snippet" {
  value = <<-EOT
    Host ${local.hostname}
      ProxyCommand cloudflared access ssh --hostname %h
  EOT
}
