# Secrets and Certificates

Sealed Secrets and cert-manager are deployed by ArgoCD from the app-of-apps
tree:

- `kubernetes/cluster/default/sealed-secrets`
- `kubernetes/cluster/default/cert-manager`

## Sealed Secrets

Install `kubeseal` CLI:

```shell
# version = 0.37.0
# release-tag = v0.37.0
wget https://github.com/bitnami/sealed-secrets/releases/download/<release-tag>/kubeseal-<version>-linux-arm64.tar.gz
tar -xvzf kubeseal-<version>-linux-arm64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

Use `kubeseal` when adding or rotating a Kubernetes Secret in this repository.

Encrypt using the certificate from the K8s cluster:

```shell
cat secret.yaml | kubeseal \
    --controller-namespace default \
    --controller-name sealed-secrets \
    --format yaml \
    > sealed-secret.yaml
```

Encrypt with the key stored locally:

```shell
cat secret.yaml | kubeseal \
    --cert my_cert.cert --format yaml >> sealed-secret.yaml
```

Decrypt a SealedSecret with the recovery private key:

```shell
cat sealed-secret.yaml | kubeseal \
    --recovery-private-key backup.yaml --recovery-unseal
```

Back up the controller key after a fresh bootstrap and store it outside this
repository:

```shell
# backup
microk8s kubectl get secret -n default -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > main.key

# NOTE: if existing key exists in `sealed-secrets\secrets`, it must be dropped

# restore
microk8s kubectl apply -f main.key
microk8s kubectl delete pod -n default -l app.kubernetes.io/name=sealed-secrets
```

## cert-manager

cert-manager is installed from the Helm chart in
`kubernetes/cluster/default/cert-manager/kustomization.yaml`.

The Cloudflare DNS-01 token is managed as a SealedSecret in
`kubernetes/cluster/default/cert-manager/secret.yaml`.

Create the Cloudflare API token for DNS-01 validation as described in the
cert-manager Cloudflare DNS-01 documentation:

- https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/

Use these permissions:

- `Zone - DNS - Edit`
- `Zone - Zone - Read`

Use `Include - All Zones` for zone resources.

The `lets-encrypt` ClusterIssuer is applied from
`kubernetes/cluster/default/cert-manager/cluster-issuer.yaml`.
