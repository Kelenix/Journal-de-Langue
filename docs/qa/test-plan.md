# Plan de test

> Rôle : QA Engineer (Inc-9). Les nombres de tests et les résultats du jour sont dans
> `PROJECT_STATE.md` (« Ce qui est vérifié »).

## Stratégie

| Niveau | Outil | Ce qui est vérifié | Où | CI |
|--------|-------|--------------------|----|----|
| Règles du serveur | pgTAP (`supabase test db`) | RLS de chaque table, quotas, crédits, récompenses, achats, signalements, vues de suivi | `supabase/tests/` | ✅ |
| Écrans et parcours | `flutter test` (doublures en mémoire) | Parcours de chaque user story, états chargement / vide / erreur, accessibilité | `test/` | ✅ |
| Chaîne complète | `flutter test test_integration` contre le Supabase local, faux serveur Claude | Edge Functions, e-mails de confirmation, webhook d'achats, rappel AdMob, pages d'historique | `test_integration/` | ❌ local |
| Vérification de signature AdMob | `deno test` | Signatures ECDSA valides, falsifiées, clé inconnue | `supabase/functions/admob-reward/` | ❌ local |
| Build | `flutter build appbundle --release` | Compilation et réduction R8 | CI | ✅ |
| Appareil | Émulateur Android (API 35) et téléphone, APK construit sur le poste | Parcours de chaque incrément, publicités de démonstration | à la main | — |

Les tests d'intégration restent locaux : ils demandent l'Edge Runtime de Supabase et le
faux serveur Claude sur le poste (`README.md`, « Tester le backend »). Les ajouter à la CI
est possible plus tard (Supabase CLI dans le job, `supabase functions serve` en arrière-plan).

## Cas limites couverts

| Cas | Comment |
|-----|---------|
| Pas de réseau, serveur en panne | Doublures qui échouent avec `NetworkFailure` : messages et « Réessayer » sur chaque écran, page suivante de l'historique comprise |
| Correction de l'IA en échec | Quota, crédit ou récompense rendu (SQL et intégration) |
| Envoi rejoué après une coupure | Même clé d'idempotence, aucun second débit (SQL et intégration) |
| Permission refusée | Micro refusé à la dictée : explication, saisie au clavier possible |
| Petit écran | Tous les tests d'écran tournent sur 360 × 800 points |
| Très grands caractères | Texte à 200 % sur les écrans principaux, sans débordement |
| Mode sombre | Règles d'accessibilité vérifiées aussi en sombre |
| Accessibilité | Cibles tactiles (48 dp, 44 pt), boutons nommés, contraste du texte (`meetsGuideline`) |
| Fraude | Client modifié : quotas, droits, crédits, récompenses et signalements décidés en base ; rappel AdMob falsifié refusé |
| Langues de l'interface | Tests en anglais ; textes français et anglais générés depuis les mêmes clés |

## Non couvert par les tests automatiques

| Point | Pourquoi | Suite |
|-------|----------|-------|
| Qualité des corrections, reformulations, exercices et notes d'examen | Demande le vrai modèle (clé API) | Relecture humaine (`docs/manual-tasks.md`) |
| Achats réels | SDK RevenueCat non intégré (Inc-4b) | Test en bac à sable avec les comptes des stores |
| Rappel réel d'AdMob | AdMob ne joint pas un serveur local | Essai sur téléphone avec le projet de production |
| Dictée et lecture à voix haute | Émulateur sans micro | Essai sur téléphone |
| iOS | Pas de Mac | TestFlight |

## Lancer les tests

Voir `README.md` : « Vérifier le code », « Tester le backend ».

## Anomalies trouvées et corrigées pendant Inc-9

- Vocabulaire tronqué à 1 000 mots par l'API (ADR-035) : reproduit avec un compte de
  mesure de 3 650 mots, corrigé (lecture par lots), vérifié sur ce compte.
- Historique complet chargé à chaque ouverture de l'app (2,1 Mo pour un an d'usage) :
  remplacé par un compteur et des pages de 20.
- Build de publication faisant tomber Docker Desktop (mémoire de Gradle) : borné (ADR-036).
