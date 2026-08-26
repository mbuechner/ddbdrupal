# Passwörter ändern

Passwörter sind keine Helm-Values. `RELEASE` steht für Release und Namespace.

| Zweck | Secret | Schlüssel |
| --- | --- | --- |
| Basic Auth | `RELEASE-drupal-http-auth` | `HTPASSWD_PWD` |
| SMTP | `RELEASE-drupal-smtp` | `SMTP_PASSWORD` |

In OpenShift unter **Workloads → Secrets** das Secret öffnen, **Edit Secret**
wählen und den Wert ändern. Anschließend Drupal neu starten:

```sh
oc -n RELEASE rollout restart deployment/RELEASE-drupal
oc -n RELEASE rollout status deployment/RELEASE-drupal
```

Vorhandene Werte bleiben bei Helm-Upgrades erhalten. MariaDB-, Redis- und
`HASH_SALT`-Secrets nicht manuell ändern; ihre Rotation erfordert eine
koordinierte Wartung.
