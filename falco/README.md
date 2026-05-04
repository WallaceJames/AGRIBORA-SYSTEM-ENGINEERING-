# Falco Runtime Security

## Status
Falco is documented here for **production deployment only**.
It requires kernel-level eBPF access not available in k3d local environment.

## Production Deployment (DigitalOcean - Phase 7)
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set driver.kind=modern_ebpf \
  --set falcosidekick.enabled=true \
  --set falcosidekick.webui.enabled=true
```

## Custom HRMS Rules
See hrms-rules-values.yaml for production rules covering:
- Shell spawned in HRMS pod
- Unexpected outbound from MariaDB
- Secret file reads
- Privilege escalation attempts
- Unexpected filesystem writes
