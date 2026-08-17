# Drupal Helm-Chart

Das Chart installiert eine Drupal-Anwendung mit MariaDB und optionalem Redis
auf OpenShift oder Kubernetes. Das Image wird mit
`drupal.image.repository` und `drupal.image.tag` gewählt. Mitgelieferte Profile
decken DDBgo und DDBpro jeweils für Produktion und Test ab.

## OpenShift Form View

Das mitgelieferte `values.schema.json` stellt die Chart-Konfiguration im
OpenShift Developer Catalog als beschriftete Form View mit Hilfetexten,
Auswahllisten und Eingabeprüfung dar. Die YAML View bleibt für selten benötigte
oder frei strukturierte Einstellungen verfügbar.

`drupal.externalHost` ist der öffentliche DNS-Name der Website, zum Beispiel
`www.example.org`. Das Chart verwendet ihn als Host der OpenShift Route oder
des Kubernetes Ingress und nimmt ihn in Drupals Trusted-Host-Regel auf.
`change-me.example.invalid` ist bewusst nicht auflösbar und nur ein sicherer,
auffälliger Platzhalter. Er muss in der Form View, einer Values-Datei oder per
`--set-string` ersetzt werden. Die Endung `.invalid` ist dafür reserviert und
verhindert, dass eine versehentlich unveränderte Installation auf eine echte
fremde Domain zeigt.

Die allgemeinen Defaults benötigen weder einen VPA-Operator noch RWX-Storage
und erlauben unterschiedliche Release- und Namespace-Namen. Damit lässt sich
das Chart unmittelbar installieren; für eine von außen erreichbare Website ist
nur noch der clusterspezifische öffentliche Host zu setzen. Die DDB-Profile
aktivieren ihre strengeren, upgrade-kompatiblen Vorgaben ausdrücklich.

## Profile

```sh
# DDBgo Produktion
helm upgrade --install ddbgo . -n ddbgo -f values-ddbgo.yaml

# DDBgo Test
helm upgrade --install ddbgo-t . -n ddbgo-t -f values-ddbgo-test.yaml

# DDBpro Produktion; Host zwingend ersetzen
helm upgrade --install ddbpro . -n ddbpro -f values-ddbpro.yaml \
  --set-string drupal.externalHost=PRODUKTIVER_DDBPRO_HOST
```

Für Standard-Kubernetes `values-kubernetes.yaml` als letzte Values-Datei
ergänzen. Sie deaktiviert OpenShift ImageStreams und erzeugt statt einer Route
ein Ingress. Zusätzlich setzt sie die numerischen Benutzer und Gruppen der
offiziellen Redis-/MariaDB-Images. VPA bleibt in den allgemeinen Standardwerten
aus, solange dessen Operator nicht ausdrücklich installiert wurde.

## Wichtige Values

| Value | Bedeutung |
| --- | --- |
| `drupal.image.repository` | austauschbares DDBgo-/DDBpro-kompatibles Image |
| `drupal.image.tag` | unabhängig veröffentlichter Image-Tag |
| `drupal.externalHost` | Öffentlicher DNS-Name für Route/Ingress und Trusted-Host-Regel; Platzhalter ersetzen |
| `drupal.config.webRoot` | Webroot im Image, Standard `/var/www/html/web` |
| `drupal.config.filePublicPath` | öffentlicher Dateipfad relativ zum Webroot |
| `drupal.config.filePrivatePath` | absoluter privater Dateipfad |
| `naming.allowedReleaseNames` | optionaler Schutz vor falschen Release-Namen |
| `platform.type` | `openshift` oder `kubernetes` |

`nameOverride` beeinflusst nur das stabile `app.kubernetes.io/name`-Label.
Die DDBgo-Profile setzen `ddbgo`, damit die unveränderlichen Selector-Labels
bestehender DDBgo-Deployments bei einem Upgrade gleich bleiben.

## Persistenz und Secrets

Das Chart erzeugt je einen PVC für Drupal, Redis und MariaDB. Die allgemeinen
Standardwerte verwenden für die einzelnen Pods `ReadWriteOnce`. Die vorhandenen
DDB-Profile behalten den bisherigen Chart-Default aus Upgrade-Kompatibilität
ausdrücklich als `ReadWriteMany`.
Mehrere Drupal-Replikate benötigen weiterhin RWX und werden entsprechend
validiert.
Erzeugte PVCs und Secrets werden bei
`helm uninstall` behalten und bei einer Neuinstallation desselben Releases
wiederverwendet. Fremde gleichnamige Ressourcen werden nicht übernommen.

Der Kubernetes-Storage-Provisioner muss das Drupal-Volume für die UID/GID des
verwendeten Anwendungsimages beschreibbar bereitstellen. Falls er das nicht
automatisch tut, muss unter `drupal.podSecurityContext` eine zum Image passende
`fsGroup` gesetzt werden. Redis und MariaDB werden im Kubernetes-Profil bereits
mit den Gruppen ihrer offiziellen Images konfiguriert.

Für extern verwaltete Objekte stehen `existingClaim` und `existingSecret` zur
Verfügung. Erwartete Secret-Schlüssel:

| Komponente | Schlüssel |
| --- | --- |
| Drupal | `hash-salt` |
| Redis | `password` |
| MariaDB | `database`, `username`, `password`, `root-password` |
| HTTP Basic Auth | `HTPASSWD_USER`, `HTPASSWD_PWD` |

## Sicherheit und Betrieb

Die OpenShift-Profile laufen ohne feste UID/GID; das Kubernetes-Profil setzt nur
für die offiziellen Redis- und MariaDB-Images deren numerische Identitäten. Alle
Container laufen ohne zusätzliche Linux-Capabilities, mit `RuntimeDefault`-
Seccomp und ohne Service-Account-Token. Dies ist mit der OpenShift `restricted`
SCC und Kubernetes Pod Security kompatibel.

OpenShift ImageStreams können bewegliche Tags regelmäßig importieren und über
Image-Change-Trigger Rollouts starten. Auf Kubernetes lädt `pullPolicy: Always`
bei einem Podstart den aktuellen Digest; automatische Rollouts benötigen dort
einen separaten GitOps- oder Image-Automation-Controller.

Änderungen an der vom Chart erzeugten Drupal-ConfigMap lösen über deren
Prüfsumme automatisch einen neuen Drupal-Rollout aus. Die Rotation extern
verwalteter Secrets erfordert weiterhin einen expliziten Pod-Restart oder einen
dafür vorgesehenen Controller.

Die Variablen `UPDATEDB_ON_STARTUP`, `CONFIG_IMPORT_ON_STARTUP` und
`CACHEREBUILD_ON_STARTUP` akzeptieren ausschließlich `yes` oder `no` und stehen
standardmäßig auf `no`.

Der vollständige Containervertrag und Installationsbeispiele stehen in der
README des Repositorys.
