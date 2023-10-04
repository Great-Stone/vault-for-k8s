# Define a SecretProviderClass resource
# https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-secret-store-driver#define-a-secretproviderclass-resource
resource "kubernetes_manifest" "secretproviderclass_vault_secret" {

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "vault-kv"
      namespace = "default"
    }
    spec = {
      provider = "vault"
      secretObjects = [{
        data = [{
          key        = "password"
          objectName = "my-password"
        }]
        secretName = "mypass"
        type       = "Opaque"
      }]
      parameters = {
        roleName     = var.auth_kubernetes_rolename
        vaultAddress = var.vault_addr
        objects = jsonencode([{
          objectName = "my-password"
          secretPath = "${var.vault_kv_path}"
          secretKey  = "password"
        }])
      }
    }
  }

  field_manager {
    force_conflicts = true
  }
}

resource "kubernetes_pod_v1" "webapp_file" {
  metadata {
    name      = "webapp-file"
    namespace = "default"
  }

  spec {
    service_account_name = "webapp-sa"

    container {
      image = "jweissig/app:0.0.1"
      name  = "webapp"

      volume_mount {
        name       = "secrets-store-inline"
        mount_path = "/mnt/secrets-store"
        read_only  = true
      }
    }

    volume {
      name = "secrets-store-inline"

      csi {
        driver    = "secrets-store.csi.k8s.io"
        read_only = true

        volume_attributes = {
          secretProviderClass = kubernetes_manifest.secretproviderclass_vault_secret.manifest.metadata.name
        }
      }
    }
  }
}

resource "kubernetes_pod_v1" "webapp_secret" {
  metadata {
    name      = "webapp-secret"
    namespace = "default"
  }

  spec {
    service_account_name = "webapp-sa"

    container {
      image = "jweissig/app:0.0.1"
      name  = "webapp"

      env {
        name = "MY_PASSWORD"
        value_from {
          secret_key_ref {
            name = "mypass"
            key  = "password"
          }
        }
      }

      volume_mount {
        name       = "secrets-store-inline"
        mount_path = "/mnt/secrets-store"
        read_only  = true
      }
    }

    volume {
      name = "secrets-store-inline"

      csi {
        driver    = "secrets-store.csi.k8s.io"
        read_only = true

        volume_attributes = {
          secretProviderClass = kubernetes_manifest.secretproviderclass_vault_secret.manifest.metadata.name
        }
      }
    }
  }
}