# Journal de décisions (DECISION_LOG)

> ADR léger. Chaque décision structurante prise par Claude **en autonomie** y est consignée :
> contexte → décision → alternatives écartées → conséquences. Le plus récent en haut.

---

## ADR-039 — Captures des stores rendues par l'app

- **Date** : 2026-11-20
- **Statut** : Accepté
- **Décideur** : Claude (rôle : playstore-appstore-engineer), à la demande de l'utilisateur
- **Contexte** : les fiches demandent des captures en français et en anglais, à refaire
  après la refonte. Les prendre sur l'émulateur demande un build et un émulateur à côté
  de Docker : sur ce PC de 16 Go, cette combinaison a déjà fait tomber Docker Desktop
  (2026-11-19), et un vrai compte ne montre pas toutes les fonctions.
- **Décision** : `tool/store_captures_test.dart` lance l'app complète sur des données en
  mémoire (abonné Premium, journal, correction avancée, vocabulaire, statistiques et
  simulation d'examen d'exemple), avec les polices de l'app et les vraies ombres, et
  enregistre cinq écrans par langue (1080 × 2400). `tool/generate_store_visuals.py` les
  met en page sous une légende, dans un contour de téléphone. Le fichier est hors de
  `test/` : il ne fait partie ni de la suite de tests ni de la CI.
- **Alternatives écartées** : captures sur l'émulateur (mémoire, barres du système à
  retirer, données à préparer à la main) ; maquettes dessinées (ne montreraient pas
  l'app réelle).
- **Conséquences** : captures reproductibles en deux commandes (README) ; pas de barre
  d'état du téléphone sur les captures.
- **Impact** : technique (réversible).

## ADR-038 — Refonte de l'interface d'après une maquette validée

- **Date** : 2026-11-20
- **Statut** : Accepté
- **Décideur** : Utilisateur (demande et validation de la maquette), Claude (exécution)
- **Contexte** : l'utilisateur juge l'interface « pas du tout moderne » et demande de la
  refaire entièrement. Une maquette de six écrans (accueil, Journal, Correction, Réviser,
  Progrès, Profil) lui a été présentée et validée.
- **Décision** : (1) Nouveau langage visuel, toujours sur le brand kit : aplats vert
  profond pour les contenus mis en avant, cartes blanches aux grands arrondis et à
  l'ombre douce, barre d'onglets flottante, boutons ronds, titres plus grands
  (`docs/design/design-system.md`). (2) Composants partagés (`SoftCard`, `HeroCard`,
  `TabAppBar`, `SoftAppBar`, `IconBadge`, `Tag`, `SettingsGroup`…) pour que chaque écran
  garde le même dessin. (3) `get_stats` renvoie aussi les jours écrits de la semaine en
  cours (migration `20261121120000_stats_week_days.sql`), pour l'en-tête du Journal.
  (4) Le Profil affiche l'e-mail du compte (`AuthRepository.currentEmail`).
- **Carte du jour** (ajoutée à la demande de l'utilisateur) : paquet des 5 premiers mots
  à réviser, fixé à son ouverture et gardé tant que l'app est ouverte, sans nouvelle
  donnée serveur ; « Je sais » enregistre le mot comme appris (même enregistrement que
  la liste), « À revoir » passe au suivant.
- **Accueil** (à la demande de l'utilisateur) : première page sans compte, comme sur
  la maquette (logo, signature, ce que l'app apporte, « Créer mon compte » et « J'ai
  déjà un compte ») ; la déconnexion y ramène. Connexion et inscription se remplacent
  l'une l'autre, le retour ramène à l'accueil. Le logo de l'app passe sur un vert plus
  foncé pour se détacher de l'aplat.
- **Écarts avec la maquette** : le graphique de Progrès montre les fautes par phrase (donnée
  existante) au lieu des journaux par semaine ; le contenu s'arrête au-dessus de la barre
  d'onglets au lieu de passer dessous, pour qu'aucun bouton ne soit caché.
- **Alternatives écartées** : retouches du thème seul (n'aurait pas changé la structure
  des écrans) ; bibliothèque de composants externe (dépendance pour peu de gain).
- **Conséquences** : textes et parcours inchangés ; quelques tests adaptés au nouveau
  découpage des textes (série, achats possédés). Un rendu des écrans en images a servi de
  contrôle visuel et révélé deux défauts corrigés (cartes et pastilles invisibles).
- **Impact** : fonctionnel mineur (réversible).

## ADR-037 — Docker uniquement pour la base locale ; Flutter sur le poste

- **Date** : 2026-11-20
- **Statut** : Accepté ; remplace ADR-007 pour tout ce qui touche à Flutter
- **Décideur** : Utilisateur (précision de sa demande)
- **Contexte** : ADR-007 avait interprété « développer avec Docker » au sens large :
  conteneur Flutter pour l'analyse, les tests et la compilation. L'utilisateur précise
  qu'il voulait Docker seulement pour la base de données. L'échec de Gradle qui
  justifiait la compilation en conteneur n'a été constaté que dans la session de Claude.
- **Décision** : Docker ne sert qu'à Supabase local (`supabase start`). Analyse, tests,
  génération de code et compilation se font sur le poste avec les commandes Flutter
  habituelles ; un APK de test est un APK unique valable pour tous les téléphones
  (`flutter build apk`, sans découpage par processeur). Le conteneur Flutter
  (`docker-compose.yml`) est supprimé ; la CI garde l'image Flutter 3.41.7.
- **Alternatives écartées** : garder le conteneur en parallèle (deux façons de compiler,
  source de confusion).
- **Conséquences** : rechargement à chaud disponible ; les volumes Docker du conteneur
  (`journaldelangue_*`) peuvent être supprimés.
- **Impact** : technique (réversible).

## ADR-036 — Build de publication : signature hors dépôt, identifiant AdMob exigé, CI Android

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : release-manager, playstore-appstore-engineer)
- **Contexte** : Inc-9 doit produire un `.aab` de publication. La clé de signature et les
  vrais identifiants AdMob n'existent pas encore ; le build Android se fait dans Docker.
- **Décision** : (1) La clé d'envoi est lue dans `android/key.properties` (ignoré par Git,
  comme les `.jks`) ; sans ce fichier, la version de publication est signée avec la clé
  de debug, installable pour un essai mais refusée par Google Play. (2) Un build de
  publication sans `-PADMOB_APP_ID` échoue au lieu d'embarquer l'identifiant de
  démonstration. (3) La CI construit l'app bundle de publication à chaque envoi (clé de
  debug, identifiants de démonstration) pour détecter tôt un échec de R8. (4) Gradle est
  limité à 3 Go : avec les 8 Go par défaut de Flutter, le build de publication a fait
  tomber Docker Desktop (8 Go pour Supabase et le build). (5) Décision de l'éditeur :
  aucune signature sur le poste de développement ; clé d'envoi et builds de publication
  sur un autre ordinateur. Les APK de test (mode profile) gardent la clé de test de Flutter.
