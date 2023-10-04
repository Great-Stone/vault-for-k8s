output "policies" {
  value = [
    vault_policy.kvv2.name,
    vault_policy.pki.name,
    // vault_policy.transit.name
  ]
}

output "vault_kv_path" {
  value = vault_kv_secret_v2.kvv2.path
}

output "vault_pki_rolename" {
  value = vault_pki_secret_backend_role.role.name
}