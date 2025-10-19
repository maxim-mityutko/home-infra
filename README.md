# Home Infrastructure

[![k8s](https://img.shields.io/badge/MicroK8s-v1.32.9-black?style=flat-square)](https://k8s.io/)
[![GitHub last commit](https://img.shields.io/github/last-commit/maxim-mityutko/home-infra/main?style=flat-square)](https://github.com/maxim-mityutko/home-infra/commits/main)

## Notes

The rollout from scratch has not been fully automated yet, and generally requires following
the process defined in the [/readme](./readme/) and [/kubernetes/scripts](./kubernetes/scripts/) folders for the initial setup.

After the initial steps are complete, deployments are handled via ArgoCD application manifests
defined in the [/kubernetes/argocd](./kubernetes/argocd/).

## Hardware

### Network

* Router: [TP-Link ER7406](https://www.omadanetworks.com/nl/business-networking/omada-router-wired-router/er7406/)
* Switch: [TP-Link TL-SG2428P](https://www.omadanetworks.com/nl/business-networking/omada-switch-smart/tl-sg2428p/)
* Access Points:
  * [TP-Link EAP245](https://www.omadanetworks.com/nl/business-networking/omada-wifi-ceiling-mount/eap245/v3%20(1-pack)/)
  * [TP-Link EAP615-Wall](https://www.omadanetworks.com/nl/business-networking/omada-wifi-wall-plate/eap615-wall/)

### Compute

* ProxMox VE Host:
  * MOBO: [ASRock IMB-X1231](https://www.asrockind.com/en-gb/IMB-X1231)
  * CPU: Intel Core i5-13500
  * RAM: Kingston Server Premier DDR4-ECC-3200 32 GB x2
  * Extension Cards:
    1. SATA Controller - 2 Port: JMB58x - M.2 M+B Key
    2. SATA Controller - 6 port: ASM1166 - M.2 M Key
  * Storage:
    1. (ProxMox System) SSD Samsung 840 Pro 256 GB x2
    2. (Master Nodes) SSD Samsung 860 Evo 1 TB
    3. (Worker Nodes) SSD Crucial BX500 1TB
    4. (NAS) SSD Crucial BX500 1TB x2
    5. (NAS) HDD Seagate IronWolf Pro NAS 12 TB x3
  * Virtual Machines:
    * TrueNAS Scale with 4 CPUs, 8GB RAM and extension cards (1) and (2) as direct passthrough and SSD (4) and HDD (5) in ZFS pulls for storage
    * (Worker) Ubuntu Server with 4 CPUs and 8GB RAM
    * (Worker) Ubuntu Server with 6 CPUs and 16GB RAM
    * (Master) Ubuntu Server with 2 CPUs and 4 GB RAM x3
  * KVM: [SiPeed NanoKVM-PCIe-PoE](https://sipeed.com/nanokvm/pcie)
* (Disabled) ProxMox VE Host (Spare):  
  * CPU Intel i7-6700
  * RAM 16 GB
  * Storage:
    1. SSD SanDisk SD7TB3Q-256G-1006 256GB
    2. NVME WD Blue NVME 500 GB
  * Virtual Machines:
    * (x3) Ubuntu Server with 2 CPUs and and 4GB RAM
* (Worker) Raspberry Pi 4B 8GB
* [Compute Blade](https://computeblade.com):
  * Raspberry Pi CM4 8GB + Crucial P3 Plus 500GB x 2
  * Raspberry Pi CM-TBD x 2

## Services

### Microk8s

Some services are installed out of the box in Microk8s, refer to `kubernetes/scripts/00.0-init.sh`

### Default (Tier 1)

| Project                    | Description                                                                                        |                                Docs / Repo                                 |                             Docker / Helm                              |
|----------------------------|----------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------:|:----------------------------------------------------------------------:|
| **ArgoCD**                 | Declarative GitOps CD for Kubernetes                                                               |             [docs](https://argo-cd.readthedocs.io/en/stable/)              |                                                                        |
| **Authentik**              | Identity Provider that emphasizes flexibility and versatility                                       |                    [docs](https://docs.goauthentik.io/docs/)<br>[repo](https://github.com/goauthentik/authentik)                    |                                             [helm](https://artifacthub.io/packages/helm/goauthentik/authentik)                                             |
| **Blocky**                 | Fast and lightweight DNS proxy as ad-blocker for local network                                      |                    [repo](https://github.com/0xERR0R/blocky)<br>[docs](https://0xerr0r.github.io/blocky/latest/)                    |                                                      [docker](https://hub.docker.com/r/spx01/blocky)                                                       |
| **Cert Manager**           | Certificate management for Kubernetes                                                              |          [docs](https://cert-manager.io/docs/installation/helm/)           | [helm](https://artifacthub.io/packages/helm/cert-manager/cert-manager) |
| **CloudnativePG (CNPG)** | CloudNativePG is a comprehensive platform designed to seamlessly manage PostgreSQL databases within Kubernetes environments, covering the entire operational lifecycle from initial deployment to ongoing maintenance | [repo](https://github.com/cloudnative-pg/cloudnative-pg)<br>[docs](https://cloudnative-pg.io/docs/) | [helm](https://github.com/cloudnative-pg/charts) |
| | **PostgreSQL** - The PostgreSQL object-relational database system provides reliability and data integrity            |                                                                                                                                     |                                                        [docker](https://hub.docker.com/_/postgres)                                                         |
| | **VectorChord** - Scalable, fast, and disk-friendly vector search in Postgres, the successor of pgvecto.rs.<br>**Required by:** *Immich* | [repo](https://github.com/tensorchord/VectorChords)<br>[docs](https://docs.vectorchord.ai/vectorchord/getting-started/overview.html) | [docker](https://github.com/tensorchord/cloudnative-vectorchord) |
| | **Plugin: Barman Cloud** - Barman Cloud [CNPG-I](https://github.com/cloudnative-pg/cnpg-i) backup plugin | [repo](https://github.com/cloudnative-pg/plugin-barman-cloud)<br>[docs](https://cloudnative-pg.io/plugin-barman-cloud/) |
| **CoreDNS** | CoreDNS is a DNS server that chains plugins and integrates with Kubernetes | [repo](https://github.com/coredns/coredns)<br>[docs](https://coredns.io) | [helm](https://github.com/coredns/helm) |
| **Garage** | S3-compatible object store for small self-hosted geo-distributed deployments | [repo](https://git.deuxfleurs.fr/Deuxfleurs/garage)<br>[docs](https://garagehq.deuxfleurs.fr) | [docker](https://hub.docker.com/r/dxflrs/garage) |
| | **Garage WebUI** - About WebUI for Garage Object Storage Service | [repo](https://github.com/khairul169/garage-webui) | [docker](https://hub.docker.com/r/khairul169/garage-webui) |
| **Ingress NGINX** | Ingress NGINX Controller for Kubernetes | [repo](https://github.com/kubernetes/ingress-nginx)<br>[docs](https://kubernetes.github.io/ingress-nginx/) | [helm](https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/README.md) |
| **Kubernetes Dashboard** | General-purpose web UI for Kubernetes clusters | [repo](https://github.com/kubernetes/dashboard)<br>[docs](https://github.com/kubernetes/dashboard/blob/master/docs/README.md) | [helm](https://github.com/kubernetes/dashboard/blob/master/charts/kubernetes-dashboard/README.md) |
| **Kubernetes Metrics Server** | Scalable and efficient source of container resource metrics for Kubernetes built-in autoscaling pipelines.<br><br>*Also required for statistics graphs in Kubernetes Dashboard*| [repo](https://github.com/kubernetes-sigs/metrics-server) | [helm](https://github.com/kubernetes-sigs/metrics-server/blob/master/charts/metrics-server/README.md) |
| **MetalLB** | A network load-balancer implementation for Kubernetes using standard routing protocols | [repo](https://github.com/metallb/metallb)<br>[docs](https://metallb.io) | [helm](https://github.com/metallb/metallb/blob/main/charts/metallb/README.md) |
| **MinIO** | High-performance, S3 compatible object storage | [repo](https://github.com/minio/minio)<br>[docs](https://min.io/docs/minio/kubernetes/upstream/index.html) | [helm-operator](https://github.com/minio/operator/tree/master/helm/operator)<br>[helm-tenant](https://github.com/minio/operator/tree/master/helm/tenant) |
| **Multus** | A CNI meta-plugin for multi-homed pods in Kubernetes | [repo](https://github.com/k8snetworkplumbingwg/multus-cni)<br>[docs](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/configuration.md) | [docker](https://github.com/k8snetworkplumbingwg/multus-cni/pkgs/container/multus-cni) |
| **NFS Subdir Provisioner** | Automatic provisioning of PVs via PVCs                                                             | [repo](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) |                                                                        |
| **OpenEBS** | A popular & widely deployed Open Source Container Native Storage platform for Stateful Persistent Applications on Kubernetes | [repo](https://github.com/openebs/openebs/tree/v4.3.3)<br>[docs](https://openebs.io/docs/)| [helm](https://github.com/openebs/openebs/blob/v4.3.3/charts/README.md) |
| **Redis** | In-memory database that persists on disk | [repo](https://github.com/redis/redis) | [helm](https://github.com/bitnami/charts/blob/main/bitnami/redis/README.md) |
| **Sealed Secrets**         | A Kubernetes controller and tool for one-way encrypted Secrets                                     |           [repo](https://github.com/bitnami-labs/sealed-secrets)           |         [helm](https://bitnami.com/stack/sealed-secrets/helm)          |
| **Tailscale K8s Operator** | Secure, remote access to on-premises | [repo](https://github.com/tailscale/tailscale)<br>[docs](https://tailscale.com/kb/1236/kubernetes-operator) | [helm](https://github.com/tailscale/tailscale/blob/main/cmd/k8s-operator/deploy/README.md) |

### Default (Tier 2)

| Project                    | Description                                                                                        |                                Docs / Repo                                 |                             Docker / Helm                              |
|----------------------------|----------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------:|:----------------------------------------------------------------------:|
| **Cloudflare DDNS**        | Dynamic DNS implementation for the Cloudflare service                                              |           [repo](https://github.com/oznu/docker-cloudflare-ddns)           |        [docker](https://hub.docker.com/r/oznu/cloudflare-ddns/)        |
| **External DNS**           | Configure external DNS servers for Kubernetes Ingresses and Services                                | [repo](https://github.com/kubernetes-sigs/external-dns)<br>[docs](https://github.com/kubernetes-sigs/external-dns/tree/master/docs) | [helm](https://bitnami.com/stack/external-dns/helm)<br>[helm-docs](https://github.com/bitnami/charts/tree/main/bitnami/external-dns/#installing-the-chart) |
| **Homer**                  | A dead simple static HOMe for your servER to keep your  services on hand from a simple yaml config |               [repo](https://github.com/bastienwirtz/homer)                |             [docker](https://hub.docker.com/r/b4bz/homer)              |
| **Omada Controller**       | TP-Link Omada Controller                                                                            |                                     [repo](https://github.com/mbentley/docker-omada-controller)                                     |                                                [docker](https://hub.docker.com/r/mbentley/omada-controller)                                                |                                                    |

### Backup

| Project                | Description                                                                                       |                                                                                                     Docs / Repo                                                                                                      |                                          Docker / Helm                                           |
|------------------------|---------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------:|
| **Borgmatic Exporter** | Prometheus exporter for Borgmatic seamlessly integrated into official Borgmatic image             |                                                                             [repo](https://github.com/maxim-mityutko/borgmatic-exporter)                                                                             | [docker](https://github.com/maxim-mityutko/borgmatic-exporter/pkgs/container/borgmatic-exporter) |
| **Borgmatic**          | Borgmatic is simple, configuration-driven backup software for servers, workstations and databases | [repo-docker-borgmatic](https://github.com/borgmatic-collective/docker-borgmatic)<br/> [repo-borgmatic](https://github.com/borgmatic-collective/borgmatic)<br/>[docs-borgmatic](https://torsion.org/borgmatic/docs/) |                        [docker](https://hub.docker.com/r/b3vis/borgmatic)                        |
| **Syncthing** | Open source continuous file synchronization | [repo](https://github.com/syncthing/syncthing)<br>[docs](https://syncthing.net) | [docker](https://docs.linuxserver.io/images/docker-syncthing/) |

### Monitoring

| Project                           | Description                                                                         |                                      Docs / Repo                                       |                                            Docker / Helm                                             |
|-----------------------------------|-------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------------:|
| **Victoria Metrics**              | Fast, cost-effective monitoring solution and time series database                   | [docs](https://docs.victoriametrics.com/) / [repo](https://github.com/VictoriaMetrics) | [helm](https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-k8s-stack) |
| | **Kubernetes Grafana Dashboards** - Observability dashboards for Kubernetes                                                                                     |             [repo](https://github.com/dotdc/grafana-dashboards-kubernetes)             |                                                                                                      |
| **Speedtest Tracker**             | Internet performance tracking that runs speedtest against Ookla's Speedtest service |                      [docs](https://docs.speedtest-tracker.dev/)                       |                    [docker](https://hub.docker.com/r/ajustesen/speedtest-tracker)                    |
| **Exportarr**                     | AIO Prometheus Exporter for *arr applications                                       |                      [repo](https://github.com/onedr0p/exportarr)                      |               [docker](https://github.com/onedr0p/exportarr/pkgs/container/exportarr)                |

### Extras

| Project                  | Description                                                                                                                                                                |                                            Docs / Repo                                            |                                                         Docker / Helm                                                         |
|--------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------------------------------------:|
| **Code Server**          | VS Code in the browser                                                                                                                                                     | [repo](https://github.com/coder/code-server)<br>[docs](https://coder.com/docs/code-server/latest) |                           [docker](https://github.com/coder/code-server/pkgs/container/code-server)                           |
| **Renovate**             | Universal dependency update tool                                                                                                                                           |                          [repo](https://github.com/renovatebot/renovate)                          |                                     [docker](https://hub.docker.com/r/renovate/renovate)                                      |
| **IT Tools**             | Useful tools for developer and people working in IT                                                                                                                        |                          [repo](https://github.com/CorentinTh/it-tools)                           |                                    [docker](https://hub.docker.com/r/corentinth/it-tools)                                     |
| **CloudBeaver**          | Cloud Database Manager                                                                                                                                                     |                          [repo](https://github.com/dbeaver/cloudbeaver)                           |                                    [docker](https://hub.docker.com/r/dbeaver/cloudbeaver)                                     |
| **Miniflux**             | Minimalist and opinionated feed reader                                                                                                                                     |              [repo](https://github.com/miniflux/v2)<br>[docs](https://miniflux.app)               |                                     [docker](https://hub.docker.com/r/miniflux/miniflux)                                      |
| **CouchDB**              | Open-source document-oriented NoSQL database. Usecase is to enable [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) for [Obsidian](https://obsidian.md) |          [docs](https://docs.couchdb.org/)<br>[repo](https://github.com/apache/couchdb)           |                          [helm](https://github.com/apache/couchdb-helm/blob/main/couchdb/README.md)                           |
| **Gitea**                | Lightweight and easy to use version control system                                                                                                                         |            [repo](https://github.com/go-gitea/gitea)<br>[docs](https://docs.gitea.com)            |                                          [helm](https://gitea.com/gitea/helm-chart)                                           |
| **PairDrop**             | Transfer Files Cross-Platform. No Setup, No Signup                                                                                                                         |                        [repo](https://github.com/schlagmichdoch/PairDrop)                         |                                   [docker](https://github.com/linuxserver/docker-pairdrop)                                    |
| **Stirling-PDF** | Locally hosted web application that allows you to perform various operations on PDF files | [repo](https://github.com/Stirling-Tools/Stirling-PDF)<br>[docs](https://docs.stirlingpdf.com) | [helm](https://github.com/Stirling-Tools/Stirling-PDF-chart) |

### Smart Home

| Project                | Description                                                                     |                                          Docs / Repo                                           |                                 Docker / Helm                                  |
|------------------------|---------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------:|
| **Tuya Gateway**       | Lightweight gateway for Tuya / Smartlife                                        |                     [repo](https://github.com/maxim-mityutko/tuya-gateway)                     |            [docker](https://hub.docker.com/r/beerhead/tuya-gateway)            |
| **Home Assistant**     | Central control system for smart home with a focus on local control and privacy | [docs](https://www.home-assistant.io/docs/)<br/>[repo](https://github.com/home-assistant/core) | [docker](https://github.com/home-assistant/core/pkgs/container/home-assistant) |
| **Mosquitto**          | An open source MQTT broker                                                      | [docs](https://mosquitto.org/documentation/)<br/>[repo](https://github.com/eclipse/mosquitto)  |              [docker](https://hub.docker.com/_/eclipse-mosquitto)              |
| **Frigate**            | Open source NVR built around real-time AI object detection                      |   [docs](https://docs.frigate.video)<br/>[repo](https://github.com/blakeblackshear/frigate)    |    [helm](https://github.com/blakeblackshear/blakeshome-charts/tree/master)    |
| **Zigbee2MQTT**        | Zigbee to MQTT bridge                                                           |      [docs](https://www.zigbee2mqtt.io)<br/>[repo](https://github.com/Koenkk/zigbee2mqtt)      |             [docker](https://hub.docker.com/r/koenkk/zigbee2mqtt)              |
| **PSA Car Controller** | Control PSA car with connected_car v4 API                                       |                      [repo](https://github.com/flobz/psa_car_controller)                       |          [docker](https://hub.docker.com/r/flobz/psa_car_controller)           |

### Privacy

| Project       | Description                                                                                                                       | Docs / Repo                                                                               | Docker / Helm                                                                                                                              |
|---------------|-----------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| **Filebrowser Quantum** | FileBrowser Quantum provides an easy way to access and manage your files from the web | [repo](https://github.com/gtsteffaniak/filebrowser)<br>[docs](https://filebrowserquantum.com/en/docs/) | [docker](https://github.com/gtsteffaniak/filebrowser/pkgs/container/filebrowser) |
| **SearXNG**   | Privacy-respecting, hackable metasearch engine                                                                                    | [repo](https://github.com/searxng/searxng)<br>[docs](https://docs.searxng.org/index.html) | [docker](https://hub.docker.com/r/searxng/searxng)                                                                                         |
| **Invidious** | **STOPPED WORKING DUE TO YOUTUBE CHANGES, NO FIX** <br>Invidious is an open source alternative front-end to YouTube               | [repo](https://github.com/iv-org/invidious)<br>[docs](https://docs.invidious.io/)         | [docker](https://quay.io/repository/invidious/invidious?tab=info)                                                                          |
| **Immich**    | High-performance self-hosted solution for backing up, viewing, managing, and sharing photos from your phone or existing galleries | [repo](https://github.com/immich-app/immich)<br>[docs](https://immich.app/docs)           | [helm](https://github.com/immich-app/immich-charts)                                                                                        |
| **Vaultwarden**          | Password management (alternative Bitwarden server)                                                                                                                         |                        [repo](https://github.com/dani-garcia/vaultwarden)                         |                                     [docker](https://hub.docker.com/r/vaultwarden/server)

### Media

A lot of general information on the topic: [TRaSH Guides](https://trash-guides.info/)

| Project               | Description                                                                             |                                                           Docs / Repo                                                           |                               Docker / Helm                               |
|-----------------------|-----------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------:|:-------------------------------------------------------------------------:|
| **Jellyfin**          | Jellyfin puts you in control of managing and streaming your media                       |                                          [repo](https://github.com/jellyfin/jellyfin)                                           |           [docker](https://hub.docker.com/r/jellyfin/jellyfin)            |
| **Jellyseerr**        | Fork of Overseerr for managing requests for the media library with Jellyfin integration |                                        [repo](https://github.com/Fallenbagel/jellyseerr)                                        |         [docker](https://hub.docker.com/r/fallenbagel/jellyseerr)         |
| **Radarr**            | Radarr is a movie collection manager for Usenet and BitTorrent users                    |                                            [repo](https://github.com/Radarr/Radarr)                                             |              [docker](https://hotio.dev/containers/radarr/)               |
| **Sonarr**            | Sonarr is a PVR for Usenet and BitTorrent users                                         |                                            [repo](https://github.com/Sonarr/Sonarr)                                             |              [docker](https://hotio.dev/containers/sonarr/)               |
| **Prowlarr**          | Prowlarr is an indexer manager/proxy                                                    |                                          [repo](https://github.com/prowlarr/prowlarr)                                           |             [docker](https://hotio.dev/containers/prowlarr/)              |
| **Bazarr**            | Bazarr is a companion application to Sonarr and Radarr to manage                        |                                         [repo](https://github.com/morpheus65535/bazarr)                                         | [docker](https://github.com/recyclarr/recyclarr/pkgs/container/recyclarr) |
| **Recyclarr**         | Automatically synchronize recommended settings from the TRaSH guides                    |                                         [repo](https://github.com/recyclarr/recyclarr/)                                         | [docker](https://github.com/recyclarr/recyclarr/pkgs/container/recyclarr) |
| **qBittorrent + Vue** |                                                                                         |    [repo-qbittorrent](https://github.com/qbittorrent/qbittorrent)<br>[repo-vuetorrent](https://github.com/WDaan/VueTorrent)     |            [docker](https://hotio.dev/containers/qbittorrent/)            |
| **qBit Manage**       | Manage qBittorrent instances with ease                                                  |                                      [repo](https://github.com/StuffAnThings/qbit_manage)                                       |            [docker](https://hotio.dev/containers/qbitmanage/)             |
| **Unpackerr**         |                                                                                         |                                         [repo](https://github.com/Unpackerr/unpackerr)                                          |            [docker](https://hotio.dev/containers/qbittorrent/)            |
| **Stash**             |                                                                                         | [repo](https://github.com/stashapp/stash)<br>[docs](https://github.com/stashapp/stash/blob/develop/docker/production/README.md) |             [docker](https://hub.docker.com/r/stashapp/stash)             |
| **FlareSolverr**         | FlareSolverr is a proxy server to bypass Cloudflare and DDoS-GUARD protection                                                                                        |                                         [repo](https://github.com/FlareSolverr/FlareSolverr)<br>[docs](https://trash-guides.info/Prowlarr/prowlarr-setup-flaresolverr/)                                          |            [docker](https://github.com/orgs/FlareSolverr/packages/container/package/flaresolverr)            |
| **Lidarr**             |  Looks and smells like Sonarr but made for music                                                                                       | [repo](https://github.com/Lidarr/Lidarr)<br>[docs](https://wiki.servarr.com/lidarrd) |             [docker](https://hotio.dev/containers/lidarr/)             |
| **Music Assistant** | Music Assistant is a free, opensource Media library manager that connects to your streaming services and a wide range of connected speakers | [repo](https://github.com/music-assistant/server)<br>[docs](https://www.music-assistant.io/) | [docker](https://github.com/music-assistant/server/pkgs/container/server) |
| **iSponsorBlockTV** | SponsorBlock client for all YouTube TV clients | [repo](https://github.com/dmunozv04/iSponsorBlockTV)<br>[docs](https://github.com/dmunozv04/iSponsorBlockTV/wiki) | [docker](https://github.com/dmunozv04/iSponsorBlockTV/pkgs/container/isponsorblocktv) |

### Standalone Applications

*This section contains the list of standalone applications or plugins that can be used to accompany the deployed services on the phones, computers or smart devices.*

| Project            | Description                                                                                                                                                                      | Link                                                                                                                                          |
|--------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| **Jellyfin Tizen** | Builds for the Jellyfin Tizen application for the Samsung smart TVs. Use [@georift/install-jellyfin-tizen](https://github.com/Georift/install-jellyfin-tizen) for quick deploys. | [docker-builds](https://github.com/babagreensheep/jellyfin-tizen-docker)<br>[repo-jellyfin-tizen](https://github.com/jellyfin/jellyfin-tizen) |
| **Obsidian** | Obsidian is a note-taking app that lets you store, link, and publish your thoughts on your device. You can customize Obsidian with plugins, themes, and graphs, and sync your notes securely across devices. | [obsidian.md](https://obsidian.md)
| **Obsidian Plugins - Self-hosted LiveSync** | Synchronization plugin, available on every obsidian-compatible platform and using CouchDB or Object Storage (e.g., MinIO, S3, R2, etc.) as the server. | [repo](https://github.com/vrtmrz/obsidian-livesync)
| **Bitwarden Password Manager** / **Bitwarden App** | Password manager that integrates with open-source Bitwarden implementation - **Vaultwarden**.  |
| **Floccus** | Sync your bookmarks privately across browsers and devices. Uses **Gitea** for bookmarks storage. |[repo](https://github.com/floccusaddon/floccus)<br>[docs](https://floccus.org/guides) |  
| **Immich-Go** | An alternative to the immich-CLI command that doesn't depend on nodejs installation. It tries its best for importing google photos takeout archives. | [repo](https://github.com/simulot/immich-go)<br>[docs](https://github.com/simulot/immich-go#running-immich-go) |

### Decomissioned / Unused

| Project       | Description                                                                                                                       | Docs / Repo                                                                               | Docker / Helm                                                                                                                              |
|---------------|-----------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| **Longhorn**               | Longhorn is a lightweight, reliable and easy-to-use distributed block storage system for Kubernetes |                                                     [docs](https://longhorn.io)                                                     |                                                   [helm](https://github.com/longhorn/charts/tree/master)                                                   |
| **Meshcentral**          | Web-based remote monitoring and management web site with Intel AMT support                                                                                                 | [repo](https://github.com/Ylianst/MeshCentral)<br>[docs](https://meshcentral.com/downloads.html)  |                              [docker](https://github.com/Ylianst/MeshCentral/tree/master/docker)                              |
