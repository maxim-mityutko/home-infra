# Secrets and Certificates

Sealed Secrets and cert-manager are deployed by ArgoCD from the app-of-apps
tree:

- `kubernetes/cluster/default/sealed-secrets`
- `kubernetes/cluster/default/cert-manager`

## Sealed Secrets

Use `kubeseal` when adding or rotating a Kubernetes Secret in this repository.

Encrypt a Secret with the certificate from the current cluster:

```shell
kubeseal \
  --controller-namespace default \
  --controller-name sealed-secrets \
  --format yaml \
  < secret.yaml \
  > sealed-secret.yaml
```

Encrypt with a local public certificate from a backed-up key:

```shell
kubeseal \
  --cert sealed-secrets-public.crt \
  --format yaml \
  < secret.yaml \
  > sealed-secret.yaml
```

Decrypt a SealedSecret with the recovery private key:

```shell
kubeseal \
  --recovery-private-key sealed-secrets-key.yaml \
  --recovery-unseal \
  < sealed-secret.yaml
```

Back up the controller key after a fresh bootstrap and store it outside this
repository:

```shell
kubectl get secret \
  -n default \
  -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml \
  > sealed-secrets-key.yaml
```

Restore the key before syncing existing SealedSecrets into a rebuilt cluster:

```shell
kubectl apply -f sealed-secrets-key.yaml
kubectl delete pod -n default -l app.kubernetes.io/name=sealed-secrets
```

## cert-manager

cert-manager is installed from the Helm chart in
`kubernetes/cluster/default/cert-manager/kustomization.yaml`.

The Cloudflare DNS-01 token is managed as a SealedSecret in
`kubernetes/cluster/default/cert-manager/secret.yaml`.

The `lets-encrypt` ClusterIssuer and wildcard `brhd.io` certificate are applied
from:

- `kubernetes/cluster/default/cert-manager/cluster-issuer.yaml`
- `kubernetes/cluster/default/cert-manager/wildcard-certificate.yaml`
