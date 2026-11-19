# Sécurité

> Tenu par le rôle Security Engineer, complété à chaque incrément.

## Mesures en place

| Sujet | Mesure | Vérifié par |
|-------|--------|-------------|
| Session | Jetons stockés dans le Keystore / Keychain (`SecureLocalStorage`), jamais dans les préférences en clair ; sauvegarde Android désactivée (`allowBackup=false`) | Revue de code |
| Secrets | L'app ne contient que l'URL Supabase et la clé publique, injectées à la compilation ; aucune clé de service | `env/example.json`, revue |
| Accès aux données | RLS activée sur `profiles` et `user_languages` ; lecture de ses propres lignes uniquement ; aucune écriture directe ; visiteur non connecté sans aucun droit | `supabase test db` |
| Écritures | Uniquement par fonctions `security definer` à `search_path` vide, basées sur `auth.uid()` : `activate_language`, `delete_account` | `supabase test db`, tests d'intégration |
| Limite d'offre | « Une langue active en gratuit » appliquée dans `activate_language`, pas dans l'app | `supabase test db` |
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

## Permissions demandées

Internet uniquement.

## Points résiduels

| Point | Traitement prévu |
|-------|------------------|
| Connexion Google et Apple non livrée | Dès que les identifiants OAuth existent (`docs/manual-tasks.md`) |
| Envoi d'e-mails en production | SMTP dédié et modèles d'e-mail à configurer (`docs/manual-tasks.md`) ; sans cela les codes n'arrivent pas |
| Limitation des tentatives de code et de connexion | Assurée par le serveur d'authentification Supabase (réglages par défaut) ; à revoir avant publication |
| Textes légaux et liens depuis l'inscription | Inc-9, avec la politique de confidentialité |
| Mention de l'envoi des journaux à Anthropic | Politique de confidentialité, Inc-9 (obligatoire avant publication) |
| Limitation du débit des appels à `correct-entry` | Le quota du jour borne déjà le coût ; un utilisateur peut toutefois multiplier les demandes refusées. À traiter avant publication si l'usage le montre |
| Comportement réel du modèle face à un texte hostile | Non vérifiable sans clé API ; à tester à la main avec la vraie API |
| Transfert d'achat entre comptes (`TRANSFER`) | Non traité : la notification est enregistrée sans effet. À traiter avec Inc-4b |
| Épinglage de certificat | Non retenu : pas de donnée bancaire ni de santé ; à réévaluer si le besoin change |
