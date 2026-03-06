# Déployer l’app sur Netlify (version web)

Pour tester avec vos amis : vous hébergez l’app sur Netlify et vous leur envoyez le lien. Ils ouvrent le lien sur leur téléphone ou ordinateur (aucune installation).

**Rappel :** en version web, les données ne sont pas enregistrées (pas de base de données dans le navigateur). C’est pour faire tester l’interface.

---

## 1. Créer un compte Netlify

- Allez sur [netlify.com](https://www.netlify.com)
- Cliquez sur **Sign up** (inscription)
- Inscription possible avec email, ou avec GitHub / Google

---

## 2. Construire l’app en version web

Sur votre ordinateur, dans le dossier du projet, ouvrez un terminal et lancez :

```bash
cd /Users/francktual/assistante_maternelle
flutter build web
```

Attendez la fin (quelques minutes). Les fichiers à déployer sont dans le dossier **`build/web/`**.

Le fichier **`web/_redirects`** est copié automatiquement dans `build/web/` lors du build, pour que la navigation de l’app fonctionne correctement sur Netlify.

---

## 3. Déployer sur Netlify (glisser-déposer)

1. Connectez-vous sur [app.netlify.com](https://app.netlify.com)
2. Cliquez sur **« Add new site »** → **« Deploy manually »**
3. Une zone **« Drag and drop your site output folder here »** s’affiche
4. Ouvrez le dossier **`build/web`** dans le Finder (Mac) ou l’Explorateur (Windows)
5. Glissez-déposez **tout le contenu** du dossier `build/web` (ou le dossier `build/web` lui-même selon ce que Netlify accepte) dans la zone
6. Netlify uploade les fichiers puis affiche une URL du type :  
   **`https://nom-aleatoire-123.netlify.app`**

---

## 4. Partager le lien

- Copiez l’URL fournie par Netlify
- Envoyez-la à vos amis (SMS, WhatsApp, email, etc.)
- Ils ouvrent le lien dans le navigateur de leur téléphone ou ordinateur : l’app s’affiche, ils peuvent cliquer partout et tester

Vous pouvez aussi personnaliser le sous-domaine dans Netlify : **Site settings** → **Domain management** → **Options** → **Edit site name** (ex. : `assistante-maternelle-demo.netlify.app`).

---

## 5. Mettre à jour plus tard

Après avoir modifié l’app :

```bash
flutter build web
```

Puis sur Netlify : **Deploys** → **Drag and drop** à nouveau le contenu de **`build/web`** (ou déployer via Git si vous avez connecté un dépôt). La nouvelle version remplace l’ancienne.

---

## En résumé

| Étape | Action |
|-------|--------|
| 1 | Créer un compte sur netlify.com |
| 2 | `flutter build web` dans le dossier du projet |
| 3 | Sur Netlify : **Deploy manually** → glisser-déposer le dossier **build/web** |
| 4 | Copier l’URL et l’envoyer à vos amis pour qu’ils testent |

C’est tout. Bon test avec vos amis.
