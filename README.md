# Agribora System Engineering - GitOps Platform

> Production-grade Kubernetes GitOps platform built with Flux, ArgoCD, Vault, and OPA Gatekeeper.

## Table of Contents
1. Architecture
2. Stack
3. Prerequisites
4. Quick Start
5. Security
6. Repository Structure
7. Operations
8. Production DigitalOcean

---

## Architecture

GitHub (main branch) - Single Source of Truth
         |                        |
    Flux CD                  ArgoCD
    (Infrastructure)         (Applications)
         |                        |
    HelmReleases             HRMS 3-tier App
    Traefik                  frontend nginx
    ArgoCD                   redis cache
    Vault                    mariadb database
    ESO                           |
    Gatekeeper               Secrets from Vault
         |                   via ESO pipeline
         +------------------------+
              k3d / DOKS Cluster
         Security Layers Active:
         PSS + NetworkPolicies + RBAC
         ResourceQuotas + OPA + Tetragon

---

## Stack

| Layer              | Tool                   | Purpose                       |
|--------------------|------------------------|-------------------------------|
| IaC                | Terraform              | Cluster provisioning          |
| GitOps Engine      | FluxCD                 | Infrastructure reconciliation |
| App Delivery       | ArgoCD                 | Application deployment        |
| Ingress            | Traefik                | Traffic routing               |
| Secret Store       | HashiCorp Vault        | Secret management             |
| Secret Sync        | External Secrets ESO   | Vault to k8s secrets          |
| Policy Enforcement | OPA Gatekeeper         | Admission control             |
| Runtime Security   | Tetragon               | eBPF runtime monitoring       |
| Observability      | Prometheus + Grafana   | Metrics and dashboards        |
| Network Security   | NetworkPolicies        | Zero-trust isolation          |
| Pod Security       | PSS Restricted         | Container hardening           |

---

## Prerequisites

- Docker Desktop running
- k3d v5+
- kubectl v1.31+
- terraform v1.5+
- flux v2.8+
- helm v3+
- git

---

## Quick Start

### 1. Clone the repository
git clone https://github.com/WallaceJames/AGRIBORA-SYSTEM-ENGINEERING-.git
cd AGRIBORA-SYSTEM-ENGINEERING-

### 2. Configure credentials
cd terraform\local
copy terraform.tfvars.example terraform.tfvars
Edit terraform.tfvars with your GitHub token and username

### 3. Provision cluster and bootstrap Flux
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve

### 4. Fix kubeconfig - Windows required after every restart
Run in PowerShell:
$kc = "$env:USERPROFILE\.kube\config"
(Get-Content $kc -Raw) -replace "host.docker.internal","127.0.0.1" | Set-Content $kc

### 5. Seed Vault secrets
kubectl exec -n vault vault-0 -- vault auth enable kubernetes
kubectl exec -n vault vault-0 -- vault kv put secret/hrms/database root-password=ROOT user-password=USER
kubectl exec -n vault vault-0 -- vault kv put secret/hrms/redis password=REDIS

### 6. Verify the stack
kubectl get nodes
kubectl get pods -A
flux get helmreleases -A
kubectl get externalsecrets -n hrms

### 7. Access the application
Add to hosts file: 127.0.0.1 hrms.local
Open browser: http://hrms.local

---

## Security

| Control            | Implementation                 | Status  |
|--------------------|--------------------------------|---------|
| Secret Management  | HashiCorp Vault + ESO          | Active  |
| Network Isolation  | Default-deny NetworkPolicies   | Active  |
| Pod Security       | PSS Restricted profile         | Active  |
| Access Control     | RBAC least privilege           | Active  |
| Resource Limits    | ResourceQuota + LimitRange     | Active  |
| Admission Control  | OPA Gatekeeper policies        | Active  |
| Runtime Security   | Tetragon eBPF local            | Active  |
| Runtime Security   | Falco modern_ebpf production   | Planned |
| Image Scanning     | Trivy via GitHub Actions       | Active  |
| Audit Logging      | Kubernetes audit policy        | Active  |

### OPA Policies Enforced
- No latest image tags allowed
- No privileged containers
- Resource limits required on all containers
- Non-root execution required

### Network Policy Rules
- default-deny-all zero trust baseline
- allow-traefik-to-frontend
- allow-frontend-to-redis
- allow-frontend-to-db
- allow-eso-egress
- allow-kubelet-probes

---

## Repository Structure

AGRIBORA-SYSTEM-ENGINEERING-/
  .github/workflows/security-scan.yaml   Trivy image scanning CI
  apps/                                  HRMS application ArgoCD managed
    namespace.yaml
    frontend/                            nginx-unprivileged
    redis/                               Redis cache
    database/                            MariaDB StatefulSet
    netpol/                              6 NetworkPolicies
    rbac/                                4 roles and bindings
    quota/                               ResourceQuota + LimitRange
  argocd/hrms-app.yaml                   ArgoCD Application
  docs/ARCHITECTURE.md                   Architecture documentation
  external-secrets/                      ESO SecretStore + ExternalSecrets
  falco/README.md                        Falco production deployment guide
  flux/clusters/local/                   Flux HelmReleases
  flux/infrastructure/vault/             Vault HelmRelease
  gatekeeper/templates/                  4 ConstraintTemplates
  gatekeeper/constraints/                4 Constraints hrms namespace
  terraform/local/                       k3d cluster + Flux bootstrap
  terraform/digitalocean/                Production DOKS + Spaces + MySQL
  .gitignore
  README.md

---

## Operations

### Daily kubeconfig fix Windows
$kc = "$env:USERPROFILE\.kube\config"
(Get-Content $kc -Raw) -replace "host.docker.internal","127.0.0.1" | Set-Content $kc

### Re-seed Vault after restart
kubectl exec -n vault vault-0 -- vault auth enable kubernetes
kubectl exec -n vault vault-0 -- vault kv put secret/hrms/redis password=Redis@Agribora2026
kubectl exec -n vault vault-0 -- vault kv put secret/hrms/database root-password=Root@Agribora2026 user-password=User@Agribora2026

### Force Flux reconcile
flux reconcile kustomization flux-system --with-source

### Access UIs
ArgoCD:  kubectl port-forward svc/argocd-argocd-server -n argocd 8080:80
Vault:   kubectl port-forward svc/vault -n vault 8200:8200
Grafana: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80

### Git workflow
git checkout dev
git add .
git commit -m "type: description"
git push origin dev
git checkout main
git merge dev --no-edit
git push origin main
git checkout dev

---

## Production DigitalOcean

### What gets provisioned
- DOKS Kubernetes cluster auto-scaling 2-5 nodes s-2vcpu-4gb
- VPC with dedicated IP range 10.10.0.0/16
- Spaces bucket versioned 30-day lifecycle private
- Managed MySQL 8 database
- Database firewall DOKS cluster access only

### Plan only zero cost
cd terraform\digitalocean
terraform init
terraform plan -var="do_token=YOUR_DO_TOKEN"

### Apply requires billing
terraform apply -var-file=terraform.tfvars

### Estimated cost
Minimum 48 USD per month 2x s-2vcpu-4gb nodes + managed DB
With autoscaling to 5 nodes 100 USD per month

---

## Commit Convention

| Prefix    | Use for              |
|-----------|----------------------|
| feat:     | New feature          |
| fix:      | Bug fix              |
| security: | Security hardening   |
| refactor: | Code restructure     |
| docs:     | Documentation        |
| chore:    | Maintenance          |