- **Alternatives écartées** : clé dans les secrets de la CI dès maintenant (rien à signer
  tant que le compte Play n'existe pas) ; Fastlane avant l'existence des comptes (non
  vérifiable).
- **Conséquences** : déploiement automatique vers les canaux de test à ajouter avec le
  compte Play (Fastlane `supply`) ; un build iOS demande un Mac (question Q3).
- **Impact** : technique (réversible).

## ADR-035 — Historique par pages, vocabulaire et export lus par lots

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : performance-engineer, backend-engineer)
- **Contexte** : mesuré sur un compte local d'un an d'usage Premium (730 journaux,
  3 650 mots, `docs/performance.md`) : l'historique complet (2,1 Mo) était chargé à chaque
  ouverture de l'app pour savoir s'il existait un journal corrigé ; l'API ne rend que
  1 000 lignes par requête, donc 2 650 mots n'apparaissaient jamais et l'export « tout »
  aurait été tronqué au-delà de 1 000 journaux.
- **Décision** : (1) `get_history_overview` compte les journaux corrigés : l'app sait
  sans rien charger si elle peut proposer les offres. (2) L'historique se lit par pages de
  20 (40 Ko), sans le vocabulaire ; la suivante se charge en fin de liste, avec
  « Réessayer » en cas d'échec. (3) Vocabulaire et export lisent tout, par lots de 500 et
  200 lignes, dans un ordre stable ; les listes sont construites à la demande.
- **Alternatives écartées** : pagination du vocabulaire (les mots à réviser passent
  avant les mots appris : l'ordre changerait sous les pages ; 3 650 mots pèsent 600 Ko) ;
  relever la limite de l'API (le problème revient plus loin).
- **Conséquences** : les mots appris et à réviser restent comptés sur la liste complète.
- **Impact** : technique (réversible).

## ADR-034 — Signalement des contenus produits par l'IA

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : playstore-appstore-engineer, security-engineer)
- **Contexte** : Google Play exige des apps qui génèrent du contenu par IA un moyen de
  signaler un contenu choquant sans quitter l'app, et l'usage de ces signalements.
- **Décision** : un drapeau sur la correction, l'exercice et la simulation d'examen ouvre
  un commentaire facultatif (500 caractères) ; `report_ai_content` vérifie que le
  contenu existe et appartient à l'utilisateur (un exercice est partagé), limite à 20
  signalements par jour et enregistre `ai_content_reports`, lisible avec le rôle service
  seulement. Les reformulations, affichées depuis la correction, se signalent avec elle.
- **Alternatives écartées** : lien `mailto:` (quitte l'app) ; signalement anonyme sans
  vérification du contenu (inexploitable).
- **Conséquences** : relire les signalements dans le tableau de bord Supabase
  (`docs/manual-tasks.md`) ; mention ajoutée à la politique de confidentialité.
- **Impact** : fonctionnel et légal (réversible).

## ADR-033 — Textes légaux livrés avec l'app

- **Date** : 2026-11-19
- **Statut** : Accepté, **à faire relire par un juriste**
- **Décideur** : Claude (rôle : documentation-pro) ; validation par l'utilisateur
- **Contexte** : les stores exigent une politique de confidentialité et, pour les
  abonnements, des conditions d'utilisation accessibles dans l'app et en ligne.
- **Décision** : (1) Les textes français et anglais sont des fichiers Markdown simples
  (`assets/legal/`) affichés par l'app (Profil, inscription, écran d'offres), lisibles
  sans compte ; les mêmes fichiers seront publiés à une adresse publique. (2) Hypothèses
  posées par défaut, réversibles avant publication : app réservée aux 16 ans et plus
  (public cible Play hors enfants, pas d'accord parental) ; base de données Supabase dans
  l'Union européenne ; droit français et médiateur de la consommation. (3) Les champs
  propres à l'éditeur restent marqués `[À COMPLÉTER : …]` ; la checklist de publication
  vérifie qu'il n'en reste aucun.
- **Alternatives écartées** : textes seulement en ligne (dépendance à un site, pas de
  lecture hors connexion) ; un paquet de rendu Markdown (une dépendance pour 4 textes).
- **Conséquences** : une modification des textes demande une nouvelle version de l'app ;
  les durées de conservation des comptes inactifs restent à décider avec le juriste.
- **Impact** : légal (réversible).

## ADR-032 — Suivi : vues SQL du coût de l'IA et de la rétention

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : backend-engineer, database-architect)
- **Contexte** : US-24 et ADR-006 : coût de l'IA par utilisateur actif et rétention à
  7 jours, sans SDK d'analytics.
- **Décision** : `ai_model_prices` donne le prix public de chaque modèle (Haiku 5.5 :
  0,10 $ / 0,50 $ par million de tokens ; Sonnet 5.5 : 2 $ / 10 $) ;
  `v_ai_cost_per_user` (par mois) et `v_ai_cost_per_month` (coût par utilisateur actif)
  en découlent ; un modèle sans prix est compté à part, jamais pour zéro.
  `v_retention_d7` : part des inscrits d'une semaine qui ont écrit un journal ou fait un
  exercice le 7e jour (UTC). Lecture réservée au rôle service.
- **Alternatives écartées** : prix codés dans les vues (une migration à chaque
  changement) ; rétention « au moins une activité entre J7 et J13 » (moins comparable).
- **Conséquences** : mettre à jour `ai_model_prices` quand un prix ou un modèle change.
  Conversion et annulations restent dans RevenueCat, les avis dans les consoles.
- **Impact** : technique (réversible).

## ADR-031 — Vidéo récompensée : accordée par le rappel signé d'AdMob

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : backend-engineer, security-engineer)
- **Contexte** : US-23 : une vidéo vue en entier rapporte 1 correction ou 3 exercices,
  au plus une fois de chaque par jour. Comme pour les achats (ADR-021, ADR-029), l'app
  ne doit pas pouvoir s'attribuer une récompense.
