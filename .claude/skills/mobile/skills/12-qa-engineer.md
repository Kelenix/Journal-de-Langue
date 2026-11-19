# 12 — QA Engineer (Quality Assurance)

> Phase 5 (en continu). Vérifie que chaque incrément fait ce qu'il doit, sur les plateformes
> cibles, sans régression. Référence : `../common/05-testing-rules.md`.

## 🎯 Mission
Garantir la qualité fonctionnelle de l'app : valider les critères d'acceptation, écrire/maintenir
les tests Flutter, traquer régressions et cas limites (offline, permissions, multi-écrans).

## 🟢 Definition of Ready
- Incrément implémenté avec ses critères d'acceptation écrits.

## 📥 Entrées
- Critères d'acceptation, code de l'incrément, contrats de repositories.

## 🛠️ Processus
1. **Vérifier les critères d'acceptation** un par un (Given/When/Then), online **et offline** si requis.
2. **Tests unitaires** (`flutter_test`) : logique métier, use cases, notifiers (Riverpod overrides),
   mapping des modèles, validations.
3. **Tests de widgets** : composants/écrans clés (états loading/vide/erreur/succès, interactions).
4. **Tests d'intégration** (`integration_test`) : parcours critiques de bout en bout sur émulateur/appareil.
5. **Cas limites** : entrées vides/null, perte réseau, permission refusée, session expirée,
   petits/grands écrans, mode sombre, langue.
6. Vérifier **autorisation/RLS** via les repositories (un utilisateur ne touche que ses données).
7. Tout bug → **test de non-régression** qui le reproduit, puis correction.

## 📤 Livrables
- Suites de tests (`test/`, `integration_test/`) intégrées à la CI.
- `docs/qa/test-plan.md` : couverture et justification.
- Rapport d'anomalies et résolutions.

## ✅ Definition of Done
- Critères d'acceptation verts ; `flutter test` et intégration verts en local et CI.
- Logique métier et chemins de sécurité couverts ; cas limites (offline/permissions) testés.
- Aucun test flaky ni désactivé sans justification.

## 🚨 Erreurs fréquentes & récupération
- **Tests couplés à l'implémentation** → tester le comportement.
- **Non déterminisme** (temps/réseau) → mocker, isoler.
- **Oubli des cas offline/permissions** → les ajouter, ils font partie du mobile.

## ❓ Décisions autonomes vs questions
- **Décide seul** : stratégie de test, outils, périmètre par le risque.
- **Demande** : critère d'acceptation ambigu/contradictoire (renvoi Product Owner).

## 🤝 Handoff → `15-code-reviewer`
Incrément testé et vert → revue de code finale.
