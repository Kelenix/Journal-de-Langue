# Performances

> Rôle : Performance Engineer (Inc-9, puis phase 5 le 2026-11-20). Mesurer d'abord,
> optimiser ensuite.

## Budgets

| Critère | Budget |
|---------|--------|
| Démarrage à froid (version de publication) | < 2 s sur un téléphone de milieu de gamme |
| Fluidité | Pas d'image au-delà de 16 ms en défilement sur les listes |
| Données au démarrage | Quelques Ko, indépendantes de l'ancienneté du compte |
| Taille téléchargée (Android, arm64) | < 30 Mo |

## Données : mesure sur un compte d'un an

Compte local de mesure : un an d'usage Premium intensif (730 journaux corrigés avec
4 fautes chacun, 3 650 mots). Requêtes de l'app rejouées sur le Supabase local (sans
latence réseau : sur mobile, la taille compte bien plus que ces temps).

| Requête | Avant | Après (ADR-035) |
|---------|-------|-----------------|
| Au démarrage (savoir si un journal est corrigé) | historique complet : 2 097 Ko, 75 à 285 ms | `get_history_overview` : 69 octets |
| Onglet Historique | 2 097 Ko d'un coup | 40 Ko par page de 20, la suivante en fin de liste |
| Onglet Réviser | 165 Ko, **tronqué à 1 000 mots sur 3 650** (limite de l'API) | 3 650 mots en 8 lots de 500, 271 ms |
| Export PDF « tout » | aurait été tronqué au-delà de 1 000 journaux | 730 journaux en 4 lots de 200, 356 ms |

Rendu : l'historique et le vocabulaire sont construits à la demande
(`ListView.builder`) ; seuls les éléments visibles sont dessinés.

## Taille de l'app (2026-11-20)

Aucun build de publication n'est fait sur le poste de développement (ADR-036) : la
taille est mesurée sur l'APK « profile » de test et sur le build de publication de la CI.

| Mesure | Valeur |
|--------|--------|
| App bundle de publication, 3 architectures (CI, job `android`) | 54,0 Mo |
| APK « profile » de test, 3 architectures | 94 Mo compressés |
| **Téléchargement estimé sur un téléphone arm64**, majorant tiré de l'APK « profile » | **23,3 Mo** (budget : 30 Mo) |

Le store n'envoie que les bibliothèques de l'architecture du téléphone ; chaque fichier
de l'APK est recompressé pour estimer le transfert. Détail du majorant :

| Partie | Mo compressés |
|--------|---------------|
| Code Java/Kotlin des modules (publicités Google, AndroidX…) | 10,4 |
| Moteur Flutter (`libflutter.so`) | 5,6 |
| Code Dart compilé de l'app (`libapp.so`) | 5,5 |
| Polices, textes légaux, logo | 0,7 |
| Service de débogage propre au mode « profile » | 0,7 |
| Ressources Android | 0,5 |

C'est un majorant : en publication, R8 retire le code Java/Kotlin inutilisé (la plus
grosse part) et le service de débogage disparaît. La taille exacte s'affiche dans la
Play Console après l'envoi du bundle (explorateur d'app bundle). Les polices sont déjà
des polices variables (une par famille) et il n'y a qu'une image : rien à retirer.

## Application (phase 5, 2026-11-20)

Optimisations issues de la relecture du code (ADR-041) :

| Point | Avant | Après |
|-------|-------|-------|
| Ouverture du Journal, correction encore possible (cas courant) | droits du jour, puis journal du jour complet (fautes et mots compris) | droits du jour seulement ; le journal (son identifiant seul) n'est lu qu'une fois la limite atteinte |
| Export PDF d'un long historique | construit sur le fil de l'interface : écran figé, risque d'ANR | construit dans un autre isolate ; un journal de 6 000 caractères se coupe d'une page à l'autre au lieu de bloquer l'export |
| Suppression d'un compte | `purchase_events` et `one_time_purchases` parcourues en entier | index sur `user_id` |
| Aperçu de l'historique (chaque démarrage) | fenêtre de l'offre recalculée pour chaque journal compté | calculée une fois par requête |
| Appel long sur une connexion morte | attente sans fin | abandon après 150 s (correction, examen), 60 s (reformulation, exercices) |
| Bannière, interstitiel | annonce préchargée après l'interstitiel, jamais montrée dans la session | plus de préchargement inutile |

Démarrage à froid : à mesurer sur le téléphone de l'utilisateur, en mode « profile »
(`flutter run --profile --trace-startup`, résultat dans `build/start_up_info.json`).
Fluidité : listes construites à la demande ; pas de travail lourd dans les `build`
relevé par la revue.
