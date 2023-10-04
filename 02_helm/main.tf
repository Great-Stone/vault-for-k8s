############################################
# VSO
############################################
# Install the Vault Secrets Operator
# https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator#install-the-vault-secrets-operator
############################################
resource "kubernetes_namespace_v1" "vso" {
  metadata {
    name = "vault-secrets-operator-system"
  }
}

resource "helm_release" "vso" {
  name       = "vault-secrets-operator"
  namespace  = kubernetes_namespace_v1.vso.metadata[0].name
  chart      = "vault-secrets-operator"
  repository = "https://helm.releases.hashicorp.com"
  version    = "0.2.0"

  values = [
    "${file("vault-operator-values.yaml")}"
  ]
}

############################################
# CSI & Sidecar (Injecting)
############################################
# CSI : https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-secret-store-driver
# Sidecar : https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar
############################################
resource "helm_release" "vault" {
  name       = "vault"
  namespace  = "default"
  chart      = "vault"
  repository = "https://helm.releases.hashicorp.com"
  version    = "0.25.0"

  set {
    name  = "global.externalVaultAddr"
    value = var.vault_addr
  }

  set {
    name  = "injector.enabled"
    value = "true"
  }

  set {
    name  = "csi.enabled"
    value = "true"
  }
}

# CSI
resource "helm_release" "csi" {
  name       = "csi-secrets-store"
  namespace  = "default"
  chart      = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  version    = "1.3.4"

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }
}