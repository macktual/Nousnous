# Documents pour la mise en ligne — NousNous

Ce dossier contient les documents prêts à l’emploi pour publier l’application sur les stores et respecter le RGPD.

---

## Fichiers

| Fichier | Usage |
|--------|--------|
| **play_store_fiche.md** | Textes pour la fiche Google Play (nom, courte description, description complète, catégorie, etc.) |
| **app_store_fiche.md** | Textes pour la fiche App Store (nom, sous-titre, description, mots-clés, catégorie, etc.) |
| **politique_confidentialite.md** | Politique de confidentialité complète (texte) — à héberger en ligne ou à convertir en page web |
| **politique_confidentialite.html** | Version HTML de la politique de confidentialité — à mettre en ligne et à utiliser comme URL dans les stores |
| **rgpd_resume.md** | Résumé RGPD (données, finalités, droits) pour les déclarations stores et la vérification interne |

---

## À faire avant publication

1. **Remplacer les placeholders** dans tous les fichiers :
   - `[VOTRE_EMAIL]` → votre adresse e-mail de contact
   - `[NOM ou RAISON SOCIALE]` / `[ADRESSE]` → votre identité et adresse (obligatoire pour le responsable du traitement)
   - `[DATE]` → date de mise à jour (ex. 24 février 2026)
   - `[VOTRE_SITE_OU_PAGE]` → URL de votre site ou page (optionnel)

2. **Héberger la politique de confidentialité**  
   Mettez en ligne le fichier `politique_confidentialite.html` (ou une page générée à partir de `politique_confidentialite.md`) sur votre site ou une page dédiée, puis notez l’URL exacte (ex. `https://votresite.com/politique-confidentialite-nousnous`).

3. **Play Store**  
   Dans la Play Console, collez les textes de `play_store_fiche.md` et indiquez l’URL de la politique de confidentialité.

4. **App Store**  
   Dans App Store Connect, utilisez les textes de `app_store_fiche.md`, renseignez l’URL de la politique de confidentialité et l’URL de support.

5. **Captures d’écran et icônes**  
   Préparez les visuels selon les recommandations indiquées dans les fiches Play Store et App Store.

---

## Rappel RGPD

- Les données de l’app sont **uniquement sur l’appareil** ; aucune donnée n’est envoyée sur un serveur.
- La politique de confidentialité et le résumé RGPD décrivent ce traitement et les droits des utilisateurs (accès, rectification, effacement, etc.).
- En cas de doute sur une déclaration dans les stores (ex. « Données collectées »), reportez-vous à `rgpd_resume.md` et à la politique de confidentialité.