- **Décision** : (1) Seul le rappel de vérification côté serveur d'AdMob (SSV) accorde
  la récompense. La fonction `admob-reward` vérifie sa signature ECDSA avec les clés
  publiées par Google (rechargées une fois si la clé est inconnue), n'accepte que les
  blocs de l'app (`ADMOB_REWARDED_AD_UNITS`) et lit l'utilisateur et la récompense que
  l'app a joints à la vidéo (`user_id`, `custom_data`). (2) `grant_ad_reward` garde
  chaque récompense par son `transaction_id` (rappel rejoué : sans effet), une seule de
  chaque sorte par jour UTC (index unique), et ignore les utilisateurs qui ne voient pas
  de publicités. (3) Ordre d'utilisation : quota de l'offre, puis crédits achetés, puis
  correction offerte ; celle-ci est retenue par la correction en cours et débitée à sa
  réussite (comme un crédit, ADR-029). Les exercices offerts s'ajoutent à la limite du
  jour. (4) Dans l'app : après la vidéo, l'app interroge le serveur pendant 10 s ; si la
  confirmation tarde, elle le dit et propose « Actualiser ».
- **Alternatives écartées** : se fier au signal de l'app (`onUserEarnedReward`), qu'un
  client modifié peut simuler ; plafond appliqué dans l'app.
- **Conséquences** : le plafond suit le jour UTC, pas le jour local du quota. Une
  récompense non utilisée reste acquise, comme un crédit. En local, AdMob ne peut pas
  joindre la fonction : la vidéo de démonstration se termine sur « récompense en
  attente » (vérifié sur émulateur, rappel simulé en base). Sans
  `ADMOB_REWARDED_AD_UNITS`, une autre app AdMob pourrait viser l'adresse : à renseigner
  avant publication (`docs/manual-tasks.md`).
- **Impact** : financier (réversible).

## ADR-030 — Publicités : éligibilité côté serveur, emplacements discrets, consentement

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : product-manager, mobile-architect, security-engineer)
- **Contexte** : INTAKE §5 : bannière discrète, interstitiel après une correction au plus
  une fois par session, vidéo récompensée ; aucune publicité pendant la saisie, la
  correction ou une révision, ni pour Premium, ni après l'achat « sans publicité », ni
  pendant les 14 premiers jours (H7). Le consentement est exigé dans l'UE.
- **Décision** : (1) Le serveur décide qui voit des publicités (`ads_enabled` : offre
  gratuite, pas d'achat « sans publicité », compte de plus de 14 jours) et l'app le lit
  par `get_ad_status`. (2) Emplacements : bannière standard 320 × 50 en bas du Journal,
  seulement champ vide et clavier fermé, et sous la carte de limite du jour ;
  interstitiel à la sortie d'une correction, au plus un par session de l'app ; rien dans
  la correction, la révision, les exercices, l'examen, la boutique ou le profil.
  (3) Consentement par le SDK Google UMP au lancement, formulaire là où la loi l'exige ;
  aucune publicité tant qu'il ne le permet pas ; le Profil permet de revoir ses choix
  quand c'est requis. (4) Blocs d'annonces passés au build (`ADMOB_BANNER_ID`,
  `ADMOB_INTERSTITIAL_ID`, `ADMOB_REWARDED_ID` en `--dart-define`) : en debug, sans
  valeur, ceux de démonstration de Google ; en version publiée, un bloc absent n'est
  jamais affiché. Identifiant d'app AdMob : `-PADMOB_APP_ID` (Android) et
  `GADApplicationIdentifier` (iOS), valeurs de démonstration en attendant le compte.
- **Alternatives écartées** : bannière adaptative (nettement plus haute à l'essai sur
  émulateur) ; règle des 14 jours dans l'app (contournable et dépendante de l'heure du
  téléphone) ; formats natifs, plus intrusifs dans un écran d'apprentissage.
- **Conséquences** : le SDK ajoute une WebView et, sur Android, la permission
  d'identifiant publicitaire (`AD_ID`) à déclarer dans la fiche Play. iOS : sans demande
  ATT, les publicités ne sont pas personnalisées ; liste SKAdNetwork de Google à ajouter
  avant publication (Inc-9). La bannière apparaît une à deux secondes après l'écran
  (chargement réseau), sans décaler la saisie.
- **Impact** : fonctionnel et financier (réversible).

## ADR-029 — Achats à l'unité : portefeuille côté serveur, repris au remboursement

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : backend-engineer, security-engineer)
- **Contexte** : INTAKE §4 et §5.3 : packs de 10 et 50 corrections, accès à une langue
  pendant 30 jours, Pack Examinateur, sans publicité. Comme pour les abonnements
  (ADR-021), l'app ne doit jamais pouvoir s'attribuer un achat.
- **Décision** : (1) La notification RevenueCat `NON_RENEWING_PURCHASE` crédite un
  portefeuille en base (`wallets`, `language_passes`) ; chaque achat est gardé par son
  `transaction_id` (`one_time_purchases`) : reçu deux fois, il ne compte qu'une fois ;
  remboursé (`CANCELLATION` pour `CUSTOMER_SUPPORT`), il est repris, sans descendre sous
  zéro si les crédits sont déjà utilisés. (2) Un crédit prend le relais du quota du jour
  une fois celui-ci épuisé (hypothèse H6) ; il est retenu par la correction en cours et
  débité seulement si elle aboutit : exactement un crédit par correction réussie, jamais
  deux pour un même envoi rejoué. (3) Un produit par langue pour l'accès de 30 jours
  (`language_pass_en`, `_es`, `_de`, `_fr`) : le store ne transmet que l'identifiant du
  produit. La langue débloquée s'ajoute à la limite de l'offre et se verrouille au
  31e jour ; une langue ouverte seulement par un accès ne prend jamais la place de la
  langue choisie par l'utilisateur. Un nouvel achat prolonge l'accès. (4) La boutique
  n'est proposée qu'après une première correction, comme les abonnements.
- **Alternatives écartées** : débiter le crédit à la réservation (il faudrait le rendre
  à chaque échec ou abandon) ; un seul produit « accès langue » avec la langue choisie
  avant l'achat (rien ne relie ce choix à la notification du store).
