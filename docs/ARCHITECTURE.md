# Agribora System Engineering - Architecture

## System Design

                    Developer
                        |
                   git push dev
                        |
                   Pull Request
                        |
                   merge to main
                        |
          +-------------+-------------+
          |                           |
       Flux CD                    ArgoCD
    Infrastructure              Applications
          |                           |
    HelmReleases               HRMS 3-tier App
    - Traefik                  - hrms-frontend
    - ArgoCD                   - hrms-redis
    - Vault                    - hrms-mariadb
    - ESO                           |
    - Gatekeeper              Secret Pipeline
          |                  Vault to ESO to k8s
          +----------+----------+
                     |
              k3d / DOKS Cluster
                     |
          +----------+----------+
          |          |          |
       hrms       monitoring  security
     namespace    namespace   namespace
          |
    Security Layers
    PSS + NetPol + RBAC
    ResourceQuota + OPA
    Tetragon runtime

---

## Namespace Layout

| Namespace         | Purpose                 | Components                       |
|-------------------|-------------------------|----------------------------------|
| flux-system       | GitOps reconciliation   | helm, kustomize, source, notify  |
| traefik           | Ingress controller      | traefik pod LoadBalancer svc     |
| argocd            | Application delivery    | server repo controller redis     |
| vault             | Secret store            | vault-0 dev mode agent-injector  |
| external-secrets  | Secret synchronization  | controller webhook cert-ctrl     |
| gatekeeper-system | Policy enforcement      | controller-manager audit         |
| tetragon          | Runtime security        | tetragon daemonset operator      |
| monitoring        | Observability           | prometheus grafana operator      |
| hrms              | Application workloads   | frontend redis mariadb           |

---

## Security Architecture - Defense in Depth

Layer 1 - Admission Control before pod runs
  OPA Gatekeeper enforces
  - No :latest image tags
  - No privileged containers
  - Resource limits required
  - Non-root execution required

Layer 2 - Pod Security Standards at scheduling
  Restricted profile enforced on hrms namespace
  - allowPrivilegeEscalation false
  - capabilities dropped ALL
  - runAsNonRoot true
  - seccompProfile RuntimeDefault

Layer 3 - Network Policies traffic control
  Zero-trust model
  - default-deny-all all ingress and egress blocked
  - allow-traefik-to-frontend port 8080 only
  - allow-frontend-to-redis port 6379 only
  - allow-frontend-to-db port 3306 only
  - allow-eso-egress ESO to Vault
  - allow-kubelet-probes health checks

Layer 4 - RBAC access control
  Least privilege roles
  - hrms-developer read-only pods services logs
  - hrms-deployer update deployments read secrets
  - hrms-monitor read metrics and status
  - default SA no secret access

Layer 5 - Secret Management
  Vault HashiCorp stores
  - secret/hrms/database root-password user-password
  - secret/hrms/redis password
  ESO syncs to Kubernetes Secrets every 1h
  Zero plaintext secrets in git

Layer 6 - Resource Controls
  ResourceQuota on hrms namespace
  - Max 20 pods
  - Max 2 CPU requests / 4 CPU limits
  - Max 2Gi memory requests / 4Gi memory limits
  LimitRange defaults per container
  - Request 100m CPU 128Mi RAM
  - Limit 500m CPU 256Mi RAM

Layer 7 - Runtime Security
  Tetragon local k3d environment
  - eBPF-based process monitoring
  - Network connection tracking
  Falco production DOKS
  - Custom rules for HRMS namespace
  - Shell spawn detection
  - Privilege escalation alerts
  - Secret file read monitoring

---

## GitOps Workflow

Push to dev -> PR review -> merge to main
                                  |
                    Flux detects change 1m interval
                                  |
                    +-------------+-------------+
                    |                           |
              Infrastructure              Application
              HelmReleases               ArgoCD sync
              reconciled                 automated
                    |                           |
              Gatekeeper validates       Pods updated
              admission policies         in cluster

---

## Data Flow

Request -> hrms.local port 80
    -> Traefik LoadBalancer
    -> IngressRoute host match
    -> hrms-frontend service
    -> nginx-unprivileged pod port 8080
    -> serves static HTML

Redis flow
    -> frontend pod
    -> hrms-redis service ClusterIP None
    -> redis pod requirepass from secret

Database flow
    -> frontend pod
    -> hrms-mariadb service ClusterIP None
    -> mariadb statefulset pod
    -> /var/lib/mysql PVC local-path 1Gi

Secret flow
    Vault pod dev mode root token
    -> ESO ClusterSecretStore kubernetes auth
    -> ExternalSecret 1h refresh
    -> Kubernetes Secret Opaque
    -> Pod env var secretKeyRef

---

## Production Design DigitalOcean

    Internet
        |
   DO Load Balancer
        |
   DOKS Cluster fra1
   VPC 10.10.0.0/16
   Nodes 2-5x s-2vcpu-4gb
        |
   +----+----+
   |         |
Traefik   ArgoCD
   |
HRMS App
   |
   +----+----+
   |         |
Vault    Managed MySQL 8
prod     private VPC only
   |
ESO -> Secrets

Backups -> DO Spaces versioned 30-day lifecycle
TLS    -> cert-manager + Lets Encrypt Phase 7
DNS    -> External DNS Phase 7

---

## CI/CD Pipeline

GitHub Actions security-scan.yaml runs on every push to main and dev
- Trivy scans nginx-unprivileged alpine
- Trivy scans mariadb 10.8
- Trivy scans redis alpine
- kubeval validates Kubernetes manifests
Results reported as GitHub Actions check
