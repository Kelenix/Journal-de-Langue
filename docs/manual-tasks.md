# Tâches manuelles (à faire par toi)

> Ce que Claude ne peut pas faire à ta place : créer des comptes, payer, signer, saisir des
> secrets. Classé par moment où la tâche devient bloquante. Mis à jour à chaque incrément.

## Poste de développement (dès maintenant, non bloquant)

- [ ] Le build Android échoue sur l'hôte : Gradle s'arrête sur
      `Unable to establish loopback connection` / `Invalid argument: connect` avec le
      Java 17.0.12 d'Oracle présent sur ce poste. Cause probable : incompatibilité entre
      ce JDK et cette version de Windows 11 (26300). Piste : installer un JDK plus récent
      (17 à jour ou 21) puis `flutter config --jdk-dir <dossier>`. En attendant, le build
      se fait dans Docker (voir README), ce qui prive du rechargement à chaud.
      À vérifier d'abord dans ton propre terminal avec `flutter run` : l'erreur a été
      constatée depuis la session de Claude.

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

- [ ] Fixer une limite de dépense mensuelle dans la console Anthropic.

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

## Avant Inc-4 (achats)

- [ ] Compte **Google Play Console** (25 $ une fois).
- [ ] Compte **Apple Developer** (99 $ par an), requis pour iOS et la connexion Apple.
- [ ] Compte **RevenueCat** (si Q1 = RevenueCat) relié aux deux stores.
- [ ] Créer les produits dans les stores, avec les prix retenus en Q4 :
      3 abonnements (hebdo, mensuel, annuel, essai de 3 jours), packs de 10 et 50
      corrections, accès langue 30 jours, Pack Examinateur, suppression des publicités.
- [ ] Renseigner les informations fiscales et bancaires dans chaque store.

## Avant Inc-8 (publicités)

- [ ] Compte **AdMob**, création de l'app et des 3 blocs (bannière, interstitiel,
      récompensée), configuration du message de consentement.

## Identité visuelle (quand tu veux)

- [ ] Valider ou remplacer l'icône et le logo générés (`design/app_icon_1024.png`) : c'est
      une première exécution du concept du brand kit, pas un logo de designer.
- [ ] Valider le mode sombre, que le brand kit ne définit pas.
- [ ] Trancher l'écart du brand kit : son aperçu dit « 10 phrases maximum », l'app
      applique les 7 phrases validées.

## Avant publication (Inc-9)

- [ ] Confirmer l'identifiant d'application `com.journaldelangue.journal_de_langue`
      (ADR-010). Il devient définitif à la première mise en ligne.
- [ ] Clé de signature Android (keystore) : génération guidée, conservation sous ta
      responsabilité. Sa perte empêche toute mise à jour.
- [ ] Certificats et profils iOS.
- [ ] Faire valider la politique de confidentialité et les conditions d'utilisation, et
      les héberger à une adresse publique.
- [ ] Fiches stores : captures, description, classification du contenu, formulaire sur les
      données collectées.
- [ ] Dépôt GitHub pour la CI (privé ou public, voir Q3).
