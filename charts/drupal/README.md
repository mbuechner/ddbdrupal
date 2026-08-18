# ddbdrupal Helm-Chart

Das Chart installiert eine Drupal-Anwendung mit MariaDB und optionalem Redis
auf OpenShift oder Kubernetes. In der OpenShift Form View kann das Drupal-Image
über `drupal.image.preset` gewählt werden. `custom` verwendet stattdessen
`drupal.image.repository` und `drupal.image.tag`. Mitgelieferte Profile decken
DDBgo und DDBpro jeweils für Produktion und Test ab.

## Profile und wichtige Unterschiede

| Profil | Release | Host | Drupal-Image |
| --- | --- | --- | --- |
| `values-ddbgo.yaml` | `ddbgo` | `go.deutsche-digitale-bibliothek.de` | `ghcr.io/mbuechner/ddbgo:tagged` |
| `values-ddbgo-test.yaml` | `ddbgo-t` | `go-t.deutsche-digitale-bibliothek.de` | `ghcr.io/mbuechner/ddbgo:test` |
| `values-ddbpro.yaml` | `ddbpro` | `pro.deutsche-digitale-bibliothek.de` | `ghcr.io/deutsche-digitale-bibliothek/ddbpro:tagged` |
| `values-ddbpro-test.yaml` | `ddbpro-t` | `pro-t.deutsche-digitale-bibliothek.de` | `ghcr.io/deutsche-digitale-bibliothek/ddbpro:test` |

Die OpenShift Form View bietet dieselben vier Image-Varianten als
`ddbgo-production`, `ddbgo-test`, `ddbpro-production` und `ddbpro-test` an.
Weitere Images bleiben mit `custom` frei konfigurierbar.

Datenbank und Benutzer werden automatisch aus Release und Preset abgeleitet:
`ddbgo[-t]` verwendet `ddbgodb`/`ddbgo`, `ddbpro[-t]` verwendet
`ddbprodb`/`ddbpro`.

## OpenShift Form View

Das mitgelieferte `values.schema.json` stellt die Chart-Konfiguration im
OpenShift Developer Catalog als beschriftete Form View mit Hilfetexten,
Auswahllisten und Eingabeprüfung dar. Die YAML View bleibt für selten benötigte
oder frei strukturierte Einstellungen verfügbar.

Wichtige profilabhängige Werte stehen oben; optionale und erweiterte Anpassungen
folgen darunter. Die sichtbaren Texte verwenden wegen älterer OpenShift-
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
- Allgemeine Defaults: `ReadWriteOnce`, VPA aus.
- DDB-Profile: `ReadWriteMany`, VPA an; RWX-Storage und VPA-CRD erforderlich.
- Mehrere Drupal-Replikate benötigen `ReadWriteMany`.
- Erzeugte PVCs und Secrets bleiben bei `helm uninstall` erhalten.
- Ein alternatives Drupal-Image muss den dokumentierten DDBgo-/DDBpro-
  Containervertrag erfüllen.
