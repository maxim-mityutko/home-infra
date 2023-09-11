Ingress is configured out of the box with the following command: 
`microk8s enable ingress:default-ssl-certificate=default/brhd-io-tls`

However, a few custom configs have to be applied using `Server-Side Apply` feature:
* enabling ingress for DNS ports for the `pihole`
    ```shell
    # This script is replaced with Server-Side Apply approach
    echo "Adding DNS TCP port to \"nginx-ingress\" for PiHole..."
    microk8s kubectl patch ds -n ingress nginx-ingress-microk8s-controller \
    --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value":{"containerPort":53,"name":"dns-tcp","hostPort":53,"protocol":"TCP"}}]'
    
    echo "Adding DNS UDP port to \"nginx-ingress\" for PiHole..."
    microk8s kubectl patch ds -n ingress nginx-ingress-microk8s-controller \
    --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value":{"containerPort":53,"name":"dns-udp","hostPort":53,"protocol":"UDP"}}]'
    
    echo "Adding DNS ports to the \"nginx-ingress\" config maps..."
    microk8s kubectl patch configmap -n ingress nginx-ingress-tcp-microk8s-conf --patch '{"data":{"53": "default/pihole-dns:53"}}'
    microk8s kubectl patch configmap -n ingress nginx-ingress-udp-microk8s-conf --patch '{"data":{"53": "default/pihole-dns:53"}}'
    ```

To enable this feature in ArgoCD application configuration, follow the instuctions here: https://github.com/argoproj/argo-cd/issues/2437#issuecomment-1264964312

**TLDR**: 
* Validate=false
* ServerSideApply=true