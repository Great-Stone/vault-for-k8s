resource "kubernetes_manifest" "secretproviderclass_vault_secret" {
  manifest = {
    "apiVersion" = "secrets-store.csi.x-k8s.io/v1"
    "kind"       = "SecretProviderClass"
    "metadata" = {
      "name" = "vault-secret"
    }
    "spec" = {
      "parameters" = {
        "objects"      = <<-EOT
        - objectName: "my-password"
          secretPath: "kvv2/data/secret"
          secretKey: "password"
        EOT
        "roleName"     = "role1"
        "vaultAddress" = "http://host.minikube.internal:8200"
      }
      "provider" = "vault"
    }
  }
}
