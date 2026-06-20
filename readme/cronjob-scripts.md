# CronJob Script Inventory

These scripts are mounted into CronJobs through generated ConfigMaps instead of
being embedded directly in workload YAML.

- [Cloudflare node DNS sync](../kubernetes/cluster/default/cloudflare/scripts/sync-node-dns.sh): maintains `DNSEndpoint` records for ready MicroK8s control plane nodes and `casa.brhd.io`.
- [Blocky Omada DNS sync](../kubernetes/cluster/default/blocky/scripts/omada-dns-sync.sh): generates Blocky custom DNS config from Omada LAN DNS records.
- [Blocky Omada clients sync](../kubernetes/cluster/default/blocky/scripts/omada-clients-sync.sh): generates Blocky client lookup config from active Omada clients.
