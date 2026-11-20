# Déclarations de données des stores

> Rôle : Play Store / App Store Engineer (Inc-9). Réponses tirées du comportement réel
> de l'app (`docs/security.md`, `assets/legal/privacy_fr.md`). Les lignes « SDK » viennent
> de la documentation des éditeurs de SDK : à revérifier sur leurs pages au moment de la
> saisie, elles peuvent changer d'une version à l'autre.

## Google Play — Sécurité des données

**Questions générales**

| Question | Réponse |
|----------|---------|
| L'app collecte ou partage des données ? | Oui |
| Données chiffrées en transit ? | Oui (HTTPS) |
| L'utilisateur peut demander la suppression de ses données ? | Oui : dans l'app (Profil, « Supprimer mon compte ») et par e-mail |
| Lien de demande de suppression du compte | URL publique de la politique de confidentialité (section « Combien de temps nous les gardons ») |

**Types de données**

| Catégorie Play | Collecté | Partagé | Obligatoire | Finalités | Source |
|----------------|----------|---------|-------------|-----------|--------|
| Infos personnelles › Adresse e-mail | Oui | Non | Oui | Fonctionnement de l'app, gestion du compte | App |
| Infos personnelles › ID utilisateur | Oui | Oui (Google, vidéos récompensées) | Oui | Fonctionnement de l'app, publicité | App |
| Activité › Autres contenus générés par l'utilisateur (journaux) | Oui | Non (Anthropic agit comme prestataire) | Oui | Fonctionnement de l'app | App |
| Infos financières › Historique d'achats | Oui | Non | Non | Fonctionnement de l'app | App |
| Position › Position approximative (adresse IP) | Oui | Oui | — | Publicité, analyses, prévention de la fraude | SDK AdMob |
| Activité › Interactions avec l'app | Oui | Oui | — | Publicité, analyses, prévention de la fraude | SDK AdMob |
| Infos et performances › Diagnostics | Oui | Oui | — | Publicité, analyses, prévention de la fraude | SDK AdMob |
| Identifiants › ID publicitaire, ID de l'ensemble d'applications | Oui | Oui | — | Publicité, analyses, prévention de la fraude | SDK AdMob |

Non collectés : audio (la dictée passe par le service vocal du système, l'app ne reçoit
que le texte), position précise, contacts, photos, fichiers, santé.

SDK AdMob : https://developers.google.com/admob/android/privacy/play-data-disclosure.
RevenueCat (Inc-4b) : compléter avec sa documentation quand le SDK sera intégré.

**Autres déclarations de la console (Contenu de l'app)**

| Rubrique | Réponse |
|----------|---------|
| Identifiant publicitaire | Utilisé : publicité et analyses (SDK AdMob) |
| Publicités | L'app contient des publicités |
| Public cible | 16-17 ans et 18 ans et plus |
| Classification du contenu (IARC) | Catégorie « Éducation » ; aucune violence, aucun contenu sexuel, pas d'échange entre utilisateurs, achats numériques : oui |
| Applications gouvernementales, finance, santé, actualités | Non concerné |

## App Store — Confidentialité de l'app

| Donnée | Liée à l'utilisateur | Utilisée pour le suivi | Finalités | Source |
|--------|----------------------|------------------------|-----------|--------|
| Coordonnées › Adresse e-mail | Oui | Non | Fonctionnalité de l'app | App |
| Contenu utilisateur › Autre contenu (journaux) | Oui | Non | Fonctionnalité de l'app | App |
| Identifiants › Identifiant utilisateur | Oui | Non | Fonctionnalité de l'app, publicité tierce | App |
| Achats › Historique d'achats | Oui | Non | Fonctionnalité de l'app | App |
| Diagnostics (plantages, performances), données publicitaires, interactions, position approximative, identifiant de l'appareil | Selon la page Google : les données de performance y sont associées à l'utilisateur, les plantages non | Non (pas de demande ATT) | Publicité tierce, analyses | SDK AdMob |

Sans demande de suivi (ATT), l'identifiant publicitaire iOS n'est pas utilisé.
SDK AdMob : https://developers.google.com/admob/ios/privacy/data-disclosure.
