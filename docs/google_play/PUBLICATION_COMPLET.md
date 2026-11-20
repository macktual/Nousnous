# Google Play Store — easynounou (préparation complète)

Ce document regroupe **tout ce qu’il faut** pour publier **easynounou** sur le Play Store avec ton compte développeur.

**Identifiant d’application (package) :** `com.assistante_maternelle.app`  
**Version actuelle du projet :** voir `pubspec.yaml` (`version: x.y.z+build`).

---

## 1. Prérequis

- Compte **Google Play Console** (frais d’inscription payés).
- **Politique de confidentialité** en ligne (obligatoire) :  
  `https://macktual.github.io/Nousnous/politique_confidentialite.html`
- **Page support / contact** (recommandé) :  
  `https://macktual.github.io/Nousnous/support.html`
- E-mail de contact développeur : **tualfranck@gmail.com** (à confirmer dans la console).

---

## 2. Clé de signature release (obligatoire pour la production)

Google Play **n’accepte pas** une app release signée avec la clé **debug** pour la publication.

1. Dans le dossier `android/` du projet :

   ```bash
   cd android
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copier `android/key.properties.example` vers `android/key.properties` et remplir les mots de passe (même alias que ci-dessus, ex. `upload`).

3. Placer `upload-keystore.jks` dans **`android/`** (le chemin `storeFile` dans `key.properties` est relatif à ce dossier).

4. **Sauvegarder** le `.jks` et les mots de passe hors du dépôt (clé USB, coffre-fort). Sans eux, tu ne pourras plus mettre à jour l’app sur le Play Store.

Le projet est déjà configuré pour utiliser `key.properties` dans `android/app/build.gradle.kts`.

---

## 3. Générer le bundle Android (AAB)

Le Play Store exige un **Android App Bundle** (`.aab`), pas un APK seul pour la piste principale.

```bash
cd /Users/francktual/assistante_maternelle
flutter pub get
flutter build appbundle --release
```

Fichier produit :

```
build/app/outputs/bundle/release/app-release.aab
```

Vérifier dans la sortie que la signature est bien **release** (après configuration du keystore).

---

## 4. Créer l’application dans Play Console

1. **Créer une application** → nom public (ex. **easynounou**), langue par défaut **Français**, application / gratuite.
2. Remplir le **Tableau de bord** : les sections marquées comme obligatoires (fiche store, confidentialité, cible, pays, etc.).

---

## 5. Fiche Play Store (textes)

Copier-coller depuis **`docs/play_store_fiche.md`** (mis à jour pour **easynounou**) :

- Titre (30 caractères max)
- Courte description (80 caractères max)
- Description complète
- Icône **512 × 512** px (PNG, sans transparence pour l’icône principale si demandé)
- Captures d’écran téléphone (minimum **2**, idéalement 4–8)
- **Feature graphic** optionnel : **1024 × 500** px

---

## 6. Déclarations obligatoires (Play Console)

À compléter avec honnêteté, en cohérence avec l’app :

| Section | Indication pour easynounou |
|--------|----------------------------|
| **Politique de confidentialité** | URL GitHub Pages ci-dessus |
| **Sécurité des données** (formulaire) | Données saisies par l’utilisateur, stockées **localement** ; pas de collecte analytics serveur ; pas de compte obligatoire. Si tu déclares « aucune collecte », reste aligné avec la politique. |
| **Cible d’âge** | Public professionnel (adultes) ; pas d’enfants comme public cible de l’app. |
| **Publicités** | Non (si l’app n’affiche pas de pub) |
| **Fonctionnalités sensibles** | Appareil photo / fichiers / notifications : déjà déclarés via les permissions du manifeste ; expliquer l’usage (photos enfants, justificatifs, rappels Doliprane). |
| **Questionnaire sécurité des données** | Décrire types de données (ex. infos personnelles saisies localement) selon les cases proposées. |

---

## 7. Soumettre une version

1. **Production** ou **Test interne** / **fermé** (recommandé pour un premier envoi).
2. Créer une version → téléverser **`app-release.aab`**.
3. Notes de version (ex. « Première publication Play Store » ou détail des fonctions).
4. Vérifier les pays / appareils / conformité.
5. **Envoyer pour examen**.

Délai courant : **quelques heures à quelques jours**.

---

## 8. Après publication

- Lien fiche : `https://play.google.com/store/apps/details?id=com.assistante_maternelle.app`
- Mettre à jour la version dans `pubspec.yaml` à chaque release (incrémenter `versionCode` = partie après `+`).

---

## 9. Fichiers utiles dans le dépôt

| Fichier | Rôle |
|---------|------|
| `docs/play_store_fiche.md` | Textes titre / descriptions |
| `docs/rgpd_resume.md` | Aide pour le formulaire données |
| `docs/politique_confidentialite.html` | Source politique (Pages) |
| `PUBLICATION_PLAY_STORE.md` | Guide court historique |
| `android/key.properties.example` | Modèle clé de signature |

---

*© Franck Tual — usage aligné avec la propriété intellectuelle du projet.*
