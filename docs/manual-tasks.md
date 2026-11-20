# Tâches manuelles (à faire par toi)

> Ce que Claude ne peut pas faire à ta place : créer des comptes, payer, signer, saisir des
> secrets. Classé par moment où la tâche devient bloquante. Mis à jour à chaque incrément.

## Pour voir de vraies corrections (Inc-2 livré, non vérifié avec le vrai modèle)

- [ ] Créer un compte **Anthropic Console**, ajouter un moyen de paiement, générer une clé
      API. Ne la colle jamais dans le chat.
- [ ] En local : copier `supabase/functions/.env.example` vers `supabase/functions/.env`
      (ignoré par Git), y mettre la clé, puis `supabase stop` et `supabase start`.
- [ ] Relire quelques corrections dans les 4 langues : la qualité pédagogique du modèle
      n'a pas pu être évaluée sans clé (seule la chaîne technique est testée).
- [ ] En production : créer un projet **Supabase** (offre gratuite suffisante au départ),
      me communiquer son URL et sa clé publique (`publishable` ou `anon`, non secrètes),
      puis :

      supabase secrets set ANTHROPIC_API_KEY=<ta clé>
      supabase functions deploy correct-entry
      supabase functions deploy rewrite-sentence
      supabase functions deploy next-exercises
      supabase functions deploy exam

- [ ] Fixer une limite de dépense mensuelle dans la console Anthropic.
- [ ] Avec la clé, mesurer la durée d'une correction avancée longue (40 phrases) et d'une
      notation d'examen : le serveur leur laisse 90 s et 120 s (ADR-041). Me donner les
      durées si elles s'en approchent.

## Voix et export (Inc-6, livré)

- [ ] Essayer la dictée et la lecture à voix haute sur un vrai téléphone, dans les 4
      langues : l'émulateur n'a pas de micro et ses voix varient.
- [ ] Dans les fiches des stores (Inc-9), déclarer l'usage du micro : dictée du
      journal, traitée sur l'appareil, rien n'est enregistré ni envoyé.

## Pour Inc-1b (connexion Google et Apple)

- [ ] Créer les identifiants OAuth Google (Google Cloud Console) et les saisir dans
      Supabase → Authentication → Providers.
- [ ] Connexion Apple : nécessite le compte Apple Developer (ci-dessous).

## Avant toute inscription réelle (projet Supabase de production)

- [ ] Brancher un service SMTP (Authentication → Emails → SMTP Settings). L'envoi intégré
      de Supabase est limité à quelques e-mails par heure : sans SMTP, les codes de
      confirmation n'arrivent pas. Des offres gratuites existent (Resend, Brevo…).
- [ ] Activer « Confirm email » et reporter les deux modèles d'e-mail de
      `supabase/templates/` (confirmation et réinitialisation) : ils doivent contenir
      `{{ .Token }}`, pas un lien.
- [ ] Régler la longueur minimale du mot de passe à 8 et la durée du code à 900 secondes,
      comme dans `supabase/config.toml`.
- [ ] Appliquer les migrations : `supabase link` puis `supabase db push`.

## Pour Inc-4b (achat réel)

- [ ] Compte **Google Play Console** (25 $ une fois).
- [ ] Compte **Apple Developer** (99 $ par an), requis pour iOS et la connexion Apple.
- [ ] Compte **RevenueCat** relié aux deux stores.
- [ ] Créer les 3 abonnements dans les stores avec **exactement** ces identifiants,
      attendus par le serveur : `premium_weekly` (2,99 €), `premium_monthly` (4,99 €),
      `premium_annual` (29,99 €), chacun avec un essai gratuit de 3 jours. Sur Google
      Play, l'identifiant est celui de l'abonnement ; l'offre de base peut porter
      n'importe quel nom. Sur l'App Store, les 3 dans **le même groupe d'abonnements** :
      un seul actif à la fois, changement de formule géré par Apple.
- [ ] Dans RevenueCat : créer le droit (entitlement) `premium`, une offre (offering)
      contenant les 3 produits, puis me communiquer les clés publiques SDK Android et iOS.
