variable "github_token" {
  description = "GitHub PAT for Flux bootstrap"
  type        = string
  sensitive   = true
}
variable "github_owner" {
  description = "Your GitHub username"
  type        = string
}
variable "github_repository" {
  type    = string
  default = "AGRIBORA-SYSTEM-ENGINEERING-"
}
variable "cluster_name" {
  type    = string
  default = "agribora-local"
}
