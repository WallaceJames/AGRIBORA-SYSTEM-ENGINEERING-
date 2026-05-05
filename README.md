# Agribora HRMS Platform - Engineering Overview

## What This Is

This repository contains everything needed to run the Agribora HRMS
(Human Resource Management System) on Kubernetes - from local development
to production deployment on DigitalOcean.

The entire platform is managed through Git. Every change - whether to the
application, infrastructure, or security policies - goes through a pull
request. Nothing is changed manually on servers. This approach is called
GitOps.

---

## The Problem This Solves

Traditional deployments suffer from three common problems:
1. "It works on my machine" - environments differ between dev and production
2. Secret sprawl - passwords stored in spreadsheets, emails, or hardcoded
3. No audit trail - no record of who changed what and when

This platform eliminates all three:
- Every environment is defined in code and reproducible
- All passwords live in HashiCorp Vault, never in files or git
- Every change is a git commit with author, timestamp, and reason

---

## How It Works - Simple Explanation

Think of it like this:

    You write code -> Push to GitHub -> Platform automatically deploys it

More specifically:

    Developer pushes code to GitHub
           |
           v
    Flux CD watches GitHub (like a security guard watching a door)
    It sees the change and automatically updates infrastructure
           |
           v
    ArgoCD watches GitHub (a second guard focused on the application)
    It automatically deploys the updated application
           |
           v
    The HRMS application is running, secured, and monitored
    Users can access it at hrms.agribora.com

No one needs to SSH into servers. No manual steps. Everything is automatic
and traceable.

---

## What Gets Deployed

The HRMS application has three components running in the cluster:

    Frontend (Web Interface)
    The user-facing part of HRMS that staff interact with daily.
    Built with nginx, running securely as a non-administrator user.

    Redis (Speed Layer)
    A fast in-memory store that makes the application respond quickly
    by caching frequently accessed data.

    MariaDB (Database)
    The main database where all HR records, employee data, and
    configurations are stored. Data is persisted on disk and backed up.

---

## Security - What Protects The System

Security is built in 7 layers, not bolted on as an afterthought:

    Layer 1 - Admission Control (OPA Gatekeeper)
    Before any software runs in the cluster, it must pass a policy check.
    Like airport security - if you do not meet the requirements, you do
    not board the plane. We enforce:
    - No software with unknown/unspecified versions (no "latest" tags)
    - No software running as administrator
    - All software must declare memory and CPU requirements
    - All software must run as a non-root user

    Layer 2 - Pod Security Standards
    Kubernetes built-in security that enforces container hardening.
    Containers cannot escalate their own privileges, must drop all
    Linux capabilities, and must use approved security profiles.

    Layer 3 - Network Isolation (Zero Trust)
    By default, nothing can talk to anything else.
    Only explicitly allowed connections work:
    - Web traffic can reach the frontend
    - Frontend can reach the cache
    - Frontend can reach the database
    - Nothing else is permitted
    This means if one component is compromised, it cannot spread.

    Layer 4 - Access Control (RBAC)
    Different people get different levels of access:
    - Developers: can view logs and pod status, cannot touch secrets
    - Deployers: can update applications, cannot delete data
    - Monitors: can view metrics and health, read-only
    - Default: no access to secrets whatsoever

    Layer 5 - Secret Management (HashiCorp Vault)
    All passwords, API keys, and credentials are stored in Vault.
    Zero passwords exist anywhere in the codebase or git history.
    The system automatically rotates and distributes secrets to
    applications without human involvement.

    Layer 6 - Resource Controls
    Hard limits prevent any single application from consuming all
    cluster resources. Maximum 20 pods, 4 CPUs, and 4GB RAM for
    the HRMS namespace. This protects other workloads.

    Layer 7 - Runtime Security (Tetragon)
    Even after software passes all the above checks and is running,
    Tetragon watches it in real-time using eBPF technology.
    It detects and alerts on suspicious behavior like:
    - A database process trying to open a shell
    - Unexpected network connections
    - Privilege escalation attempts

---

## Environments

    Local Development (Current)
    Running on k3d (Kubernetes in Docker) on a developer laptop.
    Full production-equivalent setup for testing and demonstration.
    Cost: Free

    Production (Ready to Deploy)
    DigitalOcean Kubernetes Service (DOKS) in Frankfurt data center.
    Auto-scaling from 2 to 5 nodes based on demand.
    Managed MySQL database with automatic backups.
    Object storage for file backups with 30-day retention.
    Cost: Starting at 48 USD per month

---

## What Is In This Repository

Every file in this repository has a purpose:

    apps/
    The HRMS application definition. Describes exactly how the
    frontend, database, and cache should run, including all
    security policies and resource limits.

    flux/
    Infrastructure automation. Tells the cluster which platform
    components to install (load balancer, secret manager, etc.)

    gatekeeper/
    Security policies written as code. Four policies that block
    insecure software from running in the cluster.

    external-secrets/
    The bridge between HashiCorp Vault and the application.
    Tells the system which secrets the HRMS needs and where
    to find them in Vault.

    terraform/
    Infrastructure as code. Two environments:
    - local: creates a development cluster on your laptop
    - digitalocean: creates the full production environment

    .github/workflows/
    Automated security scanning that runs on every code change.
    Scans all container images for known vulnerabilities before
    they can be deployed.

    docs/
    Technical architecture documentation for engineering teams.

---

## Compliance and Audit

Every change to the platform is:
- Tracked in git with author name and timestamp
- Reviewed via pull request before merging
- Automatically deployed without manual server access
- Logged by Kubernetes audit logs

This creates a complete audit trail suitable for compliance reviews.

---

## Quick Health Check

To verify the platform is healthy, a DevOps engineer runs:

    kubectl get pods -A           Shows all running services
    flux get helmreleases -A      Shows infrastructure status
    kubectl get externalsecrets   Shows secret sync status

All components should show "Running" or "True" status.

---

## Production Deployment Checklist

When ready to go to production on DigitalOcean:

    1. Add DigitalOcean API credentials to terraform.tfvars
    2. Run: terraform apply in terraform/digitalocean/
    3. Bootstrap Flux on the new cluster
    4. Seed Vault with production credentials
    5. Update DNS to point to the new load balancer IP
    6. Enable Falco runtime security (production kernel supports it)
    7. Configure cert-manager for automatic HTTPS certificates

Estimated time from zero to production: 45 minutes.

---

## Technology Choices - Why These Tools

    Kubernetes    Industry standard container orchestration. Used by
                  Netflix, Airbnb, and thousands of enterprises.

    FluxCD        CNCF graduated project. Pulls changes from git
                  rather than pushing from CI, reducing attack surface.

    ArgoCD        CNCF incubating project. Gives visual dashboard
                  of application deployment status and history.

    HashiCorp Vault   Industry standard secret management.
                      Used by 70% of Fortune 500 companies.

    OPA Gatekeeper    Policy as code. Security rules are version
                      controlled and reviewed like application code.

    Traefik       Cloud-native load balancer purpose-built for
                  Kubernetes workloads.

    Terraform     Industry standard infrastructure as code.
                  Reproducible, reviewable, and auditable.

---

## Repository
https://github.com/WallaceJames/AGRIBORA-SYSTEM-ENGINEERING-

## Author
Agribora DevOps Engineering Team
