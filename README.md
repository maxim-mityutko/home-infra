# Home Infrastructure
[![k8s](https://img.shields.io/badge/Microk8s-v1.27.2-black?style=flat-square)](https://k8s.io/)
[![GitHub last commit](https://img.shields.io/github/last-commit/maxim-mityutko/home-infra/main?style=flat-square)](https://github.com/maxim-mityutko/home-infra/commits/main)

## Notes
The rollout from scratch has not been fully automated yet, and generally requires following
the process defined in `\readme` and `\kubernetes\scripts` folders for the initial setup.

After the initial steps are complete, deployments are handled via ArgoCD application manifests
defined in the `kubernetes\argocd`.

## Hardware:
* VM Host: CPU Intel i5-3470 / RAM 24 GB / 2 x SSD 500 GB in RAID 0 / 2 x HDD 12TB in RAID 0 with TrueNas Scale 
  * VM1: RAM 8GB
  * VM2: RAM 4GB
* Raspberry Pi 4B / RAM 8GB
* ~~Raspberry Pi 4B / RAM 4GB~~
* Upcoming: [Compute Blade](https://www.kickstarter.com/projects/uptimelab/compute-blade) with CM4 8GB and 500 GB NVME x 2

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
| **Omada Controller**       | TP-Link Omada Controller                                                                           |        [repo](https://github.com/mbentley/docker-omada-controller)         |      [docker](https://hub.docker.com/r/mbentley/omada-controller)      |
| **PiHole**                 | Network-wide ad blocking and DNS                                                                   |                 [repo](https://github.com/pi-hole/pi-hole)                 |            [docker](https://hub.docker.com/r/pihole/pihole)            |
| **MariaDB**                | MariaDB Server is a high performing open source relational database, forked from MySQL             |             [repo](https://github.com/MariaDB/mariadb-docker)              |               [docker](https://hub.docker.com/_/mariadb)               |
| **MariaDB - Adminer**      | Database management in a single PHP file                                                           |                  [repo](https://github.com/vrana/adminer)                  |               [docker](https://hub.docker.com/_/adminer)               |
| **PostgreSQL**             | The PostgreSQL object-relational database system provides reliability and data integrity           |                                                                            |              [docker](https://hub.docker.com/_/postgres)               |

### Monitoring
| Project                           | Description                                                                         |                                      Docs / Repo                                       |                                            Docker / Helm                                             |
|-----------------------------------|-------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------------:|
| **Victoria Metrics**              | Fast, cost-effective monitoring solution and time series database                   | [docs](https://docs.victoriametrics.com/) / [repo](https://github.com/VictoriaMetrics) | [helm](https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-k8s-stack) |
| **Kubernetes Grafana Dashboards** |                                                                                     |             [repo](https://github.com/dotdc/grafana-dashboards-kubernetes)             |                                                                                                      |
| **Speedtest Tracker**             | Internet performance tracking that runs speedtest against Ookla's Speedtest service |                      [docs](https://docs.speedtest-tracker.dev/)                       |                    [docker](https://hub.docker.com/r/ajustesen/speedtest-tracker)                    |
| **Exportarr**                     | AIO Prometheus Exporter for *arr applications                                       |                     [repo](https://github.com/onedr0p/exportarr)                       |               [docker](https://github.com/onedr0p/exportarr/pkgs/container/exportarr)                |

### Extras
| Project                  | Description                                         |                            Docs / Repo                             |                                                         Docker / Helm                                                         |
|--------------------------|-----------------------------------------------------|:------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------------------------------------:|
| **Apache Guacamole**     | Clientless remote desktop gateway                   | [docs](https://guacamole.apache.org/doc/gug/guacamole-docker.html) | [docker-guacd](https://hub.docker.com/r/guacamole/guacd)<br/>[docker-guacamole](https://hub.docker.com/r/guacamole/guacamole) |
| **Jupyter with PySpark** | Python and Spark Jupyter Notebook Stack             |          [repo](https://github.com/jupyter/docker-stacks)          |                                  [docker](https://hub.docker.com/r/jupyter/pyspark-notebook)                                  |
| **Vaultwarden**          | Password management (alternative Bitwarden server)  |         [repo](https://github.com/dani-garcia/vaultwarden)         |                                     [docker](https://hub.docker.com/r/vaultwarden/server)                                     | 
| **Valutwarden Backup**   | Simple CRON powered backup for Vaultwarden          |      [repo](https://github.com/Bruceforce/vaultwarden-backup)      |                               [docker](https://hub.docker.com/r/bruceforce/vaultwarden-backup)                                |
| **Renovate**             | Universal dependency update tool                    |          [repo](https://github.com/renovatebot/renovate)           |                                     [docker](https://hub.docker.com/r/renovate/renovate)                                      |
| **IT Tools**             | Useful tools for developer and people working in IT |           [repo](https://github.com/CorentinTh/it-tools)           |                                    [docker](https://hub.docker.com/r/corentinth/it-tools)                                     |

### Smart Home
| Project            | Description                                                                     |                                          Docs / Repo                                           |                                  Docker / Helm                                  |
|--------------------|---------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------:|:-------------------------------------------------------------------------------:|
| **Tuya Gateway**   | Lightweight gateway for Tuya / Smartlife                                        |                     [repo](https://github.com/maxim-mityutko/tuya-gateway)                     |            [docker](https://hub.docker.com/r/beerhead/tuya-gateway)             |
| **Home Assistant** | Central control system for smart home with a focus on local control and privacy | [docs](https://www.home-assistant.io/docs/)<br/>[repo](https://github.com/home-assistant/core) | [docker](https://github.com/home-assistant/core/pkgs/container/home-assistant)  |
| **NanoMQ**         | An Ultra-lightweight and Blazing-fast MQTT Broker for IoT Edge                  |      [docs](https://nanomq.io/docs/en/latest/)<br/>[repo](https://github.com/emqx/nanomq)      |                 [docker](https://hub.docker.com/r/emqx/nanomq)                  |
| **Shinobi**        | Open source network video recorder (NVR)                                        |   [docs](https://docs.shinobi.video/)<br/>[repo](https://gitlab.com/Shinobi-Systems/Shinobi)   | [docker](https://gitlab.com/Shinobi-Systems/Shinobi/container_registry/2430788) |

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


