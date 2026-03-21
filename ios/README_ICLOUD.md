# iCloud (sauvegarde nousnous)

La sauvegarde iCloud dans l’app nécessite **un compte Apple Developer payant** (99 €/an) : les équipes **Personal Team** ne peuvent pas signer une app avec la capacité iCloud.

Pour réactiver après souscription :

1. Dans [developer.apple.com](https://developer.apple.com) → Identifiers → ton App ID → activer **iCloud** → **iCloud Documents**.
2. Créer `Runner/Runner.entitlements` avec le conteneur `iCloud.<TON_BUNDLE_ID>` (ex. `iCloud.com.example.assistanteMaternelle`).
3. Dans Xcode : cible **Runner** → **Signing & Capabilities** → ajouter **iCloud** (Documents) **ou** définir **Build Settings** → **Code Signing Entitlements** = `Runner/Runner.entitlements`.

Le code Swift (`AppDelegate`) et Dart (`IcloudBackupService`) sont déjà en place.
