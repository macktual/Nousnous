# Publier l’app sur le Google Play Store

Avec cette méthode, vos amis n’ont **rien à installer manuellement** : ils ouvrent le Play Store, trouvent l’app et appuient sur « Installer », comme pour n’importe quelle application.

---

## 1. Compte développeur Google Play

- Allez sur [Google Play Console](https://play.google.com/console).
- Connectez-vous avec un compte Google.
- Acceptez les conditions et payez les **25 €** (paiement unique, compte développeur à vie).
- Complétez le profil (nom, adresse, etc.) si demandé.

---

## 2. Créer l’application dans la Console

1. Dans la Play Console : **« Créer une application »**.
2. Renseignez :
   - **Nom de l’app** : Assistante Maternelle (ou le nom que vous voulez).
   - **Langue par défaut** : Français.
   - **Type** : Application.
   - **Gratuite** ou payante (vous pouvez la laisser gratuite).

---

## 3. Préparer le fichier à publier (AAB)

Sur votre ordinateur, dans le dossier du projet :

```bash
cd /Users/francktual/assistante_maternelle
flutter build appbundle --release
```

La première fois, Flutter peut vous demander de configurer une **clé de signature**. Si c’est le cas :

- Répondez **y** (yes).
- Donnez un mot de passe et un nom (ex. : `upload-key`, `key.jks`).
- Conservez le fichier `.jks` et le mot de passe en lieu sûr : ils servent pour toutes les mises à jour futures.

Le fichier généré se trouve ici :

```
build/app/outputs/bundle/release/app-release.aab
```

C’est ce fichier **.aab** (Android App Bundle) que vous enverrez au Play Store.

---

## 4. Renseigner la fiche Play Store

Dans la Play Console, pour votre application :

1. **Tableau de bord** → **Présentation de l’application** (ou « Fiche Play Store »).
2. Renseignez au minimum :
   - **Description courte** (ex. : « Gérez les contrats, vaccins et suivi des enfants accueillis. »).
   - **Description complète** (texte plus long pour expliquer l’app).
   - **Icône** : 512 x 512 px (vous pouvez exporter l’icône du projet Flutter si elle existe).
   - **Graphique de fonctionnalité** : 1024 x 500 px (optionnel mais recommandé).

Vous pouvez laisser certains champs pour plus tard et les compléter avant la première publication.

---

## 5. Publier la version

1. Dans le menu : **Production** (ou **Tests** → **Test interne** pour commencer en petit groupe).
2. **Créer une nouvelle version**.
3. **Téléverser** le fichier `app-release.aab` (celui généré à l’étape 3).
4. Renseignez les **notes de version** (ex. : « Première version : gestion des enfants, vaccins, médicaments, maladies, archivage. »).
5. Enregistrez et envoyez la version en **révision**.

Google vérifie l’app (souvent 1 à 3 jours). Une fois approuvée, elle apparaît sur le Play Store.

---

## 6. Partager avec vos amis

Une fois l’app en ligne :

- Vous pouvez leur envoyer le **lien** de la fiche Play Store (ex. : `https://play.google.com/store/apps/details?id=com.assistante_maternelle.app`).
- Ils ouvrent le lien sur leur téléphone Android et appuient sur **« Installer »**.
- Aucune manipulation d’APK, aucune activation de « sources inconnues » : tout se fait comme pour une app classique.

---

## En résumé

| Étape | Action |
|-------|--------|
| 1 | Créer un compte développeur (25 €, une fois). |
| 2 | Créer l’app dans la Play Console. |
| 3 | `flutter build appbundle --release` et (si besoin) configurer la clé de signature. |
| 4 | Renseigner la fiche (titre, description, icône). |
| 5 | Téléverser le fichier `.aab` et envoyer en révision. |
| 6 | Partager le lien Play Store : vos amis installent en un clic. |

L’identifiant de l’app est déjà configuré dans le projet : **com.assistante_maternelle.app**.
