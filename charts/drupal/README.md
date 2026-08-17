# ddbdrupal Helm-Chart

Das Chart installiert eine Drupal-Anwendung mit MariaDB und optionalem Redis
auf OpenShift oder Kubernetes. Das Image wird mit
`drupal.image.repository` und `drupal.image.tag` gewählt. Mitgelieferte Profile
decken DDBgo und DDBpro jeweils für Produktion und Test ab.

## Profile und wichtige Unterschiede

| Profil | Release | Host | Drupal-Image | Datenbank / Benutzer |
| --- | --- | --- | --- | --- |
| `values-ddbgo.yaml` | `ddbgo` | `go.deutsche-digitale-bibliothek.de` | `ghcr.io/mbuechner/ddbgo:tagged` | `ddbgodb` / `ddbgo` |
| `values-ddbgo-test.yaml` | `ddbgo-t` | `go-t.deutsche-digitale-bibliothek.de` | `ghcr.io/mbuechner/ddbgo:test` | `ddbgodb` / `ddbgo` |
| `values-ddbpro.yaml` | `ddbpro` | Platzhalter ersetzen | `ghcr.io/deutsche-digitale-bibliothek/ddbpro:tagged` | `ddbprodb` / `ddbpro` |
| `values-ddbpro-test.yaml` | `ddbpro-t` | Platzhalter ersetzen | `ghcr.io/deutsche-digitale-bibliothek/ddbpro:test` | `ddbprodb` / `ddbpro` |

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

Für DDBpro muss `drupal.externalHost` überschrieben werden. Für Kubernetes
`values-kubernetes.yaml` als letzte Values-Datei ergänzen.

## Wichtige Hinweise

- Allgemeine Defaults: `ReadWriteOnce`, VPA aus.
- DDB-Profile: `ReadWriteMany`, VPA an; RWX-Storage und VPA-CRD erforderlich.
- Mehrere Drupal-Replikate benötigen `ReadWriteMany`.
- Erzeugte PVCs und Secrets bleiben bei `helm uninstall` erhalten.
- Ein alternatives Drupal-Image muss den dokumentierten DDBgo-/DDBpro-
  Containervertrag erfüllen.
