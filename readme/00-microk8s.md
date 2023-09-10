# MicroK8s
## Cluster Setup
* Follow [these](https://ubuntu.com/tutorials/how-to-kubernetes-cluster-on-raspberry-pi#4-installing-microk8s) 
or [these](https://microk8s.io/) instuctions to install `microk8s`:
  ```
  sudo nano /boot/firmware/cmdline.txt
  ```
  Add options `cgroup_enable=memory cgroup_memory=1`
  ```
  sudo reboot
  sudo snap install microk8s --classic
  ```
  Set permissions:
  ```
  sudo usermod -a -G microk8s <user>
  sudo chown -f -R <user> ~/.kube
  newgrp microk8s
    
  micrkok8s status
  ```

__Important__, when prepping a new node, make sure to:
* Install NFS dependencies: `sudo apt install nfs-common`
* Configure DNS resolvers (see Troubleshooting section)
* Configure volatile storage for logs (see Troubleshhoting section)

## Cluster Upgrade and HA
* [Upgrade](https://microk8s.io/docs/upgrading)
* [HA Clustering](https://microk8s.io/docs/clustering)
  
## Resources
* Commands:
  * create / update: `microk8s kubectl apply -f <name>.yaml` or `microk8s kubectl apply -f <folder>`
  * delete: `microk8s kubectl delete -f <name>.yaml` or `microk8s kubectl delete -f <folder>`

## k8s Dashboard
* Installation
    ```
    microk8s enable dashboard
    ```
* Login Token
    ```
    microk8s kubectl create token default
    ```
    Login to `https://<master-node>:<port>` and use token from above command. If ingress for
    dashboard is configures, port can be omitted.
* Authentication<br>
  The easiest way to allow permanent authentication to the dashboard is to use `token` obtained
  above, and add it as header to the `ingress` configuration: `k8s--dashboard--auth-patch.yaml`

## Ingress
* Links
  * MicroK8s Info: https://microk8s.io/docs/addon-ingress 
  * General Info: https://kubernetes.io/docs/concepts/services-networking/ingress/
* Installation
    ```
    microk8s enable ingress
    ```
* Commands
  * List all ingresses: `microk8s kubectl get ing -A`
  * Delete ingress: `microk8s kubectl delete ingress -n <namespace>  <ingress-name>`
* Notes
  * TCP and UDP services can be exposed by editing the `nginx-ingress-tcp-microk8s-conf` 
  and `nginx-ingress-udp-microk8s-conf` and 
  [exposing port in the ingress controller](https://microk8s.io/docs/addon-ingress)
## Storage
### Persistent Volumes (PV) and Persistent Volume Claims (PVC)
* Links
  * General Info: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
  * Configuration: https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/
* Commands
  * List claims: ` microk8s kubectl get pvc`
  * List volumes: ` microk8s kubectl get pv`
### NFS
NFS should be configured separately before it can be used in PV.
* Links
  * General info and installation: [link1](https://ubuntu.com/server/docs/service-nfs) 
  and [link2](https://linuxize.com/post/how-to-install-and-configure-an-nfs-server-on-ubuntu-20-04/)
  * Permissions and caveats: https://serverfault.com/questions/240897/how-to-properly-set-permissions-for-nfs-folder-permission-denied-on-mounting-en
* Installation
    ```
    sudo apt install nfs-kernel-server nfs-common
    sudo systemctl start nfs-kernel-server.service
    ```
* Configuration
    ```
    sudo mkdir -p /srv/nfs/<folder>
    sudo chown -R <user>:<group> /srv/nfs/<folder>
    sudo chmod -R 777 /srv/nfs/<folder>
    
    echo '/srv/nfs/<folder>        *(rw,async,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports
    sudo exportfs -arv
    ```
* Testing
    ```
    sudo mount -t nfs -o vers=4 <server>:/srv/nfs/<folder> /<local>/<path>
    ```
* Mount in Windows: https://graspingtech.com/mount-nfs-share-windows-10/
## Services
* Commands
  * List services: `microk8s kubectl -n k<namespace> get services`

## Secrets
* Links
  * General info: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
* Commands
  * Secret should be `base64` encoded before putting it in the secrets manifest: `echo -n '<secret>' | base64`

## Tagging
* Links
  * General Info on Labels and Selectors: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
  * Recommended Labels: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/

## Commands Cheat Sheet
`microk8s kubectl scale deploy <deployment> --replicas=0`
`microk8s.add-node`
`microk8s kubectl delete pod --grace-period=0 --force --namespace [NAMESPACE] [POD_NAME]`

## Troubleshooting
* [Microk8s Troubleshooting](https://microk8s.io/docs/troubleshooting)
* [Microk8s Services](https://microk8s.io/docs/configuring-services)
* [Microk8s Installation on ARM](https://microk8s.io/docs/install-alternatives#heading--arm)
* [False Positive `snap.microk8s.daemon-apiserver-proxy is not running`](https://github.com/canonical/microk8s/issues/3375#issuecomment-1322023278)
* Fix IO performance / reduce write pressure
  ```
  In some cases, a way to mitigate the issue of low disk IO performance is to move 
  the journald logs on volatile storage. This is done by editing /etc/systemd/journald.conf 
  setting Storage=volatile
  ```
* DNS resolution
  ```
  Modern releases of Ubuntu (17.10+) include systemd-resolved which is configured by default to implement a caching 
  DNS stub resolver. The stub resolver should be disabled with: 
  
  sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf

  This will not change the nameserver settings, which point to the stub resolver thus preventing DNS resolution. 
  Change the `/etc/resolv.conf` symlink to point to `/run/systemd/resolve/resolv.conf`, which is automatically 
  updated to follow the system's netplan:
  
  sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf' 

  After making these changes, you should restart systemd-resolved using:
  
  systemctl restart systemd-resolved
  ```

## TODO:
* Slack Notifications - [kubewatch](https://github.com/bitnami-labs/kubewatch)
* Extend NodePort range to get rid of 
* Change HostPort / Service ingress implementations
* home-assistant - Home Automation
* kodi-headless - Centralised Kodi Library indexer
* nginx-ingress - Ingress controller [available out of the box in microk8s]

## Useful Links
* docker - [Hub](https://hub.docker.com/)
* helm - [ArtifactHUB](https://artifacthub.io/)
* k8s - [Pull an image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
* docker-compose - [Convert to k8s Manifest](https://github.com/kubernetes/kompose/releases)
  * Installation
    ```
    curl -L https://github.com/kubernetes/kompose/releases/download/v1.25/kompose-linux-arm64 -o kompose
    chmod +x kompose
    sudo mv ./kompose /usr/local/bin/kompose
    ```
  * Usage
    ```
    # Run at location of `docker-compose.yaml` file
    kompose convert
    ```
* inspiration - [vaskozl | Home Infra](https://github.com/vaskozl/home-infra)
* k8s - [Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
* k8s - [Commands](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)
* k9s - [Installation](https://github.com/derailed/k9s#installation)
* k9s - [MicroK8s Setup](https://github.com/derailed/k9s/issues/267#issuecomment-513431314)
