# Home Infrastructure
[![k8s](https://img.shields.io/badge/Microk8s-v1.27.2-black?style=flat-square)](https://k8s.io/)
[![GitHub last commit](https://img.shields.io/github/last-commit/maxim-mityutko/home-infra/main?style=flat-square)](https://github.com/maxim-mityutko/home-infra/commits/main)

## Notes
The rollout from scratch has not been fully automated yet, and generally requires following
the process defined in `\readme` and `\kubernetes\scripts` folders for the initial setup.

After the initial steps are complete, deployments are handled via ArgoCD application manifests
defined in the `kubernetes\argocd`.

## Hardware:
* ProxMox VE Host:
  * MOBO: [ASRock IMB-X1231](https://www.asrockind.com/en-gb/IMB-X1231)
  * CPU: Intel Core i5-13500
  * RAM: Kingston Server Premier DDR4-ECC-3200 32 GB x2
  * Extension Cards:
    1. SATA Controller - 2 Port: JMB58x - M.2 M+B Key
    2. SATA Controller - 6 port: ASM1166 - M.2 M Key
  * Storage:
    1. SSD Samsung 840 Pro 256 GB x2
    2. SSD Samsung 860 Evo 1 TB
    3. SSD Crucial BX500 1TB x2
    4. HDD Seagate IronWolf Pro NAS 12 TB x3
  * Virtual Machines:
    * TrueNAS Scale with 4 CPUs, 8GB RAM and extension cards (1) and (2) as direct passthrough and SSD (3) and HDD (4) in ZFS pulls for storage
    * Ubuntu Server with 4 CPUs and and 8GB RAM
    * Ubuntu Server with 6 CPUs and and 16GB RAM 
* ProxMox VE Host (Spare):  
  * CPU Intel i7-6700
  * RAM 16 GB 
  * Storage:
    1. SSD SanDisk SD7TB3Q-256G-1006 256GB
    2. NVME WD Blue NVME 500 GB
  * Virtual Machines:
    * (x3) Ubuntu Server with 2 CPUs and and 4GB RAM 
* Raspberry Pi 4B 8GB
* Upcoming: [Compute Blade](https://www.kickstarter.com/projects/uptimelab/compute-blade) with CM4 8GB and 500 GB NVME x 4

## Services
### Microk8s
Some services are installed out of the box in Microk8s, refer to `kubernetes/scripts/00.0-init.sh`

### Default
| Project                    | Description                                                                                        |                                Docs / Repo                                 |                             Docker / Helm                              |
|----------------------------|----------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------:|:----------------------------------------------------------------------:|
| **ArgoCD**                 | Declarative GitOps CD for Kubernetes                                                               |             [docs](https://argo-cd.readthedocs.io/en/stable/)              |                                                                        |
| **NFS Subdir Provisioner** | Automatic provisioning of PVs via PVCs                                                             | [repo](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) |                                                                        |
| **Sealed Secrets**         | A Kubernetes controller and tool for one-way encrypted Secrets                                     |           [repo](https://github.com/bitnami-labs/sealed-secrets)           |         [helm](https://bitnami.com/stack/sealed-secrets/helm)          |
| **Cert Manager**           | Certificate management for Kubernetes                                                              |          [docs](https://cert-manager.io/docs/installation/helm/)           | [helm](https://artifacthub.io/packages/helm/cert-manager/cert-manager) |
| **Cloudflare DDNS**        | Dynamic DNS implementation for the Cloudflare service                                              |           [repo](https://github.com/oznu/docker-cloudflare-ddns)           |        [docker](https://hub.docker.com/r/oznu/cloudflare-ddns/)        |
| **Homer**                  | A dead simple static HOMe for your servER to keep your  services on hand from a simple yaml config |               [repo](https://github.com/bastienwirtz/homer)                |             [docker](https://hub.docker.com/r/b4bz/homer)              |
| **Lighttpd**               | Lightweight HTTP server                                                                            |                                                                            |            [docker](https://hub.docker.com/r/sebp/lighttpd)            |
| **Omada Controller**       | TP-Link Omada Controller                                                                            |                                     [repo](https://github.com/mbentley/docker-omada-controller)                                     |                                                [docker](https://hub.docker.com/r/mbentley/omada-controller)                                                |                                                    |
| **MariaDB**                | MariaDB Server is a high performing open source relational database, forked from MySQL              |                                          [repo](https://github.com/MariaDB/mariadb-docker)                                          |                                                         [docker](https://hub.docker.com/_/mariadb)                                                         |
| **MariaDB - Adminer**      | Database management in a single PHP file                                                            |                                              [repo](https://github.com/vrana/adminer)                                               |                                                         [docker](https://hub.docker.com/_/adminer)                                                         |
| **PostgreSQL**             | The PostgreSQL object-relational database system provides reliability and data integrity            |                                                                                                                                     |                                                        [docker](https://hub.docker.com/_/postgres)                                                         |
| | **PgVecto-rs** - Scalable vector search extension for PostgreSQL<br>**Required by:** *Immich* | [repo](https://github.com/tensorchord/pgvecto.rs)<br>[docs](https://docs.pgvecto.rs/getting-started/overview.html) | [docker](https://hub.docker.com/r/tensorchord/pgvecto-rs/) |
| **Authentik**              | Identity Provider that emphasizes flexibility and versatility                                       |                    [docs](https://docs.goauthentik.io/docs/)<br>[repo](https://github.com/goauthentik/authentik)                    |                                             [helm](https://artifacthub.io/packages/helm/goauthentik/authentik)                                             |
| **Longhorn**               | Longhorn is a lightweight, reliable and easy-to-use distributed block storage system for Kubernetes |                                                     [docs](https://longhorn.io)                                                     |                                                   [helm](https://github.com/longhorn/charts/tree/master)                                                   |
| **External DNS**           | Configure external DNS servers for Kubernetes Ingresses and Services                                | [repo](https://github.com/kubernetes-sigs/external-dns)<br>[docs](https://github.com/kubernetes-sigs/external-dns/tree/master/docs) | [helm](https://bitnami.com/stack/external-dns/helm)<br>[helm-docs](https://github.com/bitnami/charts/tree/main/bitnami/external-dns/#installing-the-chart) |
| **Blocky**                 | Fast and lightweight DNS proxy as ad-blocker for local network                                      |                    [repo](https://github.com/0xERR0R/blocky)<br>[docs](https://0xerr0r.github.io/blocky/latest/)                    |                                                      [docker](https://hub.docker.com/r/spx01/blocky)                                                       |
| **Tailscale K8s Operator** | Secure, remote access to on-premises | [repo](https://github.com/tailscale/tailscale)<br>[docs](https://tailscale.com/kb/1236/kubernetes-operator) | [helm](https://github.com/tailscale/tailscale/blob/main/cmd/k8s-operator/deploy/README.md) |
| **Redis** | In-memory database that persists on disk | [repo](https://github.com/redis/redis) | [helm](https://github.com/bitnami/charts/blob/main/bitnami/redis/README.md) |

### Backup
| Project                | Description                                                                                       |                                                                                                     Docs / Repo                                                                                                      |                                          Docker / Helm                                           |
|------------------------|---------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------:|
| **Borgmatic Exporter** | Prometheus exporter for Borgmatic seamlessly integrated into official Borgmatic image             |                                                                             [repo](https://github.com/maxim-mityutko/borgmatic-exporter)                                                                             | [docker](https://github.com/maxim-mityutko/borgmatic-exporter/pkgs/container/borgmatic-exporter) |
| **Borgmatic**          | Borgmatic is simple, configuration-driven backup software for servers, workstations and databases | [repo-docker-borgmatic](https://github.com/borgmatic-collective/docker-borgmatic)<br/> [repo-borgmatic](https://github.com/borgmatic-collective/borgmatic)<br/>[docs-borgmatic](https://torsion.org/borgmatic/docs/) |                        [docker](https://hub.docker.com/r/b3vis/borgmatic)                        |

### Monitoring
| Project                           | Description                                                                         |                                      Docs / Repo                                       |                                            Docker / Helm                                             |
|-----------------------------------|-------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------------:|
| **Victoria Metrics**              | Fast, cost-effective monitoring solution and time series database                   | [docs](https://docs.victoriametrics.com/) / [repo](https://github.com/VictoriaMetrics) | [helm](https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-k8s-stack) |
| **Kubernetes Grafana Dashboards** |                                                                                     |             [repo](https://github.com/dotdc/grafana-dashboards-kubernetes)             |                                                                                                      |
| **Speedtest Tracker**             | Internet performance tracking that runs speedtest against Ookla's Speedtest service |                      [docs](https://docs.speedtest-tracker.dev/)                       |                    [docker](https://hub.docker.com/r/ajustesen/speedtest-tracker)                    |
| **Exportarr**                     | AIO Prometheus Exporter for *arr applications                                       |                      [repo](https://github.com/onedr0p/exportarr)                      |               [docker](https://github.com/onedr0p/exportarr/pkgs/container/exportarr)                |

### Extras
| Project                  | Description                                                                |                                            Docs / Repo                                            |                                                         Docker / Helm                                                         |
|--------------------------|----------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------------------------------------:|
| **Apache Guacamole**     | Clientless remote desktop gateway                                          |                [docs](https://guacamole.apache.org/doc/gug/guacamole-docker.html)                 | [docker-guacd](https://hub.docker.com/r/guacamole/guacd)<br/>[docker-guacamole](https://hub.docker.com/r/guacamole/guacamole) |
| **Meshcentral**          | Web-based remote monitoring and management web site with Intel AMT support | [repo](https://github.com/Ylianst/MeshCentral)<br>[docs](https://meshcentral.com/downloads.html)  |                              [docker](https://github.com/Ylianst/MeshCentral/tree/master/docker)                              |
| **Code Server**          | VS Code in the browser                                                     | [repo](https://github.com/coder/code-server)<br>[docs](https://coder.com/docs/code-server/latest) |                           [docker](https://github.com/coder/code-server/pkgs/container/code-server)                           |
| **Jupyter with PySpark** | Python and Spark Jupyter Notebook Stack                                    |                         [repo](https://github.com/jupyter/docker-stacks)                          |                                  [docker](https://hub.docker.com/r/jupyter/pyspark-notebook)                                  |
| **Vaultwarden**          | Password management (alternative Bitwarden server)                         |                        [repo](https://github.com/dani-garcia/vaultwarden)                         |                                     [docker](https://hub.docker.com/r/vaultwarden/server)                                     |
| **Renovate**             | Universal dependency update tool                                           |                          [repo](https://github.com/renovatebot/renovate)                          |                                     [docker](https://hub.docker.com/r/renovate/renovate)                                      |
| **IT Tools**             | Useful tools for developer and people working in IT                        |                          [repo](https://github.com/CorentinTh/it-tools)                           |                                    [docker](https://hub.docker.com/r/corentinth/it-tools)                                     |
| **CloudBeaver**          | Cloud Database Manager                                                     |                          [repo](https://github.com/dbeaver/cloudbeaver)                           |                                    [docker](https://hub.docker.com/r/dbeaver/cloudbeaver)                                     |
| **Miniflux**             | Minimalist and opinionated feed reader                                     |              [repo](https://github.com/miniflux/v2)<br>[docs](https://miniflux.app)               |                                     [docker](https://hub.docker.com/r/miniflux/miniflux)                                      |

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
| **SearXNG**   | Privacy-respecting, hackable metasearch engine                                                                                    | [repo](https://github.com/searxng/searxng)<br>[docs](https://docs.searxng.org/index.html) | [docker](https://hub.docker.com/r/searxng/searxng)                                                                                         |
| **Invidious** | Invidious is an open source alternative front-end to YouTube                                                                      | [repo](https://github.com/iv-org/invidious)<br>[docs](https://docs.invidious.io/)         | [docker](https://quay.io/repository/invidious/invidious?tab=info)                                                                          |
| **Immich**    | High-performance self-hosted solution for backing up, viewing, managing, and sharing photos from your phone or existing galleries | [repo](https://github.com/immich-app/immich)<br>[docs](https://immich.app/docs)           | [helm](https://github.com/immich-app/immich-charts)                                                                                        |
| **Nextcloud** | Nextcloud file hosting services, similar to Google Drive / Photos                                                                 | [repo](https://github.com/nextcloud/all-in-one)                                           | [helm](https://github.com/nextcloud/helm/tree/main)<br>[helm-docs](https://github.com/nextcloud/helm/blob/main/charts/nextcloud/README.md) |

### Media
A lot of general information on the topic: [TRaSH Guides](https://trash-guides.info/)

| Project               | Description                                                                             |                                                           Docs / Repo                                                           |                               Docker / Helm                               |
|-----------------------|-----------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------:|:-------------------------------------------------------------------------:|
| **Jellyfin**          | Jellyfin puts you in control of managing and streaming your media                       |                                          [repo](https://github.com/jellyfin/jellyfin)                                           |           [docker](https://hub.docker.com/r/jellyfin/jellyfin)            |
| **Jellyseerr**        | Fork of Overseerr for managing requests for the media library with Jellyfin integration |                                        [repo](https://github.com/Fallenbagel/jellyseerr)                                        |         [docker](https://hub.docker.com/r/fallenbagel/jellyseerr)         |
| **Radarr**            | Radarr is a movie collection manager for Usenet and BitTorrent users                    |                                            [repo](https://github.com/Radarr/Radarr)                                             |              [docker](https://hotio.dev/containers/radarr/)               |
| **Sonarr**            | Sonarr is a PVR for Usenet and BitTorrent users                                         |                                            [repo](https://github.com/Sonarr/Sonarr)                                             |              [docker](https://hotio.dev/containers/sonarr/)               |
| **Prowlarr**          | Prowlarr is an indexer manager/proxy                                                    |                                          [repo](https://github.com/prowlarr/prowlarr)                                           |             [docker](https://hotio.dev/containers/prowlarr/)              |
| **Readarr**           | Readarr is an ebook and audiobook collection manager for Usenet and BitTorrent users    |                                           [repo](https://github.com/readarr/readarr)                                            |              [docker](https://hotio.dev/containers/readarr/)              |
| **Bazarr**            | Bazarr is a companion application to Sonarr and Radarr to manage                        |                                         [repo](https://github.com/morpheus65535/bazarr)                                         | [docker](https://github.com/recyclarr/recyclarr/pkgs/container/recyclarr) |
| **Recyclarr**         | Automatically synchronize recommended settings from the TRaSH guides                    |                                         [repo](https://github.com/recyclarr/recyclarr/)                                         | [docker](https://github.com/recyclarr/recyclarr/pkgs/container/recyclarr) |
| **qBittorrent + Vue** |                                                                                         |    [repo-qbittorrent](https://github.com/qbittorrent/qbittorrent)<br>[repo-vuetorrent](https://github.com/WDaan/VueTorrent)     |            [docker](https://hotio.dev/containers/qbittorrent/)            |
| **qBit Manage**       | Manage qBittorrent instances with ease                                                  |                                      [repo](https://github.com/StuffAnThings/qbit_manage)                                       |            [docker](https://hotio.dev/containers/qbitmanage/)             |
| **Unpackerr**         |                                                                                         |                                         [repo](https://github.com/Unpackerr/unpackerr)                                          |            [docker](https://hotio.dev/containers/qbittorrent/)            |
| **Stash**             |                                                                                         | [repo](https://github.com/stashapp/stash)<br>[docs](https://github.com/stashapp/stash/blob/develop/docker/production/README.md) |             [docker](https://hub.docker.com/r/stashapp/stash)             |
**FlareSolverr**         | FlareSolverr is a proxy server to bypass Cloudflare and DDoS-GUARD protection.                                                                                        |                                         [repo](https://github.com/FlareSolverr/FlareSolverr)<br>[docs](https://trash-guides.info/Prowlarr/prowlarr-setup-flaresolverr/)                                          |            [docker](https://github.com/orgs/FlareSolverr/packages/container/package/flaresolverr)            |

#### Plugins and Extras
| Project            | Description                                                         | Link                                                                                                                                          |
|--------------------|---------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| **Jellyfin Tizen** | Builds for the Jellyfin Tizen application for the Samsung smart TVs | [docker-builds](https://github.com/babagreensheep/jellyfin-tizen-docker)<br>[repo-jellyfin-tizen](https://github.com/jellyfin/jellyfin-tizen) |
