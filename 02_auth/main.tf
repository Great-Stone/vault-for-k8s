// Kubernetes Service Account, Cluster Role 및 Cluster Role Binding 생성:
locals {
  vault_auth_sa = [
    "vault-auth",
    "webapp-sa"
  ]
}

resource "kubernetes_secret_v1" "vault_auth" {
  for_each = toset(local.vault_auth_sa)

  metadata {
    name      = each.key
    namespace = "default"
    annotations = {
      "kubernetes.io/service-account.name" = each.key
    }
  }

  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_service_account_v1" "vault_auth" {
  for_each = toset(local.vault_auth_sa)

  metadata {
    name      = each.key
    namespace = "default"
  }
  secret {
    name = each.key
  }

  automount_service_account_token = false
}

resource "kubernetes_cluster_role_v1" "token_reviewer" {
  metadata {
    name = "token-reviewer"
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["get"]
  }
  rule {
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
    verbs      = ["create"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "token_reviewer" {
  for_each = toset(local.vault_auth_sa)

  metadata {
    name = "${each.key}-token-reviewer"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.token_reviewer.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.vault_auth[each.key].metadata[0].name
    namespace = "default"
  }
}

// Vault Kubernetes Auth 설정:
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "k8s_config" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = var.kubernetes_host
  kubernetes_ca_cert = var.kubernetes_ca_cert
  token_reviewer_jwt = data.kubernetes_secret_v1.vault_auth_token.data["token"]
}

data "kubernetes_secret_v1" "vault_auth_token" {
  metadata {
    name      = kubernetes_service_account_v1.vault_auth["vault-auth"].metadata[0].name
    namespace = "default"
  }
}

resource "vault_kubernetes_auth_backend_role" "example_role" {
  backend   = vault_auth_backend.kubernetes.path
  role_name = "example-role"
  bound_service_account_names      = local.vault_auth_sa
  bound_service_account_namespaces = ["default"]
  token_policies                   = var.policies
  token_ttl                        = 3600
}