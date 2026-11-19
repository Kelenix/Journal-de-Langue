# **Cahier des charges fonctionnel — Journal de Langue**

## **1. Présentation du projet**

### **1.1. Concept**

**Journal de Langue** est une application mobile d'apprentissage des langues basée sur la pratique quotidienne de l'écriture et l'intelligence artificielle.

L'utilisateur rédige chaque jour un journal dans la langue qu'il souhaite apprendre. L'intelligence artificielle analyse son texte, corrige ses erreurs, fournit des explications et propose des mots ou expressions à réviser.

L'application utilise l'API Anthropic (Claude) pour les corrections, les explications et la génération d'exercices personnalisés.

### **1.2. Objectifs**

L'application a pour objectifs de :

- Encourager la pratique quotidienne d'une langue étrangère.
- Améliorer progressivement l'expression écrite.
- Aider les utilisateurs à comprendre leurs erreurs.
- Enrichir leur vocabulaire.
- Proposer des exercices adaptés aux difficultés rencontrées.
- Permettre de suivre leur progression dans l'apprentissage.

### **1.3. Positionnement**

| Élément                   | Description                                      |
| ------------------------- | ------------------------------------------------ |
| Nom                       | Journal de Langue                                |
| Type                      | Application mobile éducative avec IA             |
| Public cible              | Débutants et intermédiaires                      |
| Principe                  | Apprendre une langue en écrivant quotidiennement |
| Intelligence artificielle | API Anthropic (Claude)                           |
| Modèle économique         | Freemium + abonnement Premium                    |
| Revenus complémentaires   | Achats ponctuels et publicités optionnelles      |
| Langues proposées         | Anglais, espagnol, allemand, français            |

## **2. Fonctionnalités de l'application**

### **2.1. Journal quotidien**

L'utilisateur peut rédiger un journal dans la langue qu'il apprend.

**Fonctionnement :**

- L'utilisateur sélectionne la langue qu'il souhaite pratiquer.
- Il rédige son journal.
- Il soumet son texte pour correction.
- L'IA analyse son contenu et affiche les corrections.

**Limites :**

- Gratuit : 1 journal par jour, jusqu'à 10 phrases.
- Premium : journaux illimités.

### **2.2. Correction intelligente des textes**

L'application utilise l'intelligence artificielle pour corriger les textes rédigés.

**Corrections de base :**

- Identification des fautes.
- Affichage de la version corrigée.
- Explication brève des erreurs.

**Corrections avancées Premium :**

- Grammaire.
- Conjugaison.
- Registre de langue.
- Formulation naturelle des phrases.
- Explications détaillées.

### **2.3. Reformulation des phrases**

L'application permet d'obtenir différentes formulations d'une même phrase.

Les alternatives proposées peuvent être :

- Plus polies.
- Plus familières.
- Plus professionnelles.

Cette fonctionnalité est réservée aux utilisateurs Premium.

### **2.4. Révision du vocabulaire**

Après la correction d'un journal, l'application propose des mots ou expressions à réviser.

**Version gratuite :**

\- 5 mots ou expressions à réviser par jour.

Le vocabulaire est associé aux textes corrigés afin d'aider l'utilisateur à enrichir ses connaissances.

### **2.5. Exercices personnalisés**

L'intelligence artificielle génère des exercices à partir des erreurs identifiées dans les journaux.

**Fonctionnement :**

- Identification des erreurs récurrentes.
- Génération d'exercices adaptés.
- Proposition d'exercices pour améliorer les points faibles.

Les exercices sont limités en version gratuite et personnalisés en Premium.

### **2.6. Mode voix**

Le mode voix, réservé aux utilisateurs Premium, comprend :

- La dictée vocale.
- La lecture à voix haute.

### **2.7. Statistiques d'apprentissage**

Les utilisateurs Premium peuvent consulter leurs statistiques de progression.

**Indicateurs disponibles :**

- Nombre de mots appris.
- Erreurs fréquentes.
- Série de jours de pratique.
- Progression dans l'apprentissage.

