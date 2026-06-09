# Bootstrap Cluster

## ArgoCD Sync Waves

ArgoCD Application manifests are assigned `argocd.argoproj.io/sync-wave`
annotations so the app-of-apps rollout starts with cluster primitives and then
moves toward workload leaf apps. When adding or moving an Application, choose a
wave that preserves this dependency order instead of only matching the folder
name.

The current wave plan was created with these criteria:

- Hard dependencies go first: secrets, CNI, load balancing, DNS, certificates,
  storage, CRDs, controllers, and databases must exist before apps that consume
  them.
- CRD providers are isolated before their consumers, especially
  VictoriaMetrics, CloudNativePG, cert-manager, KEDA, and storage providers.
- Authentication, ingress, logs, and ArgoCD self-management start after the
  infrastructure they reference is available.
- Folder-level apps are split by dependency and approximate workload weight
  from declared requests and limits, so lighter leaf apps can sync before
  heavier or stateful apps.
- Related applications are grouped where they share the same dependency profile,
  but split when one app provides a service that another app needs.
- Media applications are staggered more finely than the folder structure:
  shared/download components first, Servarr managers next, then helpers,
  frontends, exporters, and the single heaviest app last.
- Later user-facing or AI apps start after the platform, monitoring, logging,
  ingress, and support services they depend on.

### Sync Wave Details

| Application Name | Sync Wave | Comment |
| --- | --- | --- |
| calico | 0 | Foundation wave: secrets, CNI, load balancing, and cluster DNS. |
| core-dns | 0 | Foundation wave: secrets, CNI, load balancing, and cluster DNS. |
| metallb | 0 | Foundation wave: secrets, CNI, load balancing, and cluster DNS. |
| sealed-secrets | 0 | Foundation wave: secrets, CNI, load balancing, and cluster DNS. |
| cert-manager | 1 | DNS/cert/network add-on wave. |
| cloudflare | 1 | DNS/cert/network add-on wave. |
| external-dns | 1 | DNS/cert/network add-on wave. |
| multus | 1 | DNS/cert/network add-on wave. |
| keda | 2 | Storage and KEDA provider wave; before all KEDA HTTP consumers. |
| nfs-subdir | 2 | Storage and KEDA provider wave. |
| openebs | 2 | Storage and KEDA provider wave. |
| victoria-metrics | 3 | Single provider wave because VM scrape/rule CRDs gate many later apps. |
| cloudnative-pg | 4 | Single controller wave before CNPG clusters. |
| cnpg-ha | 5 | Single HA database wave before Authentik. |
| argocd | 6 | Self-management grouped after CRDs it references are available. |
| authentik | 6 | Grouped with ingress/logs/ArgoCD after HA database and VM CRDs. |
| nginx-ingress | 6 | Grouped with auth/logs after network, TLS, and VM CRDs. |
| victoria-logs | 6 | Grouped with auth/ingress once VM and base infra exist. |
| blocky | 7 | Light/default platform wave. |
| metrics-server | 7 | Light/default platform wave. |
| node-feature-discovery | 7 | Light/default platform wave before GPU plugin. |
| redis | 7 | Light/default platform wave. |
| tailscale | 7 | Light/default platform wave. |
| zot | 7 | Light/default platform wave. |
| cnpg-default | 8 | Heavier/specialized default app after CNPG controller. |
| cnpg-vectorchord | 8 | Heavier/specialized default app after CNPG controller. |
| gpu | 8 | Heavier/specialized default app after node-feature-discovery. |
| headlamp | 8 | Default dashboard app. |
| homer | 8 | Default portal app. |
| omada | 8 | Heavier/specialized default app. |
| rustfs | 8 | Heavier/specialized default app. |
| speedtest | 9 | Monitoring-only wave; kept separate from smart-home. |
| x-monitoring-shared | 9 | Monitoring-only wave; kept separate from smart-home. |
| frigate | 10 | Smart-home wave. |
| home-assistant | 10 | Smart-home wave. |
| mosquitto | 10 | Smart-home wave. |
| zigbee2mqtt | 10 | Smart-home wave. |
| bento-pdf | 11 | Light extras wave. |
| cloud-beaver | 11 | Light extras wave. |
| it-tools | 11 | Light extras wave. |
| pairdrop | 11 | Light extras wave. |
| x-extras-shared | 11 | Light extras wave with shared resources. |
| code-server | 12 | Heavier/stateful extras wave. |
| couchdb | 12 | Heavier/stateful extras wave. |
| gitea | 12 | Heavier/stateful extras wave. |
| meshcentral | 12 | Heavier/stateful extras wave. |
| miniflux | 12 | Heavier/stateful extras wave. |
| renovate | 12 | Heavier/stateful extras wave. |
| borgmatic | 13 | Backup wave. |
| syncthing | 13 | Backup wave. |
| x-backup-shared | 13 | Backup wave with shared resources. |
| flaresolverr | 14 | Media base/support wave before indexers. |
| qbittorrent | 14 | Media base/download wave. |
| x-media-shared | 14 | Media base wave with shared resources. |
| bazarr | 15 | Servarr manager wave. |
| lidarr | 15 | Servarr manager wave. |
| prowlarr | 15 | Servarr manager wave. |
| radarr | 15 | Servarr manager wave. |
| sonarr | 15 | Servarr manager wave. |
| exportarr | 16 | Media exporter wave; fixes the old nonexistent monitoring path. |
| isponsorblocktv | 16 | Media helper wave. |
| jellyfin | 16 | Media ancillary/frontend wave. |
| jellyseerr | 16 | Media ancillary/frontend wave. |
| music-assistant | 16 | Media helper wave. |
| qbitmanage | 16 | Media automation wave after qBittorrent. |
| recyclarr | 16 | Media automation/exporter wave after Servarr apps. |
| unpackerr | 16 | Media automation wave after download/Servarr apps. |
| stash | 17 | Single heavy media wave. |
| filebrowser | 18 | Privacy wave. |
| immich | 18 | Privacy wave; heavier by declared resources but still okay within this group. |
| invidious | 18 | Privacy wave. |
| karakeep | 18 | Privacy wave; heavier by declared resources but still okay within this group. |
| searxng | 18 | Privacy wave. |
| vaultwarden | 18 | Privacy wave. |
| vikunja | 18 | Privacy wave. |
| x-privacy-shared | 18 | Privacy wave with shared resources. |
| browserless | 19 | AI support wave before OpenClaw. |
| victoria-logs-mcp | 19 | AI support wave; depends on VictoriaLogs. |
| victoria-metrics-mcp | 19 | AI support wave; depends on VictoriaMetrics. |
| openclaw | 20 | Final app wave after AI support services. |
