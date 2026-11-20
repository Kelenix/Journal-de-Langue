# Parcours et écrans

> Phase 3 (UI/UX). Les wireframes sont indicatifs ; les textes définitifs sont dans `lib/l10n/`.

## Parcours principal (§6 de l'INTAKE)

```mermaid
flowchart TD
  A[Première ouverture] --> B[Inscription / connexion]
  B --> C[Choix de la langue]
  C --> D[Journal : rédaction]
  D -->|Soumettre| E[Correction + explications]
  E --> F[5 mots à réviser]
  F --> D
  D -->|2e journal du jour, gratuit| G[Limite atteinte]
  G --> H[Offres Premium]
  G --> I[Utiliser un crédit / vidéo]
  G --> J[Revenir demain]
  H -->|Achat| D
```

L'écran d'offres n'est jamais montré avant qu'une première correction soit terminée.

## Onglets

`Journal` · `Historique` · `Réviser` · `Progrès` · `Profil`, dans une barre flottante aux
coins arrondis (ADR-038).

## Écrans

### Journal (accueil)

Mise en page du brand kit (ADR-019), refaite d'après la maquette (ADR-038).
```
┌──────────────────────────────┐
│▓Jeudi 20 novembre [Anglais ▾]▓│   aplat vert : date, langue active
│▓Bonjour !                    ▓│
│▓Une phrase à la fois.        ▓│
│▓┌─🔥 3 jours de suite ──────┐▓│   série
│▓│  (L)(M)(M)(J) V  S  D     │▓│   jours écrits cette semaine
│▓└──────────────────────────┘▓│
│ ╰────────────────────────────╯ │
│ ┌──────────────────────────┐ │
│ │ Mon journal du jour   🎤(P)│ │   carte blanche, dictée Premium
│ │ ┌──────────────────────┐ │ │
│ │ │ Aujourd'hui, j'ai…   │ │ │   saisie, brouillon automatique
│ │ └──────────────────────┘ │ │
│ │ ▓▓▓▓▓░░░░░  3 / 7 phrases│ │   progression en corail
│ │ [       Corriger       ] │ │
│ │ 1 correction disponible  │ │
│ └──────────────────────────┘ │
│ ╭ Journal Hist. Rév. Prog. ╮ │   barre d'onglets flottante
└──────────────────────────────┘
```
- Limite de phrases dépassée : barre et texte en rouge, bouton désactivé, explication.
- Correction du jour déjà faite : carte « Ton journal est corrigé. Découvre ce que tu as
  appris. » avec accès à la correction, puis rappel « reviens demain ». Les options
  Premium, crédits et vidéo s'y ajouteront (Inc-4, 7, 8).
- Hors ligne ou panne : la saisie reste possible et conservée ; l'envoi affiche l'erreur
  et précise que rien n'est débité.
- La série de jours et la semaine d'écriture s'affichent dans l'en-tête ; Premium ajoute
  la dictée (micro dans la carte du journal) et, s'il pratique plusieurs langues, une
  puce pour changer la langue du journal (Inc-6).
- Pas de publicité sur cet écran pendant la saisie (clavier ouvert ou texte non vide).

### Correction
```
┌──────────────────────────────┐
│ (←)      Correction       (⚑)│   boutons ronds : retour, signaler
│▓(2) 2 points à retenir       ▓│   bilan sur l'aplat vert
│▓    Chaque erreur est une…   ▓│
│ [Ta version|Version corrigée]│   bascule, corrigée par défaut
│ ┌──────────────────────────┐ │
│ │ Today I __went__ to… 🔊(P)│ │
│ └──────────────────────────┘ │
│ ┌ ~~have went~~ → went ─────┐ │   une carte par faute
│ │ Le prétérit s'emploie…    │ │
│ À réviser                    │
│ [grocery store · épicerie]   │   mots en étiquettes corail
│ Reformuler une phrase  🔒/›  │
│ [        Terminer         ]  │   toujours visible en bas
└──────────────────────────────┘
```
- Chargement : squelette + « Claude lit ton journal… » (jusqu'à 15 s).
- Erreur : « La correction n'a pas abouti. Ta correction du jour n'a pas été utilisée. » + Réessayer.
- Aucune faute : message de félicitation, vocabulaire quand même proposé.
- Gratuit : explications brèves ; les éléments Premium sont visibles et verrouillés.
- Interstitiel éventuel uniquement après « Terminer ».

### Historique
Cartes par date (pastille jour et mois, jour de la semaine, extrait, étiquette du nombre
de fautes). Gratuit : au-delà de 4 jours, carte corail « journaux conservés » avec
invitation Premium. Vide : « Ton premier journal apparaîtra ici. »

### Réviser
En tête, deux tuiles : **Exercices** (aplat vert ; une question à la fois, retour
immédiat) et **Simulation d'examen** (corail doux, après une première correction).
Ensuite la **carte du jour** : jusqu'à 5 mots à réviser, un à la fois (« Carte du jour ·
1 sur 5 », le mot, son exemple) ; la traduction s'affiche à la demande, « Je sais » le
marque appris, « À revoir » le garde ; une fois le paquet fini, « Revoir d'autres
cartes » s'il en reste. Puis **Tes mots** : mots appris sur le total, barre de
progression, cartes terme / traduction / exemple avec un bouton rond « Appris ». Vide : « Corrige un journal pour obtenir des
mots à réviser. » Aucune publicité pendant une révision.

### Progrès
Série de jours sur l'aplat vert (visible par tous), journaux écrits. Mots appris, fautes
par type, fautes par phrase semaine après semaine (la dernière semaine en vert profond) :
Premium, sinon carte corail « Statistiques détaillées ». Export PDF (Premium, onglet
Réviser).

### Profil
En-tête : initiale et e-mail du compte. Carte verte de l'offre (« Découvrir Premium »
après une première correction, « Gérer mon abonnement » pour un abonné). Puis trois
groupes : langues, boutique (solde des crédits), « Restaurer mes achats », confidentialité
des publicités ; conditions, confidentialité, à propos ; déconnexion, suppression du
compte (double confirmation).

### Offres (paywall)
```
┌──────────────────────────────┐
│ ✕   Continue ta série        │
│ ✓ Journaux illimités         │
│ ✓ Corrections détaillées …   │
│ ┌ Annuel — le plus avantageux┐│
│ │ 29,99 €/an (2,50 €/mois)   ││
│ └────────────────────────────┘│
│ ┌ Mensuel  4,99 €/mois ─────┐│
│ ┌ Hebdo    2,99 €/semaine ──┐│
│ [ Essayer 3 jours gratuits ] │
│ Puis 29,99 €/an, renouvelé   │
│ automatiquement. Annulable à │
│ tout moment dans le store.   │
│ Restaurer · CGU · Confident. │
└──────────────────────────────┘
```
Les prix affichés sont ceux renvoyés par le store. La croix de fermeture est toujours visible.

### Authentification
Connexion, inscription, saisie du code reçu par e-mail, mot de passe oublié. En-tête vert
arrondi (logo, nom et signature à la connexion et à l'inscription), formulaire sur
l'ivoire. Google et Apple en Inc-1b ; liens vers les textes légaux à l'inscription.
L'interface suit la langue du téléphone (français ou anglais).

### Onboarding
Une seule question : « Quelle langue veux-tu apprendre ? » (4 choix), puis l'écran Journal.
