# Apply annotation to Kubernetes Dashboard ingress to
# automatically use generated token for authentication.

microk8s kubectl annotate ingress kubernetes-dashboard \
"nginx.ingress.kubernetes.io/configuration-snippet"=\
"proxy_set_header Authorization \"Bearer $(microk8s kubectl get secret microk8s-dashboard-token -n kube-system -o jsonpath='{.data.token}' | base64 -d)\";" \
-n kube-system --overwrite
