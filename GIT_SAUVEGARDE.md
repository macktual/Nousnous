# Sauvegarde et reprise du projet (Git)

Le projet est sous **Git** : tout le code est versionné et tu peux reprendre les modifications plus tard.

## État actuel

- **Premier commit** : tout le développement actuel de l’app « nousnous » est enregistré (244 fichiers).
- **Branche** : `main`.

## Commandes utiles

### Voir l’historique
```bash
cd /Users/francktual/assistante_maternelle
git log --oneline
```

### Après des modifications : enregistrer
```bash
git add -A
git status
git commit -m "Description de tes changements"
```

### Revenir à cet état plus tard
Si tu modifies des fichiers et veux tout annuler :
```bash
git checkout -- .
```
Pour revenir au dernier commit (en gardant les fichiers non suivis) :
```bash
git reset --hard HEAD
```

## Sauvegarde à distance (recommandé)

Pour ne pas tout perdre en cas de panne du Mac, pousse le projet sur un dépôt distant :

1. **Créer un dépôt** sur [GitHub](https://github.com/new) (gratuit, privé possible) ou [GitLab](https://gitlab.com).
2. **Lier et pousser** (remplace `URL_DE_TON_REPO` par l’URL du dépôt) :
   ```bash
   cd /Users/francktual/assistante_maternelle
   git remote add origin URL_DE_TON_REPO
   git push -u origin main
   ```
3. Ensuite, après chaque `git commit`, tu peux faire :
   ```bash
   git push
   ```

Comme ça, tu retrouves le projet sur un autre ordinateur en faisant :
```bash
git clone URL_DE_TON_REPO
cd nom_du_dossier
flutter pub get
```

---

**Résumé** : le travail est sauvegardé dans Git en local. Pour une vraie sauvegarde durable, ajoute un dépôt distant (GitHub/GitLab) et fais un `git push` après tes commits.