- **Conséquences** : 8 produits à créer à l'identique dans les stores
  (`docs/manual-tasks.md`). Le transfert d'achats entre comptes (`TRANSFER`) n'est pas
  traité : à voir avec le SDK RevenueCat (Inc-4b). Les crédits n'expirent pas.
- **Impact** : financier et fonctionnel (réversible).

## ADR-028 — Simulation d'examen : un pack, un sujet, une copie notée

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : utilisateur pour « un pack = une simulation » (ADR-008, Q2) ; Claude
  pour le reste
- **Contexte** : US-20 : un sujet, une rédaction, une correction renforcée notée et un
  plan de révision ; une simulation interrompue reste disponible.
- **Décision** : l'utilisateur choisit le niveau visé (A2, B1, B2 ou C1) ; la fonction
  `exam` utilise un pack, demande à Claude un sujet de production écrite dans la langue
  apprise, au format des examens officiels, puis corrige la copie : note sur 20, quatre
  critères sur 5 (tâche, cohérence, vocabulaire, grammaire), niveau estimé, copie
  corrigée, fautes expliquées dans la langue de l'interface et plan de révision en 3 à
  5 étapes. Modèle supérieur (`EXAM_MODEL`, Claude Sonnet 5.5 par défaut) : c'est la
  « correction renforcée ». Une seule simulation ouverte à la fois ; son brouillon est
  enregistré en base pendant la saisie et la retrouve sur tout appareil. Si le sujet ne
  peut pas être créé, le pack est rendu ; si la correction échoue, la copie est gardée et
  peut être renvoyée. Les notes et critères hors bornes renvoyés par le modèle sont
  ramenés dans leurs bornes.
- **Alternatives écartées** : niveau imposé (moins utile à un candidat) ; brouillon
  gardé seulement sur l'appareil (perdu en changeant de téléphone, et un effacement de
  plus à gérer à la suppression du compte).
- **Conséquences** : coût d'une simulation : deux appels au modèle supérieur, couverts
  par le prix du pack (7,99 €). Qualité des sujets et des notes à relire avec une clé
  API.
- **Impact** : fonctionnel et financier (réversible).

## ADR-027 — Voix et export PDF : paquets, permissions, contrainte de version

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : flutter-engineer, security-engineer)
- **Contexte** : ADR-005 retient la voix et le PDF sur l'appareil. Il faut des paquets,
  des permissions et une façon de remettre le PDF à l'utilisateur.
- **Décision** : `speech_to_text` (reconnaissance du système) et `flutter_tts`
  (synthèse du système) derrière une interface `VoiceService` ; `pdf` pour créer le
  document avec les polices de l'app embarquées, `share_plus` pour le remettre par la
  feuille de partage du système (enregistrer, envoyer, imprimer), sans écrire de
  fichier nous-mêmes. Permissions Android : `RECORD_AUDIO`, demandée à la première
  dictée seulement ; les permissions Bluetooth suggérées par le paquet ne sont pas
  déclarées (inutiles sans casque Bluetooth, permissions minimales). iOS : raisons du
  micro et de la reconnaissance vocale dans `Info.plist`. Le paquet `image`, dépendance
  de `pdf`, est contraint sous 4.11 : la 4.11 appelle une fonction d'`archive` 4.1 que
  `pdf` 3.12 refuse ; `pdf` 3.13 lèvera la contrainte mais demande Dart 3.12.
- **Constat lié** : la permission Internet n'était déclarée que pour les versions debug
  et profile ; une version publiée n'aurait pas joint Supabase. Elle est maintenant
  dans le manifeste principal.
- **Alternatives écartées** : services vocaux cloud (coût par usage, ADR-005) ;
  `printing` pour l'export (moteur d'impression natif plus lourd, inutile pour un
  partage) ; `dependency_overrides` (masque les conflits au lieu de les borner).
- **Conséquences** : qualité de la dictée et des voix variable selon l'appareil ; la
  dictée est masquée si l'appareil ne reconnaît pas la langue. Dictée et lecture ne
  sont pas testables sur un émulateur sans micro : à vérifier sur un téléphone.
- **Impact** : technique (réversible).

## ADR-026 — Statistiques calculées en base, série visible par tous

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : backend-engineer, product-owner)
- **Contexte** : US-16 réserve les statistiques à Premium mais rend la série visible en
  gratuit. L'historique gratuit est limité à 4 jours par la RLS : l'app ne peut pas
  compter seule une série plus longue.
- **Décision** : une fonction `get_stats(langue, date)` calcule en base : série (jours
  consécutifs avec un journal corrigé, toutes langues confondues, jusqu'à aujourd'hui
  ou hier, pour ne pas la perdre avant la fin de la journée), nombre de journaux de la
  langue, et pour Premium seulement : mots appris, fautes par type, fautes par phrase
  semaine par semaine sur 8 semaines. Une date d'appareil invraisemblable est remplacée
  par celle du serveur. L'écran présente la série en chiffre principal, les fautes par
  type en barres classées et les 8 dernières semaines en colonnes, une par semaine,
  vides comprises, pour que l'axe du temps reste régulier ; chaque valeur est donnée
  au toucher et dans une liste « Voir le détail ».
- **Alternatives écartées** : calcul dans l'app (impossible au-delà de 4 jours en
  gratuit) ; table de compteurs tenue à jour (plus de code, risque d'écart).
- **Conséquences** : un appel léger par ouverture de l'écran Progrès ou du Journal ; la
  série reste juste même si l'utilisateur change de langue.
- **Impact** : fonctionnel (réversible).

## ADR-025 — Plusieurs langues : langues « utilisables » selon l'offre

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : database-architect, product-owner)
- **Contexte** : INTAKE §11 : une langue en gratuit, 3 en Premium hebdomadaire ou
  mensuel, 4 en annuel. À la fin d'un abonnement, rien ne doit être perdu, mais les
  langues en trop ne doivent plus servir.
- **Décision** : la limite `max_languages` s'ajoute aux limites de l'offre. Les langues
  utilisables sont les langues actives les plus récemment choisies, dans cette limite ;
  la plus récente est la langue du journal. Choisir une langue déjà active en fait la
  langue en cours, sans rien retirer. En gratuit, choisir une langue remplace la
  précédente, comme avant. Correction et exercices exigent une langue utilisable (la
  fonction d'exercices ne vérifiait pas la langue : corrigé). Les langues sont relues
  après un achat, pas à chaque changement d'offre, pour ne pas renvoyer la navigation
  vers l'écran de démarrage pendant le rechargement.
- **Alternatives écartées** : désactiver les langues en trop à l'expiration (aucun
  événement fiable à l'instant de l'expiration, et perte de la liste au réabonnement) ;
  langue en cours gardée sur l'appareil (différente d'un appareil à l'autre).
