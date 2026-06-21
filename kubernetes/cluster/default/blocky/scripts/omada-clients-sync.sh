#!/bin/sh
#
# Sync active Omada clients from the configured LAN subnet into Blocky's generated
# clientLookup ConfigMap, then patch the Blocky StatefulSet annotation so pods
# roll when the generated config changes.
#
# Prerequisites:
# - Omada OpenAPI access must be enabled and the client credentials must have
#   permission to read LAN network details and clients
# - config env: OMADA_BASE_URL, BLOCKY_STATEFULSET, CLIENT_LOOKUP_CONFIGMAP
# - secret env: OMADA_CONTROLLER_ID, OMADA_SITE_ID, OMADA_LAN_NETWORK_ID,
#   OMADA_CLIENT_ID, OMADA_CLIENT_SECRET

echo "Starting Omada clients sync"
workdir="$(mktemp -d)"
trap 'status=$?; rm -rf "$workdir"; if [ "$status" -ne 0 ]; then echo "Omada clients sync failed with exit code $status" >&2; fi' EXIT

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

page_size=1000
: > "$workdir/clients.jsonl"

echo "Fetching Omada LAN network"
lan_network_json="$(
  curl -fsS \
    "$OMADA_BASE_URL/openapi/v1/$OMADA_CONTROLLER_ID/sites/$OMADA_SITE_ID/lan-networks/$OMADA_LAN_NETWORK_ID" \
    -H "Authorization: AccessToken=$access_token"
)"
lan_gateway_subnet="$(
  printf '%s' "$lan_network_json" |
  jq -er '
    .result.gatewaySubnet
    | select(type == "string" and length > 0)
  '
)"
client_search_key="$(
  printf '%s' "$lan_network_json" |
  jq -er '
    .result.gatewaySubnet
    | capture("^(?<ip>[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)/(?<mask>[0-9]+)$") as $cidr
    | ($cidr.ip | split(".")) as $octets
    | ($cidr.mask | tonumber) as $mask
    | if $mask >= 24 then
        ($octets[0:3] | join(".")) + "."
      elif $mask >= 16 then
        ($octets[0:2] | join(".")) + "."
      elif $mask >= 8 then
        $octets[0] + "."
      else
        ""
      end
  '
)"
echo "Filtering Omada clients by LAN subnet $lan_gateway_subnet"
if [ -n "$client_search_key" ]; then
  echo "Using Omada client search key '$client_search_key'"
else
  echo "LAN subnet is too broad for an Omada client search key; scanning online clients"
fi

fetch_clients() {
  page=1

  while :; do
    echo "Fetching Omada clients page $page"
    request_body="$(
      jq -nc \
        --argjson page "$page" \
        --argjson pageSize "$page_size" \
        --arg searchKey "$client_search_key" \
        '{
          page: $page,
          pageSize: $pageSize,
          scope: 1,
          filters: {ipExist: true}
        } + (
          if $searchKey != "" then
            {searchKey: $searchKey}
          else
            {}
          end
        )'
    )"
    client_json="$(
      printf '%s' "$request_body" |
      curl -fsS -X POST \
        "$OMADA_BASE_URL/openapi/v2/$OMADA_CONTROLLER_ID/sites/$OMADA_SITE_ID/clients" \
        -H "Authorization: AccessToken=$access_token" \
        -H "Content-Type: application/json" \
        -d @-
    )"

    printf '%s' "$client_json" |
    jq -c --arg subnet "$lan_gateway_subnet" '
      def ipv4num($ip):
        ($ip | split(".")) as $parts
        | if
            ($parts | length) == 4
            and all($parts[]; test("^[0-9]+$") and ((tonumber) >= 0) and ((tonumber) <= 255))
          then
            (($parts[0] | tonumber) * 16777216)
            + (($parts[1] | tonumber) * 65536)
            + (($parts[2] | tonumber) * 256)
            + ($parts[3] | tonumber)
          else
            null
          end;

      def ipv4_in_cidr($ip; $cidr):
        ($cidr | capture("^(?<base>[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)/(?<mask>[0-9]+)$")) as $parsed
        | ($parsed.mask | tonumber) as $mask
        | if $mask < 0 or $mask > 32 then
            false
          else
            (ipv4num($ip)) as $ipnum
            | (ipv4num($parsed.base)) as $basenum
            | if $ipnum == null or $basenum == null then
                false
              else
                (pow(2; 32 - $mask)) as $size
                | (($basenum / $size | floor) * $size) as $network
                | ($ipnum >= $network and $ipnum < ($network + $size))
              end
          end;

      .result.data[]?
      | select(.active == true)
      | select(.ip? | type == "string" and length > 0)
      | select(ipv4_in_cidr(.ip; $subnet))
    ' >> "$workdir/clients.jsonl"

    current_size="$(printf '%s' "$client_json" | jq -r '.result.currentSize // (.result.data // [] | length)')"
    total_rows="$(printf '%s' "$client_json" | jq -r '.result.totalRows // 0')"
    echo "Fetched $current_size clients on page $page ($total_rows total rows reported)"

    if [ "$current_size" -eq 0 ] || [ "$((page * page_size))" -ge "$total_rows" ]; then
      break
    fi

    page="$((page + 1))"
  done
}