### **2.8. Historique des journaux**

L'application conserve les journaux de l'utilisateur.

| Version  | Historique         |
| -------- | ------------------ |
| Gratuite | 7 derniers jours   |
| Premium  | Historique complet |

### **2.9. Export des révisions**

Les utilisateurs Premium peuvent exporter leurs révisions au format PDF.

### **2.10. Gestion des langues**

L'application permet de pratiquer différentes langues.

**Langues mentionnées :**

- Anglais.
- Espagnol.
- Allemand.
- Français.

**Limites selon l'offre :**

- Gratuit : une langue à la fois.
- Premium mensuel : jusqu'à 3 langues.
- Premium : possibilité de pratiquer plusieurs langues simultanément, selon les limites de l'offre.

## **3. Modèle économique**

L'application adopte un modèle **Freemium + Abonnements auto-renouvelables + Achats intégrés ponctuels**.

Les publicités constituent une source de revenus secondaire.

### **3.1. Version gratuite**

La version gratuite doit permettre de découvrir et d'utiliser l'application au quotidien.

| Fonctionnalité      | Limite gratuite                |
| ------------------- | ------------------------------ |
| Journal quotidien   | 1 par jour                     |
| Longueur du journal | 7 phrases maximum             |
| Corrections         | Corrections de base            |
| Explications        | Brèves                         |
| Vocabulaire         | 5 mots ou expressions par jour |
| Exercices           | Limités                        |
| Historique          | 4 jours                        |
| Langues             | 1 langue à la fois             |
| Publicités          | Optionnelles et discrètes      |

Une fois sa correction gratuite utilisée, l'utilisateur doit attendre le lendemain ou choisir une option payante pour continuer.

### **3.2. Abonnements Premium**

Les abonnements sont renouvelés automatiquement jusqu'à leur annulation.

Un essai gratuit de 3 ou 7 jours peut être proposé.

| Offre                | Prix indicatif     | Contenu                                                                                              |
| -------------------- | ------------------ | ---------------------------------------------------------------------------------------------------- |
| Premium hebdomadaire | 2,99 €/semaine     | Accès Premium pour une courte durée                                                                  |
| Premium mensuel      | 4,99 à 6,99 €/mois | Journaux illimités, corrections détaillées, 3 langues, historique complet et fonctionnalités Premium |
| Premium annuel       | 29,99 à 39,99 €/an | Tous les avantages Premium, tarif équivalent à environ 2,50 à 3,33 €/mois                            |

L'abonnement annuel doit être présenté comme l'offre la plus avantageuse, tout en affichant clairement les prix, les durées et les conditions de renouvellement.

### **3.3. Avantages Premium**

L'abonnement Premium donne accès aux fonctionnalités suivantes :

- Journaux illimités.
- Corrections avancées et détaillées.
- Reformulations polies, familières et professionnelles.
- Exercices personnalisés.
- Dictée et lecture à voix haute.
- Statistiques d'apprentissage.
- Historique complet.
- Export PDF des révisions.
- Pratique de plusieurs langues.

## **4. Achats intégrés ponctuels**

Les achats intégrés constituent une alternative pour les utilisateurs qui ne souhaitent pas souscrire un abonnement.

| Produit                             | Prix indicatif | Utilisation                                                   |
| ----------------------------------- | -------------- | ------------------------------------------------------------- |
| Pack de 10 corrections              | 1,99 €         | Voyage, examen ou usage occasionnel                           |
| Pack de 50 corrections              | 5,99 €         | Usage régulier sans abonnement                                |
| Accès à une langue pendant 30 jours | 2,99 €         | Déblocage temporaire d'une langue                             |
| Pack Examinateur                    | 7,99 €         | Simulation d'examen, correction renforcée et plan de révision |

### **4.1. Gestion des crédits**

Les packs de corrections fonctionnent avec un système de crédits consommables.

- Les crédits sont attribués après l'achat.
- Chaque correction utilise un crédit.
- Les crédits consommés sont déduits du solde.
- L'utilisateur peut racheter des crédits lorsqu'il n'en possède plus.

