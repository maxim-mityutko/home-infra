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
version, target user, whether Raspberry Pi cgroup memory flags are needed,
whether the node is a Proxmox VM, and network interface layout. It then
performs the common node setup that used to be documented here manually:

- writes `/etc/netplan/50-cloud-init.yaml`
- optionally adds Raspberry Pi cgroup memory flags
- updates the system and installs `nfs-common`, `nano`, `git`, and `btop`
- optionally installs `qemu-guest-agent` on Proxmox VMs
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

## MicroK8s

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
