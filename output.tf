output "check_kubernetes_auth_login" {
  value = nonsensitive(module.auth.vault_auth_kubernetes_login_cli)
}

output "check_csi" {
  value = {
    file   = "kubectl exec webapp-file -- cat /mnt/secrets-store/my-password"
    secret = "kubectl exec webapp-secret -- env | grep MY_PASSWORD"
  }
}

output "check_sidecar" {
  value = {
    kv       = <<-EOF
    kubectl exec \
      $(kubectl get pod -l app=issues -o jsonpath="{.items[0].metadata.name}") \
      -c webapp -- cat /vault/secrets/database-config.txt
    EOF
    pki_cert = <<-EOF
    kubectl exec \
      $(kubectl get pod -l app=issues -o jsonpath="{.items[0].metadata.name}") \
      -c webapp -- cat /vault/secrets/cert.pem
    EOF
    pki_key  = <<-EOF
    kubectl exec \
      $(kubectl get pod -l app=issues -o jsonpath="{.items[0].metadata.name}") \
      -c webapp -- cat /vault/secrets/key.pem
    EOF
  }
}

output "check_vso" {
  value = {
    secretkv = "echo $(kubectl get secret secretkv -o jsonpath='{.data.password}') | base64 -d"
    secretpki = "echo $(kubectl get secret secretpki -o jsonpath='{.data.certificate}') | base64 -d"
    pod_check = <<-EOF
    kubectl exec \
      $(kubectl get pod -l test=vso-pki-demo -o jsonpath="{.items[0].metadata.name}") \
      -- env | grep PKI_EXPIRATION | awk -F'=' '{print $2}' | xargs date -r
    EOF
  }
}