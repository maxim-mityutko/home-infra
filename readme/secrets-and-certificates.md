# Secrets and Certificates

Sealed Secrets and cert-manager are deployed by ArgoCD from the app-of-apps
tree:

- `kubernetes/cluster/default/sealed-secrets`
- `kubernetes/cluster/default/cert-manager`

## Sealed Secrets

Use `kubeseal` when adding or rotating a Kubernetes Secret in this repository.

Encrypt a Secret with the certificate from the current cluster:

```shell
cat secret.yaml | kubeseal \
  --controller-namespace sealed-secrets \
  --controller-name sealed-secrets \
  --format yaml \
  > sealed-secret.yaml
```

Encrypt with a local public certificate from a backed-up key:

```shell
cat secret.yaml | kubeseal \
  --cert sealed-secrets-public.crt \
  --format yaml \
  > sealed-secret.yaml
```

Decrypt a SealedSecret with the recovery private key:

```shell
cat sealed-secret.yaml | kubeseal \
  --recovery-private-key sealed-secrets-key.yaml \
  --recovery-unseal
```

Back up the controller key after a fresh bootstrap and store it outside this
repository:

```shell
kubectl get secret \
  -n sealed-secrets \
  -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml \
  > sealed-secrets-key.yaml
```

Restore the key before syncing existing SealedSecrets into a rebuilt cluster:

```shell
kubectl apply -f sealed-secrets-key.yaml
kubectl delete pod -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets
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

The `lets-encrypt` ClusterIssuer and wildcard `brhd.io` certificate are applied
from:

- `kubernetes/cluster/default/cert-manager/cluster-issuer.yaml`
- `kubernetes/cluster/default/cert-manager/wildcard-certificate.yaml`
