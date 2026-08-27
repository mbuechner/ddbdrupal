# ddbdrupal

Helm-Chart für Drupal mit MariaDB und Redis auf OpenShift oder Kubernetes.

## Installation

```sh
helm upgrade --install RELEASE ./charts/drupal \
  --namespace RELEASE \
  --create-namespace \
  --values ./charts/drupal/UMGEBUNGSDATEI \
  --atomic \
  --timeout 15m
```

Auf Kubernetes zusätzlich `values-kubernetes.yaml` zuletzt laden.

## Dokumentation

- [Chart-Konfiguration](charts/drupal/values.yaml)
- [Passwörter verwalten](charts/drupal/PASSWORDS.md)
- [Releases erstellen](docs/releasing.md)
