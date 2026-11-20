# Changelog

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) ; versions
[SemVer](https://semver.org/lang/fr/). Le numéro de build (`+N` dans `pubspec.yaml`)
augmente à chaque envoi aux stores.

## [Non publiée]

En attente pour une première soumission : achats réels (RevenueCat, Inc-4b), comptes
des stores et d'AdMob, textes légaux complétés et publiés (`docs/store/compliance-checklist.md`).

## [1.0.0] — en préparation

Première version.

### Ajouté

- Compte par e-mail avec code de confirmation, mot de passe oublié, suppression du compte.
- Journal quotidien dans la langue apprise (anglais, espagnol, allemand, français), corrigé
  par Claude : version corrigée, explication de chaque faute, mots à réviser.
- Vocabulaire à réviser, exercices à choix multiple, historique des journaux.
- Série de jours d'écriture et écran Progrès ; dictée et lecture à voix haute ; export PDF.
- Premium (hebdomadaire, mensuel, annuel, essai de 3 jours) : corrections avancées,
  reformulations, exercices ciblés, plusieurs langues, historique complet, sans publicité.
- Achats à l'unité : packs de corrections, accès à une langue pendant 30 jours, Pack
  Examinateur (simulation d'examen notée), suppression des publicités.
- Publicités discrètes pour les comptes gratuits après 14 jours, avec consentement ;
  vidéo récompensée pour une correction ou trois exercices de plus.
- Textes légaux dans l'app, signalement des contenus produits par l'IA.
- Suivi interne du coût de l'IA par utilisateur et de la rétention à 7 jours.
- Interface moderne : écran d'accueil, en-têtes sur aplat vert, cartes arrondies à l'ombre douce, barre
  d'onglets flottante, semaine d'écriture sur l'écran Journal, cartes du jour pour
  réviser ses mots, e-mail du compte dans le Profil.
- Progrès Premium : journaux écrits par semaine sur les 8 dernières semaines.
- Profil : carte de l'offre, langues, achats et confidentialité regroupés ; l'app reste
  en mode clair.
- Écrans de compte au style de l'accueil (logo et titre sur le vert, formulaire en bas) ;
  plus de bande grise sous l'app ; Profil réparti sur toute la hauteur des grands
  téléphones.

### Corrigé (phase 5, qualité et performance)

- Une coupure réseau pendant le renouvellement de la session ne bloque plus l'app sur
  l'écran d'erreur.
- L'app restée ouverte d'un jour à l'autre propose le journal du nouveau jour.
- Un envoi renvoyé pendant sa correction n'appelle plus Claude une seconde fois ; les
  textes refusés à répétition sont plafonnés par jour.
- Corrections avancées et notation d'examen : plus de temps accordé à Claude.
- Exercices offerts par une vidéo comptés correctement ; une réponse renvoyée après une
  coupure ne coûte plus un exercice.
- Examen : le dernier texte est enregistré en quittant, une copie en cours de notation
  ne se modifie plus, le résultat ne s'affiche plus vide.
- Export PDF : un long journal ne bloque plus l'export, construit sans figer l'écran.
- Dictée sur Android 13 et plus, lecture à voix haute avec plusieurs boutons, vidéo
  récompensée en échec, achats non encore lus, changement de langue raté : comportements
  corrigés.
