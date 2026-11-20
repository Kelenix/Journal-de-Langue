# Journal de Langue

Application mobile (Android, iOS) pour apprendre une langue en écrivant un journal chaque
jour, corrigé par Claude. Flutter · Riverpod · go_router · Supabase.

Cahier des charges : `INTAKE.md` · Plan : `docs/PLAN.md` · Avancement : `PROJECT_STATE.md`.

## Prérequis

- Flutter 3.41.7 : analyse, tests, compilation et lancement de l'app, sur le poste
- Supabase CLI et Docker Desktop démarré : Docker sert uniquement à la base locale

## Démarrer

1. Base locale (Postgres, Auth, Edge Functions), lancée dans Docker par Supabase :

   ```powershell
   supabase start
   ```

2. Créer `env/dev.json` à partir de `env/example.json`, avec la clé affichée par :

   ```powershell
   supabase status
   ```

3. Lancer l'app sur un émulateur Android :

   ```powershell
   flutter run --dart-define-from-file=env/dev.json
   ```

Un compte de démonstration avec des journaux corrigés et du vocabulaire est créé par
`supabase db reset` : ses identifiants sont en tête de `supabase/seed.sql`.

Pour obtenir de vraies corrections, copier `supabase/functions/.env.example` vers
`supabase/functions/.env`, y mettre la clé API Anthropic, puis relancer `supabase stop`
et `supabase start`. Sans clé, l'app affiche « La correction n'a pas abouti » et ne
débite rien.

L'émulateur joint le backend local par `http://10.0.2.2:55321`. Sur un téléphone réel,
remplacer `10.0.2.2` par l'adresse IP du poste sur le réseau local.

Si l'installation répond `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, l'app installée a été
signée avec une autre clé de test : la désinstaller une fois du téléphone, puis
réinstaller.

## Vérifier le code

Comme la CI :

```powershell
dart format --output=none --set-exit-if-changed lib test test_integration
```

```powershell
flutter analyze
```

```powershell
flutter test
```

## Tester le backend

Règles d'accès et fonctions SQL (pgTAP) :

```powershell
supabase test db
```

Chaîne complète contre le Supabase local (e-mails de confirmation, fonction de
correction, quota) avec un faux serveur Claude lancé par les tests. Dans un premier
terminal :

```powershell
supabase functions serve --env-file supabase/functions/.env.test
```

Puis dans un second :

```powershell
flutter test test_integration --concurrency=1
```

Ces tests ne consomment aucun crédit Anthropic. Après eux, arrêter `functions serve`,
puis `supabase stop` et `supabase start` (avec les mêmes `-x` si des services sont
exclus) : un simple `supabase start` ne recrée pas les fonctions. Les données locales
sont gardées.

Les e-mails envoyés en local sont visibles sur http://127.0.0.1:55324.

## Configuration

Valeurs passées à l'app au build (`--dart-define-from-file=env/<fichier>.json`, voir
`env/example.json`) :

| Clé | Rôle |
|-----|------|
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | Projet Supabase (clé publique, non secrète) |
| `ADMOB_BANNER_ID`, `ADMOB_INTERSTITIAL_ID`, `ADMOB_REWARDED_ID` | Blocs AdMob ; vides en debug : blocs de démonstration de Google ; vides en publication : pas de publicité |

Propriété Gradle : `-PADMOB_APP_ID=ca-app-pub-…~…` (obligatoire pour un build de
publication Android). Secrets des Edge Functions (`supabase secrets set`, jamais dans le
dépôt) : voir `supabase/functions/.env.example`.

## Tester sur un téléphone

Le téléphone doit être sur le même Wi-Fi que le poste, qui garde Supabase démarré. Créer
`env/phone.json` comme `env/dev.json`, en remplaçant `10.0.2.2` par l'adresse IP du poste
sur le Wi-Fi (`ipconfig`), puis :

```powershell
flutter build apk --release --dart-define-from-file=env/phone.json -PADMOB_APP_ID=ca-app-pub-3940256099942544~3347511713
```

Copier `build/app/outputs/flutter-apk/app-release.apk` (un seul APK, valable pour tous
les téléphones) sur le téléphone et l'ouvrir, en autorisant l'installation
d'applications inconnues. C'est la version publiée, signée avec la clé de test d'Android
car aucune clé d'envoi n'existe sur ce poste : installable, refusée par Google Play.
Identifiant AdMob de démonstration, comme la CI ; sans bloc d'annonce, aucune publicité.
Avec le projet Supabase en ligne, remplacer `env/phone.json` par `env/prod.json`.

