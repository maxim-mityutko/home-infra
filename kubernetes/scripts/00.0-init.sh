# Setup addons
# microk8s enable dashboard
microk8s enable dns
# microk8s enable ingress:default-ssl-certificate=default/brhd-io-tls
# When NVIDIA drivers can be preinstalled on the node `--gpu-operator-driver host`, more info https://microk8s.io/docs/addon-gpu
# microk8s enable nvidia --gpu-operator-driver host
# Full restart
microk8s stop
microk8s start
microk8s status --wait-ready