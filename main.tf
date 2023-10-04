locals {
  vault_addr      = "http://127.0.0.1:8200"
  vault_addr_k2v  = "http://host.minikube.internal:8200"
  kubernetes_host = [for cluster in yamldecode(file("~/.kube/config"))["clusters"] : cluster["cluster"]["server"] if cluster["name"] == "minikube"][0]
}

provider "vault" {
  address = local.vault_addr
  token   = "root"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

// Debuging Pod
resource "kubernetes_pod" "curl" {
  metadata {
    name = "curl"

    labels = {
      run = "curl"
    }
  }

  spec {
    container {
      name              = "curl"
      image             = "curlimages/curl"
      command           = ["sleep", "3600"]
      image_pull_policy = "Always"
    }

    restart_policy = "Always"
  }
}

module "secrets" {
  source = "./01_secrets"
}

module "auth" {
  source = "./02_auth"

  kubernetes_host    = local.kubernetes_host
  kubernetes_ca_cert = file("~/.minikube/ca.crt")
  policies           = module.secrets.policies
}

module "helm" {
  source = "./02_helm"

  vault_addr = local.vault_addr_k2v
}

module "csi" {
  depends_on = [
    module.secrets,
    module.auth,
    module.helm
  ]

  source = "./03_csi"

  vault_addr                 = local.vault_addr_k2v
  vault_auth_kubernetes_path = module.auth.auth_kubernetes_path
  auth_kubernetes_rolename   = module.auth.auth_kubernetes_rolename
  vault_kv_path              = module.secrets.vault_kv_path
}

module "sidecar" {
  depends_on = [
    module.secrets,
    module.auth,
    module.helm
  ]

  source = "./03_sidecar"

  auth_kubernetes_rolename = module.auth.auth_kubernetes_rolename
  vault_kv_path            = module.secrets.vault_kv_path
  vault_pki_rolename       = module.secrets.vault_pki_rolename
}

module "vso" {
  depends_on = [
    module.secrets,
    module.auth,
    module.helm
  ]

  source = "./03_vso"

  vault_auth_kubernetes_rolename = module.auth.auth_kubernetes_rolename
  vault_auth_kubernetes_path     = module.auth.auth_kubernetes_path
  vault_kv_path                  = module.secrets.vault_kv_path
  vault_pki_rolename                 = module.secrets.vault_pki_rolename
}