Vérification depuis le navigateur du téléphone : `http://<IP du poste>:55321/auth/v1/health`
doit afficher « No API key found in request ». Sinon, le téléphone ne joint pas le poste
(autre réseau, isolation des appareils par la box) : passer par le câble USB, sans Wi-Fi.
Créer `env/usb.json` comme `env/dev.json` avec `127.0.0.1` à la place de `10.0.2.2`,
activer le débogage USB, puis :

```powershell
adb reverse tcp:55321 tcp:55321
```

```powershell
flutter run --dart-define-from-file=env/usb.json
```

Le Supabase local n'envoie aucun vrai e-mail : les codes de confirmation arrivent dans la
boîte locale du poste, http://127.0.0.1:55324. Le compte de démonstration
(identifiants en tête de `supabase/seed.sql`) évite l'inscription.

## Build de publication (Android)

À faire sur l'ordinateur de publication : la clé d'envoi n'est jamais sur le poste de
développement (`docs/manual-tasks.md`, étape 3).

```powershell
flutter build appbundle --release --dart-define-from-file=env/prod.json -PADMOB_APP_ID=<identifiant AdMob de l'app>
```

L'app bundle est produit dans `build/app/outputs/bundle/release/`. Il est signé avec la clé
d'envoi décrite par `android/key.properties`, à créer une fois (`docs/manual-tasks.md`) ;
sans ce fichier, il est signé avec la clé de debug et Google Play le refuse. Avant chaque
version : `docs/store/compliance-checklist.md`.

## Suivi (coût de l'IA, rétention)

Dans l'éditeur SQL du tableau de bord Supabase :

```sql
select * from v_ai_cost_per_month order by month desc;
select * from v_retention_d7 order by cohort_week desc;
select * from ai_content_reports order by created_at desc;
```

## Simuler un abonnement en local

Sans store, un abonnement se simule en envoyant une notification à la fonction
`revenuecat-webhook` : voir `test_integration/subscription_backend_test.dart`, qui le fait
pour chaque cas (essai, renouvellement, expiration, remboursement).

## Ports locaux

Ce projet utilise la plage **5532x** (API 55321, base 55322, Studio 55323, e-mails 55324)
pour cohabiter avec d'autres projets Supabase locaux sur la plage par défaut 5432x.
Réglage : `supabase/config.toml`.

## Arrêter

```powershell
supabase stop
```

## Régénérer l'icône et le logo

Le symbole est dessiné une seule fois dans `tool/generate_app_icons.py` (Pillow requis) :

```powershell
python tool/generate_app_icons.py
```

Visuels des fiches des stores : icône 512, image de présentation, et captures
commentées (Android 1080 × 1920, iPhone 6,9" 1320 × 2868) dans `docs/store/assets/`.
Les écrans sont d'abord rendus par l'app avec des données d'exemple, en français et en
anglais, dans `docs/store/captures/` (sans émulateur), puis mis en page :

```powershell
flutter test tool/store_captures_test.dart --update-goldens
```

```powershell
python tool/generate_store_visuals.py
```

À relancer après chaque changement visible de l'interface.

## Régénérer le code

Après modification d'un modèle `@freezed` (fichiers `*.freezed.dart`, `*.g.dart`) :

```powershell
dart run build_runner build
```

## Structure

```
lib/
├── core/       configuration, thème
├── routing/    navigation (go_router)
├── l10n/       textes fr / en
├── shared/     widgets communs
└── features/   une fonctionnalité par dossier
supabase/       configuration, migrations, Edge Functions
assets/         polices, logo et textes légaux (fr, en) embarqués
design/         original de l'icône (non embarqué)
tool/           génération de l'icône et des visuels des stores
docs/           plan, produit, architecture, données, design, risques, qualité,
                performances, fiches des stores, tâches manuelles
```

## Documentation

| Sujet | Fichier |
|-------|---------|
| User stories | `docs/product/user-stories.md` |
| Architecture | `docs/architecture.md`, `docs/system-design.md` |
| Modèle de données | `docs/data-model.md` |
| Design | `docs/design/design-system.md`, `docs/design/flows.md` |
| Risques | `docs/risks.md` |
| Sécurité | `docs/security.md` |
| Plan de test | `docs/qa/test-plan.md` |
| Performances | `docs/performance.md` |
| Fiches et conformité des stores | `docs/store/` |
| Textes légaux | `assets/legal/` |
| Versions | `CHANGELOG.md` |
| Décisions | `DECISION_LOG.md` |
| À faire par l'éditeur | `docs/manual-tasks.md` |
