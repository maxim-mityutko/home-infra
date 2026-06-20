# CronJob Script Inventory

These scripts are mounted into CronJobs through generated ConfigMaps instead of
being embedded directly in workload YAML.

- [Calico restart](../kubernetes/cluster/default/calico/scripts/restart-calico-node.sh): restarts the `calico-node` DaemonSet on its maintenance schedule.
- [Multus restart](../kubernetes/cluster/default/multus/scripts/restart-multus.sh): restarts the `multus` DaemonSet on its maintenance schedule.
- [Cloudflare node DNS sync](../kubernetes/cluster/default/cloudflare/scripts/sync-node-dns.sh): maintains `DNSEndpoint` records for ready MicroK8s control plane nodes and `casa.brhd.io`.
- [Blocky Omada DNS sync](../kubernetes/cluster/default/blocky/scripts/omada-dns-sync.sh): generates Blocky custom DNS config from Omada LAN DNS records.
- [Blocky Omada clients sync](../kubernetes/cluster/default/blocky/scripts/omada-clients-sync.sh): generates Blocky client lookup config from active Omada clients.
- [Recyclarr sync](../kubernetes/cluster/media/recyclarr/scripts/recyclarr-sync.sh): runs the scheduled Recyclarr sync.