- **Conséquences** : un ancien abonné garde ses journaux et son vocabulaire dans toutes
  ses langues, et pratique la dernière choisie. Les achats « langue 30 jours » (Inc-7)
  s'ajouteront à cette limite.
- **Impact** : fonctionnel (réversible).

## ADR-024 — Exercices : réserve partagée, corrigés par le serveur

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : backend-engineer, flutter-engineer)
- **Contexte** : Générer des exercices à chaque demande coûterait un appel à Claude par
  séance et ferait attendre l'utilisateur (INTAKE §9 : mettre en cache les exercices
  répétitifs). Envoyer la bonne réponse à l'app permettrait de la lire avant de répondre.
- **Décision** : (1) Les exercices sont des questions à 4 choix, rangées dans une réserve
  **partagée** par langue apprise, type d'erreur et langue d'interface. Claude n'est
  appelé (8 questions par appel) que si l'utilisateur a épuisé les questions qu'il n'a
  jamais faites et que la réserve compte moins de 60 questions ; au-delà, les anciennes
  questions sont resservies. (2) La bonne réponse et l'explication restent en base ;
  l'app les reçoit de `answer_exercise` après avoir répondu. C'est cette réponse qui
  consomme la limite du jour (3 en gratuit, 20 en Premium), pas l'affichage.
  (3) Gratuit : le type d'erreur change chaque jour ; Premium : le type le plus fréquent
  dans les corrections de l'utilisateur pour cette langue. (4) Une reformulation est
  enregistrée par journal et par phrase : la redemander ne rappelle pas Claude et ne
  consomme rien (limite : 30 nouvelles reformulations par jour).
- **Alternatives écartées** : Exercices générés par utilisateur (coût et attente à
  chaque séance) ; correction faite dans l'app (réponse lisible, limite contournable).
- **Conséquences** : Coût d'exercices quasi nul une fois la réserve constituée. Les
  questions ne citent pas les phrases de l'utilisateur : la personnalisation porte sur
  le type d'erreur. Qualité des questions à relire avec le vrai modèle. La vidéo
  récompensée (3 exercices de plus) viendra avec Inc-8.
- **Impact** : fonctionnel et financier modéré (réversible).

## ADR-023 — Modèles de l'IA Premium

- **Date** : 2026-11-19
- **Statut** : Accepté (modèle des corrections avancées choisi par l'utilisateur)
- **Décideur** : utilisateur pour le modèle avancé ; Claude pour le reste
- **Contexte** : Premium promet des corrections plus fines (registre, formulation
  naturelle, explications détaillées), des reformulations et des exercices. Le choix du
  modèle fixe à la fois la qualité et le coût par abonné.
- **Décision** : Corrections avancées avec **Claude Sonnet 5.5** (choix de
  l'utilisateur) ; correction de base, reformulations et génération d'exercices avec
  Claude Haiku 5.5. Chaque modèle se change sans redéployer l'app, par une variable
  d'environnement des fonctions (`CORRECTION_MODEL`, `ADVANCED_CORRECTION_MODEL`,
  `REWRITE_MODEL`, `EXERCISE_MODEL`). Si le modèle refuse un texte, la fonction ne
  bascule pas vers un autre modèle : l'utilisateur est informé que ce texte ne peut pas
  être traité, et rien n'est décompté.
- **Alternatives écartées** : Haiku partout (qualité Premium peu différenciée) ; Opus
  pour les corrections avancées (coût par abonné trop élevé pour le prix visé).
- **Conséquences** : Coût d'une correction Premium plus élevé que celui d'une correction
  gratuite, borné par 30 corrections et 40 phrases par jour ; à mesurer dans `ai_usage`
  (US-24) avant de fixer les prix définitifs. Aucune correction réelle n'a encore été
  exécutée (pas de clé API).
- **Impact** : financier (réversible par configuration).

## ADR-022 — Pas de provider dérivé d'un provider rechargé à la demande

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : state-management-engineer)
- **Contexte** : Riverpod 3 met en pause les abonnements des écrans masqués (onglet
  inactif, écran recouvert) et les reprend pendant la reconstruction. Avec
  flutter_riverpod 3.3.2, si un provider invalidé entre-temps est observé par un autre
  provider, cette reprise lève « setState() called during build » en mode debug. La
  version 3.5.0 n'est pas installable avec Flutter 3.41.7.
- **Décision** : (1) Un provider observé par d'autres est relu **tout de suite** après
  son invalidation (`await ref.read(provider.future)`), jamais laissé « à recalculer ».
  (2) Les valeurs dérivées d'un provider rechargé à la demande sont des fonctions
  appelées par les écrans (`watchActiveSubscription`, `watchHasCorrectedJournal`), pas
  des providers.
- **Alternatives écartées** : Monter de version (impossible aujourd'hui) ; désactiver
  la mise en pause (perte d'économie d'énergie et comportement non standard).
- **Conséquences** : Règle à respecter dans les incréments suivants ; couverte par
  `test/tab_refresh_regression_test.dart`. À revoir quand Flutter permettra Riverpod 3.5.
- **Impact** : technique (réversible).

## ADR-021 — Abonnements : droits côté serveur maintenant, SDK RevenueCat ensuite (Inc-4b)

- **Date** : 2026-11-19
- **Statut** : Accepté (périmètre annoncé à l'utilisateur avant de commencer)
- **Décideur** : Claude (rôles : backend-engineer, flutter-engineer)
- **Contexte** : Un achat réel exige les comptes Google Play et RevenueCat, qui
  n'existent pas encore. Le SDK RevenueCat ne peut pas être vérifié sans eux.
- **Décision** : Inc-4 livre tout ce qui ne dépend pas des comptes :
  - table `subscriptions`, limites selon l'offre appliquées en base, fonction
    `revenuecat-webhook` (secret partagé, notification rejouée ou en retard gérée,
    remboursement, expiration), testés avec des notifications au format documenté par
    RevenueCat ;
  - écran d'offres, points d'entrée, profil, derrière l'interface `BillingRepository`,
    testés avec un faux store.
  L'adaptateur `purchases_flutter` est l'incrément **Inc-4b**, à faire quand les comptes
  et les produits existent. D'ici là l'app utilise `UnavailableBillingRepository` : l'écran
  d'offres affiche « les abonnements ne sont pas encore disponibles ».
- **Identifiants de produits** attendus par le serveur : `premium_weekly`,
  `premium_monthly`, `premium_annual`.
- **Limites Premium** (hypothèse H4) : 40 phrases et 6000 caractères par journal,
  30 corrections par jour, vocabulaire et historique sans limite.
- **Écran d'offres** : il ne cite que les avantages déjà livrés (journaux illimités, plus
  longs, historique complet). Corrections avancées, reformulations, exercices, voix,
  statistiques, PDF et multi-langues s'y ajouteront avec leurs incréments.
- **Points ouverts** : « Journaux illimités » est le terme de l'INTAKE alors qu'un
  plafond de 30 par jour existe : à mentionner dans les conditions d'utilisation (Inc-9).
  Les transferts d'achat entre comptes (notification `TRANSFER`) ne sont pas traités.
  Les liens vers les textes légaux sur l'écran d'offres arrivent avec ces textes (Inc-9).
- **Impact** : métier, financier, technique.

## ADR-020 — Vocabulaire et historique (Inc-3)

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôles : database-architect, backend-engineer)
- **Contexte** : US-08 (5 mots à réviser par jour) et US-09 (historique de 4 jours en
  gratuit, journaux plus anciens conservés mais verrouillés).
