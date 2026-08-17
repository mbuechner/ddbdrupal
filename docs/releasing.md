# Chart veröffentlichen

Die Chart-Veröffentlichung ist vollständig im eigenständigen Helm-Repository
enthalten und benötigt keinen Checkout des DDBgo- oder DDBpro-Quellcodes.

## Kanal

| Branch | Chart-Version | GitHub Pages |
| --- | --- | --- |
| `main` | exakt `version` aus `charts/drupal/Chart.yaml` | `/helm/stable/` |

Das Chart wird zusätzlich unter
`oci://ghcr.io/<owner>/ddbdrupal` veröffentlicht. Owner und Pages-URL werden
im Workflow aus dem neuen GitHub-Repository abgeleitet; beim Umbenennen sind
keine Workflow-Anpassungen erforderlich.

`main` ist der einzige Quell- und Release-Branch. `gh-pages` bleibt als rein
technischer Branch für die generierten Pakete und den Repository-Index bestehen.

## Ablauf

1. Die nächste stabile Version in `Chart.yaml` setzen.
2. Das Chart lokal oder in einem Pull Request prüfen.
3. Die Änderung nach `main` übernehmen. Der Main-Lauf veröffentlicht die
   stabile Version.

Eine vorhandene Version wird nie überschrieben. Existiert dieselbe Version mit
abweichendem Inhalt, bricht die Action ab und `Chart.yaml` muss erhöht werden.

## Einmalige GitHub-Konfiguration

1. Unter **Settings → Actions → General → Workflow permissions** Schreibrechte
   für Workflows erlauben.
2. `publish.yml` einmal auf `main` ausführen, damit `gh-pages` entsteht.
3. Unter **Settings → Pages** „Deploy from a branch“, `gh-pages` und `/ (root)`
   wählen.
4. Die Paket-Sichtbarkeit unter **Packages** bei Bedarf auf „Public“ setzen.

Danach lautet die klassische Repository-URL:

```text
https://<owner>.github.io/<repository>/helm/stable/
```

## Installation einer veröffentlichten Version

Ein Profil ist Bestandteil des Chart-Archivs. Für dessen Verwendung das Archiv
zuerst entpacken:

```sh
CHART_VERSION=0.2.0
helm pull oci://ghcr.io/OWNER/ddbdrupal \
  --version "$CHART_VERSION" \
  --untar

helm upgrade --install ddbgo ./ddbdrupal \
  --namespace ddbgo \
  --values ./drupal/values-ddbgo.yaml \
  --atomic \
  --timeout 15m
```

Für ein Testsystem wird dieselbe Chart-Version mit dem passenden
`*-test.yaml`-Profil verwendet. Der Image-Tag bleibt davon unabhängig.

## OpenShift Developer Catalog

Beispiel für den stabilen Kanal:

```yaml
apiVersion: helm.openshift.io/v1beta1
kind: ProjectHelmChartRepository
metadata:
  name: ddbdrupal
  namespace: ddbgo
spec:
  name: Drupal environments
  connectionConfig:
    url: https://OWNER.github.io/REPOSITORY/helm/stable/
```

Für Test den Ziel-Namespace und das passende `*-test.yaml`-Profil einsetzen. In
der OpenShift-Oberfläche müssen die Website-spezifischen Values eingetragen
werden, weil der Catalog nur die Standardwerte des Charts vorausfüllt.

## Rollback

```sh
helm history RELEASE -n NAMESPACE
helm rollback RELEASE REVISION -n NAMESPACE --wait --timeout 15m
```

`helm uninstall` ist kein normaler Rollback: Workloads und Services werden
entfernt, die standardmäßig behaltenen PVCs und Secrets jedoch nicht.
