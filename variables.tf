variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID for your domain"
  type        = string
}

variable "domain" {
  description = "Your domain, e.g. example.com"
  type        = string
}

variable "machine_name" {
  description = "Subdomain for the machine, e.g. homebox -> homebox.example.com"
  type        = string
}

variable "ssh_port" {
  description = "SSH port on the home machine"
  type        = number
  default     = 22
}

variable "allowed_emails" {
  description = "Comma-separated emails allowed through Cloudflare Access, e.g. a@x.com,b@y.com"
  type        = string
}
