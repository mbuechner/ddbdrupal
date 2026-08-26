# ddbdrupal

Helm-Chart für Drupal mit MariaDB und Redis auf OpenShift oder Kubernetes.

## Profile

| Values-Datei | Release/Namespace | Host |
| --- | --- | --- |
| `values-ddbgo.yaml` | `ddbgo` | `go.deutsche-digitale-bibliothek.de` |
| `values-ddbgo-test.yaml` | `ddbgo-t` | `go-t.deutsche-digitale-bibliothek.de` |
| `values-ddbpro.yaml` | `ddbpro` | `pro.deutsche-digitale-bibliothek.de` |
| `values-ddbpro-test.yaml` | `ddbpro-t` | `pro-t.deutsche-digitale-bibliothek.de` |

Alternativ erlaubt `deploymentProfile: custom` eine freie Domain und ein
eigenes Drupal-Image. Release-Name und Namespace müssen identisch sein.

## Installation

```sh
helm upgrade --install RELEASE ./charts/drupal \
  --namespace RELEASE \
  --create-namespace \
  --values ./charts/drupal/PROFILDATEI \
  --atomic \
  --timeout 15m
```

Auf Kubernetes muss `values-kubernetes.yaml` zuletzt geladen werden:

```sh
helm upgrade --install ddbgo ./charts/drupal \
  --namespace ddbgo \
  --create-namespace \
  --values ./charts/drupal/values-ddbgo.yaml \
  --values ./charts/drupal/values-kubernetes.yaml
```

## Konfiguration

`values.schema.json` stellt im OpenShift Developer Catalog eine validierte Form
View bereit. Regelmäßig anzupassen sind insbesondere:

- `drupal.config.trustedHosts`
- `drupal.startup`
- `drupal.basicAuth`
- `drupal.smtp`

Das Chart erzeugt und verwaltet alle Secrets. Passwörter für Basic Auth und
SMTP werden direkt in den jeweiligen Bereichen eingegeben und sollten nicht in
öffentliche Values-Dateien geschrieben werden.

OpenShift setzt RWX-Storage und die VPA-CRD voraus. Erzeugte PVCs und Secrets
bleiben bei `helm uninstall` standardmäßig erhalten. Vorhandene release-eigene
PVCs werden unverändert wiederverwendet; die konfigurierte Größe gilt nur bei
der ersten Anlage.

Hinweise zur Veröffentlichung stehen in
[docs/releasing.md](docs/releasing.md).
