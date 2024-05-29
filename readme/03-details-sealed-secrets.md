# Install
## Controller
Can be installed directly from manifest, however Helm charts are also available. ArgoCD app is configured.
```shell
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.5/controller.yaml
```

## CLI
```shell
# version = 0.18.5
# release-tag = v0.18.5
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/<release-tag>/kubeseal-<version>-linux-arm64.tar.gz
tar -xvzf kubeseal-<version>-linux-arm64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

# Encrypt Secret
```shell
# Encrypt using the certificate from the K8s cluster
cat secret.yaml | kubeseal \
    --controller-namespace sealed-secrets \
    --controller-name sealed-secrets \
    --format yaml \
    > sealed-secret.yaml
```
```shell
# Encrypt with the key stored locally (can be obtained from backup)
cat secret.yaml | kubeseal \
    --cert my_cert.cert --format yaml >> sealed-secret.yaml
```

# Decrypt Secret
```shell
cat sealed-secret.yaml | kubeseal \
    --recovery-private-key backup.yaml --recovery-unseal
```

# Backup / Recovery
Public and private keys that controller generates upon startup can be backed up and rolled out back to
the cluster if necessary.
```shell
# backup
microk8s kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > main.key

# NOTE: if existing key exists in `sealed-secrets\secrets`, it must be dropped

# restore
microk8s kubectl apply -f main.key
microk8s kubectl delete pod -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets
```

FAQ: https://github.com/bitnami-labs/sealed-secrets#how-can-i-do-a-backup-of-my-sealedsecrets

# Pre-Commit Hook
```shell
pip install pre-commit
```

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/k8s-at-home/sops-pre-commit
    rev: v2.1.0
    hooks:
    - id: forbid-secrets
```

```shell
pre-commit install
```

# Links
* [Sealed Secrets Releases](https://github.com/bitnami-labs/sealed-secrets/releases)
* [Sealed Secrets Readme](https://github.com/bitnami-labs/sealed-secrets/tree/main/helm/sealed-secrets)