# État du projet — PROJECT_STATE

> Mis à jour par Claude à la fin de chaque phase / incrément. Permet de **reprendre** le
> travail à tout moment, même dans une nouvelle session. Toujours lire ce fichier avant d'agir.

## Snapshot

- **Phase courante** : 4 — Implémentation
- **Dernière mise à jour** : 2026-11-20
- **Santé** : 🟢 bonne
- **Prochaine action** : Inc-9 en cours (feu vert du 2026-11-19). Fait : suivi du coût
  de l'IA et de la rétention, textes légaux dans l'app, historique par pages, tests
  d'accessibilité, signalement des contenus IA, build de publication vérifié, CI Android,
  configuration iOS, fiches et déclarations des stores, image de présentation, tests
  d'intégration relancés (52). Demande du 2026-11-20 : **interface entièrement refaite**
  d'après la maquette validée, carte du jour comprise (ADR-038), à essayer sur le téléphone avec un APK
  « profile » (`build/app/outputs/flutter-apk/`). Sans compte, l'app s'ouvre sur
  l'accueil de la maquette. Captures des stores refaites avec la nouvelle interface, en
  français et en anglais (ADR-039). Inc-9 est terminé pour tout ce qui ne dépend pas
  des comptes des stores.
  En attente côté utilisateur : comptes stores, RevenueCat (Inc-4b) et AdMob, clé API
  Anthropic, textes légaux à compléter (voir `docs/manual-tasks.md`).
- **Règle de l'utilisateur (2026-11-19)** : rien n'est signé sur ce PC ; clé d'envoi et
  builds de publication sur un autre ordinateur (ADR-036).
- **Mode** : PLAN_PUIS_VALIDATION (plan validé le 2026-11-19, valeurs par défaut retenues).
  Règle fixée par l'utilisateur le 2026-11-19 : **demander son feu vert avant de commencer
  chaque nouvel incrément** ; vérifications complètes, compilation comprise, à chaque incrément. Docker sert
  uniquement à la base Supabase locale ; Flutter s'utilise sur le poste (ADR-037).

## Avancement par phase