- **Décision** :
  - Le vocabulaire est demandé à Claude **dans le même appel** que la correction : aucun
    coût d'appel supplémentaire.
  - La limite de 5 mots par jour et l'absence de doublon (par utilisateur et par langue)
    sont appliquées en base, dans `complete_correction`.
  - La fenêtre de 4 jours est une règle RLS : un journal plus ancien reste en base mais
    l'app ne peut pas le lire, même en modifiant le client. La fenêtre est calculée sur
    le fuseau le plus en retard, donc jamais moins de 4 jours pour personne.
  - Le vocabulaire reste lisible quel que soit l'âge du journal d'origine.
  - L'app ne peut modifier que l'état « appris » d'un mot (droit limité à cette colonne).
  - `supabase/seed.sql` crée un compte de démonstration local pour tester sans clé API.
- **Alternatives écartées** : Second appel à Claude pour le vocabulaire (coût doublé) ;
  masquer les vieux journaux dans l'app seulement (contournable).
- **Conséquences** : Les tests d'intégration partagent le port du faux Claude et se
  lancent un fichier à la fois (`--concurrency=1`).
- **Impact** : métier, sécurité, financier (aucun surcoût IA).

## ADR-019 — Application du brand kit

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Utilisateur (brand kit fourni) ; arbitrages d'application par Claude
- **Contexte** : L'utilisateur a fourni le brand kit en cours de projet : palette vert
  profond / ivoire / corail, DM Sans et Inter, cartes arrondies, ton bienveillant, concept
  de logo (carnet ouvert + bulle de dialogue). La direction visuelle choisie par Claude en
  phase 3 est remplacée.
- **Décision** :
  - Palette, formes, typographie et microtextes du brand kit appliqués dans
    `lib/core/theme/` et `lib/l10n/` (`docs/design/design-system.md`).
  - Polices téléchargées depuis github.com/google/fonts avec l'accord de l'utilisateur et
    **embarquées** (pas de chargement à l'exécution, donc aucun appel à Google depuis
    l'appareil).
  - Accessibilité : le corail n'est jamais utilisé pour du texte (contraste 1,8 sur
    ivoire) ; le petit texte secondaire utilise un gris plus foncé que celui du brand kit
    (5,1 au lieu de 3,5).
  - Icône et logo : première exécution du concept, générée par
    `tool/generate_app_icons.py` ; à remplacer par le logo définitif.
  - Mode sombre dérivé de la palette, le brand kit n'en définissant pas.
- **Écarts assumés** : l'aperçu du brand kit mentionne « 10 phrases maximum » ; la limite
  validée reste 7 (ADR-008). Pas d'écran d'accueil intermédiaire avec « Écrire mon
  journal » : l'onglet Journal ouvre la rédaction.
- **Impact** : métier (image de marque), technique (réversible : tout est centralisé).

## ADR-018 — Tests de la correction avec un faux serveur Claude

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : qa-engineer)
- **Contexte** : Aucune clé API Anthropic n'est disponible ; même avec une clé, des tests
  automatiques ne doivent ni coûter de l'argent ni dépendre des réponses du modèle.
- **Décision** : Les tests d'intégration lancent un faux serveur de l'API Anthropic ; la
  fonction `correct-entry` y est dirigée par `ANTHROPIC_BASE_URL` (variable lue nativement
  par le SDK), définie dans `supabase/functions/.env.test`. Le reste de la chaîne est réel :
  app, fonction, SDK Anthropic, base.
- **Alternatives écartées** : Appeler la vraie API dans les tests (coût, non déterminisme) ;
  ne tester que des doublures (la chaîne réelle ne serait pas exercée).
- **Conséquences** : La chaîne technique est vérifiée, **pas la qualité des corrections**
  du vrai modèle : à relire à la main dès qu'une clé existe (tâche manuelle).
- **Impact** : technique (réversible).

## ADR-017 — Brouillon du journal dans le stockage sécurisé

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : security-engineer)
- **Contexte** : Le brouillon doit survivre hors ligne et à la fermeture de l'app. Un
  journal est un texte personnel.
- **Décision** : Brouillon chiffré dans le Keystore / Keychain (`flutter_secure_storage`,
  déjà présent), un par compte et par langue ; effacé après correction et à la
  suppression du compte.
- **Alternatives écartées** : `shared_preferences` (texte personnel en clair, dépendance
  de plus) ; base locale (disproportionné pour un seul texte).
- **Impact** : sécurité, technique (réversible).

## ADR-016 — Jour civil fourni par l'appareil et contrôlé par le serveur

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : database-architect)
- **Contexte** : « Un journal par jour » s'entend dans le fuseau de l'utilisateur. Stocker
  son fuseau demandait un plugin, une colonne et une écriture de plus.
- **Décision** : L'app envoie sa date locale. Le serveur l'accepte si elle est
  « aujourd'hui » dans au moins un fuseau (UTC-12 à UTC+14) et si elle ne recule pas par
  rapport au dernier journal.
