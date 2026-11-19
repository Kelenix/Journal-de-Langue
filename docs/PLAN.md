# Plan de réalisation — Journal de Langue

> Livrable de la phase 0 (cadrage). Statut : **en attente de validation**.
> Source : `INTAKE.md`. Décisions : `DECISION_LOG.md`. Avancement : `PROJECT_STATE.md`.

## 1. Compréhension du besoin

**Objectif.** Application mobile où l'utilisateur écrit chaque jour un journal dans la langue
qu'il apprend (anglais, espagnol, allemand, français). Claude corrige, explique, propose du
vocabulaire et des exercices ciblés sur ses erreurs. Modèle freemium : abonnement Premium,
achats ponctuels, publicité discrète.

**Périmètre (les 18 points du §11 de l'INTAKE, tous livrés).**
Journal quotidien · correction IA · explications · reformulations · vocabulaire du jour ·
exercices personnalisés · dictée et lecture à voix haute · statistiques · historique ·
export PDF · multi-langues selon l'offre · abonnements hebdo/mensuel/annuel · essai gratuit ·
packs de corrections · accès langue 30 jours · Pack Examinateur · publicités · suppression
des publicités.

**Hors périmètre (non demandé, donc non livré).**
Version web ou tablette dédiée · mode hors-ligne pour la correction (l'IA exige le réseau) ·
fonctions sociales, classements, partage · notifications push de rappel · autres langues
que les 4 citées · back-office d'administration (le suivi se fait via les tableaux de bord
Supabase, RevenueCat et AdMob).

**Plateformes.** Android et iOS, téléphones, portrait. Le poste de développement est sous
Windows : le build Android est vérifiable localement, le build iOS ne l'est pas (voir
question Q3).

### Contradictions relevées dans l'INTAKE

| Sujet | Valeur A | Valeur B | Retenu par défaut |
|-------|----------|----------|-------------------|
| Phrases par journal gratuit | 10 (§2.1) | 7 (§3.1, §7) | **7** |
| Historique gratuit | 7 jours (§2.8) | 4 jours (§3.1, §7) | **4 jours** |
| Durée de l'essai | 3 ou 7 jours (§3.2) | 3 jours (§9) | **3 jours** |
| Périmètre v1 | lancement en 3 phases (§9) | 18 fonctions en v1 (§11) | tout est construit, livré dans l'ordre des phases du §9 |

### Hypothèses comblant les vides

| # | Hypothèse | Pourquoi |
|---|-----------|----------|
| H1 | Compte obligatoire (e-mail + mot de passe, Google, Apple). Pas de mode invité. | Un quota gratuit lié à un compte anonyme se contourne en réinstallant l'app, ce qui fait payer l'IA sans limite. |
| H2 | Interface en français et en anglais ; les explications de l'IA sont dans la langue de l'interface. | Un francophone apprend l'anglais, mais l'app propose aussi le français comme langue cible. |
| H3 | Premium hebdo et mensuel : 3 langues. Premium annuel : les 4. | L'INTAKE ne chiffre que le mensuel. |
| H4 | Plafonds Premium « équitables » : 40 phrases par journal, 30 corrections par jour. | « Illimité » sans plafond technique rend le coût IA incontrôlable (§8.2). |
| H5 | Exercices en gratuit : 3 par jour, génériques. Premium : personnalisés sur les erreurs récurrentes. | L'INTAKE dit « limités » sans chiffre. |
| H6 | Ordre de consommation : quota gratuit du jour, puis crédits achetés, puis correction offerte par vidéo. | Non précisé. |
| H7 | Aucune publicité pendant les 14 jours suivant l'inscription de chaque utilisateur. | Lecture par utilisateur du §9, applicable après le lancement. |
| H8 | Application destinée aux 16 ans et plus, non dirigée vers les enfants. | Évite le régime « Families » des stores et le consentement parental RGPD. |
| H9 | Suppression de compte et des données depuis l'app. | Exigé par Apple et Google, et par le RGPD. |
| H10 | Les prix ne sont pas dans le code : ils sont saisis dans les stores et affichés tels que renvoyés par eux. | Obligation des stores ; permet de les ajuster sans nouvelle version. |

