# User stories — Journal de Langue

> Phase 1 (Product Owner). Source : `INTAKE.md`, `docs/PLAN.md`, ADR-008.
> Priorité MoSCoW : **M** indispensable · **S** important · **C** souhaitable.
> « Refusé par le serveur » signifie que la règle est appliquée côté serveur, pas seulement masquée dans l'app.

## Personas

- **Léa, débutante** : écrit 3 à 5 phrases le soir sur son téléphone, connexion variable.
  Veut comprendre ses fautes sans jargon. Utilise la version gratuite.
- **Marc, intermédiaire** : prépare un examen ou un départ à l'étranger. Écrit plus long,
  veut registre, reformulations, exercices ciblés et suivi. Prêt à payer.
- **Sofia, occasionnelle** : besoin ponctuel (voyage). Refuse l'abonnement, achète un pack.

## Règles transverses

- **Hors ligne** : la rédaction fonctionne sans réseau et le brouillon est conservé sur
  l'appareil. Soumettre, acheter et consulter une correction non encore chargée exigent le
  réseau ; l'app l'indique et propose de réessayer, sans perte du texte.
- **Permissions** : micro et reconnaissance vocale, demandées à la première dictée
  seulement. Aucune autre permission sensible.
- **Jour** : un « jour » est le jour civil dans le fuseau horaire de l'utilisateur.
- **Phrase** : segment terminé par `.`, `!`, `?` ou une fin de texte ; comptée par le serveur.

## Stories

### Compte et langues (Inc-1)

**US-01 (M, S)** — En tant que nouvel utilisateur, je veux créer un compte (e-mail, Google
ou Apple) afin de retrouver mes journaux sur tout appareil.
- Given un e-mail valide et un mot de passe de 8 caractères ou plus, When je m'inscris,
  Then mon compte est créé et j'arrive au choix de la langue.
- Given des identifiants erronés, When je me connecte, Then un message clair s'affiche sans
  révéler si l'e-mail existe.

**US-02 (M, S)** — En tant qu'utilisateur, je veux choisir la langue que j'apprends afin
d'écrire mon journal dans cette langue.
- Given un compte gratuit, When je choisis une langue, Then elle devient ma seule langue active.
- Given un compte gratuit avec une langue active, When j'en choisis une autre, Then elle
  remplace la précédente (une seule à la fois) et l'historique de l'ancienne est conservé.
- Given l'onboarding terminé, Then j'arrive sur l'écran de rédaction sans voir d'offre payante.

**US-03 (M, S)** — En tant qu'utilisateur, je veux supprimer mon compte et mes données
depuis l'app afin d'exercer mes droits.
- Given une confirmation explicite, When je supprime mon compte, Then mes journaux,
  corrections, vocabulaire et profil sont effacés et je suis déconnecté.

**US-04 (S, M)** — En tant qu'abonné, je veux pratiquer plusieurs langues afin de
progresser en parallèle.
- Given Premium hebdo ou mensuel, Then je peux activer jusqu'à 3 langues ; annuel, les 4.
- Given un accès « langue 30 jours » acheté, Then cette langue s'ajoute jusqu'à expiration.
- Given une limite atteinte, When j'ajoute une langue, Then le serveur refuse et l'app
  présente les offres.

### Journal et correction (Inc-2)

**US-05 (M, M)** — En tant qu'apprenant, je veux rédiger mon journal du jour afin de pratiquer.
- Given l'écran de rédaction, When j'écris, Then le nombre de phrases et la limite de mon
  offre sont affichés ; le brouillon est sauvegardé localement.
- Given un compte gratuit, When je dépasse 7 phrases, Then l'envoi est bloqué avec explication.

**US-06 (M, L)** — En tant qu'apprenant, je veux soumettre mon texte afin d'obtenir une
correction de base.
- Given un texte valide, When je soumets, Then je vois sous 15 s la version corrigée, les
  fautes repérées et une explication brève par faute, dans la langue de l'interface.