- **Alternatives écartées** : Fuseau stocké dans le profil (même possibilité de triche,
  plus de code) ; jour UTC (le quota se renouvellerait à 1 h ou 2 h du matin en France).
- **Conséquences** : Un tricheur gagne au plus une correction d'avance, une seule fois.
- **Impact** : métier (faible), technique (réversible).

## ADR-015 — Modèle Claude de la correction de base : Haiku 5.5

- **Date** : 2026-11-19
- **Statut** : Accepté (à confirmer après relecture de vraies corrections)
- **Décideur** : Claude (rôle : backend-engineer), d'après l'INTAKE §8.3
- **Contexte** : L'INTAKE demande « un modèle Claude moins coûteux pour les corrections
  simples » ; le coût IA est le premier risque du projet (R1).
- **Décision** : `claude-haiku-5-5`, effort `low`, sortie structurée validée par schéma,
  SDK officiel `@anthropic-ai/sdk`. Tarif relevé le 2026-11-03 : 0,10 $ par million de
  tokens en entrée, 0,50 $ en sortie. Le modèle se change sans redéployer l'app, par la
  variable `CORRECTION_MODEL` de la fonction.
- **Alternatives écartées** : Sonnet 5.5 (2 $ / 10 $) ou Opus 5.5 (4 $ / 20 $) : 20 à 40
  fois plus chers, réservés aux corrections avancées Premium (Inc-5) si la qualité le
  justifie.
- **Conséquences** : Ordre de grandeur d'une correction gratuite (7 phrases) : quelques
  centièmes de centime. Chaque appel est journalisé dans `ai_usage` pour le vérifier.
  Les refus de sécurité de ce modèle n'ont pas de repli automatique : la fonction les
  traite comme « texte non corrigeable », sans débit.
- **Impact** : financier (réversible par configuration).

## ADR-014 — Connexion Google et Apple livrée séparément (Inc-1b)

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : project-director)
- **Contexte** : US-01 prévoit e-mail, Google et Apple. Les deux derniers exigent des
  identifiants OAuth et un compte Apple Developer qui n'existent pas encore ; le code ne
  pourrait pas être vérifié.
- **Décision** : Inc-1 livre le compte par e-mail, testé de bout en bout. Google et Apple
  forment Inc-1b, démarré quand les identifiants sont fournis.
- **Alternatives écartées** : Écrire le code sans pouvoir le lancer (contraire à « vérifier
  avant de dire fait »).
- **Conséquences** : US-01 partiellement couverte tant qu'Inc-1b n'est pas livré. Apple
  exige la connexion Apple dès que Google est proposé sur iOS : les deux sortent ensemble.
- **Impact** : fonctionnel (réversible).

## ADR-013 — Écritures de compte par fonctions SQL, sans Edge Function

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : backend-engineer)
- **Contexte** : Activer une langue et supprimer son compte sont des écritures sous contrôle
  serveur. Le plan initial citait une Edge Function `delete-account`.
- **Décision** : Deux fonctions Postgres `security definer` appelées par RPC :
  `activate_language` et `delete_account`. La langue de l'interface n'est pas stockée : elle
  suit le téléphone et sera transmise à chaque demande de correction.
- **Alternatives écartées** : Edge Function (un service de plus pour une seule requête SQL).
- **Conséquences** : Moins de code et de déploiement ; règles testées en SQL (pgTAP).
  Les Edge Functions arrivent en Inc-2, où elles sont nécessaires (clé Anthropic).
- **Impact** : technique (réversible).

## ADR-012 — E-mail confirmé par code à 6 chiffres

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : security-engineer)
- **Contexte** : Le compte obligatoire (ADR-004) sert à protéger le quota gratuit, donc le
  coût IA. Sans vérification de l'e-mail, créer des comptes jetables reste trivial.
- **Décision** : L'inscription envoie un code à 6 chiffres, valable 15 minutes, à saisir
  dans l'app. Le mot de passe oublié suit le même mécanisme. Pas de lien à ouvrir.
- **Alternatives écartées** : Pas de confirmation (quota contournable) ; lien de
  confirmation (exige des liens profonds et casse si l'e-mail est lu sur un autre appareil) ;
  connexion sans mot de passe (s'écarte de l'hypothèse H1 validée).
- **Conséquences** : Un écran de plus à l'inscription. **En production il faut un service
  SMTP** (l'envoi intégré de Supabase est limité à quelques e-mails par heure) et reporter
  les modèles d'e-mail : tâches manuelles ajoutées.
- **Impact** : métier (friction à l'inscription), financier (service SMTP, offres gratuites
  existantes), sécurité.

## ADR-011 — Ports Supabase locaux sur la plage 5532x

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : backend-engineer)
- **Contexte** : Un autre projet Supabase local (`flirt-coach`) occupe déjà la plage par
  défaut 5432x sur ce poste ; `supabase start` échouait.
- **Décision** : Ce projet utilise 55320 à 55329 (`supabase/config.toml`). L'autre projet
  n'a pas été touché.
- **Alternatives écartées** : Arrêter l'autre projet (il n'appartient pas à ce travail).
- **Conséquences** : Les deux projets tournent en parallèle ; l'URL locale est
  `http://10.0.2.2:55321` depuis l'émulateur.
- **Impact** : technique (réversible).

## ADR-010 — Identifiant d'application `com.journaldelangue.journal_de_langue`

- **Date** : 2026-11-19
- **Statut** : Proposé (à confirmer avant la première publication)
- **Décideur** : Claude (rôle : mobile-architect)
- **Contexte** : `flutter create` exige une organisation ; aucune n'est donnée dans l'INTAKE.
- **Décision** : Organisation `com.journaldelangue`.
- **Conséquences** : Modifiable librement tant que l'app n'est pas publiée ; **définitif**
  après la première mise en ligne sur un store. Confirmation inscrite dans
  `docs/manual-tasks.md`.
- **Impact** : irréversible après publication.

## ADR-009 — Riverpod sans génération de code

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : state-management-engineer)
- **Contexte** : Le skill recommande `@riverpod` (code généré). Avec Flutter 3.41.7,
  `riverpod_generator` ne se résout pas : il exige `meta ^1.18` alors que le SDK fige
  `meta 1.17.0`.
- **Décision** : Riverpod 3 avec providers déclarés à la main (`Provider`,
  `NotifierProvider`, `AsyncNotifierProvider`).
- **Alternatives écartées** : Rétrograder Riverpod pour retrouver un générateur compatible
  (versions anciennes) ; changer de canal Flutter (moins stable).
