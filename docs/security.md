# Sécurité

> Tenu par le rôle Security Engineer, complété à chaque incrément.

## Mesures en place

| Sujet | Mesure | Vérifié par |
|-------|--------|-------------|
| Session | Jetons stockés dans le Keystore / Keychain (`SecureLocalStorage`), jamais dans les préférences en clair ; sauvegarde Android désactivée (`allowBackup=false`) | Revue de code |
| Secrets | L'app ne contient que l'URL Supabase et la clé publique, injectées à la compilation ; aucune clé de service | `env/example.json`, revue |
| Accès aux données | RLS activée sur `profiles` et `user_languages` ; lecture de ses propres lignes uniquement ; aucune écriture directe ; visiteur non connecté sans aucun droit | `supabase test db` |
| Écritures | Uniquement par fonctions `security definer` à `search_path` vide, basées sur `auth.uid()` : `activate_language`, `delete_account` | `supabase test db`, tests d'intégration |
| Achats à l'unité | Crédités seulement par la notification du store (secret partagé), une fois par transaction ; repris au remboursement ; un crédit débité à la réussite de la correction, sous verrou par utilisateur ; un pack d'examen débité par le serveur et rendu si le sujet échoue ; l'app ne peut que lire son portefeuille | `supabase test db`, tests d'intégration |
| Limite d'offre | Nombre de langues selon l'offre appliqué dans `activate_language` ; seules les langues utilisables sont corrigées ou servent aux exercices ; détails des statistiques réservés à Premium dans `get_stats` | `supabase test db` |
| Inscription | E-mail confirmé par code à 6 chiffres (15 min) avant toute connexion ; mot de passe de 8 caractères minimum, vérifié aussi côté serveur | Tests d'intégration |
| Énumération de comptes | Message unique « e-mail ou mot de passe incorrect » ; la demande de réinitialisation répond de la même façon qu'un compte existe ou non | Tests d'écran |
| Suppression de compte | Double confirmation ; suppression de l'utilisateur et, par cascade, de toutes ses données | Tests d'intégration et SQL |
| Journaux techniques | Seules les erreurs imprévues sont journalisées, sans e-mail ni mot de passe | Revue de code |
| Validation des entrées | E-mail, mot de passe, code : dans l'app et par le serveur d'authentification | Tests unitaires et d'intégration |
| Clé Anthropic | Uniquement dans les secrets des fonctions (`correct-entry`, `rewrite-sentence`, `next-exercises`) ; jamais dans l'app ni dans le dépôt (`supabase/functions/.env` ignoré par Git) | Revue, `git check-ignore` |
| Quota et coût IA | Réservé en base avant l'appel à Claude, sous verrou par utilisateur ; rendu si la correction échoue ; rejeu du même envoi sans second débit | `supabase test db`, tests d'intégration |
| Accès aux journaux | RLS : lecture de ses journaux corrigés uniquement, aucune écriture ; les fonctions de réservation ne sont exécutables que par le rôle service | `supabase test db` (48 tests) |
| Fonctions Premium (`rewrite-sentence`, `next-exercises`) | Droit Premium et limites du jour vérifiés en base, jamais dans l'app ; une phrase à reformuler doit figurer dans la version corrigée d'un journal de l'utilisateur (500 caractères au plus) ; la bonne réponse d'un exercice ne quitte la base qu'après la réponse | `supabase test db`, tests d'intégration |
| Fonction `correct-entry` | Jeton de l'utilisateur vérifié auprès du serveur d'authentification ; entrées validées (langue, date, identifiant, taille) ; limites de l'offre appliquées en base | Tests d'intégration |
| Injection d'instructions | Le journal est transmis à Claude dans un champ JSON, présenté comme texte à corriger ; la réponse est contrainte par un schéma ; le modèle n'a ni outil ni accès aux données | Tests d'intégration (forme de la requête) |
| Données envoyées à l'IA | Le texte du journal et la langue ; aucun identifiant, e-mail ou métadonnée | Revue de code |
| Journaux techniques du serveur | Messages d'erreur seulement, jamais le texte d'un journal | Revue de code |
| Historique limité | Fenêtre de 4 jours appliquée par la RLS : un journal plus ancien est illisible même par un client modifié | `supabase test db` |
| Vocabulaire | Lecture de ses mots uniquement ; seule la colonne « appris » est modifiable ; limite de 5 par jour appliquée en base | `supabase test db`, tests d'intégration |
| Données de démonstration | `supabase/seed.sql` n'est joué qu'en local ; son compte de test n'existe pas en production | Revue |
| Abonnement | Écrit uniquement par la fonction `revenuecat-webhook` ; l'app ne peut que le lire. Les limites Premium sont appliquées en base : un client modifié n'obtient rien | `supabase test db`, tests d'intégration |
| Webhook d'achats | Secret partagé comparé en temps constant ; sans secret configuré, tout est refusé ; notification rejouée appliquée une seule fois ; notification plus ancienne ignorée | Tests d'intégration |
| Brouillon | Chiffré sur l'appareil (Keystore / Keychain) ; effacé après correction et à la suppression du compte | Tests d'écran |
| Publicités | Montrées seulement si le serveur l'autorise (`get_ad_status` : gratuit, sans l'achat « sans publicité », compte de plus de 14 jours) et, là où la loi l'exige, après le formulaire de consentement de Google (UMP), que le Profil permet de rouvrir ; rien pendant la saisie, la correction ou la révision | Tests d'écran, `supabase test db`, émulateur |
| Vidéos récompensées | Récompense accordée seulement par le rappel signé d'AdMob : signature ECDSA vérifiée avec les clés de Google, blocs de l'app seuls acceptés (`ADMOB_REWARDED_AD_UNITS`), même rappel compté une fois, une récompense de chaque sorte par jour ; l'app ne peut ni lire ni écrire `ad_rewards` | Tests Deno, `supabase test db`, tests d'intégration |
| Signalements de contenus IA | `report_ai_content` : contenu existant et appartenant à l'utilisateur (exercice partagé excepté), 20 par jour au plus, commentaire de 500 caractères au plus ; signalements illisibles par l'app | `supabase test db`, tests d'intégration |
| Vues de suivi (coût, rétention) | Rôle service seulement : l'app et les visiteurs n'y ont aucun accès | `supabase test db` |
| Signature de publication | Clé d'envoi dans `android/key.properties` et `.jks`, ignorés par Git ; un build de publication refuse l'identifiant AdMob de démonstration | `git check-ignore`, build Docker |
| Textes légaux | Lisibles sans compte depuis l'inscription, et dans le Profil et l'écran d'offres | Tests d'écran |

