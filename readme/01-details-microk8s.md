# MicroK8s

## Node Setup

Run the repository bootstrap script instead of repeating the old manual setup
steps:

```shell
sudo ./node/01-initial-node-setup.sh
```

The script handles the common setup for a new Ubuntu MicroK8s node:

- static netplan configuration for the selected main interface
- optional VLAN or second NIC configuration for a no-address secondary interface
- optional Raspberry Pi cgroup memory flags
- package updates and base package installation
- MicroK8s installation from the selected stable channel
- `kubectl` alias and `microk8s` group access
- volatile journald storage
- systemd-resolved DNS stub listener disablement

Reboot after the script completes. If the current shell user was added to the
`microk8s` group, run `newgrp microk8s` after reboot or start a new login
session.

For persistent interface altnames, run:

```shell
sudo ./node/02-set-interface-altnames.sh --subnet x.x.x.x/xx
```

This maps the interface with an IPv4 address in the provided subnet to `forge`
and the interface without a global IPv4 address to `pub`.

## Cluster Upgrade and HA

- [Upgrade](https://microk8s.io/docs/upgrading)
- [HA Clustering](https://microk8s.io/docs/clustering)

## Resources

Commands:

```shell
microk8s kubectl apply -f <name>.yaml
microk8s kubectl apply -f <folder>
microk8s kubectl delete -f <name>.yaml
microk8s kubectl delete -f <folder>
```

## Dashboard

Headlamp is the GitOps-managed dashboard for regular use. The built-in MicroK8s
dashboard can still be enabled temporarily when needed:

```shell
microk8s enable dashboard
microk8s kubectl create token default
```

## Ingress

Links:

- MicroK8s Info: https://microk8s.io/docs/addon-ingress
- General Info: https://kubernetes.io/docs/concepts/services-networking/ingress/

Installation:

```shell
microk8s enable ingress
```

Commands:

```shell
microk8s kubectl get ing -A
microk8s kubectl delete ingress -n <namespace> <ingress-name>
```

TCP and UDP services can be exposed by editing
`nginx-ingress-tcp-microk8s-conf` and `nginx-ingress-udp-microk8s-conf`, then
exposing the port in the ingress controller.

## Storage

### Persistent Volumes and Claims

Links:

- https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/

Commands:

```shell
microk8s kubectl get pvc
microk8s kubectl get pv
```

### NFS

NFS server setup is separate from node bootstrap. Client dependency
`nfs-common` is installed by `node/01-initial-node-setup.sh`.

Links:

- https://ubuntu.com/server/docs/service-nfs
- https://linuxize.com/post/how-to-install-and-configure-an-nfs-server-on-ubuntu-20-04/
- https://serverfault.com/questions/240897/how-to-properly-set-permissions-for-nfs-folder-permission-denied-on-mounting-en

Server installation:

```shell
sudo apt install nfs-kernel-server
sudo systemctl start nfs-kernel-server.service
```

Configuration:

```shell
sudo mkdir -p /srv/nfs/<folder>
sudo chown -R <user>:<group> /srv/nfs/<folder>
sudo chmod -R 777 /srv/nfs/<folder>
echo '/srv/nfs/<folder> *(rw,async,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports
sudo exportfs -arv
```

Testing:

```shell
sudo mount -t nfs -o vers=4 <server>:/srv/nfs/<folder> /<local>/<path>
```

Windows mount reference: https://graspingtech.com/mount-nfs-share-windows-10/

### Longhorn

- Installation prerequisites: https://longhorn.io/docs/1.6.2/deploy/install/#installation-requirements
- Installation with ArgoCD: https://longhorn.io/docs/1.6.2/deploy/install/install-with-argocd/
- Uninstall Longhorn: https://longhorn.io/docs/1.6.2/deploy/uninstall/
- Data migration example: https://github.com/longhorn/longhorn/blob/master/examples/data_migration.yaml
- Various examples: https://github.com/longhorn/longhorn/tree/v1.6.2/examples

## Services

```shell
microk8s kubectl -n <namespace> get services
```

## Secrets

Secrets should be `base64` encoded before putting them in a Secret manifest:

```shell
echo -n '<secret>' | base64
```

## Tagging

- https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/

## Commands Cheat Sheet

```shell
microk8s kubectl scale deploy <deployment> --replicas=0
microk8s.add-node
microk8s kubectl delete pod --grace-period=0 --force --namespace <namespace> <pod-name>
```

## Troubleshooting

- [MicroK8s Troubleshooting](https://microk8s.io/docs/troubleshooting)
- [MicroK8s Services](https://microk8s.io/docs/configuring-services)
- [MicroK8s Installation on ARM](https://microk8s.io/docs/install-alternatives#heading--arm)
- [False Positive `snap.microk8s.daemon-apiserver-proxy is not running`](https://github.com/canonical/microk8s/issues/3375#issuecomment-1322023278)

The bootstrap script already configures volatile journald storage and disables
the systemd-resolved DNS stub listener. If either setting must be repaired
manually, rerun the script or inspect these files:

- `/etc/systemd/journald.conf`
- `/etc/systemd/resolved.conf`
- `/etc/resolv.conf`

Refresh MicroK8s certs if logs fail with an x509 certificate validation error:

```shell
sudo microk8s refresh-certs --cert server.crt
```

## Useful Links

- docker: https://hub.docker.com/
- helm: https://artifacthub.io/
- k8s private registry pull secrets: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
- k8s cheat sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- k8s commands: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
- k9s installation: https://github.com/derailed/k9s#installation
- k9s MicroK8s setup: https://github.com/derailed/k9s/issues/267#issuecomment-513431314
