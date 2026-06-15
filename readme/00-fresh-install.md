# Rollout Runbook

## Ubuntu

### Installation

- select **minimized** OS installation
- use LVM while setting up volumes
- configure enough temporary network access to clone this repository
- do not select the installer MicroK8s snap if this repository's node bootstrap
  script will be used

### Node Bootstrap

Run the node bootstrap helper from the repository root:

```shell
sudo ./node/01-initial-node-setup.sh
```

The script prompts for the static node IP, gateway, nameserver, MicroK8s
version, target user, and network interface layout. It then performs the common
node setup that used to be documented here manually:

- writes `/etc/netplan/50-cloud-init.yaml`
- optionally adds Raspberry Pi cgroup memory flags
- updates the system and installs `nfs-common`, `nano`, `git`, and `btop`
- installs MicroK8s from the selected stable snap channel
- creates the `kubectl` snap alias
- adds the selected user to the `microk8s` group and prepares `~/.kube`
- switches journald to volatile storage
- disables the systemd-resolved DNS stub listener for pod DNS compatibility

Review the script's summary before confirming. Reboot after it finishes so
network and boot parameter changes take effect.

### Interface Altnames

After the node has the expected IP layout, create persistent interface altnames:

```shell
sudo ./node/02-set-interface-altnames.sh --subnet x.x.x.x/xx
```

The script maps the interface with an IPv4 address in the provided subnet to
`forge` and the interface without a global IPv4 address to `pub`. Use
`--confirm` only when the subnet is already known and non-interactive execution
is wanted.

### Optional Proxmox Step

Install **qemu-guest-agent** on Proxmox VMs to enable proper management from
Proxmox:

```shell
sudo apt install qemu-guest-agent
```

See the [Proxmox docs](https://pve.proxmox.com/wiki/Qemu-guest-agent) for more
details.

## MicroK8s

### Addons

Enable only the addons that are still expected for the current cluster. Most
cluster services are managed through ArgoCD after bootstrap.

```shell
# microk8s enable dashboard
# microk8s enable dns
# microk8s enable ingress:default-ssl-certificate=default/brhd-io-tls
# When NVIDIA drivers can be preinstalled on the node:
microk8s enable nvidia --gpu-operator-driver host
```

### Dashboard

Use **Headlamp** as the GitOps-managed Kubernetes dashboard after bootstrap. For
the built-in MicroK8s dashboard, create a temporary token when needed:

```shell
microk8s kubectl create token default
```

### ArgoCD

Install ArgoCD and bootstrap the app-of-apps tree:

```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl delete secret argocd-initial-admin-secret -n argocd
kubectl apply -f kubernetes/app-of-apps.yaml
```

Follow [02-details-argocd.md](./02-details-argocd.md) for detailed ArgoCD setup.

### Sealed Secrets

Wait for the **Sealed Secrets** application to sync, then restore the backed-up
key if needed:

```shell
kubectl apply -f <path-to-secret>/key.yaml
```

Follow [03-details-sealed-secrets.md](./03-details-sealed-secrets.md) for
backup, recovery, and `kubeseal` usage.

## Kubernetes Cluster

### Tags

Add custom tags to nodes:

```shell
# type = intel / nvidia
kubectl label nodes <node> kubernetes.io/gpu=<type>
# size = large / medium / small
kubectl label nodes <node> kubernetes.io/node-size=<size>
```

### Local Storage

Create or mount the drive that will be used for local storage:

```shell
sudo mkdir /mnt/my-local-storage
```

Tag the node:

```shell
kubectl label nodes <node> kubernetes.io/local-storage=true
```
