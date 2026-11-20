# Plan de test

> Rôle : QA Engineer (Inc-9, repris en phase 5 le 2026-11-20). Les nombres de tests et
> les résultats du jour sont dans `PROJECT_STATE.md` (« Ce qui est vérifié »).

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
| Mode sombre du téléphone | Sans objet : l'app reste en thème clair (ADR-040) |
| Accessibilité | Cibles tactiles (48 dp, 44 pt), boutons nommés, contraste du texte (`meetsGuideline`) |
| Fraude | Client modifié : quotas, droits, crédits, récompenses et signalements décidés en base ; rappel AdMob falsifié refusé |
| Langues de l'interface | Tests en anglais ; textes français et anglais générés depuis les mêmes clés |

## Critères d'acceptation et tests

Chaque story de `docs/product/user-stories.md` et les fichiers qui vérifient ses
critères. Écrans : `test/` ; serveur : `test_integration/` et `supabase/tests/`.

| Story | Écrans | Serveur |
|-------|--------|---------|
| US-01 Compte | `account_journey_test` : inscription et code, code renvoyé, identifiants erronés sans dire si l'e-mail existe, mot de passe oublié | `account_backend_test` ; Google et Apple avec Inc-1b |
| US-02 Langue | `account_journey_test`, `languages_and_stats_test` (une seule langue en gratuit), `journal_journey_test` (aucune offre avant la première correction) | `languages_and_stats_backend_test`, `profiles_and_languages_test.sql` |
| US-03 Suppression | `account_journey_test` (deux confirmations, annulation, échec) | `account_backend_test` (compte et données effacés) |
| US-04 Plusieurs langues | `languages_and_stats_test` (3 ou 4 langues, refus, fin d'abonnement) | `languages_and_stats_backend_test`, `languages_and_stats_test.sql` |
| US-05 Rédaction | `journal_journey_test` (compteur, 7 phrases, brouillon), `secure_journal_draft_store_test` | `correction_backend_test` (plus de 7 phrases refusé) |
| US-06 Correction | `journal_journey_test` (correction, journal sans faute, « Ta version », panne sans débit, refus expliqué) | `correction_backend_test`, `journal_and_corrections_test.sql` |
| US-07 Limite du jour | `journal_journey_test`, `shop_and_exam_test` (boutique), `ads_test` (vidéo) | `purchases_and_exams_test.sql` (crédit après le quota), `ads_and_rewards_test.sql` |
| US-08 Vocabulaire | `review_and_history_test` (Réviser, carte du jour, mots appris) | `review_backend_test`, `vocabulary_and_history_test.sql` (5 par jour) |
| US-09 Historique | `review_and_history_test` (4 jours, pages), `premium_test` (tout l'historique) | `review_backend_test`, `vocabulary_and_history_test.sql` (4 jours, par la RLS) |
| US-10 Offres | `premium_test` (ordre, conditions, jamais ouvertes d'elles-mêmes avant la première correction) | — |
| US-11 Abonnement | `premium_test` (achat, confirmation en retard, restauration, expiration) | `subscription_backend_test` (essai, remboursement, résiliation, secret), `subscriptions_test.sql` |
| US-12 Correction avancée | `premium_ai_test` | `premium_ai_backend_test`, `premium_ai_test.sql` |
| US-13 Reformulation | `premium_ai_test` | `premium_ai_backend_test` |
| US-14 Exercices | `premium_ai_test`, `ads_test` (3 de plus par vidéo) | `premium_ai_backend_test` (réserve partagée), `premium_ai_test.sql` |
| US-15 Voix | `voice_and_export_test` (dictée, micro refusé, langue absente, lecture) | — |
| US-16 Statistiques | `languages_and_stats_test` | `languages_and_stats_backend_test`, `languages_and_stats_test.sql` |
| US-17 Export PDF | `voice_and_export_test` | — |
| US-18 Crédits | `shop_and_exam_test` (achat, un seul crédit débité) | `purchases_and_exams_backend_test`, `purchases_and_exams_test.sql` |
| US-19 Langue 30 jours | `shop_and_exam_test` | `purchases_and_exams_backend_test`, `purchases_and_exams_test.sql` |
| US-20 Examen | `shop_and_exam_test` (pack, sujet, copie notée, reprise) | `purchases_and_exams_backend_test` (sujet impossible : pack rendu), `purchases_and_exams_test.sql` |
| US-21 Sans publicité | `shop_and_exam_test` (achat, restauration), `ads_test` | `purchases_and_exams_backend_test` |
| US-22 Publicités | `ads_test` (bannière, interstitiel, consentement) | `ads_backend_test` (14 jours), `ads_and_rewards_test.sql` |
| US-23 Vidéo récompensée | `ads_test` | `ads_backend_test` (rappel mal signé), `ads_and_rewards_test.sql`, `deno test` de `admob-reward` |
| US-24 Suivi | — | `monitoring_test.sql` |

## Couverture du code (2026-11-20)

Lignes de `lib/` exécutées par les tests, fichiers générés exclus (`*.g.dart`,
`*.freezed.dart`, traductions) :

| Tests | Lignes couvertes |
|-------|------------------|
| Écrans seuls (`flutter test --coverage`) | 87,2 % |
| Écrans et intégration (lcov fusionnés) | **92,7 %** (3 920 sur 4 227) |

Par couche, avec les deux : domaine 98 %, écrans 97 %, application 91 %, `core` 90 %,
données 60 %. Les lignes de données restantes enveloppent des SDK du téléphone,
vérifiables seulement sur un appareil : publicités (`admob_ads_service.dart`), dictée
et voix (`system_voice_service.dart`) ; `unavailable_billing_repository.dart` sera
remplacé par RevenueCat (Inc-4b).

Mesure des tests d'intégration (Supabase local démarré) :
`flutter test test_integration --concurrency=1 --coverage --coverage-path=coverage/integration.info`.

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

## Anomalies trouvées et corrigées en phase 5

Trois relectures complètes du code (ADR-041). Chaque correction a son test de
non-régression quand le comportement est vérifiable sans appareil.

| Anomalie | Test |
|----------|------|
| CI rouge : test SQL dépendant de la date (exercices du jour) | `premium_ai_test.sql` |
| Envoi rejoué pendant sa correction : Claude appelé deux fois | `retries_and_limits_test.sql` |
| Textes refusés en boucle : quota rendu, coût sans limite | `retries_and_limits_test.sql` |
| Reprise d'un journal hors de l'historique gratuit | `retries_and_limits_test.sql` |
| Exercices offerts déjà faits comptés deux fois | `ads_and_rewards_test.sql` |
| Réponse renvoyée après une coupure : un exercice de plus décompté | `ads_and_rewards_test.sql`, `premium_ai_test.sql` |
| Expiration d'une formule remplacée qui coupe l'abonnement actif | `retries_and_limits_test.sql` |
| Exercice généré mal formé : tout le lot perdu | `retries_and_limits_test.sql` |
| App restée ouverte : limite d'hier affichée le lendemain | `journal_journey_test` |
| Brouillon plus long que la limite envoyé puis refusé | `journal_journey_test` |
| Quota utilisé ailleurs : éditeur figé sur une erreur | `journal_journey_test` |
| Erreur de la puce de langue affichée dans le profil | `languages_and_stats_test` |
| Effacement des brouillons qui modifie la liste qu'il parcourt | `secure_journal_draft_store_test` |
| Texte d'examen perdu en quittant l'écran | `shop_and_exam_test` |
| Copie en cours de notation modifiable | `shop_and_exam_test` |
| Achats non lus présentés comme « rien acheté » | `shop_and_exam_test` |
| Long journal : export PDF bloqué | `voice_and_export_test`, `review_pdf_test` (isolate) |
| Erreur du flux de session rejouée : app bloquée au démarrage | relecture (le faux compte n'émet pas d'erreur) |
| Dictée Android 13+, lecture à plusieurs boutons, interstitiel raté | à vérifier sur téléphone |
