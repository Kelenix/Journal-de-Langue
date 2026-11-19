# État du projet — PROJECT_STATE

> Mis à jour par Claude à la fin de chaque phase / incrément. Permet de **reprendre** le
> travail à tout moment, même dans une nouvelle session. Toujours lire ce fichier avant d'agir.

## Snapshot

- **Phase courante** : 4 — Implémentation
- **Dernière mise à jour** : 2026-11-19
- **Santé** : 🟡 attention (build Android impossible sur l'hôte, contourné par Docker)
- **Prochaine action** : Inc-7 — achats ponctuels (crédits, langue 30 jours, Pack
  Examinateur, sans publicité), après feu vert de l'utilisateur. En attente côté
  utilisateur : comptes stores et RevenueCat (Inc-4b), clé API Anthropic.
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
| 4 — Implémentation          | 🔄 en cours | Inc-0 à Inc-6 livrés : jalons J1 (boucle gratuite) et J2 (Premium complet) atteints |
| 5 — Qualité & performance   | ⬜ à faire | QA et revue faites à chaque incrément |
| 6 — Publication (stores)    | ⬜ à faire | |
| 7 — Documentation           | ⬜ à faire | README et docs tenus au fil de l'eau |
| 8 — Maintenance             | ⬜ à faire | |

> États : ⬜ à faire · 🔄 en cours · ✅ fait · ⏸️ en attente (raison)

## Backlog incréments (incrément vertical = livrable)

| ID | Incrément | Stories | État | Notes |
|----|-----------|---------|------|-------|
| Inc-0 | Socle technique, Docker, CI | — | ✅ | CI exécutée sur GitHub depuis le premier push |
| Inc-1 | Compte par e-mail, choix de la langue, suppression de compte | US-01 (e-mail), US-02, US-03 | ✅ | |
| Inc-1b | Connexion Google et Apple | US-01 (reste) | ⏸️ | attend les identifiants OAuth (ADR-014) |
| Inc-2 | Journal et correction de base | US-05, 06, 07 | ✅ | chaîne technique vérifiée avec un faux Claude ; qualité des vraies corrections à relire (ADR-018) |
| Inc-3 | Vocabulaire et historique | US-08, 09 | ✅ | historique complet et filtre par langue avec Premium (Inc-4) |
| Inc-4 | Abonnements Premium et essai : droits serveur, webhook, écran d'offres | US-10, 11 | ✅ | testé avec un faux store et des notifications simulées (ADR-021) |
| Inc-4b | Achat réel : SDK RevenueCat (`purchases_flutter`) | US-11 (reste) | ⏸️ | attend comptes Google Play, RevenueCat et produits |
| Inc-5 | IA Premium : corrections avancées, reformulations, exercices | US-12, 13, 14 | ✅ | testé avec un faux Claude ; qualité réelle à relire avec une clé API (ADR-023, ADR-024) |
| Inc-6 | Voix, statistiques, PDF, multi-langues | US-04, 15, 16, 17 | ✅ | dictée et lecture à essayer sur un vrai téléphone ; « langue 30 jours » avec Inc-7 (ADR-025 à 027) |
| Inc-7 | Achats ponctuels | US-18 à 21 | ⬜ | |
| Inc-8 | Publicités | US-22, 23 | ⬜ | attend le compte AdMob |
| Inc-9 | Qualité, publication, documentation, textes légaux | US-24 | ⬜ | |

## Ce qui est vérifié (2026-11-19)

| Vérification | Résultat |
|--------------|----------|
| `flutter analyze` (hôte et conteneur) | 0 problème |
| `flutter test` (hôte) | 137 tests verts |
| `flutter test test_integration --concurrency=1` (Supabase local, fonctions de correction, d'achat, de reformulation et d'exercices, langues et statistiques, faux Claude) | 44 tests verts |
| `supabase test db` (RLS et fonctions) | 152 tests verts |
| `supabase db reset` (migrations rejouées depuis zéro, données de démonstration) | réussi |
| Build APK de debug | réussi dans Docker ; **échoue sur l'hôte** (JDK) |
| Parcours sur émulateur Android (APK de debug) | inscription avec code reçu par e-mail local, choix de la langue, session et brouillon conservés après mise à jour de l'app, compteur de phrases, envoi sans clé Claude (message « rien n'est débité »), déconnexion : OK. Non rejoués à la main : suppression de compte, correction réussie (couverts par les tests). |
| Rendu du brand kit sur émulateur | écran Journal, écran de connexion, icône dans le tiroir d'applications : conformes. Mode sombre et iOS non contrôlés visuellement. |
| Écrans Inc-3 à Inc-5 sur émulateur (APK construit dans Docker, Supabase local) | conformes : Réviser avec carte Exercices, séance d'exercices corrigée par le serveur (bonne réponse et choix faux marqués d'une icône), Historique limité puis complet avec Premium, écran d'offres depuis une phrase à reformuler en gratuit, trois reformulations en Premium (faux Claude). Données temporaires retirées ensuite. |
| Écrans Inc-6 sur émulateur (APK Docker, Supabase local, Premium simulé) | conformes : série sur le Journal, écran Progrès gratuit puis Premium, ajout d'une langue et changement par la puce (brouillon gardé par langue), demande du micro à la première dictée et refus expliqué, PDF généré et proposé au partage, aperçu lisible (accents, tableau, pagination). Deux défauts trouvés et corrigés : semaines sans journal absentes du graphique (axe trompeur), langue des journaux comptés non précisée. Dictée acceptée et lecture à voix haute : non essayées (pas de micro). Données de test retirées. |


