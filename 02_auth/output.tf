output "vault_auth_kubernetes_login_cli" {
  value = "vault write auth/${vault_auth_backend.kubernetes.path}/login role=${vault_kubernetes_auth_backend_role.example_role.role_name} jwt=${data.kubernetes_secret_v1.vault_auth_token.data["token"]}"
}

output "auth_kubernetes_path" {
  value = vault_auth_backend.kubernetes.path
}

output "auth_kubernetes_rolename" {
  value = vault_kubernetes_auth_backend_role.example_role.role_name
}

output "bound_service_account_names" {
  value = local.vault_auth_sa
}