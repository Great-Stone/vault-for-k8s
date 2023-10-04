# Sidecar
# doc : https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar
# annotation : https://developer.hashicorp.com/vault/docs/platform/k8s/injector/annotations
resource "kubernetes_deployment" "webapp_sidecar" {
  metadata {
    name = "webapp-sidecar"
    labels = {
      app = "issues"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "issues"
      }
    }

    template {
      metadata {
        labels = {
          app = "issues"
        }

        annotations = {
          "vault.hashicorp.com/agent-inject"                              = "true"
          "vault.hashicorp.com/agent-inject-status"                       = "update"
          "vault.hashicorp.com/role"                                      = var.auth_kubernetes_rolename
          "vault.hashicorp.com/agent-inject-secret-database-config.txt"   = var.vault_kv_path
          "vault.hashicorp.com/agent-inject-template-database-config.txt" = <<-EOT
            {{- with secret "${var.vault_kv_path}" -}}
            postgresql://{{ .Data.data.username }}:{{ .Data.data.password }}@postgres:5432/wizard
            {{- end -}}
          EOT
          "vault.hashicorp.com/agent-inject-secret-cert.pem"              = "pki/issue/${var.vault_pki_rolename}"
          "vault.hashicorp.com/agent-inject-template-cert.pem"            = <<-EOT
            {{- with secret "pki/issue/${var.vault_pki_rolename}" "common_name=test.example.com" "ttl=10s" -}}
            {{ .Data.certificate }}
            {{ .Data.issuing_ca }}
            {{- end -}}
          EOT
          "vault.hashicorp.com/agent-inject-secret-key.pem"               = "pki/issue/${var.vault_pki_rolename}"
          "vault.hashicorp.com/agent-inject-template-key.pem"             = <<-EOT
            {{- with secret "pki/issue/${var.vault_pki_rolename}" "common_name=test.example.com" "ttl=10s" -}}
            {{ .Data.private_key }}
            {{- end -}}
          EOT
          "vault.hashicorp.com/template-static-secret-render-interval"    = "10s"
        }
      }

      spec {
        service_account_name = "webapp-sa"

        container {
          name  = "webapp"
          image = "jweissig/app:0.0.1"
        }
      }
    }
  }
}
