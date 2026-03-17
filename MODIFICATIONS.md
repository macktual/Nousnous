# Historique des modifications et améliorations – App nousnous

Document récapitulatif des principales évolutions apportées au projet (assistante maternelle / nousnous).  
© Franck Tual – Usage personnel/professionnel.

---

## Enfants et contrat

- **Fiche enfant** : nom, prénom, date de naissance, dates de contrat, photo, vacances scolaires, particularités d’accueil.
- **Capitalisation automatique** : première lettre en majuscule pour les noms et prénoms (enfant, parents, profil assistant).
- **Profil enfant** : correction des chevauchements des champs (parent 1 / parent 2, adresse, etc.).
- **PDF « Fiche enfant »** : génération avec infos enfant, parents, horaires ; titre et pagination en en-tête, date d’édition en pied de page.

---

## Horaires d’accueil

- **Historique des horaires** : chaque changement d’horaires est enregistré avec une date de prise d’effet (sans écraser les anciennes périodes).
- **Modification des horaires** : bouton « Modifier les horaires (nouveaux à compter du…) » → choix de la date puis saisie des nouveaux horaires (Semaine type, option Semaine B). L’ancienne période est clôturée, la nouvelle est ajoutée.
- **Document final** : dans la fiche enfant PDF et dans la déclaration arrivée/départ, toutes les périodes sont listées avec :
  - « Horaires à compter du [date] (début de contrat) » pour la première période ;
  - « Nouveaux horaires à compter du [date] » pour les suivantes ;
  - même structure (Semaine type / Semaine B) pour chaque période.

---

## Vaccinations

- **Schéma vaccinal** : choix selon le médecin – **Hexavalent** (INFANRIX HEXA®, Hexyon®, Vaxelis®) ou **Séparé** (Hib Infanrixquinta®/Pentavac® + Hépatite B Engerix®/HBVAXPRO®). Les entrées affichées (DTP-Coq-Hib-Hépatite B vs Hib / Hépatite B) s’adaptent au schéma.
- **Produits** : noms des vaccins mis à jour (Hib : Infanrixquinta®, Pentavac® ; Hépatite B : Engerix®/HBVAXPRO® à chaque dose ; **Pneumocoque** : ajout de **VAXNEUVANCE®**).
- **Justificatifs** : pour chaque vaccination, possibilité de renseigner une source (ex. WhatsApp, email, papier), une date et une **photo justificatif** (reçu du parent).
- **Photo justificatif** : clic sur la vignette pour afficher la photo en grand ; vignette incluse dans le PDF récapitulatif des vaccinations.
- **Déduplication des photos** : si la même photo est utilisée pour plusieurs vaccins, un seul fichier est stocké (hash du contenu) pour limiter l’espace utilisé.
- **Ordre d’affichage** : les vaccins à faire restent en haut, les vaccins déjà faits en bas, avec la chronologie conservée.

---

## Doliprane (ordonnances)

- **Module Doliprane** : enregistrement des ordonnances Doliprane par enfant.
- **Durée** : ordonnance **valable 6 mois** (non modifiable). Affichage **uniquement de la date de fin**.
- **Données** : date de fin d’ordonnance, **date de l’ordonnance** (identique à la date de prise du poids), **poids de l’enfant (kg)**, **nombre de semaines avant la fin** pour un rappel (X défini par l’utilisateur, de 0 à 52).
- **Rappel** : affichage de la date de rappel (fin − X semaines) sur chaque carte ; mise en évidence lorsque le rappel est dans les 7 jours.
- **Notifications push (locales)** : une notification est planifiée à 9 h le jour du rappel (date de fin − X semaines). À la sauvegarde d’une ordonnance avec rappel, la notification est programmée ; à la suppression ou à la modification (sans rappel), elle est annulée. Sur Android : permission « Notifications » ; sur iOS : autorisation « Notifications » au premier lancement.
- **Photo** : copie de l’ordonnance par photo (galerie ou appareil photo), consultable en grand au clic.
- **Accès** : depuis la fiche enfant, module « Doliprane » (icône médicament liquide).

