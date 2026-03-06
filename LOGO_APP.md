# Logo de l’application

## Image actuelle (en stock)

L’icône générée pour l’app est conservée ici :

- **`assets/images/app_icon.png`**

Vous pouvez la garder comme référence ou comme secours.

---

## Utiliser votre propre logo

Oui, vous pouvez mettre **votre propre logo** à la place.

### 1. Préparer votre image

- **Format** : PNG (ou JPG si pas de transparence).
- **Taille conseillée** : **1024 x 1024 pixels** (carré). Sinon au minimum **512 x 512**.
- Contenu : logo simple, lisible en petit (icône sur l’écran d’accueil).

### 2. Où la mettre dans le projet

Enregistrez votre fichier dans le dossier des images du projet, par exemple :

- **`assets/images/mon_logo.png`**  
  (ou un autre nom, par ex. `logo_assistante_maternelle.png`)

Tant que le fichier est dans **`assets/images/`**, il sera pris en compte.

### 3. En faire l’icône de l’app (Android, iOS, Web)

Pour que votre logo devienne l’icône affichée sur le téléphone et le web, il faut régénérer les icônes à partir de ce fichier.

**Option A – Outil en ligne (le plus simple)**  
1. Allez sur [appicon.co](https://appicon.co) ou [easyappicon.com](https://easyappicon.com).  
2. Uploadez **votre image** (1024x1024 ou 512x512).  
3. Téléchargez le pack généré (Android + iOS).  
4. Remplacez les fichiers dans :
   - **Android** : `android/app/src/main/res/` (dossiers `mipmap-xxxhdpi`, `mipmap-xxhdpi`, etc.) par les dossiers « android » du pack.
   - **iOS** : `ios/Runner/Assets.xcassets/AppIcon.appiconset/` par les images du pack « iOS ».  
   - **Web** : `web/icons/` par les icônes 192 et 512 du pack si fournies.

**Option B – Avec le projet (package Flutter)**  
Si le package **flutter_launcher_icons** est ajouté au projet, vous pourrez mettre votre image dans `assets/images/mon_logo.png`, configurer ce nom dans `pubspec.yaml`, puis lancer une commande pour générer toutes les tailles. Les étapes exactes seront alors dans le `README` ou un fichier dédié du projet.

---

## Récapitulatif

| Fichier / dossier | Rôle |
|------------------|------|
| **`assets/images/app_icon.png`** | Logo actuel, gardé en stock. |
| **`assets/images/mon_logo.png`** (à créer) | Votre logo ; à utiliser pour générer les icônes (Option A ou B). |
| **`assets/images/`** | Tous les logos / images de l’app (stock + le vôtre). |

En résumé : l’image actuelle reste en stock ; vous pouvez ajouter votre propre logo dans **`assets/images/`** et en faire l’icône de l’app en suivant l’option A ou B ci‑dessus.
