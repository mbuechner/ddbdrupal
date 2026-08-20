# ddbdrupal Helm-Chart

Das Chart installiert eine Drupal-Anwendung mit MariaDB und optionalem Redis
auf OpenShift oder Kubernetes. In der OpenShift Form View steht
`deploymentProfile` ganz oben. Das Profil setzt Domain und Drupal-Image
gemeinsam und prüft den passenden Release-Namen. `custom` verwendet stattdessen
die frei konfigurierbare Domain sowie `drupal.image.repository` und
`drupal.image.tag`.

## Profile und wichtige Unterschiede

| Profil | Release | Host | Drupal-Image |
| --- | --- | --- | --- |
| `values-ddbgo.yaml` | `ddbgo` | `go.deutsche-digitale-bibliothek.de` | `ghcr.io/mbuechner/ddbgo:tagged` |
| `values-ddbgo-test.yaml` | `ddbgo-t` | `go-t.deutsche-digitale-bibliothek.de` | `ghcr.io/mbuechner/ddbgo:test` |
| `values-ddbpro.yaml` | `ddbpro` | `pro.deutsche-digitale-bibliothek.de` | `ghcr.io/deutsche-digitale-bibliothek/ddbpro:tagged` |
| `values-ddbpro-test.yaml` | `ddbpro-t` | `pro-t.deutsche-digitale-bibliothek.de` | `ghcr.io/deutsche-digitale-bibliothek/ddbpro:test` |

Die OpenShift Form View bietet dieselben vier vollständigen Deployment-Profile
als `ddbgo-production`, `ddbgo-test`, `ddbpro-production` und `ddbpro-test` an.
Weitere Domains und Images bleiben mit `custom` frei konfigurierbar.

Datenbank und Benutzer werden automatisch aus Release und Deployment-Profil abgeleitet:
`ddbgo[-t]` verwendet `ddbgodb`/`ddbgo`, `ddbpro[-t]` verwendet
`ddbprodb`/`ddbpro`.

## OpenShift Form View

Das mitgelieferte `values.schema.json` stellt die Chart-Konfiguration im
OpenShift Developer Catalog als beschriftete Form View mit Hilfetexten,
Auswahllisten und Eingabeprüfung dar. Die YAML View bleibt für selten benötigte
oder frei strukturierte Einstellungen verfügbar.

Die Profilauswahl steht ganz oben. Danach folgen die wenigen wichtigen
Website-Einstellungen; optionale und erweiterte Anpassungen stehen weiter
unten. Die sichtbaren Texte verwenden wegen älterer OpenShift-
Zeichensatzprobleme `ae`, `oe`, `ue` und `ss`.

## Installation

```sh
helm upgrade --install RELEASE . -n RELEASE -f PROFILDATEI
```

Für Kubernetes `values-kubernetes.yaml` als letzte Values-Datei ergänzen.

## Wichtige Hinweise

- Ressourcen und Container werden aus dem Release-Namen abgeleitet. Die
  Hauptcontainer heißen `<release>-drupal`, `<release>-redis` und
  `<release>-db`; Init-Container beginnen ebenfalls mit `<release>-`.
- MariaDB, der Schutz vor fremden Ressourcen sowie die VPA-Ressourcen `cpu`
  und `memory` sind feste Chart-Invarianten und deshalb keine Values-Optionen.
- OpenShift-Defaults: `ReadWriteMany`, VPA an; RWX-Storage und VPA-CRD
  erforderlich.
- `values-kubernetes.yaml`: `ReadWriteOnce`, VPA aus.
- Mehrere Drupal-Replikate benötigen `ReadWriteMany`.
- Erzeugte PVCs und Secrets bleiben bei `helm uninstall` erhalten.
- Einen bereits anderweitig angelegten PVC bindet das Chart nicht automatisch
  ein. Dafür `COMPONENT.persistence.create=false` und
  `COMPONENT.persistence.existingClaim=PVC-NAME` setzen (`COMPONENT` ist
  `drupal`, `redis` oder `database`). Ein vom Chart behaltener PVC wird bei
  einer Neuinstallation mit demselben Release und Namespace automatisch
  wiederverwendet, sofern seine Helm-Ownership-Metadaten noch vorhanden sind.
- Ein alternatives Drupal-Image muss den dokumentierten DDBgo-/DDBpro-
  Containervertrag erfüllen.
