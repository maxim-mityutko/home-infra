# Setup addons
microk8s enable dashboard
microk8s enable dns
microk8s enable ingress:default-ssl-certificate=default/brhd-io-tls
# Full restart
microk8s stop
microk8s start
microk8s status --wait-ready