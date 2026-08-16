#!/bin/sh
#
# Maintain Cloudflare-backed DNSEndpoint resources for healthy MicroK8s control
# plane nodes and the shared casa.brhd.io endpoint. Requires node read access
# and DNSEndpoint create/update/delete permissions.

notready_nodes="$(
  kubectl get nodes \
    -l node.kubernetes.io/microk8s-controlplane \
    -o json |
  jq -r '
    .items[]
    | select(.status.conditions[] | select(.type == "Ready" and .status == "False"))
    | .metadata.name
  '
)"

for node in $notready_nodes; do
  kubectl delete dnsendpoint "node-$node" -n default --ignore-not-found=true
done

ready_nodes="$(
  kubectl get nodes \
    -l node.kubernetes.io/microk8s-controlplane \
    -o json |
  jq -r '
    .items[]
    | select(.status.conditions[] | select(.type == "Ready" and .status == "True"))
    | .metadata.name + " " + (.status.addresses[] | select(.type == "InternalIP") | .address)
  '
)"

echo "$ready_nodes" | while read -r name ip; do
  [ -n "$name" ] || continue
  cat <<EOF | kubectl apply -f -
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: $name.brhd.io
  namespace: default
  annotations:
    argocd.argoproj.io/tracking-id: cloudflare:externaldns.k8s.io/DNSEndpoint:default/$name.brhd.io
    argocd.argoproj.io/sync-options: Prune=false
    argocd.argoproj.io/compare-options: IgnoreExtraneous
spec:
  endpoints:
    - dnsName: $name.brhd.io
      recordTTL: 86400
      recordType: A
      targets:
        - $ip
EOF
done

cat <<EOF | kubectl apply -f -
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: casa.brhd.io
  namespace: default
  annotations:
    argocd.argoproj.io/tracking-id: cloudflare:externaldns.k8s.io/DNSEndpoint:default/casa.brhd.io
    argocd.argoproj.io/sync-options: Prune=false
    argocd.argoproj.io/compare-options: IgnoreExtraneous
spec:
  endpoints:
    - dnsName: casa.brhd.io
      recordTTL: 300
      recordType: A
      targets:
$(echo "$ready_nodes" | awk '{print "        - " $2}')
EOF
