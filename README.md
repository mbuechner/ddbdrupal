# ddbdrupal

Helm-Chart für Drupal mit MariaDB und optionalem Redis auf OpenShift oder
Kubernetes. `values.schema.json` stellt im OpenShift Developer Catalog eine
validierte Form View bereit.

## Profile und wichtige Unterschiede

| Profil | Release | Host | Drupal-Image |
| --- | --- | --- | --- |
| `values-ddbgo.yaml` | `ddbgo` | `go.deutsche-digitale-bibliothek.de` | `ghcr.io/mbuechner/ddbgo:tagged` |
| `values-ddbgo-test.yaml` | `ddbgo-t` | `go-t.deutsche-digitale-bibliothek.de` | `ghcr.io/mbuechner/ddbgo:test` |
| `values-ddbpro.yaml` | `ddbpro` | `pro.deutsche-digitale-bibliothek.de` | `ghcr.io/deutsche-digitale-bibliothek/ddbpro:tagged` |
| `values-ddbpro-test.yaml` | `ddbpro-t` | `pro-t.deutsche-digitale-bibliothek.de` | `ghcr.io/deutsche-digitale-bibliothek/ddbpro:test` |

In der OpenShift Form View steht `deploymentProfile` als erste und wichtigste
Auswahl. Das Profil setzt Domain und Drupal-Image gemeinsam und prüft den
passenden Release-Namen. `custom` erlaubt weiterhin eine freie Domain und ein
beliebiges kompatibles Drupal-Image.

`drupal.externalHost` ist der öffentliche DNS-Name für Route/Ingress und
Drupals Trusted-Host-Regel.

Datenbank und Benutzer werden aus Release und Deployment-Profil abgeleitet. Dabei ergeben
`ddbgo` und `ddbgo-t` den Zugang `ddbgodb`/`ddbgo`; `ddbpro` und `ddbpro-t`
ergeben `ddbprodb`/`ddbpro`.

## Installation

```sh
helm upgrade --install RELEASE ./charts/drupal \
  --namespace RELEASE \
  --create-namespace \
  --values ./charts/drupal/PROFILDATEI \
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

- Ressourcen und Container werden aus dem Release-Namen abgeleitet. Die
  Hauptcontainer heißen `<release>-drupal`, `<release>-redis` und
  `<release>-db`; Init-Container beginnen ebenfalls mit `<release>-`.
- MariaDB, der Schutz vor fremden Ressourcen sowie die VPA-Ressourcen `cpu`
  und `memory` sind feste Chart-Invarianten und deshalb keine Values-Optionen.
- OpenShift verwendet standardmäßig `ReadWriteMany` und aktiviert VPA; dafür
  müssen RWX-Storage und die VPA-CRD im Cluster vorhanden sein.
- `values-kubernetes.yaml` stellt VPA aus und verwendet `ReadWriteOnce`.
- Mehrere Drupal-Replikate benötigen `ReadWriteMany`.
- Erzeugte PVCs und Secrets bleiben bei `helm uninstall` erhalten.
- Einen bereits anderweitig angelegten PVC bindet das Chart nicht automatisch
  ein. Dafür `COMPONENT.persistence.create=false` und
  `COMPONENT.persistence.existingClaim=PVC-NAME` setzen (`COMPONENT` ist
  `drupal`, `redis` oder `database`). Ein vom Chart behaltener PVC wird bei
  einer Neuinstallation mit demselben Release und Namespace automatisch
  wiederverwendet, sofern seine Helm-Ownership-Metadaten noch vorhanden sind.

Ein alternatives Drupal-Image muss unprivilegiert auf Port `8080` laufen, den
konfigurierten Webroot und Health-Endpunkt bereitstellen und den in
`values.yaml` verwendeten DDBgo-/DDBpro-Umgebungsvariablenvertrag unterstützen.

## Veröffentlichung

`main` ist der einzige Quell- und Release-Branch; `gh-pages` enthält nur das
klassische Helm-Repository. Das OCI-Chart wird als
`oci://ghcr.io/<owner>/ddbdrupal` veröffentlicht.

Details und die einmalige GitHub-Konfiguration stehen in
[docs/releasing.md](docs/releasing.md).