## Reste à faire sur les incréments livrés

- Liens vers les textes légaux sur l'écran d'inscription : avec les textes, en Inc-9.
- Achat réel impossible tant que l'app n'est pas reliée à RevenueCat (Inc-4b) : l'écran
  d'offres affiche « abonnements pas encore disponibles ».
- Historique et vocabulaire chargés en une fois : la pagination viendra avec
  l'historique complet de Premium (Inc-4).
- Message de limite du jour : texte neutre pour l'instant (« reviens demain ») ; la
  proposition Premium, les crédits et la vidéo s'y ajoutent en Inc-4, 7 et 8.
- L'écran Journal ne se rafraîchit pas seul au passage de minuit : rouvrir l'app.
- Correction, reformulation et génération d'exercices avec le vrai modèle : jamais
  exécutées (pas de clé API). La qualité des exercices et des corrections avancées
  reste à relire.
- Exercices : 3 exercices de plus par vidéo récompensée (US-14) avec Inc-8 ; les
  résultats d'exercices n'entrent pas dans les statistiques (non demandé par US-16).
- Dictée et lecture à voix haute : vérifiées par des tests avec un service vocal
  simulé ; jamais essayées sur un téléphone (voir `docs/manual-tasks.md`).
- Langues : un abonnement qui expire pendant que l'app est ouverte n'en réduit le
  nombre qu'au prochain démarrage ; le serveur, lui, applique la limite tout de suite.
- Reformulations : une phrase de plus de 500 caractères est refusée par le serveur
  avec un message générique.
- CI GitHub Actions : verte sur le dernier commit poussé (analyse, tests, base) ; rouge
  sur le commit intermédiaire `f046a68`, qui contenait le début d'Inc-5 sans sa
  doublure de test. Le build Android n'est pas dans la CI (Inc-9).
- Icône iOS générée mais jamais vue sur un appareil ; visuels des stores à produire depuis
  `design/app_icon_1024.png` (Inc-9).
- Mode sombre dérivé du brand kit : à faire valider.
- Inc-0 à Inc-5 sont commités et poussés sur GitHub par l'utilisateur ; Inc-6 attend
  son commit.

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

- 2026-11-19 — Inc-6 livré : plusieurs langues selon l'offre (3 ou 4 en Premium,
  langue du journal au choix, rien d'effacé à la fin d'un abonnement), série de
  jours sur le Journal et écran Progrès (détails en Premium), dictée et lecture à
  voix haute par les services du système, export PDF des révisions partagé par le
  système. Permission Internet ajoutée au manifeste principal (absente hors debug).
  Clé API retirée de l'historique Git avant le premier push. ADR-025 à 027.
- 2026-11-19 — Inc-5 livré : corrections avancées pour les abonnés (Claude Sonnet 5.5,
  fautes classées par catégorie), reformulation d'une phrase en trois registres
  depuis l'écran de correction (offres présentées sans abonnement), exercices à
  choix multiple depuis l'onglet Réviser (3 par jour en gratuit, 20 en Premium sur
  l'erreur la plus fréquente), réserve d'exercices partagée et corrigée par le
  serveur. ADR-023, ADR-024.
- 2026-11-19 — Inc-4 livré : abonnements et limites par offre en base, fonction
  `revenuecat-webhook`, écran d'offres (annuel mis en avant, essai, conditions),
  proposition Premium à la limite du jour, dans l'historique et le profil, jamais avant
  la première correction. Défaut Riverpod trouvé et contourné (ADR-022). Build Docker :
  le NDK était retéléchargé à chaque fois, désormais conservé (volume `android_sdk`).
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
