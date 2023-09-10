# Copy certificates to `omada-cert` NFS location
microk8s kubectl get secret brhd-io-tls -n cert-manager --template='{{ index .data "tls.crt" }}' | base64 -d > tls.crt && scp tls.crt nas.brhd.io:/mnt/master/k8s/pods/omada-cert && rm tls.crt
microk8s kubectl get secret brhd-io-tls -n cert-manager --template='{{ index .data "tls.key" }}' | base64 -d > tls.key && scp tls.key nas.brhd.io:/mnt/master/k8s/pods/omada-cert && rm tls.key
# Restart Omada to apply changes
microk8s kubectl rollout restart deployment omada -n default
