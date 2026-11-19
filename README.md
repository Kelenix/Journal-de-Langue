# Journal de Langue

Application mobile (Android, iOS) pour apprendre une langue en écrivant un journal chaque
jour, corrigé par Claude. Flutter · Riverpod · go_router · Supabase.

Cahier des charges : `INTAKE.md` · Plan : `docs/PLAN.md` · Avancement : `PROJECT_STATE.md`.

## Prérequis

- Docker Desktop démarré
- Supabase CLI
- Flutter 3.41.7 sur l'hôte, uniquement pour lancer l'app sur émulateur ou téléphone

## Démarrer

1. Backend local (Postgres, Auth, Edge Functions) dans Docker :

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

### Si le build Android échoue sur l'hôte

Sur ce poste, Gradle échoue avec `Unable to establish loopback connection`
(`Invalid argument: connect`, Java 17.0.12). Tant que le JDK n'est pas mis à jour
(voir `docs/manual-tasks.md`), compiler dans Docker puis installer avec adb :

```powershell
docker compose run --rm flutter sh -c "flutter pub get && flutter build apk --debug --dart-define-from-file=env/dev.json && mkdir -p dist && cp build/app/outputs/flutter-apk/app-debug.apk dist/"
```

```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" install -r dist/app-debug.apk
```

Le premier build télécharge le NDK Android (environ 1 Go) : il peut durer plus de dix
minutes. Les suivants réutilisent le volume Docker `android_sdk` et sont bien plus courts.

Si adb répond `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, l'app installée a été signée avec une
autre clé de debug : la désinstaller une fois (`adb uninstall
com.journaldelangue.journal_de_langue`), puis réinstaller. La clé est ensuite conservée
dans le volume Docker `android_home`.

## Vérifier le code (dans Docker)

Même image que la CI.

```powershell
docker compose run --rm flutter sh -c "flutter pub get && dart format --output=none --set-exit-if-changed lib test test_integration && flutter analyze && flutter test"
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

Ces tests ne consomment aucun crédit Anthropic. Après eux, relancer `supabase start`
pour retrouver la configuration normale des fonctions.

Les e-mails envoyés en local sont visibles sur http://127.0.0.1:55324.

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
assets/         polices et logo embarqués
design/         original de l'icône (non embarqué)
tool/           génération de l'icône
docs/           plan, produit, architecture, données, design, risques, tâches manuelles
```

## Documentation

| Sujet | Fichier |
|-------|---------|
| User stories | `docs/product/user-stories.md` |
| Architecture | `docs/architecture.md`, `docs/system-design.md` |
| Modèle de données | `docs/data-model.md` |
| Design | `docs/design/design-system.md`, `docs/design/flows.md` |
| Risques | `docs/risks.md` |
| Décisions | `DECISION_LOG.md` |
| À faire par l'éditeur | `docs/manual-tasks.md` |
