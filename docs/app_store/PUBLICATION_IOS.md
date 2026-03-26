# Publication iOS - easynounou

Ce guide couvre la mise en ligne sur App Store Connect avec ton compte Apple Developer.

## 1) Prerequis Apple (une seule fois)

- Apple Developer Program actif.
- App creee dans App Store Connect (meme `Bundle ID` que le projet Xcode).
- Certificats/profils en signature automatique Xcode.

## 2) Verifications projet (fait dans ce repo)

- Nom app iOS: `easynounou`
- Version/build Flutter: `pubspec.yaml` (`version: x.y.z+n`)
- Icone iOS generee via `flutter_launcher_icons`
- Entitlements iCloud actives: `ios/Runner/Runner.entitlements`
- Build settings `CODE_SIGN_ENTITLEMENTS` relies au target Runner

## 3) Points a completer avant soumission

### Identite App Store

- Verifier/remplacer le bundle id actuel si besoin:
  - Actuel: `com.example.assistanteMaternelle`
  - Recommande: un id de ton domaine (ex: `fr.tual.easynounou`)
- Nom public App Store (peut differer du nom interne).
- SKU interne (ex: `easynounou-ios-001`).

### Fiches App Store Connect

- Description FR (voir template `docs/app_store/metadata_fr.md`).
- Mots-cles FR.
- URL de support (obligatoire).
- URL de politique de confidentialite (obligatoire).
- Captures ecran iPhone (obligatoire).

### Conformite

- Questionnaire privacy "Data Collection" dans App Store Connect.
- Export compliance (chiffrement) a confirmer.
- Age rating et categories.

## 4) Build archive & upload

Option Xcode (recommande):
- `open ios/Runner.xcworkspace`
- Product > Archive
- Organizer > Distribute App > App Store Connect > Upload

Option CLI:
- Build IPA: `tool/build_ios_ipa_appstore.sh`
- Upload:
  - `xcrun altool --upload-app -f build/ios/ipa/Runner.ipa -t ios -u "<APPLE_ID>" -p "<APP_SPECIFIC_PASSWORD>"`
  - ou Transporter (app macOS) avec l'IPA

## 5) TestFlight

- Ajouter infos "What to Test".
- Ajouter testeurs internes.
- Tester:
  - ouverture app
  - base locale
  - photo camera/galerie
  - notifications locales
  - sauvegarde/restauration iCloud

## 6) Release

- Completer "What's New in this Version".
- Soumettre a review.
- Apres validation: publication manuelle ou automatique.

## Check rapide avant envoi

- [ ] Bundle ID final valide et unique
- [ ] Version/build incrementes
- [ ] URL support + privacy policy renseignees
- [ ] Captures ecran iPhone ajoutees
- [ ] Build TestFlight installee et validee
- [ ] Questionnaire privacy complete
