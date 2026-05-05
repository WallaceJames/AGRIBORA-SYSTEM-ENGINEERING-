output "cluster_id" {
  description = "DOKS cluster ID"
  value       = digitalocean_kubernetes_cluster.agribora.id
}

output "cluster_endpoint" {
  description = "DOKS API endpoint"
  value       = digitalocean_kubernetes_cluster.agribora.endpoint
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = digitalocean_kubernetes_cluster.agribora.version
}

output "spaces_bucket_name" {
  description = "Spaces bucket name for backups"
  value       = digitalocean_spaces_bucket.hrms_backups.name
}

output "spaces_bucket_domain" {
  description = "Spaces bucket domain"
  value       = digitalocean_spaces_bucket.hrms_backups.bucket_domain_name
}

output "database_host" {
  description = "Managed DB host"
  value       = digitalocean_database_cluster.hrms_db.host
  sensitive   = true
}

output "database_port" {
  description = "Managed DB port"
  value       = digitalocean_database_cluster.hrms_db.port
}

output "vpc_id" {
  description = "VPC ID"
  value       = digitalocean_vpc.agribora_vpc.id
}
