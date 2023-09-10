# Installation
* Deploy ArgoCD infrastructure to the k8s cluster and complete initial setup.
  ```shell
  # Create namespace and install standard ArgoCD manifest
  microk8s kubectl create namespace argocd
  microk8s kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  # Get admin password
  microk8s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
  # Drop admin password secret
  microk8s kubectl delete secret argocd-initial-admin-secret -n argocd
  # Switch context to `argocd` namespace
  microk8s kubectl config set-context --current --namespace=argocd
  ```
* Setup ingress: `cluster\default\argocd\ingress.yaml`
* Enable Helm: `cluster\default\argocd\config.yaml`

# ArgoCD Configuration with CLI

Download appropriate CLI from [here](https://github.com/argoproj/argo-cd/releases/) or on Linux:
```shell
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64
sudo chmod +x /usr/local/bin/argocd
```

* Manage password
    ```shell
    # default username: admin
    # Option 1: before ingress configuration
    argocd login localhost --insecure --port-forward-namespace argocd
    # Option 2: after ingress configuration
    argocd login argocd.brhd.io
  
    argocd account update-password --insecure --port-forward-namespace argocd
    ```
* Add repo
    * Generate key according to [these](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key)
    instructions. Add public key to `Repo -> Settings -> Deploy Keys`

    ```shell
    argocd repo add git@github.com:maxim-mityutko/home-infra.git --ssh-private-key-path ~/.ssh/argocd.brhd.io --insecure --port-forward-namespace argocd
    ```

# Tips
* if new `project` is created, cluster resource allow list should be specified, e.g.:
    ```yaml
    kind: PersistentVolume
    group: *
    ```

# Links
* General Info: https://argo-cd.readthedocs.io/en/stable/
* Getting Started: https://argo-cd.readthedocs.io/en/stable/getting_started/
* Ingress: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/
* CLI Installation: https://argo-cd.readthedocs.io/en/stable/cli_installation/
* Private Repo Setup: https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/
* Manifests: https://github.com/argoproj/argo-cd/tree/master/manifests
