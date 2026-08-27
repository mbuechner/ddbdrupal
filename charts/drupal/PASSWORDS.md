# Passwörter ändern

Passwörter sind keine Helm-Values. `RELEASE` steht für Release und Namespace.

| Zweck | Secret | Schlüssel |
| --- | --- | --- |
| Drupal Hash-Salt | `RELEASE-drupal` | `hash-salt` |
| MariaDB | `RELEASE-db` | `password`, `root-password` |
| Redis | `RELEASE-redis` | `password` |
| Basic Auth | `RELEASE-drupal-http-auth` | `HTPASSWD_PWD` |
| SMTP | `RELEASE-drupal-smtp` | `SMTP_PASSWORD` |

Die Zugangsdaten liegen absichtlich in getrennten Secrets, sodass jeder
Container nur die von ihm benötigten Schlüssel erhält.

In OpenShift unter **Workloads → Secrets** das Secret öffnen, **Edit Secret**
wählen und den Wert ändern. Anschließend Drupal neu starten:

```sh
oc -n RELEASE rollout restart deployment/RELEASE-drupal
oc -n RELEASE rollout status deployment/RELEASE-drupal
```

Vorhandene Werte bleiben bei Helm-Upgrades erhalten. MariaDB-, Redis- und
`HASH_SALT`-Secrets nicht manuell ändern; ihre Rotation erfordert eine
koordinierte Wartung.

Das Chart übernimmt bei Upgrades alle vorhandenen Secret-Daten. Automatisch
generierte Passwörter und `HASH_SALT` bleiben dadurch unverändert. Die Secrets
für MariaDB, Redis und `HASH_SALT` sind unveränderbar (`immutable`). Die
Secrets für HTTP Basic Auth und SMTP bleiben dagegen veränderbar, damit ihre
Zugangsdaten im laufenden Betrieb geändert und neue Schlüssel ergänzt werden
können.
