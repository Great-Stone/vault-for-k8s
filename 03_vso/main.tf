# The Vault Secrets Operator on Kubernetes
# https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator

locals {
  kv_path_split = split("/", var.vault_kv_path)
}

resource "kubernetes_manifest" "vso_vault_auth" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultAuth"
    metadata = {
      name      = "static-auth"
      namespace = "default"
    }
    spec = {
      method = "kubernetes"
      mount  = var.vault_auth_kubernetes_path
      kubernetes = {
        role           = var.vault_auth_kubernetes_rolename
        serviceAccount = "webapp-sa"
        audiences      = ["vault"]
      }
    }
  }
}

# Deploy and sync a secret (KV)
resource "kubernetes_manifest" "vault_kv_app" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultStaticSecret"
    metadata = {
      name      = "vault-kv-app"
      namespace = "default"
    }
    spec = {
      vaultAuthRef = kubernetes_manifest.vso_vault_auth.manifest.metadata.name
      type  = "kv-v2"
      mount = local.kv_path_split[0]
      path  = trimprefix(var.vault_kv_path, "${local.kv_path_split[0]}/${local.kv_path_split[1]}/")
      destination = {
        name   = "secretkv"
        create = true
      }
      refreshAfter = "10s"
    }
  }
}

# Dynamic secrets (PKI)
# https://developer.hashicorp.com/vault/docs/platform/k8s/vso/sources/vault

resource "kubernetes_manifest" "vault_pki_app" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultPKISecret"
    metadata = {
      name      = "vault-pki-app"
      namespace = "default"
    }
    spec = {
      vaultAuthRef = kubernetes_manifest.vso_vault_auth.manifest.metadata.name
      mount = "pki"
      role = var.vault_pki_rolename
      commonName  = "test.example.com"
      format = "pem"
      expiryOffset = "2s"
      ttl = "30s"
      destination = {
        name   = "secretpki"
        create = true
      }
      rolloutRestartTargets = [{
        kind = "Deployment"
        name = "vso-pki-demo"
      }]
    }
  }
}

resource "kubernetes_deployment_v1" "vso_pki_demo" {
  depends_on = [kubernetes_manifest.vault_pki_app]

  metadata {
    name      = "vso-pki-demo"
    namespace = "default"
    labels = {
      test = "vso-pki-demo"
    }
  }

  spec {
    replicas = 2
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = 1
      }
    }

    selector {
      match_labels = {
        test = "vso-pki-demo"
      }
    }

    template {
      metadata {
        labels = {
          test = "vso-pki-demo"
        }
      }

      spec {
        volume {
          name = "secrets"
          secret {
            secret_name = "secretpki"
          }
        }

        container {
          name  = "webapp"
          image = "jweissig/app:0.0.1"

          env {
            name = "PKI_EXPIRATION"
            value_from {
              secret_key_ref {
                name = "secretpki"
                key  = "expiration"
              }
            }
          }

          volume_mount {
            name       = "secrets"
            mount_path = "/etc/secrets"
            read_only  = true
          }
        }
      }
    }
  }
}