## Permissions demandées

- Internet : Supabase et les fonctions de l'app. Déclarée dans le manifeste
  principal depuis Inc-6 (elle ne l'était qu'en debug, ADR-027).
- Micro (Android `RECORD_AUDIO`, iOS micro et reconnaissance vocale) : dictée du
  journal en Premium, demandée à la première dictée seulement ; un refus laisse
  l'app utilisable au clavier. La voix est traitée par le système de
  l'appareil, jamais envoyée à nos serveurs.
- Publicités (Inc-8), ajoutées par le SDK Google Mobile Ads et ses dépendances, sans
  demande à l'utilisateur : état du réseau, identifiant publicitaire (`AD_ID`), API
  publicitaires d'Android (`ACCESS_ADSERVICES_*`), `WAKE_LOCK`, `FOREGROUND_SERVICE`
  (WorkManager). À déclarer dans la fiche Play (identifiant publicitaire, sécurité des
  données). iOS : aucune demande de suivi (ATT), donc publicités non personnalisées.
- Aucune autre : le PDF passe par la feuille de partage du système, sans accès
  au stockage.

## Points résiduels

| Point | Traitement prévu |
|-------|------------------|
| Connexion Google et Apple non livrée | Dès que les identifiants OAuth existent (`docs/manual-tasks.md`) |
| Envoi d'e-mails en production | SMTP dédié et modèles d'e-mail à configurer (`docs/manual-tasks.md`) ; sans cela les codes n'arrivent pas |
| Limitation des tentatives de code et de connexion | Assurée par le serveur d'authentification Supabase (réglages par défaut) ; à revoir avant publication |
| Textes légaux | Rédigés et affichés (Inc-9) : champs de l'éditeur à compléter, relecture par un juriste, publication à une adresse publique (`docs/manual-tasks.md`) |
| Comptes inactifs | Conservés tant qu'ils existent : durée de conservation à décider avec le juriste (nécessiterait une tâche planifiée) |
| Blocs de vidéos récompensées non déclarés | Sans `ADMOB_REWARDED_AD_UNITS`, une autre app AdMob pourrait viser `admob-reward` (gain limité à la récompense du jour) : secret à renseigner avant publication |
| Limitation des appels à Claude | Traité (ADR-041) : envoi rejoué en cours → `busy`, tentatives qui rendent le quota plafonnées par 24 h (10 corrections, 5 notations d'examen), reformulations comptées refus compris. Reste : une rafale de reformulations simultanées (Premium, modèle économique), et les pannes de l'API, non comptées |
| Achats de test (sandbox) | Acceptés en production, sans quoi Apple ne peut pas valider l'app ; les testeurs sont connus (ADR-041) |
| Comportement réel du modèle face à un texte hostile | Non vérifiable sans clé API ; à tester à la main avec la vraie API |
| Transfert d'achat entre comptes (`TRANSFER`) | Non traité : la notification est enregistrée sans effet. À traiter avec Inc-4b |
| Épinglage de certificat | Non retenu : pas de donnée bancaire ni de santé ; à réévaluer si le besoin change |
