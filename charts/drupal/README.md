# ddbdrupal Helm-Chart

Installiert Drupal mit MariaDB und Redis auf OpenShift oder Kubernetes.

```sh
helm upgrade --install RELEASE . \
  --namespace RELEASE \
  --values UMGEBUNGSDATEI
```

Auf Kubernetes zusätzlich `values-kubernetes.yaml` zuletzt laden.

Beispiel für DDBgo Test auf OpenShift:

```sh
helm upgrade --install ddbgo-t . \
  --namespace ddbgo-t \
  --create-namespace \
  --values values-ddbgo-test.yaml \
  --atomic \
  --timeout 15m
```

Weitere Informationen:

- [Konfigurationswerte](values.yaml)
- [Passwörter verwalten](PASSWORDS.md)