- [ ] Dans RevenueCat, Integrations > Webhooks : URL
      `https://<projet>.supabase.co/functions/v1/revenuecat-webhook` et, dans
      « Authorization header », une longue chaîne aléatoire. Enregistrer la même valeur
      côté serveur, sans la coller dans le chat :

      supabase secrets set REVENUECAT_WEBHOOK_AUTHORIZATION=<la chaîne>
      supabase functions deploy revenuecat-webhook

- [ ] Créer les achats uniques avec **exactement** ces identifiants (ADR-029) :
      consommables `corrections_10` (1,99 €), `corrections_50` (5,99 €), `exam_pack`
      (7,99 €), `language_pass_en`, `language_pass_es`, `language_pass_de`,
      `language_pass_fr` (2,99 € chacun) ; non consommable `remove_ads` (2,99 €).
      Prix indicatifs de l'INTAKE, à ajuster dans les stores.
- [ ] Renseigner les informations fiscales et bancaires dans chaque store.

## Publicités (Inc-8 livré, testé avec les publicités de démonstration de Google)

- [ ] Compte **AdMob** (gratuit), relié à un profil de paiement Google.
- [ ] Créer l'app Android et l'app iOS dans AdMob et me communiquer leurs identifiants
      d'app (`ca-app-pub-…~…`, non secrets). Android : passé au build par
      `flutter build appbundle -PADMOB_APP_ID=<identifiant>` ; iOS : remplace celui de
      démonstration dans `ios/Runner/Info.plist` (`GADApplicationIdentifier`).
- [ ] Pour chaque app, créer 3 blocs : bannière, interstitiel, avec récompense. Me
      communiquer leurs identifiants (`ca-app-pub-…/…`, non secrets) : ils sont passés au
      build par `--dart-define` (`ADMOB_BANNER_ID`, `ADMOB_INTERSTITIAL_ID`,
      `ADMOB_REWARDED_ID`), un jeu par plateforme.
- [ ] Sur chaque bloc avec récompense, activer la vérification côté serveur avec
      l'adresse `https://<projet>.supabase.co/functions/v1/admob-reward`, puis
      enregistrer les numéros de ces blocs (la partie après `/`) et déployer :

      supabase secrets set ADMOB_REWARDED_AD_UNITS=<numéro android>,<numéro ios>
      supabase functions deploy admob-reward