### **4.2. Accès temporaire à une langue**

L'utilisateur peut acheter l'accès à une langue spécifique pour une durée de 30 jours.

### **4.3. Pack Examinateur**

Le pack Examinateur comprend :

- Simulation d'examen.
- Correction renforcée.
- Plan de révision.

## **5. Monétisation publicitaire**

Les publicités doivent rester discrètes pour préserver l'expérience d'apprentissage.

### **5.1. Formats publicitaires**

| Format            | Fonctionnement                                                    |
| ----------------- | ----------------------------------------------------------------- |
| Bannière          | Affichée discrètement en bas de l'écran d'accueil ou du journal   |
| Interstitiel      | Après une correction, au maximum une fois par session             |
| Vidéo récompensée | Permet d'obtenir 1 correction supplémentaire ou 3 exercices bonus |

### **5.2. Restrictions publicitaires**

- Aucune publicité pendant la saisie d'un journal.
- Aucune publicité interrompant une correction.
- Aucune publicité pendant une révision.
- Aucune publicité pour les abonnés Premium.
- Pas de publicités intrusives.

Les interstitiels éventuels doivent être affichés uniquement après la fin d'une correction, et non pendant sa consultation.

### **5.3. Suppression des publicités**

Une option d'achat unique permet de supprimer les publicités.

**Supprimer les publicités**

Achat unique

## **2,99–3,99 €**

## **6. Parcours utilisateur**

Le parcours principal repose sur la rédaction quotidienne et la découverte progressive des fonctionnalités Premium.

1. **Rédaction du journal**

   L'utilisateur écrit son premier journal dans la langue qu'il souhaite apprendre.
2. **Correction par l'IA**

   Il reçoit la correction de ses phrases et des explications.
3. **Révision du vocabulaire**

   L'application lui propose 5 mots ou expressions à réviser.
4. **Atteinte de la limite quotidienne**

   L'utilisateur essaie d'écrire un deuxième journal ou demande une explication supplémentaire.
5. **Présentation de Premium**

   L'application affiche : « Tu as utilisé ta correction gratuite du jour. Continue ta série avec Premium. »
6. **Découverte des offres**

   L'utilisateur découvre les avantages Premium : corrections illimitées, voix, statistiques et historique complet.

L'écran d'abonnement ne doit pas apparaître dès la première ouverture. L'utilisateur doit d'abord pouvoir tester la correction gratuite.

## **7. Comparaison des offres**

| Fonctionnalité            | Gratuit      | Premium                      |
| ------------------------- | ------------ | ---------------------------- |
| Journal quotidien         | 1/jour       | Illimité                     |
| Nombre de phrases         | 7 maximum   | Selon les limites techniques |
| Correction de base        | Oui          | Oui                          |
| Correction avancée        | Non          | Oui                          |
| Explications détaillées   | Non          | Oui                          |
| Reformulation des phrases | Non          | Oui                          |
| Vocabulaire à réviser     | 5/jour       | Oui                          |
| Exercices personnalisés   | Non          | Oui                          |
| Mode voix                 | Non          | Oui                          |
| Statistiques              | Non          | Oui                          |
| Historique                | 4 jours      | Complet                      |
| Export PDF                | Non          | Oui                          |
| Langues simultanées       | 1            | Plusieurs                    |
| Publicités                | Optionnelles | Aucune                       |

## **8. Intelligence artificielle et gestion des coûts**

### **8.1. Utilisation de l'IA**

L'application utilise l'API Anthropic (Claude) pour :

- Corriger les journaux.
- Expliquer les erreurs.
- Reformuler les phrases.
- Générer des exercices personnalisés.
- Identifier les erreurs récurrentes.

### **8.2. Coûts de fonctionnement**

Le principal coût variable de l'application provient de l'utilisation de l'API Anthropic.

Chaque correction, explication et génération d'exercices consomme des tokens.

