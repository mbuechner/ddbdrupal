# ddbdrupal Helm-Chart

Installiert Drupal mit MariaDB und Redis auf OpenShift oder Kubernetes.

## Profile

| Values-Datei | Release/Namespace | Host |
| --- | --- | --- |
| `values-ddbgo.yaml` | `ddbgo` | `go.deutsche-digitale-bibliothek.de` |
| `values-ddbgo-test.yaml` | `ddbgo-t` | `go-t.deutsche-digitale-bibliothek.de` |
| `values-ddbpro.yaml` | `ddbpro` | `pro.deutsche-digitale-bibliothek.de` |
| `values-ddbpro-test.yaml` | `ddbpro-t` | `pro-t.deutsche-digitale-bibliothek.de` |

`deploymentProfile: custom` erlaubt eine freie Domain und ein eigenes
Drupal-Image. Release-Name und Namespace müssen identisch sein.

## Installation

```sh
helm upgrade --install RELEASE . \
  --namespace RELEASE \
  --values PROFILDATEI
```

Für Kubernetes `values-kubernetes.yaml` als letzte Values-Datei ergänzen.

## Konfiguration

Die wichtigsten anwendungsspezifischen Bereiche sind:

- `drupal.config.trustedHosts`
- `drupal.startup`
- `drupal.basicAuth`
- `drupal.smtp`

Basic-Auth-Secrets benötigen `HTPASSWD_USER` und `HTPASSWD_PWD`, SMTP-Secrets
den Schlüssel `SMTP_PASSWORD`. Redis und MariaDB sind feste Chart-Bestandteile.
Erzeugte PVCs und Secrets bleiben bei einer Deinstallation standardmäßig
erhalten.
