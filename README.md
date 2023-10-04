# Vault for K8S

This Terraform code identifies three cases for integrating Vault into Kubernets.

## Tested environment
- macOS
- vault v1.15.0
- helm v3.12.1
- kubectl v5.0.1
- minikube v1.31.2
- docker (server) v23.0.6
- docker (client) v24.0.2-rd

## Run!!!

### Vault dev mode

```bash
vault server -dev -dev-root-token-id=root -log-level=trace
```

- vault env
  - `VAULT_ADDR=http://127.0.0.1:8200`
  - `VAULT_TOKEN=root`

### minikube

```bash
minikube start
```

- minikube to vault
  - `VAULT_ADDR=http://host.minikube.internal:8200`
  - `VAULT_TOKEN=root`

## Setup from Terraform

```bash
terraform apply
```

> `yaml` - original files

- module `01_secret`
  - enable secret engine `kvv2`
  - create policy `kvv2`
  - create kv data
  - enable secret engine `pki`
  - create policy `pki`
  - create `pki` role
- module `02_auth`
  - create Kubernetes `Service Account` for Vault
  - enable Vault auth method - `kubernetes`
- module `02_helm`
  - `vault-secrets-operator`
  - `vault`
  - `secrets-store-csi-driver`
- module `03_csi`
  - `SecretProviderClass`
  - POD using CSI as a `FILE`
  - POD using CSI as a `ENV` & `FILE`
- module `03_sidecar`
  - Deployment using `agent-inject`
- module `03_vso`
  - `VaultAuth` for vso
  - `VaultStaticSecret`
  - Deployment using static secret
  - `VaultPKISecret`
  - Deployment using dynamic(pki) secret

## Install Check

### minikube-vault connect

```bash
kubectl exec -it curl -- curl -X GET http://host.minikube.internal:8200/v1/sys/health
```

### helm - vault

```bash
$ kubectl get pods -n default

NAME                                    READY   STATUS    RESTARTS   AGE
vault-agent-injector-56fcd88cbb-r7fzq   1/1     Running   0          4m52s
vault-csi-provider-22mnw                2/2     Running   0          4m52s
```

### helm - vso

```bash
$ kubectl get pods -n vault-secrets-operator-system

NAME                                                         READY   STATUS    RESTARTS   AGE
vault-secrets-operator-controller-manager-67879cb4d4-ck967   2/2     Running   0          9m29s
```

### helm - csi

```bash
$ kubectl get pods -l "app=secrets-store-csi-driver"

NAME                                               READY   STATUS    RESTARTS   AGE
csi-secrets-store-secrets-store-csi-driver-k5p82   3/3     Running   0          3m32s
```

## CSI Check

```bash
kubectl exec webapp-file -- cat /mnt/secrets-store/my-password
```

```bash
kubectl exec webapp-secret -- env | grep MY_PASSWORD
```

## Sidecar Check

### Containers list

```bash
kubectl get pods -n default -l app=issues -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{range .spec.containers[*]}{.name}{"=>"}{.image}{","}{end}{end}'|sort|column -t
```

### Check secrets kv

```bash
kubectl exec \
  $(kubectl get pod -l app=issues -o jsonpath="{.items[0].metadata.name}") \
  -c webapp -- cat /vault/secrets/database-config.txt
```

### Check secrets dynamic (pki)

```bash
kubectl exec \
  $(kubectl get pod -l app=issues -o jsonpath="{.items[0].metadata.name}") \
  -c webapp -- cat /vault/secrets/cert.pem
```

```bash
kubectl exec \
  $(kubectl get pod -l app=issues -o jsonpath="{.items[0].metadata.name}") \
  -c webapp -- cat /vault/secrets/key.pem
```

## VSO Check

### Check secrets kv

```bash
echo $(kubectl get secret secretkv -o jsonpath='{.data.password}') | base64 -d
```

### Check secrets dynamic (pki)

```bash
kubectl exec \
  $(kubectl get pod -l test=vso-pki-demo -o jsonpath="{.items[0].metadata.name}") \
  -- env | grep PKI_EXPIRATION | awk -F'=' '{print $2}' | xargs date -r
```

```bash
kubectl exec \
  $(kubectl get pod -l app=issues -o jsonpath="{.items[0].metadata.name}") \
  -c webapp -- cat /vault/secrets/key.pem
```