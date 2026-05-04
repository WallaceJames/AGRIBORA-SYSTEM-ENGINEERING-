terraform {
  required_version = ">= 1.5.0"
  required_providers {
    null       = { source = "hashicorp/null",       version = "~> 3.2" }
    github     = { source = "integrations/github",  version = "~> 6.0" }
    flux       = { source = "fluxcd/flux",          version = "~> 1.3" }
    kubernetes = { source = "hashicorp/kubernetes",  version = "~> 2.27" }
  }
}

resource "null_resource" "k3d_cluster" {
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "k3d cluster delete agribora-local 2>$null; k3d cluster create agribora-local --port 80:80@loadbalancer --port 443:443@loadbalancer --k3s-arg --disable=traefik@server:0 --wait; k3d kubeconfig merge agribora-local --kubeconfig-merge-default"
  }
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["PowerShell", "-Command"]
    command     = "k3d cluster delete agribora-local 2>$null"
  }
}

resource "null_resource" "wait" {
  depends_on = [null_resource.k3d_cluster]
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "kubectl wait --for=condition=Ready nodes --all --timeout=120s"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-agribora-local"
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

provider "flux" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "k3d-agribora-local"
  }
  git = {
    url = "https://github.com/${var.github_owner}/${var.github_repository}.git"
    http = {
      username = var.github_owner
      password = var.github_token
    }
  }
}

resource "flux_bootstrap_git" "this" {
  depends_on = [null_resource.wait]
  path       = "flux/clusters/local"
}
