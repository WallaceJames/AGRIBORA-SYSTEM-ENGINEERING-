variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "fra1"
}

variable "cluster_name" {
  description = "DOKS cluster name"
  type        = string
  default     = "agribora-prod"
}

variable "node_size" {
  description = "Droplet size for worker nodes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "spaces_bucket_name" {
  description = "Name of the Spaces bucket for backups"
  type        = string
  default     = "agribora-hrms-backups"
}
