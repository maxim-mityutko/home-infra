# Blocky DNS Authority

Blocky is the local authority for `internal.brhd.io` records generated from
Omada LAN DNS. The sync job writes a full `customDNS.zone` with SOA, NS, A, and
CNAME records into `blocky-omada-customdns`; Blocky then answers those names
directly instead of forwarding them to the router.

The authoritative name server records are configured through the
`blocky-omada-sync` ConfigMap:

- `AUTHORITATIVE_ZONE_PRIMARY_NS`
- `AUTHORITATIVE_ZONE_SECONDARY_NS`
- `AUTHORITATIVE_ZONE_ADMIN`

The NS hostnames must resolve inside the generated zone. In practice, keep
matching Omada LAN DNS A records for `ns-01.internal.brhd.io` and
`ns-02.internal.brhd.io`.

## Implications

- Clients that use Blocky get answers for `internal.brhd.io` from Blocky's local
  zone.
- Queries for generated records no longer depend on Omada/router DNS at query
  time; Omada is only used by the sync jobs.
- Blocky still acts as a recursive/filtering resolver for everything outside the
  local zone.
- Blocky is not delegated as a public Internet authority for `brhd.io`.

## CoreDNS

CoreDNS is intentionally unchanged. Cluster DNS still forwards non-Kubernetes
queries to the router, so Kubernetes workloads keep the existing DNS path unless
CoreDNS is explicitly changed later to forward `internal.brhd.io` to Blocky.

## Cloudflare

Cloudflare remains authoritative for public `brhd.io`, managed by external-dns
and the existing DDNS jobs. No Cloudflare DNS changes are needed for this local
authority model.

Only change Cloudflare if `internal.brhd.io` should become publicly delegated.
That would require public NS records under `brhd.io` pointing at reachable name
servers, and is not recommended for this private LAN zone.
