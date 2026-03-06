# Installer l’app sur Android et iOS (avec base de données)

Sur téléphone ou tablette **installée** (pas en version web), l’app utilise SQLite : **toutes les données restent sur l’appareil** (enfants, vaccins, médicaments, maladies, etc.).

---

# Android

## Option A : Téléphone branché en USB (pour tester tout de suite)

1. **Activer le mode développeur** sur le téléphone Android :
   - **Réglages** → **À propos du téléphone**
   - Appuyez 7 fois sur **Numéro de build**
   - Un message confirme que le mode développeur est activé

2. **Activer le débogage USB** :
   - **Réglages** → **Options pour les développeurs**
   - Activez **Débogage USB**

3. **Brancher le téléphone** au Mac/PC avec un câble USB.

4. **Vérifier que l’appareil est reconnu** (dans un terminal, à la racine du projet) :
   ```bash
   cd /Users/francktual/assistante_maternelle
   flutter devices
   ```
   Votre téléphone Android doit apparaître dans la liste.

5. **Lancer et installer l’app** :
   ```bash
   flutter run --release
   ```
   Ou en mode debug (pour développer) :
   ```bash
   flutter run
   ```
   L’app est installée sur le téléphone et se lance. Les données sont bien enregistrées sur l’appareil.

---

## Option B : Fichier APK à partager (sans brancher le téléphone)

Utile pour envoyer l’app à quelqu’un qui n’a pas le câble.

1. **Générer l’APK** (dans un terminal, à la racine du projet) :
   ```bash
   cd /Users/francktual/assistante_maternelle
   flutter build apk --release
   ```

2. **Où se trouve l’APK** :
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Transférer l’APK** sur le téléphone (email, Google Drive, WhatsApp, câble, etc.).

4. **Sur le téléphone Android** :
   - Ouvrir le fichier **app-release.apk**
   - Si demandé, autoriser **« Sources inconnues »** (ou **« Installer des applications inconnues »** pour l’app utilisée pour ouvrir l’APK)
   - Suivre l’assistant d’installation
   - L’app est installée, la base de données fonctionne comme en Option A.

---

# iOS (iPhone / iPad)

**Prérequis :** un **Mac** avec **Xcode** installé (gratuit sur l’App Store).

## Tester sur ton iPhone (résumé)

1. **Ouvrir le projet dans Xcode** (une seule fois pour la signature) :
   ```bash
   cd /Users/francktual/assistante_maternelle
   open ios/Runner.xcworkspace
   ```

2. **Dans Xcode** :
   - Clique sur **Runner** (projet, colonne de gauche)
   - Onglet **Signing & Capabilities**
   - Coche **Automatically manage signing**
   - **Team** : choisis ton compte Apple ID (un compte gratuit suffit pour ton propre iPhone)

3. **Branche ton iPhone** en USB, déverrouille l’écran, accepte **« Faire confiance à cet ordinateur »** si l’iPhone le demande.

4. **Dans un terminal** (à la racine du projet) :
   ```bash
   cd /Users/francktual/assistante_maternelle
   flutter devices
   ```
   Ton iPhone doit apparaître dans la liste.

5. **Lancer l’app sur l’iPhone** :
   ```bash
   flutter run
   ```
   Ou en version optimisée :
   ```bash
   flutter run --release
   ```

6. **Première installation sur l’iPhone** :  
   Si un message indique que l’app n’est pas de confiance :
   - **Réglages** → **Général** → **Gestion des appareils** (ou **Profils et gestion des appareils** / **VPN et gestion des appareils**)
   - Touche ton compte développeur → **Faire confiance**

L’app **nousnous** est installée sur l’iPhone et la base de données fonctionne (données stockées sur l’appareil).

---

# Récapitulatif

| Plateforme | Méthode        | Commande / Fichier                    | Base de données |
|-----------|----------------|---------------------------------------|-----------------|
| **Android** | USB            | `flutter run --release`               | Oui (SQLite)    |
| **Android** | APK à partager | `flutter build apk --release` → `build/.../app-release.apk` | Oui (SQLite)    |
| **iOS**     | USB (Mac)      | `flutter run --release` + Xcode (signature) | Oui (SQLite)    |

- **Version web (navigateur)** : pas de base de données, les données ne restent pas.
- **Version installée (Android ou iOS)** : base de données locale, tout est enregistré sur l’appareil.