- Given un texte sans faute, Then l'app le dit et félicite.
- Given un échec réseau ou IA, Then aucun quota ni crédit n'est consommé et je peux réessayer.
- Given un texte vide, hors langue cible ou dépassant la limite, Then le serveur refuse avec
  un motif exploitable.

**US-07 (M, M)** — En tant qu'utilisateur gratuit, je veux connaître ma limite afin de
savoir quand revenir.
- Given ma correction gratuite du jour utilisée, When je tente un 2e journal, Then le
  serveur refuse et l'app affiche « Tu as utilisé ta correction gratuite du jour. Continue
  ta série avec Premium. » avec les options : attendre demain, Premium, crédits, vidéo.
- Given des crédits achetés ou une correction gagnée par vidéo, Then la correction est
  autorisée et débitée dans l'ordre : quota gratuit, crédits, bonus vidéo.

### Vocabulaire et historique (Inc-3)

**US-08 (M, M)** — En tant qu'apprenant, je veux des mots ou expressions à réviser issus de
mon texte afin d'enrichir mon vocabulaire.
- Given une correction terminée, Then jusqu'à 5 éléments sont proposés avec traduction et
  exemple, rattachés au journal.
- Given un compte gratuit, Then pas plus de 5 éléments par jour au total.
- When je marque un élément « appris », Then il compte dans mes mots appris.

**US-09 (M, S)** — En tant qu'utilisateur, je veux relire mes journaux et corrections passés.
- Given un compte gratuit, Then je vois les journaux des 4 derniers jours ; les plus anciens
  sont conservés mais verrouillés, avec invitation Premium.
- Given Premium, Then tout l'historique est accessible, filtrable par langue.

### Premium (Inc-4)

**US-10 (M, L)** — En tant qu'utilisateur, je veux comparer les offres afin de choisir.
- Given l'écran d'offres, Then chaque abonnement affiche prix réel, période, durée de
  l'essai, renouvellement automatique et modalités d'annulation ; l'ordre est annuel
  (mis en avant), mensuel, hebdomadaire.
- Given une première ouverture, Then l'écran d'offres n'apparaît pas avant une première
  correction terminée.

**US-11 (M, L)** — En tant qu'utilisateur, je veux m'abonner avec un essai de 3 jours.
- Given un achat validé par le store, Then mes droits Premium sont actifs côté serveur en
  moins d'une minute et les limites gratuites disparaissent.
- Given un abonnement expiré ou remboursé, Then je repasse en gratuit sans perte de données.
- When je touche « Restaurer mes achats », Then mes droits sont rétablis.

### IA Premium (Inc-5)

**US-12 (S, L)** — En tant qu'abonné, je veux une correction avancée (grammaire,
conjugaison, registre, formulation naturelle, explications détaillées).
- Given Premium, Then chaque faute est classée par catégorie avec explication détaillée.
- Given un compte gratuit, Then le serveur ne renvoie que la correction de base.

**US-13 (S, M)** — En tant qu'abonné, je veux reformuler une phrase en version polie,
familière ou professionnelle.
- Given une phrase de mon journal, When je demande une reformulation, Then les 3 variantes
  s'affichent. Gratuit : refusé par le serveur, offres présentées.

**US-14 (S, L)** — En tant qu'apprenant, je veux des exercices afin de travailler mes
points faibles.
- Given Premium, Then les exercices ciblent mes catégories d'erreurs les plus fréquentes.
- Given un compte gratuit, Then 3 exercices génériques par jour (plus 3 par vidéo récompensée).
- When je réponds, Then je vois immédiatement le résultat et l'explication.
- Given un exercice déjà généré pour une même erreur et langue, Then il est servi depuis le cache.

### Voix, statistiques, export (Inc-6)

**US-15 (S, M)** — En tant qu'abonné, je veux dicter mon journal et écouter la version corrigée.
- Given la permission micro accordée, When je dicte, Then le texte s'insère dans le journal.
- Given la permission refusée, Then l'app explique et reste utilisable au clavier.
- Given la langue indisponible sur l'appareil, Then la fonction est masquée.

