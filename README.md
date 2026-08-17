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
├── charts/drupal/           # Chart und Website-Profile
├── docs/releasing.md        # Release- und GitHub-Pages-Runbook
├── LICENSE
└── README.md
```

`helm/` enthält damit alles, was für das neue GitHub-Repository benötigt wird.
Beim Auslagern wird der **Inhalt** dieses Verzeichnisses zur Wurzel des neuen
Repositories. Es wird kein verschachteltes `.git`-Verzeichnis angelegt.

## Entwicklung und Veröffentlichung

Pull Requests und Branch-Pushes werden durch `lint.yml` für alle vier Profile
sowie für Kubernetes und OpenShift geprüft. `publish.yml` behält die vorhandene
Kanalstrategie bei:

- `test` veröffentlicht eine eindeutige Test-Prerelease-Version;
- `master` veröffentlicht die stabile Version aus `Chart.yaml`;
- beide Versionen erscheinen als OCI-Artefakt in GHCR und als klassisches
  Helm-Repository auf GitHub Pages.

Details und die einmalige GitHub-Konfiguration stehen in
[docs/releasing.md](docs/releasing.md).
