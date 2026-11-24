#!/bin/sh
#
# Sync enabled Omada LAN DNS A/CNAME records into Blocky's generated customDNS
# ConfigMap, then patch the Blocky StatefulSet annotation so pods roll when the
# generated config changes.
#
# Prerequisites:
# - Omada OpenAPI access must be enabled and the client credentials must have
#   permission to read LAN network details and LAN DNS settings
# - config env: OMADA_BASE_URL, BLOCKY_STATEFULSET, CUSTOM_DNS_CONFIGMAP,
#   AUTHORITATIVE_ZONE_PRIMARY_NS, AUTHORITATIVE_ZONE_SECONDARY_NS,
#   AUTHORITATIVE_ZONE_ADMIN
# - secret env: OMADA_CONTROLLER_ID, OMADA_SITE_ID, OMADA_LAN_NETWORK_ID,
#   OMADA_CLIENT_ID, OMADA_CLIENT_SECRET

echo "Starting Omada DNS sync"
dns_ttl="3600"

workdir="$(mktemp -d)"
trap 'status=$?; rm -rf "$workdir"; if [ "$status" -ne 0 ]; then echo "Omada DNS sync failed with exit code $status" >&2; fi' EXIT

fqdn() {
  case "$1" in
    *.) printf '%s' "$1" ;;
    *) printf '%s.' "$1" ;;
  esac
}

echo "Requesting Omada access token"
request_body="$(
  jq -nc \
    --arg omadacId "$OMADA_CONTROLLER_ID" \
    --arg clientId "$OMADA_CLIENT_ID" \
    --arg clientSecret "$OMADA_CLIENT_SECRET" \
    '{omadacId: $omadacId, client_id: $clientId, client_secret: $clientSecret}'
)"
token_json="$(
  printf '%s' "$request_body" |
  curl -fsS -X POST "$OMADA_BASE_URL/openapi/authorize/token?grant_type=client_credentials" \
    -H "Content-Type: application/json" \
    -d @-
)"
access_token="$(printf '%s' "$token_json" | jq -er '.result.accessToken')"

echo "Fetching Omada LAN network"
lan_network_json="$(
  curl -fsS \
    "$OMADA_BASE_URL/openapi/v1/$OMADA_CONTROLLER_ID/sites/$OMADA_SITE_ID/lan-networks/$OMADA_LAN_NETWORK_ID" \
    -H "Authorization: AccessToken=$access_token"
)"
dns_origin="$(
  printf '%s' "$lan_network_json" |
  jq -er '
    .result.domain
    | select(type == "string" and length > 0)
    | if endswith(".") then . else . + "." end
  '
)"
echo "Using DNS origin $dns_origin"
primary_ns="$(fqdn "$AUTHORITATIVE_ZONE_PRIMARY_NS")"
secondary_ns="$(fqdn "$AUTHORITATIVE_ZONE_SECONDARY_NS")"
zone_admin="$(fqdn "$AUTHORITATIVE_ZONE_ADMIN")"
echo "Using authoritative zone primary NS $primary_ns"

echo "Fetching Omada LAN DNS records"
dns_json="$(
  curl -fsS \
    "$OMADA_BASE_URL/openapi/v1/$OMADA_CONTROLLER_ID/sites/$OMADA_SITE_ID/setting/lan/dns?page=1&pageSize=1000" \
    -H "Authorization: AccessToken=$access_token"
)"

records="$(
  printf '%s' "$dns_json" |
  jq -r --arg lan "$OMADA_LAN_NETWORK_ID" '
    def fqdn: if endswith(".") then . else . + "." end;
    def record_ttl: if .customTtl == true and ((.ttl? // 0) >= 1) then .ttl else 3600 end;

    .result.data
    | map(select(
        .enable == true
        and .type == 0
        and ((.lanNetworkIds // []) | index($lan))
        and (((.ipAddresses // []) | length) > 0)
      ))
    | sort_by(.domain)
    | .[]
    | (.domain | fqdn) as $domain
    | (record_ttl | tostring) as $ttl
    | (
        (.ipAddresses // [] | sort[] | "\($domain) \($ttl) IN A \(.)"),
        (.aliases // [] | sort[] | (. | fqdn) as $alias | "\($alias) \($ttl) IN CNAME \($domain)")
      )
  '
)"
if [ -n "$records" ]; then
  record_count="$(printf '%s\n' "$records" | wc -l | tr -d ' ')"
else
  record_count="0"
fi
echo "Generated $record_count DNS zone records"
zone_serial="$(printf '%s\n%s\n' "$dns_origin" "$records" | cksum | awk '{print $1}')"

{
  printf 'customDNS:\n'
  printf '  filterUnmappedTypes: true\n'
  printf '  zone: |\n'
  printf '    $ORIGIN %s\n' "$dns_origin"
  printf '    $TTL %s\n' "$dns_ttl"
  printf '    @ %s IN SOA %s %s %s 3600 600 604800 300\n' \
    "$dns_ttl" "$primary_ns" "$zone_admin" "$zone_serial"
  printf '    @ %s IN NS %s\n' "$dns_ttl" "$primary_ns"
  if [ -n "$secondary_ns" ]; then
    printf '    @ %s IN NS %s\n' "$dns_ttl" "$secondary_ns"
  fi
  printf '\n'
  if [ -n "$records" ]; then
    printf '%s\n' "$records" | sed 's/^/    /'
  fi
} > "$workdir/omada-custom-dns.yml"

new_hash="$(sha256sum "$workdir/omada-custom-dns.yml" | awk '{print $1}')"
old_hash="$(
  kubectl get configmap "$CUSTOM_DNS_CONFIGMAP" \
    -o json 2>/dev/null |
    jq -r '.metadata.annotations["omada.brhd.io/hash"] // ""' || true
)"

if [ "$new_hash" = "$old_hash" ]; then
  echo "Omada custom DNS config is unchanged ($new_hash)"
  exit 0
fi

echo "Updating $CUSTOM_DNS_CONFIGMAP ($new_hash)"
if kubectl get configmap "$CUSTOM_DNS_CONFIGMAP" >/dev/null 2>&1; then
  kubectl patch configmap "$CUSTOM_DNS_CONFIGMAP" --type merge -p "$(
    jq -n \
      --arg hash "$new_hash" \
      --rawfile config "$workdir/omada-custom-dns.yml" \
      '{
        metadata: {
          labels: {
            "app.kubernetes.io/name": "blocky",
            "app.kubernetes.io/component": "omada-sync"
          },
          annotations: {"omada.brhd.io/hash": $hash}
        },
        data: {"omada-custom-dns.yml": $config}
      }'
  )"
else
  kubectl create configmap "$CUSTOM_DNS_CONFIGMAP" \
    --from-file=omada-custom-dns.yml="$workdir/omada-custom-dns.yml" \
    --dry-run=client -o yaml |
    kubectl label --local -f - \
      app.kubernetes.io/name=blocky \
      app.kubernetes.io/component=omada-sync \
      -o yaml |
    kubectl annotate --local -f - \
      omada.brhd.io/hash="$new_hash" \
      -o yaml |
    kubectl create -f -
fi

echo "Patching $BLOCKY_STATEFULSET with DNS config hash"
kubectl patch statefulset "$BLOCKY_STATEFULSET" \
  --type merge \
  -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"omada.brhd.io/dns-hash\":\"$new_hash\"}}}}}"
echo "Omada DNS sync completed"