| Poste                             | Éléments à prendre en compte                                           |
| --------------------------------- | ---------------------------------------------------------------------- |
| Abonnement mensuel                | Revenu indicatif à partir de 4,99 €                                    |
| Commissions des stores            | Généralement de l'ordre de 15 à 30 %, selon les conditions applicables |
| Coût IA des utilisateurs gratuits | À surveiller et plafonner                                              |
| Coût IA des abonnés               | À contrôler avec des limites techniques équitables                     |
| Publicité                         | Revenus complémentaires dépendant du trafic                            |

### **8.3. Optimisation des coûts**

Les mécanismes prévus pour maîtriser les dépenses sont :

- Limiter le nombre de phrases par journal.
- Appliquer une limite quotidienne aux comptes gratuits.
- Mettre en cache les exercices répétitifs.
- Utiliser un modèle Claude moins coûteux pour les corrections simples.
- Mesurer le coût moyen de l'IA par utilisateur actif.

## **9. Stratégie de lancement**

Le lancement doit être progressif, en conservant uniquement les fonctionnalités prévues.

### **Phase 1 — Lancement initial**

- Proposer une langue cible au choix.
- Permettre un journal gratuit par jour.
- Ne pas afficher de publicité pendant les 14 premiers jours.
- Proposer un essai Premium de 3 jours.
- Mettre en avant l'abonnement annuel, puis mensuel, puis hebdomadaire.

### **Phase 2 — Monétisation complémentaire**

- Introduire les packs de crédits pour les utilisateurs souhaitant payer ponctuellement.
- Exploiter les formats publicitaires prévus, sans perturber l'apprentissage.
- Proposer les achats intégrés définis précédemment.

### **Phase 3 — Suivi des performances**

Analyser les indicateurs suivants :

- Taux de conversion vers Premium.
- Rétention des utilisateurs à 7 jours.
- Coût API par utilisateur.
- Nombre d'annulations d'abonnement.
- Avis négatifs des utilisateurs.

## **10. Règles commerciales et conformité**

### **10.1. Abonnements**

Les offres doivent présenter clairement :

- Le prix réel.
- La période de facturation.
- La durée de l'essai gratuit.
- Le renouvellement automatique.
- Les conditions d'annulation.

### **10.2. Achats intégrés**

Les packs de corrections, les accès temporaires et les abonnements doivent respecter les mécanismes de facturation applicables sur Google Play et l'App Store.

Les crédits de correction sont consommables. L'accès de 30 jours à une langue et le Pack Examinateur doivent être configurés selon leur durée et leur mode d'utilisation.

### **10.3. Références officielles**

- [Google Play — Abonnements](https://support.google.com/googleplay/android-developer/answer/140504/?utm_source=chatgpt.com)
- [Apple — Achats intégrés](https://developer.apple.com/design/human-interface-guidelines/apple-in-app-purchase/?utm_source=chatgpt.com)
- [Apple — Règles de l'App Store](https://developer.apple.com/app-store/review/guidelines/?utm_source=chatgpt.com)

## **11. Périmètre fonctionnel de la première version**

Le périmètre défini pour Journal de Langue comprend exclusivement :

1. Journal quotidien dans une langue choisie.
2. Correction intelligente des textes avec Claude.
3. Explications des erreurs.
4. Reformulations des phrases.
5. Vocabulaire quotidien à réviser.
6. Exercices personnalisés.
7. Dictée et lecture à voix haute.
8. Statistiques d'apprentissage.
9. Historique des journaux.
10. Export PDF des révisions.
11. Pratique d'une ou plusieurs langues selon l'offre.
12. Abonnements Premium hebdomadaire, mensuel et annuel.
13. Essai gratuit Premium.
14. Achats de packs de corrections.
15. Accès temporaire à une langue.
16. Pack Examinateur.
17. Publicités discrètes et récompensées.
18. Achat unique pour supprimer les publicités.

**Objectif final :** développer une application mobile d'apprentissage des langues qui encourage les utilisateurs à écrire quotidiennement, à comprendre leurs erreurs et à mesurer leur progression grâce à l'intelligence artificielle, tout en reposant sur un modèle économique durable.






