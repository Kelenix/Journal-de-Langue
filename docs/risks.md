# Registre des risques

> Phase 2 (Project Manager). P = probabilité, I = impact (1 faible, 3 fort). 🔴 = P×I ≥ 6.

| ID | Risque | P | I | | Parade | Incrément |
|----|--------|---|---|--|--------|-----------|
| R1 | Coût IA supérieur aux revenus | 2 | 3 | 🔴 | Quotas serveur, plafonds Premium (40 phrases, 30 corrections/jour), modèle économique par défaut, limite de tokens de sortie, cache d'exercices, table `ai_usage`, limite de dépense dans la console Anthropic | Inc-2, 5, 9 |
| R2 | Refus de l'app par un store | 2 | 3 | 🔴 | Écran d'offres conforme (§10.1), restauration, suppression de compte, connexion Apple, consentement publicitaire, déclaration des données | Inc-1, 4, 8, 9 |
| R3 | Fraude aux quotas, crédits ou récompenses | 2 | 2 | | Décisions serveur uniquement, débit atomique et idempotent, compte obligatoire, plafond quotidien des récompenses | Inc-2, 7, 8 |
| R4 | Réponse de Claude mal formée ou hors sujet | 1 | 2 | | Sortie structurée validée par schéma ; échec = aucun débit, message de nouvelle tentative | Inc-2 |
| R5 | Injection d'instructions dans le journal | 2 | 2 | | Le texte utilisateur est passé comme donnée délimitée ; la sortie est contrainte au schéma ; aucun outil ni donnée d'autrui accessible à l'IA | Inc-2 |
| R6 | Build iOS non vérifiable sous Windows | 3 | 2 | 🔴 | Android d'abord (ADR-008) ; plugins choisis compatibles iOS ; build iOS en CI macOS avant publication | Inc-9 |
| R7 | Comptes développeur ou RevenueCat absents au moment d'Inc-4 | 2 | 2 | | Tâches manuelles datées ; couche d'achats derrière une interface testée avec un faux fournisseur, branchée dès que les comptes existent | Inc-4 |
| R8 | Double crédit ou crédit perdu (webhook rejoué, réseau coupé) | 2 | 3 | 🔴 | Identifiant de transaction unique en base, traitement idempotent du webhook, soumission de correction avec clé d'idempotence | Inc-4, 7 |
| R9 | Voix indisponible ou médiocre selon l'appareil | 2 | 1 | | Détection des langues disponibles, fonction masquée sinon | Inc-6 |
| R10 | Journaux = données personnelles envoyées à un sous-traitant (RGPD) | 3 | 2 | 🔴 | Mention dans la politique de confidentialité, minimisation (aucun identifiant envoyé à l'IA), suppression de compte effective, public 16+ | Inc-1, 2, 9 |
| R11 | Dépendance à un plugin Flutter non maintenu | 1 | 2 | | Plugins officiels ou largement adoptés, versions figées, vérifiés à l'introduction | tous |
| R12 | Docker Desktop arrêté ou ports occupés | 2 | 1 | | Commande de démarrage documentée, message d'erreur explicite dans le README | Inc-0 |

Tous les 🔴 ont une parade planifiée ; aucun ne nécessite de question supplémentaire.

## Chemin critique

Inc-0 → Inc-1 → Inc-2 (clé Anthropic et projet Supabase requis pour un test réel) →
Inc-4 (comptes stores et RevenueCat requis pour un achat réel) → Inc-9 (signatures).
Inc-3, 5, 6 ne dépendent d'aucun compte tiers supplémentaire.
