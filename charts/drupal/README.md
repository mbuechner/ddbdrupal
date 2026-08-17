# Drupal Helm-Chart

Das Chart installiert eine Drupal-Anwendung mit MariaDB und optionalem Redis
auf OpenShift oder Kubernetes. Das Image wird mit
`drupal.image.repository` und `drupal.image.tag` gewählt. Mitgelieferte Profile
decken DDBgo und DDBpro jeweils für Produktion und Test ab.

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
ein Ingress.

## Wichtige Values

| Value | Bedeutung |
| --- | --- |
| `drupal.image.repository` | austauschbares DDBgo-/DDBpro-kompatibles Image |
| `drupal.image.tag` | unabhängig veröffentlichter Image-Tag |
| `drupal.externalHost` | Host von Route/Ingress und Trusted-Host-Regel |
| `drupal.config.webRoot` | Webroot im Image, Standard `/var/www/html/web` |
| `drupal.config.filePublicPath` | öffentlicher Dateipfad relativ zum Webroot |
| `drupal.config.filePrivatePath` | absoluter privater Dateipfad |
| `naming.allowedReleaseNames` | optionaler Schutz vor falschen Release-Namen |
| `platform.type` | `openshift` oder `kubernetes` |

`nameOverride` beeinflusst nur das stabile `app.kubernetes.io/name`-Label.
Die DDBgo-Profile setzen `ddbgo`, damit die unveränderlichen Selector-Labels
bestehender DDBgo-Deployments bei einem Upgrade gleich bleiben.

## Persistenz und Secrets

Das Chart erzeugt je einen PVC für Drupal, Redis und MariaDB. Standardmäßig ist
`ReadWriteMany` erforderlich. Erzeugte PVCs und Secrets werden bei
`helm uninstall` behalten und bei einer Neuinstallation desselben Releases
wiederverwendet. Fremde gleichnamige Ressourcen werden nicht übernommen.

Für extern verwaltete Objekte stehen `existingClaim` und `existingSecret` zur
Verfügung. Erwartete Secret-Schlüssel:

| Komponente | Schlüssel |
| --- | --- |
| Drupal | `hash-salt` |
| Redis | `password` |
| MariaDB | `database`, `username`, `password`, `root-password` |
| HTTP Basic Auth | `HTPASSWD_USER`, `HTPASSWD_PWD` |

## Sicherheit und Betrieb

Die Pods laufen ohne feste UID/GID, ohne zusätzliche Linux-Capabilities, mit
`RuntimeDefault`-Seccomp und ohne Service-Account-Token. Dies ist mit der
OpenShift `restricted` SCC und Kubernetes Pod Security kompatibel.

OpenShift ImageStreams können bewegliche Tags regelmäßig importieren und über
Image-Change-Trigger Rollouts starten. Auf Kubernetes lädt `pullPolicy: Always`
bei einem Podstart den aktuellen Digest; automatische Rollouts benötigen dort
einen separaten GitOps- oder Image-Automation-Controller.

Die Variablen `UPDATEDB_ON_STARTUP`, `CONFIG_IMPORT_ON_STARTUP` und
`CACHEREBUILD_ON_STARTUP` akzeptieren ausschließlich `yes` oder `no` und stehen
standardmäßig auf `no`.

Der vollständige Containervertrag und Installationsbeispiele stehen in der
README des Repositorys.