## 2. Architecture cible (résumé, détaillée en phase 3)

- **App** : Flutter, Riverpod, go_router, freezed. Découpage par fonctionnalité
  (`journal`, `correction`, `vocabulary`, `exercises`, `stats`, `billing`, `ads`, `auth`),
  chacune en couches présentation / domaine / données. Logique hors des widgets.
- **Backend** : Supabase (Postgres, Auth, RLS sur toutes les tables).
- **IA** : l'app n'appelle jamais Anthropic directement. Des Edge Functions Supabase
  détiennent la clé, vérifient l'offre et les quotas, appellent Claude, enregistrent le
  résultat et le coût en tokens. Modèle économique pour la correction de base, modèle
  supérieur pour les corrections avancées, reformulations et examens. Cache des exercices.
- **Quotas et droits** : calculés et appliqués côté serveur uniquement. L'app ne fait
  qu'afficher.
- **Achats** : RevenueCat au-dessus de Google Play Billing et StoreKit ; un webhook met à
  jour les droits et les crédits dans Supabase (voir Q1).
- **Publicité** : AdMob avec recueil du consentement (UMP).
- **Voix** : reconnaissance et synthèse vocales du système (gratuit, sans coût IA).
- **PDF** : généré sur l'appareil.
- **Environnement de développement : Docker** (demande utilisateur du 2026-11-19, ADR-007).
  Le backend complet (Postgres, Auth, Edge Functions) tourne en local dans Docker via
  `supabase start`. Un conteneur Flutter, à version figée, exécute `flutter analyze`, les
  tests et le build Android ; la CI utilise la même image. Seul le lancement de l'app sur
  émulateur ou téléphone se fait depuis l'hôte, un conteneur n'ayant pas accès à l'écran
  ni à l'USB sous Windows.
- **Suivi (§9 phase 3)** : coût API par utilisateur et rétention à 7 jours par requêtes SQL
  sur Supabase ; conversion et annulations dans RevenueCat ; avis dans les consoles des
  stores. Aucun SDK d'analytics supplémentaire.

## 3. Incréments verticaux (ordonnés)

| ID | Incrément | Exigences (§11) | Taille | Critères d'acceptation |
|----|-----------|-----------------|--------|------------------------|
| Inc-0 | Socle : projet Flutter, thème, navigation, environnement Docker (Supabase local + conteneur Flutter), lint, CI | — | M | Une commande documentée démarre le backend dans Docker ; `flutter analyze` et tests verts dans le conteneur et en CI ; l'app démarre sur Android |
| Inc-1 | Compte et onboarding : inscription, connexion, choix de la langue, suppression de compte | 1, 11 | M | Un nouvel utilisateur arrive sur l'écran de rédaction sans voir d'offre payante ; RLS testée |
| Inc-2 | Journal et correction de base | 1, 2, 3 | L | Texte soumis, corrigé et expliqué ; 2e journal du jour et 8e phrase refusés par le serveur |
| Inc-3 | Vocabulaire du jour et historique | 5, 9 | M | 5 mots proposés après correction ; historique limité à 4 jours en gratuit |
| Inc-4 | Premium : écran d'offres, 3 abonnements, essai 3 jours, restauration | 12, 13 | L | Achat en bac à sable débloque Premium côté serveur ; prix, durée, renouvellement et annulation affichés ; l'écran n'apparaît qu'après la limite atteinte |
| Inc-5 | IA Premium : corrections avancées, reformulations, exercices personnalisés | 2, 4, 6 | L | Refusées en gratuit par le serveur ; exercices issus des erreurs récurrentes ; cache actif |
| Inc-6 | Voix, statistiques, export PDF, multi-langues | 7, 8, 10, 11 | L | Dictée et lecture dans les 4 langues ; série de jours exacte ; PDF lisible |
| Inc-7 | Achats ponctuels : crédits 10 et 50, langue 30 jours, Pack Examinateur, sans publicité | 14, 15, 16, 18 | L | Un crédit débité par correction, jamais deux fois ; accès langue expiré au 31e jour |
| Inc-8 | Publicités : bannière, interstitiel, vidéo récompensée | 17 | M | Aucune publicité en saisie, correction, révision, Premium, ni les 14 premiers jours ; 1 interstitiel par session au plus |
| Inc-9 | Qualité, performance, publication, documentation | — | L | Build `.aab` de release ; fiches stores ; docs et tâches manuelles complètes |