---

## Médicaments

- **Liste des médicaments** : noms proposés au fur et à mesure de la saisie (autocomplete) pour limiter les doublons.
- **PDF récap** : colonnes distinctes pour **Motif**, **Observation** et **Administrée par**.

---

## Maladies

- Gestion des maladies avec PDF dédié (intégré au flux existant).

---

## Signatures

- **Signature du profil assistant** : capture et enregistrement de la signature dans le profil ; elle est réutilisée automatiquement dans le PDF « Déclaration arrivée/départ ».
- **Signature à l’archivage** : lors de l’archivage d’un enfant, possibilité de signer (optionnel) ; la signature est enregistrée et utilisée pour la déclaration archivée.
- **Pavé de signature** : utilisation de **Listener** (événements pointeur) pour un meilleur fonctionnement sur **iOS** ; **ValueNotifier** pour éviter que le pavé bouge pendant la signature (pas de rebuild inutile du layout).
- **Page qui bouge** : sur iOS/Android, désactivation du scroll (dialogue d’archivage, page profil assistant) pendant que le doigt est sur la zone de signature, pour que la page ne bouge plus pendant la signature.
- **Signature dans les PDF** : taille du cadre augmentée, signature en `BoxFit.cover` pour remplir la case. Signature optionnelle pour la déclaration archivée (possibilité de signer à la main après impression).

---

## Archivage

- **Étape unique** : date de fin de contrat, motif et signature (optionnelle) saisis **lors de l’archivage**, en une seule fois. Après archivage, les données sont **non modifiables**.
- **PDF d’archivage** : titre et pagination en en-tête, date d’édition en pied de page ; **Déclaration arrivée/départ** (version non modifiable) disponible parmi les PDF archivés.

---

## PDF et affichage

- **Zoom des PDF** : **InteractiveViewer** sur la page d’aperçu PDF pour zoom et déplacement au doigt sur **Android et iOS**.
- **Boutons en bas** : **SafeArea** autour du contenu de l’aperçu PDF pour que les boutons Imprimer / Partager restent visibles au-dessus de la barre de navigation sur Android (et dans la zone sûre sur iOS).

---

## Appareil photo et permissions

- **Permissions** : déclarations d’usage **iOS** (NSCameraUsageDescription, NSPhotoLibraryUsageDescription) et permissions **Android** (CAMERA, READ_EXTERNAL_STORAGE, READ_MEDIA_IMAGES) pour éviter que l’app se ferme à l’ouverture de l’appareil photo ou de la galerie.
- **Gestion d’erreurs** : `try/catch` autour de l’ouverture caméra/galerie avec message à l’utilisateur en cas d’échec (ex. autorisation refusée).

---

## Interface

- **Schéma vaccinal (smartphone)** : affichage sur plusieurs lignes / pleine largeur (plus de chips trop longs) pour une lecture correcte sur petit écran.

---

## Droits et mentions

- **Propriété** : fichier **PROPRIETARY.md**, page **À propos / Mentions légales** dans l’app, copyright **Franck Tual** dans la description du projet (pubspec) et dans l’app.

---

## Technique (pour reprise du code)

- **Base de données** : migrations jusqu’à la version 20 (colonnes `valid_from` / `valid_until` sur les plannings, `archive_signature_path`, dénomination Pneumocoque avec VAXNEUVANCE®, etc.).
- **Dépendances** : `crypto` pour le hash des photos justificatif (déduplication).
- **Git** : dépôt initialisé, premier commit avec l’état actuel du projet ; guide **GIT_SAUVEGARDE.md** pour reprendre et faire des commits plus tard.

---

*Dernière mise à jour de ce document : état du projet au moment de la sauvegarde Git initiale.*
