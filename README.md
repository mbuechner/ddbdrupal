# ddbdrupal

Helm-Chart für Drupal mit MariaDB und optionalem Redis auf OpenShift oder
Kubernetes. `values.schema.json` stellt im OpenShift Developer Catalog eine
validierte Form View bereit.

## Profile und wichtige Unterschiede

| Profil | Release | Host | Drupal-Image | Datenbank / Benutzer |
| --- | --- | --- | --- | --- |
| `values-ddbgo.yaml` | `ddbgo` | `go.deutsche-digitale-bibliothek.de` | `ghcr.io/mbuechner/ddbgo:tagged` | `ddbgodb` / `ddbgo` |
| `values-ddbgo-test.yaml` | `ddbgo-t` | `go-t.deutsche-digitale-bibliothek.de` | `ghcr.io/mbuechner/ddbgo:test` | `ddbgodb` / `ddbgo` |
| `values-ddbpro.yaml` | `ddbpro` | Platzhalter ersetzen | `ghcr.io/deutsche-digitale-bibliothek/ddbpro:tagged` | `ddbprodb` / `ddbpro` |
| `values-ddbpro-test.yaml` | `ddbpro-t` | Platzhalter ersetzen | `ghcr.io/deutsche-digitale-bibliothek/ddbpro:test` | `ddbprodb` / `ddbpro` |

`drupal.externalHost` ist der öffentliche DNS-Name für Route/Ingress und
Drupals Trusted-Host-Regel. Werte unter `.invalid` sind nicht auflösbare
Platzhalter und müssen ersetzt werden.

## Installation

```sh
helm upgrade --install RELEASE ./charts/drupal \
  --namespace RELEASE \
  --create-namespace \
  --values ./charts/drupal/PROFILDATEI \
  --atomic \
  --timeout 15m
```

DDBpro benötigt zusätzlich den echten Host:

```sh
helm upgrade --install ddbpro ./charts/drupal \
  --namespace ddbpro \
  --create-namespace \
  --values ./charts/drupal/values-ddbpro.yaml \
  --set-string drupal.externalHost=PRODUKTIVER_DDBPRO_HOST \
  --atomic \
  --timeout 15m
```

Für Kubernetes `values-kubernetes.yaml` zuletzt laden:

```sh
helm upgrade --install ddbgo ./charts/drupal \
  --namespace ddbgo \
  --create-namespace \
  --values ./charts/drupal/values-ddbgo.yaml \
  --values ./charts/drupal/values-kubernetes.yaml
```

## Wichtige Hinweise

- Die allgemeinen Defaults verwenden `ReadWriteOnce` und deaktivieren VPA.
- Die DDB-Profile bewahren für kompatible Upgrades `ReadWriteMany` und VPA;
  dafür müssen RWX-Storage und VPA-CRD im Cluster vorhanden sein.
- Mehrere Drupal-Replikate benötigen `ReadWriteMany`.
- Erzeugte PVCs und Secrets bleiben bei `helm uninstall` erhalten.

Ein alternatives Drupal-Image muss unprivilegiert auf Port `8080` laufen, den
konfigurierten Webroot und Health-Endpunkt bereitstellen und den in
`values.yaml` verwendeten DDBgo-/DDBpro-Umgebungsvariablenvertrag unterstützen.

## Veröffentlichung

`main` ist der einzige Quell- und Release-Branch; `gh-pages` enthält nur das
klassische Helm-Repository. Das OCI-Chart wird als
`oci://ghcr.io/<owner>/ddbdrupal` veröffentlicht.

Details und die einmalige GitHub-Konfiguration stehen in
[docs/releasing.md](docs/releasing.md).
