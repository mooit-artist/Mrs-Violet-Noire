# Hostinger Terraform Provider Configuration
# Infrastructure as Code for Git Server and Web Hosting

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    hostinger = {
      source  = "hostinger/hostinger"
      version = "~> 0.1.18"
    }
  }
}

# Configure Hostinger provider
provider "hostinger" {
  # API token will be loaded from environment variable HOSTINGER_API_TOKEN
  # or you can specify it directly (not recommended for security)
  # api_token = var.hostinger_api_token
}

# Variables for configuration
variable "hostinger_api_token" {
  description = "Hostinger API token for authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key for VPS access"
  type        = string
  default     = ""
}

variable "git_server_hostname" {
  description = "Hostname for the Git server"
  type        = string
  default     = "git-server.example.com"
}

variable "domain_name" {
  description = "Domain name for DNS configuration"
  type        = string
  default     = "example.com"
}

variable "vps_plan" {
  description = "VPS plan to use for Git server"
  type        = string
  default     = "hostingercom-vps-kvm2-usd-1m"  # Basic VPS plan
}

variable "data_center_id" {
  description = "Data center ID for VPS deployment"
  type        = number
  default     = 13  # Default data center
}

variable "template_id" {
  description = "OS template ID (Ubuntu 22.04 LTS)"
  type        = number
  default     = 1002  # Ubuntu 22.04 LTS
}

# Container server specific variables
variable "container_vps_plan" {
  description = "VPS plan for container server (needs more resources)"
  type        = string
  default     = "hostingercom-vps-kvm4-usd-1m"  # Premium VPS plan for containers
}

variable "container_server_hostname" {
  description = "Hostname for the container server"
  type        = string
  default     = "container-server.example.com"
}
