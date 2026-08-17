# Wiederverwendbare Drupal-Umgebung

Dieses Repository enthält ein eigenständig versionierbares Helm-Chart für eine
Drupal-Anwendung mit MariaDB und optionalem Redis. Es unterstützt Kubernetes
und OpenShift. Das Anwendungsimage ist nicht an den Release-Zyklus des Charts
gekoppelt und wird vollständig über Values gewählt.

## Enthaltene Profile

| Profil | Drupal-Image | Release-Tag |
| --- | --- | --- |
| `values-ddbgo.yaml` | `ghcr.io/mbuechner/ddbgo` | `tagged` |
| `values-ddbgo-test.yaml` | `ghcr.io/mbuechner/ddbgo` | `test` |
| `values-ddbpro.yaml` | `ghcr.io/deutsche-digitale-bibliothek/ddbpro` | `tagged` |
| `values-ddbpro-test.yaml` | `ghcr.io/deutsche-digitale-bibliothek/ddbpro` | `test` |

DDBgo und DDBpro erfüllen denselben unten beschriebenen Containervertrag. Die
DDBgo-Profile enthalten die bekannten Hosts. Für DDBpro sind absichtlich
`.invalid`-Hosts eingetragen, weil die produktiven Domains nicht Teil dieses
Repositories sind. Sie müssen bei der Installation überschrieben werden.

Das Chart enthält außerdem ein `values.schema.json`. OpenShift kann damit im
Developer Catalog eine Form View mit verständlichen Feldnamen, Hilfetexten,
Auswahllisten und Validierung anzeigen. Das zentrale Feld
`drupal.externalHost` bezeichnet den öffentlichen DNS-Namen für Route/Ingress
und Drupals Trusted-Host-Regel. Der Standard `change-me.example.invalid` ist
bewusst nicht auflösbar und muss vor einem realen Einsatz ersetzt werden.

## Schnellstart

DDBgo-Produktion auf OpenShift:

```sh
helm upgrade --install ddbgo ./charts/drupal \
  --namespace ddbgo \
  --create-namespace \
  --values ./charts/drupal/values-ddbgo.yaml \
  --atomic \
  --timeout 15m
```

DDBgo-Testsystem:

```sh
helm upgrade --install ddbgo-t ./charts/drupal \
  --namespace ddbgo-t \
  --create-namespace \
  --values ./charts/drupal/values-ddbgo-test.yaml \
  --atomic \
  --timeout 15m
```

DDBpro mit explizitem Host:

```sh
helm upgrade --install ddbpro ./charts/drupal \
  --namespace ddbpro \
  --create-namespace \
  --values ./charts/drupal/values-ddbpro.yaml \
  --set-string drupal.externalHost=PRODUKTIVER_DDBPRO_HOST \
  --atomic \
  --timeout 15m
```

Für Kubernetes wird das Plattformprofil zuletzt ergänzt:

```sh
helm upgrade --install ddbgo ./charts/drupal \
  --namespace ddbgo \
  --create-namespace \
  --values ./charts/drupal/values-ddbgo.yaml \
  --values ./charts/drupal/values-kubernetes.yaml
```

Das Plattformprofil setzt für Redis und MariaDB Kubernetes-kompatible
Non-Root-IDs und deaktiviert die OpenShift Image-Automatisierung. Die allgemeinen
Defaults verwenden bereits `ReadWriteOnce` und lassen VPA aus. Wenn der
VPA-Operator installiert ist, kann VPA mit
`--set verticalPodAutoscaler.enabled=true` aktiviert werden. Mehrere
Drupal-Replikate benötigen weiterhin eine RWX-fähige StorageClass. Die DDB-
Profile bewahren aus Upgrade-Kompatibilität die bisherigen Chart-Defaults RWX
und VPA; für ein Cluster ohne diese Voraussetzungen können beide Werte
überschrieben werden.

## Weitere Webseiten und Images

Ohne Website-Profil erlaubt das Chart beliebige Release-Namen. Mindestens Host,
Image-Repository und Tag sollten explizit gesetzt werden:

```sh
helm upgrade --install meine-seite ./charts/drupal \
  --namespace meine-seite \
  --create-namespace \
  --set-string drupal.externalHost=www.example.org \
  --set-string drupal.image.repository=ghcr.io/example/mein-drupal \
  --set-string drupal.image.tag=2026.08.0
```

Ein weiteres dauerhaft gepflegtes Profil wird als
`charts/drupal/values-<website>.yaml` abgelegt. Image und Anwendungsversion
werden dadurch unabhängig von `Chart.yaml` geändert.

## Containervertrag

Ein austauschbares Drupal-Image muss:

- unprivilegiert laufen und HTTP auf Port `8080` bereitstellen;
- den Webroot unter `drupal.config.webRoot` verwenden, standardmäßig
  `/var/www/html/web`;
- `/bin/sh`, `mkdir` und bei aktivierter Basic Auth `curl` enthalten;
- den Health-Endpunkt aus `drupal.probes.path` anbieten;
- die vom Chart gesetzten Variablen unterstützen.

Der gemeinsame DDBgo-/DDBpro-Vertrag umfasst:

`MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_HOSTNAME`,
`MYSQL_PORT`, `HASH_SALT`, `UPDATE_FREE_ACCESS`, `FILE_PUBLIC_PATH`,
`FILE_PRIVATE_PATH`, `TMP`, `TRUSTED_HOST_PATTERNS`, `USE_REDIS`, `REDIS_HOST`,
`REDIS_PORT`, `REDIS_PASSWORD`, `DRUSH_OPTIONS_URI`, `UPDATEDB_ON_STARTUP`,
`CONFIG_IMPORT_ON_STARTUP`, `CACHEREBUILD_ON_STARTUP`, `HTPASSWD_GREETING`,
`HTPASSWD_USER` und `HTPASSWD_PWD`.

Ein beliebiges Upstream-Drupal-Image ohne diesen Vertrag ist nicht automatisch
kompatibel. Dessen Entrypoint, Ports, Pfade und Variablen müssten zuerst an das
Chart angepasst werden.

## Repository-Struktur

```text
.
├── .github/workflows/       # CI und Veröffentlichung
├── charts/drupal/           # Chart, Form-View-Schema und Website-Profile
├── docs/releasing.md        # Release- und GitHub-Pages-Runbook
├── LICENSE
└── README.md
```

Das Repository heißt `ddbdrupal`. Das veröffentlichte OCI-Chart liegt daher
direkt unter `oci://ghcr.io/<owner>/ddbdrupal`; `helm/drupal` ist kein
Repository- oder OCI-Pfad. `charts/drupal/` ist lediglich das interne
Quellverzeichnis des Charts.

## Entwicklung und Veröffentlichung

Pull Requests und Branch-Pushes werden durch `lint.yml` für alle vier Profile
sowie für Kubernetes und OpenShift geprüft. Beide Workflows verwenden `main`
als einzigen Quell- und Release-Branch. `publish.yml` veröffentlicht dort:

- die stabile Version aus `Chart.yaml` als OCI-Artefakt in GHCR;
- dieselbe Version im klassischen Helm-Repository unter GitHub Pages.

Die `*-test.yaml`-Dateien sind Installationsprofile und kein eigener
Release-Kanal oder Quell-Branch. Der technische Branch `gh-pages` enthält
ausschließlich das generierte klassische Helm-Repository.

Details und die einmalige GitHub-Konfiguration stehen in
[docs/releasing.md](docs/releasing.md).
