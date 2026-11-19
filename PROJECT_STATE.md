# État du projet — PROJECT_STATE

> Mis à jour par Claude à la fin de chaque phase / incrément. Permet de **reprendre** le
> travail à tout moment, même dans une nouvelle session. Toujours lire ce fichier avant d'agir.

## Snapshot

- **Phase courante** : 4 — Implémentation
- **Dernière mise à jour** : 2026-11-19
- **Santé** : 🟡 attention (build Android impossible sur l'hôte, contourné par Docker)
- **Prochaine action** : Inc-4 — abonnements Premium et essai. Bloqué pour un achat
  réel tant que les comptes Google Play et RevenueCat n'existent pas ; la partie
  indépendante des stores (droits côté serveur, écran d'offres) peut avancer.
  En parallèle, côté utilisateur : fournir une clé API Anthropic pour relire de vraies
  corrections (voir `docs/manual-tasks.md`).
- **Mode** : PLAN_PUIS_VALIDATION (plan validé le 2026-11-19, valeurs par défaut retenues).
  Règle fixée par l'utilisateur le 2026-11-19 : **demander son feu vert avant de commencer
  chaque nouvel incrément** ; vérifications complètes, build Docker compris, à chaque incrément.

## Avancement par phase

| Phase | État | Notes |
|-------|------|-------|
| 0 — Cadrage & intake        | ✅ fait | `docs/PLAN.md`, ADR-008 |
| 1 — Définition produit      | ✅ fait | `docs/product/user-stories.md` (24 stories) |
| 2 — Planification           | ✅ fait | `docs/risks.md`, backlog ci-dessous |
| 3 — Architecture & design   | ✅ fait | `docs/architecture.md`, `system-design.md`, `data-model.md`, `design/` |
| 4 — Implémentation          | 🔄 en cours | Inc-0 à Inc-3 livrés : jalon J1 (boucle gratuite complète) |
| 5 — Qualité & performance   | ⬜ à faire | QA et revue faites à chaque incrément |
| 6 — Publication (stores)    | ⬜ à faire | |
| 7 — Documentation           | ⬜ à faire | README et docs tenus au fil de l'eau |
| 8 — Maintenance             | ⬜ à faire | |

> États : ⬜ à faire · 🔄 en cours · ✅ fait · ⏸️ en attente (raison)

## Backlog incréments (incrément vertical = livrable)

| ID | Incrément | Stories | État | Notes |
|----|-----------|---------|------|-------|
| Inc-0 | Socle technique, Docker, CI | — | ✅ | CI écrite mais jamais exécutée (pas de dépôt distant) |
| Inc-1 | Compte par e-mail, choix de la langue, suppression de compte | US-01 (e-mail), US-02, US-03 | ✅ | |
| Inc-1b | Connexion Google et Apple | US-01 (reste) | ⏸️ | attend les identifiants OAuth (ADR-014) |
| Inc-2 | Journal et correction de base | US-05, 06, 07 | ✅ | chaîne technique vérifiée avec un faux Claude ; qualité des vraies corrections à relire (ADR-018) |
| Inc-3 | Vocabulaire et historique | US-08, 09 | ✅ | historique complet et filtre par langue avec Premium (Inc-4) |
| Inc-4 | Abonnements Premium et essai | US-04, 10, 11 | ⬜ | attend comptes stores et RevenueCat |
| Inc-5 | IA Premium | US-12, 13, 14 | ⬜ | |
| Inc-6 | Voix, statistiques, PDF, multi-langues | US-04, 15, 16, 17 | ⬜ | |
| Inc-7 | Achats ponctuels | US-18 à 21 | ⬜ | |
| Inc-8 | Publicités | US-22, 23 | ⬜ | attend le compte AdMob |
| Inc-9 | Qualité, publication, documentation, textes légaux | US-24 | ⬜ | |

## Ce qui est vérifié (2026-11-19)

| Vérification | Résultat |
|--------------|----------|
| `flutter analyze` (hôte et conteneur) | 0 problème |
| `flutter test` (hôte et conteneur) | 79 tests verts |
| `flutter test test_integration --concurrency=1` (Supabase local, fonction de correction, faux Claude) | 21 tests verts |
| `supabase test db` (RLS et fonctions) | 68 tests verts |
| `supabase db reset` (migrations rejouées depuis zéro, données de démonstration) | réussi |
| Build APK de debug | réussi dans Docker ; **échoue sur l'hôte** (JDK) |
| Parcours sur émulateur Android (APK de debug) | inscription avec code reçu par e-mail local, choix de la langue, session et brouillon conservés après mise à jour de l'app, compteur de phrases, envoi sans clé Claude (message « rien n'est débité »), déconnexion : OK. Non rejoués à la main : suppression de compte, correction réussie (couverts par les tests). |
| Rendu du brand kit sur émulateur | écran Journal, écran de connexion, icône dans le tiroir d'applications : conformes. Mode sombre et iOS non contrôlés visuellement. |
| Écrans Réviser et Historique (Inc-3) sur émulateur | **en attente** : l'APK n'est pas encore construit. Le build retéléchargeait le NDK Android (environ 1 Go) à chaque fois ; il est maintenant conservé dans le volume Docker `android_sdk`, mais le premier téléchargement est en cours sur une connexion lente. |

Un compte de test `emu-…@example.test` existe dans la base locale ; l'émulateur est resté sur l'écran de connexion.

## Reste à faire sur les incréments livrés

- Liens vers les textes légaux sur l'écran d'inscription : avec les textes, en Inc-9.
- Journaux plus anciens que 4 jours : signalés comme conservés, sans proposition
  d'achat tant que Premium n'existe pas (Inc-4).
- Historique et vocabulaire chargés en une fois : la pagination viendra avec
  l'historique complet de Premium (Inc-4).
- Message de limite du jour : texte neutre pour l'instant (« reviens demain ») ; la
  proposition Premium, les crédits et la vidéo s'y ajoutent en Inc-4, 7 et 8.
- L'écran Journal ne se rafraîchit pas seul au passage de minuit : rouvrir l'app.
- Correction avec le vrai modèle : jamais exécutée (pas de clé API).
- CI GitHub Actions : à exécuter une première fois après création du dépôt distant.
- Icône iOS générée mais jamais vue sur un appareil ; visuels des stores à produire depuis
  `design/app_icon_1024.png` (Inc-9).
- Mode sombre dérivé du brand kit : à faire valider.
- Rien n'est commité : le dépôt Git local est initialisé, sans commit.

## Décisions ouvertes / questions à l'utilisateur

- [ ] Confirmer l'identifiant d'application avant publication (ADR-010).
- [ ] JDK du poste : voir « Blocages ».

## Blocages

- **Build Android sur l'hôte** : Gradle échoue (`Unable to establish loopback connection` /
  `Invalid argument: connect`, Java 17.0.12 Oracle, Windows 11 build 26300). Constaté depuis
  la session de Claude ; à confirmer dans le terminal de l'utilisateur. Contournement :
  build dans Docker puis `adb install` (README). Conséquence : pas de rechargement à chaud.