Jalons démontrables : **J1** après Inc-3 (boucle gratuite complète), **J2** après Inc-6
(Premium complet, correspond à la phase 1 du lancement), **J3** après Inc-8 (phase 2),
**J4** après Inc-9 (publiable).

## 4. Séquence des phases et rôles

0 Cadrage (ce document) → 1 Produit (user stories, critères) → 2 Planification (backlog,
risques) → 3 Architecture, modèle de données, design → 4 Implémentation Inc-0 à Inc-8
(backend, Flutter, état, sécurité en continu) → 5 Qualité et performance → 6 Publication →
7 Documentation → 8 Maintenance. QA et revue de code à chaque incrément.

## 5. Risques et parades

| Risque | Prob. × impact | Parade |
|--------|----------------|--------|
| Coût IA supérieur aux revenus | Moyenne × fort | Quotas serveur, plafonds Premium (H4), modèle économique par défaut, cache, table de coût par utilisateur |
| Refus des stores (abonnements, essai, publicité) | Moyenne × fort | Écran d'offres conforme au §10.1, restauration des achats, suppression de compte, consentement publicitaire |
| Triche sur les quotas ou les crédits | Moyenne × moyen | Tout est décidé côté serveur ; débit de crédit atomique ; compte obligatoire |
| Sortie de Claude mal formée | Faible × moyen | Sortie structurée validée par schéma ; en cas d'échec, pas de débit de quota ni de crédit |
| Build iOS impossible sous Windows | Certaine × moyen | Voir Q3 |
| Achats non testables sans comptes développeur | Certaine × moyen | Inc-4 démarre seulement quand les comptes existent ; Inc-0 à Inc-3 n'en dépendent pas |
| Qualité inégale de la voix selon l'appareil | Moyenne × faible | Fonction masquée si la langue n'est pas disponible sur l'appareil |

## 6. Tâches manuelles

Voir `docs/manual-tasks.md`.

## 7. Questions ouvertes

Chaque question a une valeur par défaut, appliquée sans réponse.

**Q1 — Achats intégrés : RevenueCat ou intégration directe ? (financier)**
RevenueCat gère abonnements, essais, crédits et validation serveur pour les deux stores.
Gratuit jusqu'à 2 500 $ de revenus suivis par mois, puis 1 % (tarif à confirmer sur leur
site au moment de créer le compte). L'alternative, l'intégration directe, est gratuite
mais demande d'écrire et de maintenir la validation des reçus Apple et Google.
*Recommandation et défaut : RevenueCat.*

**Q2 — Pack Examinateur : que donne un achat à 7,99 € ? (métier, financier)**
(a) Une simulation complète : examen, correction renforcée, plan de révision. Rachetable.
(b) Un accès permanent et illimité : coût IA sans plafond pour un paiement unique.
(c) Un accès de 30 jours avec plafond de simulations.
*Recommandation et défaut : (a).*

**Q3 — iOS : quand et comment ? (financier, planning)**
Compiler pour iOS exige macOS. (a) Android d'abord, code compatible iOS, build iOS ensuite
par GitHub Actions sur machine macOS (gratuit sur dépôt public, minutes payantes au-delà
du quota sur dépôt privé). (b) Tu disposes d'un Mac et les deux avancent ensemble.
*Recommandation et défaut : (a).*

**Q4 — Contradictions et prix.** Confirmes-tu 7 phrases, 4 jours d'historique, essai de
3 jours ? Prix proposés, à saisir dans les stores : hebdo 2,99 €, mensuel 4,99 €, annuel
29,99 €, sans publicité 2,99 €. *Défaut : ces valeurs.*

**Q5 — Textes légaux. (légal)** Politique de confidentialité et conditions d'utilisation
sont obligatoires pour publier. Les journaux sont envoyés à Anthropic pour correction, ce
qui doit y figurer. Je peux rédiger des modèles ; leur validation juridique et le nom de
l'éditeur (toi ou une société) restent à ta charge. *Défaut : je rédige les modèles.*
