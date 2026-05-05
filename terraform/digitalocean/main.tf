# =============================================================================
# Agribora DevOps Task  DigitalOcean Production Infrastructure
# Provider: DOKS + Spaces + Managed MySQL
# NOTE: Run terraform plan -var="do_token=YOUR_TOKEN" to validate
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

#  DOKS Cluster 
resource "digitalocean_kubernetes_cluster" "agribora" {
  name    = var.cluster_name
  region  = var.region
  version = "1.31.1-do.4"

  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    node_count = var.node_count
    auto_scale = true
    min_nodes  = 2
    max_nodes  = 5

    labels = {
      env  = "production"
      team = "agribora-devops"
    }
  }

  maintenance_policy {
    start_time = "04:00"
    day        = "sunday"
  }
}

#  Spaces Bucket (S3-compatible backup storage) 
resource "digitalocean_spaces_bucket" "hrms_backups" {
  name   = var.spaces_bucket_name
  region = var.region
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      days = 7
    }
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://agribora.com"]
    max_age_seconds = 3000
  }
}

#  Managed MySQL Database 
resource "digitalocean_database_cluster" "hrms_db" {
  name       = "agribora-hrms-db"
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1

  maintenance_window {
    hour = "04:00"
    day  = "sunday"
  }
}

#  Database firewall (only allow from DOKS cluster) 
resource "digitalocean_database_firewall" "hrms_db_firewall" {
  cluster_id = digitalocean_database_cluster.hrms_db.id

  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.agribora.id
  }
}

#  VPC for network isolation 
resource "digitalocean_vpc" "agribora_vpc" {
  name     = "agribora-vpc"
  region   = var.region
  ip_range = "10.10.0.0/16"
}
