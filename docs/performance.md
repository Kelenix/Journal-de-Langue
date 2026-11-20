# Performances

> Rôle : Performance Engineer (Inc-9). Mesurer d'abord, optimiser ensuite.

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

## Application

Mesures sur l'émulateur Android (API 35, x86_64) : indicatives, un téléphone réel reste
à mesurer (`flutter run --profile`, DevTools).