**US-16 (S, M)** — En tant qu'abonné, je veux voir mes statistiques.
- Then j'y trouve : mots appris, erreurs fréquentes par catégorie, série de jours, évolution
  du taux d'erreurs par phrase. La série de jours est visible aussi en gratuit (elle motive
  le message de l'US-07).

**US-17 (C, S)** — En tant qu'abonné, je veux exporter mes révisions en PDF.
- When j'exporte, Then un PDF (vocabulaire et corrections de la période choisie) est généré
  sur l'appareil et partageable.

### Achats ponctuels (Inc-7)

**US-18 (S, L)** — En tant qu'utilisateur sans abonnement, je veux acheter 10 ou 50 corrections.
- Given un achat validé, Then mon solde augmente d'autant ; une correction réussie débite
  exactement 1 crédit, jamais deux pour la même soumission.
- Given un solde nul, Then l'app propose de racheter.

**US-19 (C, M)** — En tant qu'utilisateur, je veux débloquer une langue pour 30 jours.
- Given l'achat, Then la langue est active 30 jours puis se verrouille ; ses journaux restent.

**US-20 (C, L)** — En tant que candidat, je veux une simulation d'examen.
- Given un Pack Examinateur acheté, When je lance la simulation, Then je reçois un sujet,
  je rédige, puis j'obtiens une correction renforcée notée et un plan de révision. Un pack
  donne une simulation ; une simulation interrompue reste disponible.

**US-21 (C, S)** — En tant qu'utilisateur gratuit, je veux supprimer les publicités par un
achat unique, restaurable.

### Publicités (Inc-8)

**US-22 (S, M)** — En tant qu'utilisateur gratuit, je veux des publicités discrètes.
- Then bannière en bas de l'accueil uniquement hors saisie ; interstitiel au plus une fois
  par session, à la sortie d'une correction, jamais pendant sa lecture.
- Then aucune publicité : pendant la saisie, la correction, une révision, pour Premium ou
  « sans publicité », ni durant les 14 jours suivant l'inscription.
- Given le consentement requis par la région, Then il est demandé avant toute publicité.

**US-23 (S, M)** — En tant qu'utilisateur gratuit, je veux regarder une vidéo pour obtenir
1 correction ou 3 exercices.
- Given la vidéo vue en entier, Then la récompense est créditée côté serveur ; plafond de
  1 correction et 3 exercices bonus par jour.

### Suivi (Inc-9)

**US-24 (S, S)** — En tant qu'éditeur, je veux mesurer le coût IA par utilisateur actif et
la rétention à 7 jours.
- Then chaque appel IA enregistre modèle, tokens et fonction ; des vues SQL donnent le coût
  par utilisateur et la rétention.

## Couverture des exigences (§11 de l'INTAKE)

| § | Exigence | Stories |
|---|----------|---------|
| 1 | Journal quotidien | US-02, US-05 |
| 2 | Correction intelligente | US-06, US-12 |
| 3 | Explications | US-06, US-12 |
| 4 | Reformulations | US-13 |
| 5 | Vocabulaire quotidien | US-08 |
| 6 | Exercices personnalisés | US-14 |
| 7 | Dictée et lecture | US-15 |
| 8 | Statistiques | US-16 |
| 9 | Historique | US-09 |
| 10 | Export PDF | US-17 |
| 11 | Une ou plusieurs langues | US-02, US-04 |
| 12 | Abonnements | US-10, US-11 |
| 13 | Essai gratuit | US-11 |
| 14 | Packs de corrections | US-18 |
| 15 | Accès temporaire à une langue | US-19 |
| 16 | Pack Examinateur | US-20 |
| 17 | Publicités | US-22, US-23 |
| 18 | Suppression des publicités | US-21 |
| §6 | Parcours et paywall différé | US-07, US-10 |
| §8.3 | Maîtrise des coûts | US-05, US-07, US-14, US-24 |
| §10 | Conformité | US-03, US-10, US-22 |

## MVP et suite

- **MVP (jalon J1)** : US-01 à US-09.
- **Lancement phase 1 (J2)** : + US-10 à US-17.
- **Phase 2 (J3)** : + US-18 à US-23.
- **Phase 3 (J4)** : + US-24, publication.