| Phase | État | Notes |
|-------|------|-------|
| 0 — Cadrage & intake        | ✅ fait | `docs/PLAN.md`, ADR-008 |
| 1 — Définition produit      | ✅ fait | `docs/product/user-stories.md` (24 stories) |
| 2 — Planification           | ✅ fait | `docs/risks.md`, backlog ci-dessous |
| 3 — Architecture & design   | ✅ fait | `docs/architecture.md`, `system-design.md`, `data-model.md`, `design/` |
| 4 — Implémentation          | 🔄 en cours | Inc-0 à Inc-8 livrés : jalons J1 (boucle gratuite), J2 (Premium complet) et J3 (monétisation complète) atteints ; restent Inc-1b et Inc-4b, bloqués par des comptes |
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
| Inc-7 | Achats ponctuels : crédits, accès langue, Pack Examinateur, sans publicité | US-18 à 21 | ✅ | achats réels avec Inc-4b ; sujets et notes d'examen à relire avec une clé API (ADR-028, ADR-029) |
| Inc-8 | Publicités : bannière, interstitiel, vidéo récompensée, consentement | US-22, 23 | ✅ | testé avec les publicités de démonstration de Google ; rappel de récompense simulé en local (ADR-030, ADR-031) ; vrais blocs avec le compte AdMob |
| Inc-9 | Qualité, publication, documentation, textes légaux | US-24 | ✅ | ADR-032 à 039 (refonte de l'interface et captures des stores comprises) ; mise en ligne avec les comptes des stores |

## Ce qui est vérifié (2026-11-19)

| Vérification | Résultat |
|--------------|----------|
| `flutter analyze` (hôte et conteneur) | 0 problème |
| `flutter test` (hôte) | 159 tests verts |
| `flutter test test_integration --concurrency=1` (Supabase local, fonctions de correction, d'achat, de reformulation, d'exercices, d'examen et de récompense, langues, statistiques, achats à l'unité, faux Claude) | 51 tests verts |
| `supabase test db` (RLS et fonctions) | 222 tests verts |
| Tests Deno (vérification des signatures AdMob) et `deno check` des 6 fonctions | 5 tests verts, types corrects |
| `supabase db reset` (migrations rejouées depuis zéro, données de démonstration) | réussi |
| Build APK | réussi (conteneur Flutter jusqu'au 2026-11-19, remplacé par le poste : ADR-037) |
| Parcours sur émulateur Android (APK de debug) | inscription avec code reçu par e-mail local, choix de la langue, session et brouillon conservés après mise à jour de l'app, compteur de phrases, envoi sans clé Claude (message « rien n'est débité »), déconnexion : OK. Non rejoués à la main : suppression de compte, correction réussie (couverts par les tests). |
| Rendu du brand kit sur émulateur | écran Journal, écran de connexion, icône dans le tiroir d'applications : conformes. Mode sombre et iOS non contrôlés visuellement. |
| Écrans Inc-3 à Inc-5 sur émulateur (APK construit dans Docker, Supabase local) | conformes : Réviser avec carte Exercices, séance d'exercices corrigée par le serveur (bonne réponse et choix faux marqués d'une icône), Historique limité puis complet avec Premium, écran d'offres depuis une phrase à reformuler en gratuit, trois reformulations en Premium (faux Claude). Données temporaires retirées ensuite. |
| Écrans Inc-6 sur émulateur (APK Docker, Supabase local, Premium simulé) | conformes : série sur le Journal, écran Progrès gratuit puis Premium, ajout d'une langue et changement par la puce (brouillon gardé par langue), demande du micro à la première dictée et refus expliqué, PDF généré et proposé au partage, aperçu lisible (accents, tableau, pagination). Deux défauts trouvés et corrigés : semaines sans journal absentes du graphique (axe trompeur), langue des journaux comptés non précisée. Dictée acceptée et lecture à voix haute : non essayées (pas de micro). Données de test retirées. |
| Écrans Inc-7 sur émulateur (APK Docker, Supabase local, achats simulés par le webhook, faux Claude) | conformes : carte Simulation d'examen dans Réviser, choix du niveau, sujet, compteur de mots, brouillon enregistré en base, copie notée (critères, copie corrigée, plan de révision), boutique avec les achats en cours depuis le Profil. Libellé corrigé : « les achats ne sont pas encore disponibles » (et non « les abonnements »). Achat réel impossible sans store (Inc-4b). Données de test retirées. |
| Écrans Inc-8 sur émulateur (APK Docker, publicités de démonstration de Google, faux Claude) | conformes : formulaire de consentement au premier lancement, bannière 320 × 50 en bas du Journal masquée pendant la saisie, aucune publicité sur l'écran de correction, interstitiel à sa sortie (une fois par session), vidéo récompensée depuis la carte de limite, message « récompense en attente » puis « Actualiser » après le rappel simulé en base, correction offerte utilisée puis plus de vidéo proposée ce jour-là. Deux ajustements : bannière adaptative remplacée par le format standard (trop haute) ; bouton « Actualiser » ajouté quand la confirmation tarde. Rappel réel d'AdMob impossible en local (le serveur n'est pas joignable). Compte de démonstration vieilli de 15 jours pour voir les publicités (`supabase db reset` le remet à zéro) ; données de test retirées. |


## Reste à faire sur les incréments livrés

- Liens vers les textes légaux sur l'écran d'inscription : avec les textes, en Inc-9.
- Achat réel impossible tant que l'app n'est pas reliée à RevenueCat (Inc-4b) : l'écran
  d'offres affiche « abonnements pas encore disponibles ».
- Historique et vocabulaire chargés en une fois : la pagination viendra avec
  l'historique complet de Premium (Inc-4).
- L'écran Journal ne se rafraîchit pas seul au passage de minuit : rouvrir l'app.
- Correction, reformulation et génération d'exercices avec le vrai modèle : jamais
  exécutées (pas de clé API). La qualité des exercices et des corrections avancées
  reste à relire.
- Exercices : les résultats n'entrent pas dans les statistiques (non demandé par US-16).
- Publicités : vrais blocs d'annonces, identifiant d'app AdMob, message de consentement
  et adresse du rappel de récompense à configurer avec le compte AdMob
  (`docs/manual-tasks.md`). iOS : demande de suivi (ATT) et liste SKAdNetwork non
  faites (Inc-9, ADR-030).
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
- Inc-0 à Inc-6 sont commités par l'utilisateur ; Inc-7 et Inc-8 attendent leur commit.

## Décisions ouvertes / questions à l'utilisateur

- [ ] Confirmer l'identifiant d'application avant publication (ADR-010).

## Blocages

- Aucun côté utilisateur : il compile sur son poste avec les commandes Flutter habituelles.
  Dans la session de Claude seulement, Gradle échoue (`Unable to establish loopback
  connection`) : à relancer hors du bac à sable de la session plutôt que dans Docker.

## Environnement constaté

- Windows 11, Flutter 3.41.7 (Dart 3.11.5), Git 2.54, Supabase CLI 2.121, Docker 29.9.3.
- Supabase local sur les ports 5532x (ADR-011) ; un autre projet local (`flirt-coach`)
  occupe 5432x et n'a pas été touché.
- Émulateur Android `emulator-5554` (API 35).

## Tâches manuelles utilisateur en attente

- voir `docs/manual-tasks.md`

## Journal de session (résumé court, le plus récent en haut)

- 2026-11-19 — Inc-8 livré : publicités pour les comptes gratuits de plus de 14 jours
  seulement (décidé par le serveur), consentement par le SDK Google, bannière standard
  en bas du Journal hors saisie, interstitiel à la sortie d'une correction une fois par
  session, vidéo récompensée (1 correction ou 3 exercices par jour) accordée par le
  rappel signé d'AdMob, jamais par l'app. Vérifié sur émulateur avec les publicités de
  démonstration ; bannière passée au format standard et bouton « Actualiser » ajouté
  après cet essai. ADR-030, ADR-031.
- 2026-11-19 — Inc-7 livré : boutique d'achats à l'unité (10 ou 50 corrections, accès
  à une langue 30 jours, Pack Examinateur, sans publicité), crédits utilisés une fois
  la correction du jour faite, achats crédités par la notification du store et repris
  au remboursement, simulation d'examen notée avec plan de révision. Défaut trouvé par
  les tests : un accès langue racheté verrouillait à son expiration la langue de
  l'utilisateur ; corrigé. ADR-028, ADR-029.
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
