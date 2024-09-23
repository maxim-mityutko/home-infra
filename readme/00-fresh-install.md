# Rollout Runbook

## Ubuntu

### Installation

- configure static IP
- select **minimized** OS installation
- select **microk8s** during Ubuntu installation
- use LVM while setting up volumes

### (Optional) Post-Installation RPi
- configure **network**

  ```shell
  sudo nano /etc/netplan/00-installer-config.yaml
  # use the below template
  sudo chmod u=rw,g=,o= /etc/netplan/00-installer-config.yaml
  sudo netplan try
  ```
  
  Config template:
  ```yaml
    network:
      ethernets:
        eth0:
          addresses:
          - x.x.x.x/x        # node ip and mask
          nameservers:
            addresses:
            - x.x.x.x        # gateway ip
            search:
            - brhd.io
          routes:
          - to: default
            via: x.x.x.x    # gateway ip
      version: 2
    ```

- enable **cgroups**

  ```shell
  sudo nano /boot/firmware/cmdline.txt
  ```
  Add options `cgroup_enable=memory cgroup_memory=1`

- install **rpi kernel modules**

  ```shell
  sudo apt install linux-modules-extra-raspi

  # On Ubuntu 24.04 the package with extra modules is not yet(?) available
  sudo apt install linux-raspi
  ```

- install **microk8s**

  ```shell
  # Version 1.29 or whatever is currently installed on the master nodes
  snap install microk8s --channel=1.29/stable --classic
  ```

### (Optional) Post-Installation Proxmox
- install **qemu-guest-agent** to enable proper management of the node from Proxmox, refer to [docs](https://pve.proxmox.com/wiki/Qemu-guest-agent)

  ```
  sudo apt install qemu-guest-agent
  ```

### Post-Installation
- install dependencies

    ```shell
    sudo apt update
    sudo apt install nfs-common nano git
    ```
- add **kubectl** alias
    ```shell
    sudo snap alias microk8s.kubectl kubectl
    ```
- grant permissions on **microk8s** command

    ```shell
    mkdir ~/.kube
    microk8s config > ~/.kube/config

    sudo usermod -a -G microk8s <user>
    sudo chown -R <user> ~/.kube
    newgrp microk8s
    ```
- add **DNS** servers

    ```shell
    sudo nano /etc/systemd/resolved.conf
    ```
    Set `DNS=1.1.1.1` and `FallbackDNS=1.0.0.1`

- move **journald logs** to *volatile* storage to reduce the disk pressure

    ```shell
    sudo nano /etc/systemd/journald.conf 
    ```
    Set `Storage=volatile`

- disable **DNS stub resolver** to enable DNS resolving in pods

    ```shell
    sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf  

    sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf' 

    sudo systemctl restart systemd-resolved
    ```

## Microk8s

### Plugins

- enable **plugins**

    ```shell
    microk8s enable dashboard
    microk8s enable dns
    microk8s enable ingress:default-ssl-certificate=default/brhd-io-tls
    # When NVIDIA drivers can be preinstalled on the node `--gpu-operator-driver host`, more info https://microk8s.io/docs/addon-gpu
    microk8s enable nvidia --gpu-operator-driver host
    ```

### Dashboard

- configure **ingress** and **authentication**

    ```shell
    kubectl apply -f home-infra/kubernetes/cluster/kube-system/dashboard/ingress.yaml
    ./home-infra/kubernetes/scripts/02-dashboad-auth.sh
    ```

### ArgoCD

- install **ArgoCD**

    ```shell
    # Create namespace and apply ArgoCD manifest
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    # Get admin password
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    # Drop admin password secret
    kubectl delete secret argocd-initial-admin-secret -n argocd
    ```

- enable **ingress**
    ```shell
    kubectl apply -f home-infra/kubernetes/cluster/argocd/ingress.yaml
    ```

- login into **ArgoCD** and create repo from SSH repo

### Sealed Secrets

- install **Sealed Secrets**

    ```shell
    kubectl apply -f home-infra/kubernetes/argocd/03_default/sealed-secrets.yaml
    ```

- apply **certificate** and **key** to be able to unseal the secrets
    ```shell
    kubctl apply -f <path--to-secret>/key.yaml
    ```

### Other

- apply all other manifests, but the recommendation is to start with

    ```shell
    kubectl apply -f kubernetes/argocd/02_ingress/microk8s-ingress.yaml
    kubectl apply -f kubernetes/argocd/03_default/cert-manager.yaml
    kubectl apply -f kubernetes/argocd/03_default/nfs-subdir.yaml
    kubectl apply -f kubernetes/argocd/03_default/postgres.yaml
    kubectl apply -f kubernetes/argocd/03_default/authentik.yaml
    kubectl apply -f kubernetes/argocd/03_default/mariadb.yaml
    ```
