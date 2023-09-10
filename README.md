# Home Cluster
[![k8s](https://img.shields.io/badge/Microk8s-v1.27.2-black?style=flat-square)](https://k8s.io/)
[![GitHub last commit](https://img.shields.io/github/last-commit/maxim-mityutko/casa-ursa/main?style=flat-square)](https://github.com/maxim-mityutko/casa-ursa/commits/main)

## Notes
The rollout from scratch has not been fully automated yet, and generally requires following
the process defined in `\kubernetes\scripts` and `\readme` folders for the initial setup.

After the initial steps are complete, deployments are handled via ArgoCD applications 
defined in the `kubernetes\argocd`.

## Hardware:
* CPU Intel i5-3470 / RAM 24 GB / 2 x SSD 500 GB in RAID 0 / 2 x HDD 12TB in RAID 0 with TrueNas Scale and 2 VMs (8GB + 4GB)
* Raspberry Pi 4B / RAM 4GB
* Raspberry Pi 4B / RAM 8GB 

## Services
### Microk8s
Some services are installed out of the box in Microk8s, refer to `kubernetes/scripts/00.0-init.sh`

### Essential
* [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) - Declarative GitOps CD for Kubernetes
* [NFS Subdir Provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) - Automatic provisioning of PVs via PVCs
* [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) - A Kubernetes controller and tool for one-way encrypted Secrets
* [Cert Manager](https://cert-manager.io/docs/installation/helm/) - Certificate management for Kubernetes
* [Cloudflare DDNS](https://hub.docker.com/r/oznu/cloudflare-ddns/) - Dynamic DNS implementation for the Cloudflare service
* [Homer](https://hub.docker.com/r/b4bz/homer) - A dead simple static HOMe for your servER to keep your services on hand from a simple yaml config.
* [Lighttpd](https://hub.docker.com/r/sebp/lighttpd) - Lightweight HTTP server
* [Omada Controller](https://hub.docker.com/r/mbentley/omada-controller) - Docker image to run TP-Link Omada Controller 
* [Pihole](https://hub.docker.com/r/pihole/pihole) - Network-wide ad blocking

### Observability / Monitoring
* [Victoria Metrics](https://victoriametrics.com/):
  * Docs: https://docs.victoriametrics.com/
  * Charts: https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-k8s-stack
  * Github: https://github.com/VictoriaMetrics
* Dashboards:
  * [Grafana Dashboards Kubernetes](https://github.com/dotdc/grafana-dashboards-kubernetes)
  * (NOT INTEGRATED) [Kubernetes Mixin](https://github.com/kubernetes-monitoring/kubernetes-mixin)
* [Speedtest Tracker](https://docs.speedtest-tracker.dev/)

### Database
* [PostgreSQL](https://hub.docker.com/_/postgres) - The PostgreSQL object-relational database system provides reliability and data integrity.
* MariaDB
  * [MariaDB](https://hub.docker.com/_/mariadb) - MariaDB Server is a high performing open source relational database, forked from MySQL
  * [Adminer](https://hub.docker.com/_/adminer) - Database management in a single PHP file

### Extras
* [Apache Guacamole](https://guacamole.apache.org/doc/gug/guacamole-docker.html) - Clientless remote desktop gateway
  * [guacamole/guacd](https://hub.docker.com/r/guacamole/guacd)
  * [guacamole/guacamole](https://hub.docker.com/r/guacamole/guacamole)
  * depends on MariaDB 
* [Jupyter PySpark](https://github.com/jupyter/docker-stacks)
* [Vaultwarden](https://github.com/dani-garcia/vaultwarden) - Password management (alternative Bitwarden server)
* [Vaultwarden Backup](https://hub.docker.com/r/bruceforce/vaultwarden-backup) - Simple CRON powered backup for Vaultwarden
* [Renovate](https://hub.docker.com/r/renovate/renovate) - Universal dependency update tool
* [IT Tools](https://github.com/CorentinTh/it-tools) - Useful tools for developer and people working in IT

### Smarthome
* [Tuya Gateway](https://github.com/maxim-mityutko/tuya-gateway)

### Media
A lot of general information on the topic: [TRaSH Guides](https://trash-guides.info/)

The majority of *arr and supporting containers can be found on [Hotio](https://hotio.dev/) 
* [Jellyfin](https://github.com/jellyfin/jellyfin) - Jellyfin puts you in control of managing and streaming your media.
  * Image: https://hub.docker.com/r/jellyfin/jellyfin
* [Jellyseerr](https://github.com/Fallenbagel/jellyseerr) - Fork of Overseerr for managing requests for the media library with Jellyfin integration.
* [Radarr](https://github.com/Radarr/Radarr)
* [Sonarr](https://github.com/Sonarr/Sonarr)
* [Prowlarr](https://github.com/prowlarr/prowlarr)
* [Readarr](https://github.com/readarr/readarr)
* [Bazarr](https://github.com/bazarr/bazarr)
* [qBittorrent](https://hotio.dev/containers/qbittorrent/)
* [qBitManage](https://hotio.dev/containers/qbitmanage/)
* [Recyclarr](https://github.com/recyclarr/recyclarr/) 
  * Docker: https://github.com/recyclarr/recyclarr/pkgs/container/recyclarr
* [Unpackerr](https://github.com/Unpackerr/unpackerr)
* [Stash](https://github.com/stashapp/stash/blob/develop/docker/production/README.md)