## Environnement constaté

- Windows 11, Flutter 3.41.7 (Dart 3.11.5), Git 2.54, Supabase CLI 2.121, Docker 29.9.3.
- Supabase local sur les ports 5532x (ADR-011) ; un autre projet local (`flirt-coach`)
  occupe 5432x et n'a pas été touché.
- Émulateur Android `emulator-5554` (API 35).

## Tâches manuelles utilisateur en attente

- voir `docs/manual-tasks.md`

## Journal de session (résumé court, le plus récent en haut)

- 2026-11-19 — Inc-3 livré : Claude propose jusqu'à 5 mots par correction (limite de 5
  par jour et dédoublonnage en base), écran Réviser avec mots appris, écran Historique
  limité aux 4 derniers jours par la RLS, journaux anciens conservés. Données de
  démonstration locales (`supabase/seed.sql`). ADR-020.
- 2026-11-19 — Brand kit fourni par l'utilisateur et appliqué : palette, DM Sans et Inter
  embarquées, cartes et boutons, microtextes, écran Journal, icône Android et logo
  générés par script. ADR-019. Reste : icône iOS et visuels des stores (Inc-9), logo
  définitif, validation du mode sombre.
- 2026-11-19 — Inc-2 livré : rédaction avec compteur de phrases et brouillon chiffré,
  fonction `correct-entry` (Claude Haiku 5.5, sortie structurée), quota d'une correction
  par jour réservé en base et rendu en cas d'échec, écran de correction. Deux défauts
  trouvés par les tests et corrigés (ordre des fautes, message d'erreur de chargement).
  ADR-015 à 018.
- 2026-11-19 — Inc-1 livré : compte par e-mail avec code de confirmation, mot de passe
  oublié, choix et changement de langue, déconnexion, suppression de compte ; migration
  `profiles` / `user_languages` avec RLS ; session en stockage sécurisé. ADR-012 à 014.
- 2026-11-19 — Inc-0 livré : projet Flutter, thème, navigation à 5 onglets, fr/en,
  Supabase local dans Docker, conteneur Flutter, CI. App lancée sur l'émulateur.
  ADR-009 à 011.
- 2026-11-19 — Phases 1 à 3 : user stories, risques, architecture, modèle de données, design.
- 2026-11-19 — Plan validé par l'utilisateur avec les valeurs par défaut (ADR-008).
  Exigence ajoutée : développement sous Docker (ADR-007).
- 2026-11-19 — Lecture de l'INTAKE, reformulation, plan de réalisation, hypothèses H1 à H10,
  questions Q1 à Q5.