- [ ] Dans AdMob, « Confidentialité et messages » : créer et publier le message de
      consentement RGPD (et celui des États américains si l'app y est distribuée). Sans
      message publié, aucun formulaire n'apparaît.
- [ ] Déclarer ton téléphone comme appareil de test dans AdMob avant d'essayer les vrais
      blocs : cliquer sur ses propres publicités peut faire suspendre le compte.
- [ ] Essayer sur ce téléphone avec un compte de plus de 14 jours : la vidéo doit
      débloquer la correction en quelques secondes (rappel réel d'AdMob, impossible en
      local).
- [ ] Avant publication (Inc-9) : fichier `app-ads.txt` sur le site du développeur
      déclaré dans les stores ; fiche Play (identifiant publicitaire, sécurité des
      données) ; iOS : liste SKAdNetwork de Google et choix de la demande de suivi (ATT).

## Identité visuelle (quand tu veux)

- [ ] Valider ou remplacer l'icône et le logo générés (`design/app_icon_1024.png`) : c'est
      une première exécution du concept du brand kit, pas un logo de designer.
- [ ] Trancher l'écart du brand kit : son aperçu dit « 10 phrases maximum », l'app
      applique les 7 phrases validées.

## Publication (après Inc-4b), étape par étape

La liste de contrôle complète est `docs/store/compliance-checklist.md`.

### 1. Textes légaux — obligatoire, gratuit (hors juriste)

Les stores et le RGPD exigent une politique de confidentialité et, pour les abonnements,
des conditions d'utilisation. Les textes sont rédigés (`assets/legal/`, ADR-033).

1. [ ] Remplacer chaque `[À COMPLÉTER : …]` dans les 4 fichiers de `assets/legal/` et dans
       `docs/store/listing.md` : nom de l'éditeur, adresse, e-mail de contact, médiateur
       de la consommation (obligatoire pour vendre à des consommateurs en France).
2. [ ] Les faire relire par un juriste. Points à trancher : âge minimum (16 ans retenu),
       durée de conservation des comptes inactifs, renonciation au droit de rétractation.
3. [ ] Les publier à une adresse publique (site de l'éditeur, ou GitHub Pages) et reporter
       les adresses dans les fiches des stores.

Vérification : `git grep -n "À COMPLÉTER\|TO COMPLETE" -- assets docs/store` ne renvoie
rien.

### 2. Projet Supabase de production

1. [ ] Le créer dans une région de l'Union européenne (Francfort ou Paris), comme
       l'annonce la politique de confidentialité.
2. [ ] Appliquer « Avant toute inscription réelle » ci-dessus (SMTP, e-mails, mot de passe).
3. [ ] `supabase link`, puis `supabase db push`, puis les secrets et le déploiement des six
       fonctions : `correct-entry`, `rewrite-sentence`, `next-exercises`, `exam`,
       `revenuecat-webhook`, `admob-reward`.
4. [ ] Créer `env/prod.json` sur le modèle de `env/example.json` (adresse et clé publique
       du projet, blocs AdMob). Ce fichier n'est pas versionné.

### 3. Clé d'envoi Android — sur ton ordinateur de publication, jamais sur ce PC

Décision de l'éditeur (2026-11-19) : rien n'est signé sur le poste de développement ; la
clé d'envoi, `android/key.properties` et le build de publication sont faits sur un autre
ordinateur. Google Play signe l'app avec sa propre clé (« signature des applications par
Google Play ») ; la clé d'envoi prouve que les versions viennent de toi. Perdue, elle se
remplace par une demande au support de Google, ce qui bloque les mises à jour quelques
jours.

Sur l'ordinateur de publication : cloner le dépôt, installer Flutter 3.41.7, créer
`env/prod.json`, puis :

1. [ ] Depuis la racine du projet, créer la clé dans `android/app/` (les `.jks` sont
       ignorés par Git) ; choisir un mot de passe solide, à ne jamais coller dans le chat.
       `keytool` est fourni avec Java (Android Studio l'installe) :

       keytool -genkeypair -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

2. [ ] Créer `android/key.properties` (ignoré par Git) :

       storePassword=<mot de passe>
       keyPassword=<mot de passe>
       keyAlias=upload
       storeFile=upload-keystore.jks

3. [ ] Copier `upload-keystore.jks` et les mots de passe dans un gestionnaire de mots de
       passe ou un coffre : ils ne sont nulle part ailleurs.

Vérification : le build de publication (`README.md`) réussit, et
`keytool -printcert -jarfile <app-release.aab>` affiche ton certificat, pas
« Android Debug ».

### 4. Google Play Console — 25 $ une fois

1. [ ] Confirmer l'identifiant d'application `com.journaldelangue.journal_de_langue`
       (ADR-010) : il devient définitif à la première mise en ligne.
2. [ ] Créer l'app, puis remplir « Contenu de l'app » avec `docs/store/data-safety.md`
       (sécurité des données, identifiant publicitaire, public cible, classification).
3. [ ] Remplir la fiche avec `docs/store/listing.md` et `docs/store/assets/` (icône 512,
       image de présentation, captures du téléphone).
4. [ ] Créer les produits (section « Pour Inc-4b »).
5. [ ] Envoyer l'app bundle en test fermé : un nouveau compte personnel doit garder au
       moins 12 testeurs pendant 14 jours avant d'accéder à la production.
6. [ ] Publier en production par paliers (10 %, 50 %, 100 %) et suivre les plantages.

### 5. App Store — 99 $ par an, un Mac nécessaire

1. [ ] Sur un Mac avec Xcode : certificats, profil de distribution, `flutter build ipa`.
2. [ ] Dans App Store Connect : fiche (`docs/store/listing.md`, captures iPhone 6,9" de
       `docs/store/assets/`), confidentialité de l'app (`docs/store/data-safety.md`),
       liens vers les conditions et la politique, achats intégrés.
3. [ ] Test par TestFlight, puis soumission.

### 6. Après la publication

- [ ] Chaque semaine : `v_ai_cost_per_month`, `v_retention_d7` et les signalements
      (`ai_content_reports`) dans l'éditeur SQL de Supabase (`README.md`, « Suivi ») ;
      conversion et annulations dans RevenueCat ; avis dans les consoles des stores.
- [ ] Mettre à jour `ai_model_prices` si un prix de modèle change.
- [ ] Dépôt GitHub pour la CI : privé ou public (question Q3 du plan).