- **Conséquences** : Un peu plus de déclarations manuelles ; une chaîne de génération en
  moins. Réversible quand le SDK Flutter aura évolué.
- **Impact** : technique (réversible).

## ADR-008 — Réponses aux questions de cadrage Q1 à Q5

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Utilisateur (« Oui, lance » : plan validé avec les valeurs par défaut)
- **Décision** :
  - Q1 : achats intégrés via **RevenueCat**.
  - Q2 : Pack Examinateur = **une simulation complète par achat**, rachetable (consommable).
  - Q3 : **Android d'abord**, code compatible iOS, build iOS ensuite par CI macOS.
  - Q4 : gratuit = **7 phrases**, **4 jours** d'historique ; essai **3 jours** ; prix à
    saisir dans les stores : 2,99 €/semaine, 4,99 €/mois, 29,99 €/an, sans publicité 2,99 €.
  - Q5 : Claude rédige des modèles de politique de confidentialité et de conditions
    d'utilisation ; validation juridique et identité de l'éditeur à la charge de l'utilisateur.
  - Hypothèses H1 à H10 de `docs/PLAN.md` acceptées.
- **Impact** : métier, financier, légal.

## ADR-007 — Développement sous Docker

- **Date** : 2026-11-19
- **Statut** : Remplacé par ADR-037 (Docker seulement pour la base locale)
- **Décideur** : Utilisateur (exigence) ; périmètre précisé par Claude (interprétation)
- **Contexte** : L'utilisateur demande que le développement utilise Docker.
- **Décision** : Backend Supabase local dans Docker (`supabase start`) ; conteneur Flutter à
  version figée pour analyse, tests et build Android, réutilisé en CI. Exécution de l'app
  sur émulateur ou appareil depuis l'hôte.
- **Alternatives écartées** : Tout sur l'hôte (non conforme à la demande) ; émulateur
  Android dans un conteneur (pas d'accélération matérielle ni d'USB fiables sous Windows).
- **Conséquences** : Environnement reproductible ; Docker Desktop doit être démarré ; le
  build iOS reste hors Docker (macOS requis).
- **Impact** : technique (réversible).

## ADR-006 — Suivi des indicateurs sans SDK d'analytics

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : project-director)
- **Contexte** : Le §9 demande conversion, rétention à 7 jours, coût API par utilisateur,
  annulations, avis négatifs.
- **Décision** : Coût API et rétention par requêtes SQL sur Supabase (table d'usage IA) ;
  conversion et annulations dans le tableau de bord des achats ; avis dans les consoles stores.
- **Alternatives écartées** : Firebase Analytics, PostHog (SDK et consentement
  supplémentaires pour des chiffres déjà disponibles).
- **Conséquences** : Moins de données personnelles collectées ; pas d'entonnoir d'écrans détaillé.
- **Impact** : technique (réversible).

## ADR-005 — Voix et PDF sur l'appareil

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : mobile-architect)
- **Contexte** : Dictée, lecture à voix haute et export PDF sont des fonctions Premium.
- **Décision** : Reconnaissance et synthèse vocales du système ; PDF généré localement.
- **Alternatives écartées** : Services vocaux cloud (coût récurrent par utilisation).
- **Conséquences** : Coût nul ; qualité dépendante de l'appareil ; permission micro demandée
  seulement à la première dictée.
- **Impact** : technique (réversible).

## ADR-004 — Compte obligatoire, pas de mode invité

- **Date** : 2026-11-19
- **Statut** : Accepté (hypothèse H1, contestable)
- **Décideur** : Claude (rôle : security-engineer)
- **Contexte** : Le quota gratuit déclenche un coût IA à chaque correction.
- **Décision** : Inscription requise (e-mail + mot de passe, Google, Apple).
- **Alternatives écartées** : Session anonyme (quota contournable par réinstallation).
- **Conséquences** : Une étape de plus avant le premier journal ; Apple Sign-In obligatoire
  dès lors que Google est proposé sur iOS.
- **Impact** : métier (modéré), sécurité.

## ADR-003 — Quotas et droits appliqués côté serveur

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : security-engineer)
- **Contexte** : Limites gratuites, crédits consommables, accès temporaires, droits Premium.
- **Décision** : Toute vérification et tout débit se font dans Postgres et les Edge
  Functions ; le débit de crédit est atomique ; l'app ne fait qu'afficher l'état.
- **Alternatives écartées** : Contrôle dans l'app (falsifiable).
- **Conséquences** : Pas de correction hors ligne ; cohérence garantie entre appareils.
- **Impact** : sécurité, financier (protège le coût IA).

## ADR-002 — Appels à Claude via Edge Functions Supabase

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : backend-engineer)
- **Contexte** : La clé Anthropic ne doit jamais se trouver dans le binaire.
- **Décision** : Edge Functions authentifiées détenant la clé ; sortie structurée validée ;
  modèle économique pour la correction de base, modèle supérieur pour les fonctions
  Premium ; journalisation des tokens par utilisateur.
- **Alternatives écartées** : Appel direct depuis l'app (clé exposée) ; serveur dédié
  (infrastructure supplémentaire sans besoin).
- **Conséquences** : Coût mesurable par utilisateur (§8.3) ; latence d'un saut réseau en plus.
- **Impact** : sécurité, financier.

## ADR-001 — Gestion d'état : Riverpod

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Décideur** : Claude (rôle : mobile-architect / state-management-engineer)
- **Contexte** : Besoin d'une gestion d'état Flutter testable, sûre et scalable.
- **Décision** : Utiliser **Riverpod** (stack par défaut du skill).
- **Alternatives écartées** : Bloc (plus verbeux), Provider seul, setState, GetX.
- **Conséquences** : État découplé de `BuildContext`, providers testables.
- **Impact** : technique (réversible avec effort).

---

## ADR-000 — Modèle d'enregistrement

- **Date** : 2026-11-19
- **Statut** : Accepté
- **Contexte** : Établit le format des décisions.
- **Décision** : Utiliser ce gabarit pour toute décision ayant un impact sur l'architecture,
  les dépendances, la sécurité, le coût ou le comportement produit.
- **Conséquences** : Traçabilité complète ; l'utilisateur peut revenir sur tout choix.

> Décisions en attente de l'utilisateur (non consignées tant qu'elles ne sont pas tranchées) :
> Q1 à Q5 de `docs/PLAN.md`.
