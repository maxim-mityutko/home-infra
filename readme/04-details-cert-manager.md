## Installation
* Default install: https://cert-manager.io/docs/installation/
* *(done)* Helm install: https://cert-manager.io/docs/installation/helm/
* Microk8s installation (can be ignored): https://microk8s.io/docs/addon-cert-manager

## Cloudflare
Create API token as explained: [here](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/)

* Permissions:
   * `Zone - DNS - Edit`
   * `Zone - Zone - Read`
* Zone Resources:
   * `Include - All Zones`

## Ingress
Enable ingress:
`microk8s enable ingress:default-ssl-certificate=default/brhd-io-tls`

## Troubleshooting
* General Troubleshooting: https://cert-manager.io/docs/troubleshooting/
* Troubleshooting Issuing ACME Certificates: https://cert-manager.io/docs/troubleshooting/acme/
* Troubleshooting Issuing ACME Certificates: https://cert-manager.io/v0.15-docs/faq/acme/
* Verify Installation: https://cert-manager.io/docs/installation/verify/
* Leader Election Issue on HA: https://github.com/cert-manager/cert-manager/issues/4102