fetch_clients
raw_client_count="$(wc -l < "$workdir/clients.jsonl" | tr -d ' ')"
echo "Retained $raw_client_count active client records inside $lan_gateway_subnet"

clients="$(
  jq -s -r '
    def trim: gsub("^\\s+|\\s+$"; "");

    map({
      name: ((.name // .hostName // .mac // "") | tostring | trim),
      ips: ([.ip?] | map(select(type == "string" and length > 0)) | unique)
    })
    | map(select(.name != "" and (.ips | length > 0)))
    | sort_by(.name | ascii_downcase)
    | group_by(.name)
    | sort_by(.[0].name | ascii_downcase)
    | map({
      name: .[0].name,
      ips: (map(.ips[]) | unique | sort)
    })
    | map(
      "    " + (.name | @json) + ":\n" +
      (.ips | map("      - " + .) | join("\n"))
    )
    | join("\n")
  ' "$workdir/clients.jsonl"
)"

{
  printf 'clientLookup:\n'
  if [ -n "$clients" ]; then
    printf '  clients:\n'
    printf '%s\n' "$clients"
  else
    printf '  clients: {}\n'
  fi
} > "$workdir/omada-client-lookup.yml"
echo "Generated Omada client lookup config"

new_hash="$(sha256sum "$workdir/omada-client-lookup.yml" | awk '{print $1}')"
old_hash="$(
  kubectl get configmap "$CLIENT_LOOKUP_CONFIGMAP" \
    -o json 2>/dev/null |
    jq -r '.metadata.annotations["omada.brhd.io/hash"] // ""' || true
)"

if [ "$new_hash" = "$old_hash" ]; then
  echo "Omada client lookup config is unchanged ($new_hash)"
  exit 0
fi

echo "Updating $CLIENT_LOOKUP_CONFIGMAP ($new_hash)"
if kubectl get configmap "$CLIENT_LOOKUP_CONFIGMAP" >/dev/null 2>&1; then
  kubectl patch configmap "$CLIENT_LOOKUP_CONFIGMAP" --type merge -p "$(
    jq -n \
      --arg hash "$new_hash" \
      --rawfile config "$workdir/omada-client-lookup.yml" \
      '{
        metadata: {
          labels: {
            "app.kubernetes.io/name": "blocky",
            "app.kubernetes.io/component": "omada-clients-sync"
          },
          annotations: {"omada.brhd.io/hash": $hash}
        },
        data: {"omada-client-lookup.yml": $config}
      }'
  )"
else
  kubectl create configmap "$CLIENT_LOOKUP_CONFIGMAP" \
    --from-file=omada-client-lookup.yml="$workdir/omada-client-lookup.yml" \
    --dry-run=client -o yaml |
    kubectl label --local -f - \
      app.kubernetes.io/name=blocky \
      app.kubernetes.io/component=omada-clients-sync \
      -o yaml |
    kubectl annotate --local -f - \
      omada.brhd.io/hash="$new_hash" \
      -o yaml |
    kubectl create -f -
fi

echo "Patching $BLOCKY_STATEFULSET with client lookup config hash"
kubectl patch statefulset "$BLOCKY_STATEFULSET" \
  --type merge \
  -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"omada.brhd.io/clients-hash\":\"$new_hash\"}}}}}"
echo "Omada clients sync completed"
