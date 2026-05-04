# Agribora System Engineering - Architecture

## Stack Overview

GitHub (main branch) - Single Source of Truth
    Flux watches infrastructure HelmReleases
    ArgoCD watches apps and Deployments
    Both target the k3d / k8s Cluster

    Cluster namespaces:
    traefik | argocd | vault | external-secrets
    hrms-frontend (nginxinc-unprivileged)
    hrms-redis    (redis:alpine)
    hrms-mariadb  (mariadb:10.8)

## Security Layers

| Layer             | Tool                          | Status |
|-------------------|-------------------------------|--------|
| Pod Security      | Kubernetes PSS restricted     | Active |
| Network Policies  | Zero-trust deny-all           | Active |
| RBAC              | Least privilege roles         | Active |
| Resource Quotas   | CPU/Memory limits enforced    | Active |
| Admission Control | OPA Gatekeeper                | Active |
| Secret Management | Vault + External Secrets      | Active |
| Runtime Security  | Tetragon (local) Falco (prod) | Active |
| Image Scanning    | Trivy CI                      | Active |

## GitOps Workflow

1. Developer pushes to dev branch
2. PR reviewed and merged to main
3. Flux reconciles infrastructure
4. ArgoCD deploys applications
5. Gatekeeper enforces policies at admission
6. Tetragon monitors runtime behavior

## Namespace Layout

| Namespace         | Purpose             |
|-------------------|---------------------|
| flux-system       | GitOps engine       |
| traefik           | Ingress controller  |
| argocd            | App delivery        |
| vault             | Secret store        |
| external-secrets  | Secret sync         |
| gatekeeper-system | Policy enforcement  |
| tetragon          | Runtime security    |
| hrms              | Application workloads |
