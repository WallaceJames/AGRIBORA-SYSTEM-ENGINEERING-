output "cluster_name" {
  value = var.cluster_name
}
output "kubeconfig_context" {
  value = "k3d-${var.cluster_name}"
}
