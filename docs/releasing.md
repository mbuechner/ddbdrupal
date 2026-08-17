# Chart veröffentlichen

Die Chart-Veröffentlichung ist vollständig im eigenständigen Helm-Repository
enthalten und benötigt keinen Checkout des DDBgo- oder DDBpro-Quellcodes.

## Kanäle

| Branch | Chart-Version | GitHub Pages |
| --- | --- | --- |
| `test` | `<version>-test.<run>.<attempt>.sha<commit>` | `/helm/test/` |
| `master` | exakt `version` aus `charts/drupal/Chart.yaml` | `/helm/stable/` |

Beide Kanäle werden zusätzlich unter
`oci://ghcr.io/<owner>/helm/drupal` veröffentlicht. Owner und Pages-URL werden
im Workflow aus dem neuen GitHub-Repository abgeleitet; beim Umbenennen sind
keine Workflow-Anpassungen erforderlich.

## Ablauf

1. Auf `test` die nächste stabile Basisversion in `Chart.yaml` setzen.
2. Änderungen nach `test` pushen und die erzeugte Prerelease testen.
3. Den unveränderten Stand nach `master` mergen.
4. Der Master-Lauf veröffentlicht die stabile Basisversion.

Eine vorhandene Version wird nie überschrieben. Existiert dieselbe Version mit
abweichendem Inhalt, bricht die Action ab und `Chart.yaml` muss erhöht werden.

## Einmalige GitHub-Konfiguration

1. Unter **Settings → Actions → General → Workflow permissions** Schreibrechte
   für Workflows erlauben.
2. `publish.yml` einmal auf `test` ausführen, damit `gh-pages` entsteht.
3. Unter **Settings → Pages** „Deploy from a branch“, `gh-pages` und `/ (root)`
   wählen.
4. Die Paket-Sichtbarkeit unter **Packages** bei Bedarf auf „Public“ setzen.

Danach lauten die klassischen Repository-URLs:

```text
https://<owner>.github.io/<repository>/helm/test/
https://<owner>.github.io/<repository>/helm/stable/
```

## Installation einer veröffentlichten Version

Ein Profil ist Bestandteil des Chart-Archivs. Für dessen Verwendung das Archiv
zuerst entpacken:

```sh
CHART_VERSION=0.2.0
helm pull oci://ghcr.io/OWNER/helm/drupal \
  --version "$CHART_VERSION" \
  --untar

helm upgrade --install ddbgo ./drupal \
  --namespace ddbgo \
  --values ./drupal/values-ddbgo.yaml \
  --atomic \
  --timeout 15m
```

Für ein Testsystem wird die vollständige Prerelease-Version und das passende
`*-test.yaml`-Profil verwendet. Der Image-Tag bleibt davon unabhängig.

## OpenShift Developer Catalog

Beispiel für den stabilen Kanal:

```yaml
apiVersion: helm.openshift.io/v1beta1
kind: ProjectHelmChartRepository
metadata:
  name: drupal
  namespace: ddbgo
spec:
  name: Drupal environments
  connectionConfig:
    url: https://OWNER.github.io/REPOSITORY/helm/stable/
```

Für Test `/helm/test/` und den Ziel-Namespace einsetzen. In der OpenShift-
Oberfläche müssen die Website-spezifischen Values eingetragen werden, weil der
Catalog nur die Standardwerte des Charts vorausfüllt.

## Rollback

```sh
helm history RELEASE -n NAMESPACE
helm rollback RELEASE REVISION -n NAMESPACE --wait --timeout 15m
```

`helm uninstall` ist kein normaler Rollback: Workloads und Services werden
entfernt, die standardmäßig behaltenen PVCs und Secrets jedoch nicht.
