#### Vault KV
resource "vault_mount" "kvv2" {
  path    = "kvv2"
  type    = "kv"
  options = { version = "2" }
}

resource "vault_policy" "kvv2" {
  name = "kv"

  policy = <<EOT
path "kvv2/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kv_secret_v2" "kvv2" {
  mount               = vault_mount.kvv2.path
  name                = "secret"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      username = "static-user",
      password = "static-password-v1"
    }
  )
}

#### Vault PKI
resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_policy" "pki" {
  name = "pki"

  policy = <<EOT
path "pki/*" {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_pki_secret_backend_root_cert" "root" {
  backend     = vault_mount.pki.path
  type        = "internal"
  common_name = "test"
  ttl         = "86400"
}

resource "vault_pki_secret_backend_role" "role" {
  backend          = vault_mount.pki.path
  name             = "my-role"
  ttl              = 30
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 4096
  allowed_domains  = ["example.com", "my.domain"]
  allow_subdomains = true
}

#### Vault Transit for VSO
// resource "vault_mount" "transit" {
//   path                      = "demo-transit"
//   type                      = "transit"
//   description               = "for vso"
//   default_lease_ttl_seconds = 3600
//   max_lease_ttl_seconds     = 86400
// }

// resource "vault_transit_secret_backend_key" "key" {
//   backend = vault_mount.transit.path
//   name    = "vso-client-cache"

//   deletion_allowed = true
// }

// resource "vault_policy" "transit" {
//   name = "demo-auth-policy-operator"

//   policy = <<EOT
// path "${vault_mount.transit.path}/encrypt/${vault_transit_secret_backend_key.key.name}" {
//    capabilities = ["create", "update"]
// }
// path "${vault_mount.transit.path}/decrypt/${vault_transit_secret_backend_key.key.name}" {
//    capabilities = ["create", "update"]
// }
// EOT
// }