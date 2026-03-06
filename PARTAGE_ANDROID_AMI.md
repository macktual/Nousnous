# Faire tester l’app nousnous à un ami sur Android

Ce guide explique comment **générer l’APK** (fichier d’installation Android) et **comment ton ami l’installe** sur son téléphone.

---

## Côté toi (sur ton Mac)

### 1. Générer l’APK

Dans un terminal, à la racine du projet :

```bash
cd /Users/francktual/assistante_maternelle
flutter build apk --release
```

Quand c’est terminé, l’APK se trouve ici :

```
build/app/outputs/flutter-apk/app-release.apk
```

### 2. Envoyer l’APK à ton ami

Tu peux par exemple :

- **WhatsApp** : envoyer le fichier `app-release.apk` (tu peux le renommer en `nousnous.apk` pour plus de clarté)
- **Email** : joindre le fichier (certains serveurs refusent les .apk ; dans ce cas mets-le dans une archive .zip)
- **Google Drive / Dropbox** : déposer le fichier et envoyer le lien
- **WeTransfer** : https://wetransfer.com (gros fichiers, pas d’inscription pour le destinataire)

Indique à ton ami que l’app s’appelle **nousnous** et que les données restent sur son téléphone.

---

## Côté ton ami (sur son téléphone Android)

### 1. Télécharger / récupérer le fichier

- **WhatsApp** : ouvrir la discussion, télécharger la pièce jointe (fichier `.apk`).
- **Email** : ouvrir le mail, télécharger la pièce jointe (ou extraire le .zip si tu as envoyé une archive).
- **Lien** : ouvrir le lien (Drive, WeTransfer, etc.) et télécharger le fichier.

### 2. Autoriser l’installation depuis une source inconnue

Android demande souvent d’autoriser l’installation d’apps en dehors du Play Store.

- Au moment d’ouvrir le fichier `.apk`, Android peut afficher un message du type **« Installation bloquée »** ou **« Sources inconnues »**.
- Cliquer sur **Paramètres** (ou **Réglages**) dans ce message, puis activer l’option proposée (par ex. **« Autoriser depuis cette source »** ou **« Installer des applications inconnues »** pour **Fichiers** ou **Chrome**).
- Revenir en arrière et rouvrir le fichier `.apk`.

*(Selon la marque du téléphone, le chemin peut être : Réglages → Sécurité → Sources inconnues / Installer des apps inconnues.)*

### 3. Installer l’app

- Ouvrir le fichier **app-release.apk** (ou **nousnous.apk**).
- Appuyer sur **Installer**.
- Une fois l’installation terminée, ouvrir l’app **nousnous** comme n’importe quelle autre app.

Les données (enfants, vaccins, etc.) sont enregistrées **uniquement sur le téléphone** de ton ami.

---

## En résumé

| Étape | Toi | Ton ami |
|--------|-----|---------|
| 1 | `flutter build apk --release` | — |
| 2 | Envoyer `build/app/outputs/flutter-apk/app-release.apk` (ex. par WhatsApp, Drive, WeTransfer) | Télécharger le fichier reçu |
| 3 | — | Autoriser « sources inconnues » si Android le demande |
| 4 | — | Ouvrir le .apk et appuyer sur « Installer » |
