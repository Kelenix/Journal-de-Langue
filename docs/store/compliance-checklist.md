# Conformité des stores — checklist avant soumission

> Rôles : Play Store / App Store Engineer et Release Manager (Inc-9). État au
> 2026-11-19. ✅ fait dans l'app ou le dépôt · ⬜ à faire par toi (`docs/manual-tasks.md`)
> · ⏸️ attend un incrément.

## Bloquants pour une première soumission

| Point | État |
|-------|------|
| Achats réels (Google Play Billing et StoreKit, via RevenueCat) | ⏸️ Inc-4b. Sans eux, l'écran d'offres affiche « pas encore disponibles » : refus probable pour app incomplète |
| Textes légaux complétés (éditeur, adresse, e-mail, médiateur), relus par un juriste, publiés à une adresse publique | ⬜ |
| Projet Supabase de production dans l'UE : migrations, secrets, fonctions déployées | ⬜ |
| Clé d'envoi Android et compte Google Play ; compte Apple Developer, certificats et un Mac | ⬜ |
| Vrais identifiants AdMob, message de consentement publié, `ADMOB_REWARDED_AD_UNITS` | ⬜ |

## Google Play

| Exigence | État |
|----------|------|
| App bundle (.aab) signé, `versionCode` croissant | ✅ build vérifié (clé de debug) ; ⬜ clé d'envoi |
| API cible récente | ✅ `targetSdk` 36, `minSdk` 24 (valeurs de Flutter 3.41) |
| Politique de confidentialité dans l'app et en ligne | ✅ app (Profil, inscription, offres) ; ⬜ adresse publique |
| Suppression du compte dans l'app et sans l'app | ✅ Profil ; ✅ demande par e-mail décrite dans la politique ; ⬜ adresse publique |
| Sécurité des données, identifiant publicitaire, public cible, classification | ✅ réponses prêtes (`docs/store/data-safety.md`) ; ⬜ saisie |
| Permissions justifiées | ✅ micro demandé à la première dictée, refus géré ; autres permissions ajoutées par le SDK publicitaire (`docs/security.md`) |
| Abonnements : prix, période, essai, renouvellement, annulation ; gestion depuis le Profil | ✅ |
| Contenus générés par IA : signalement sans quitter l'app | ✅ drapeau sur la correction, l'exercice et la simulation (ADR-034) |
| Publicités : consentement UE, pas d'enfants visés, rien pendant l'apprentissage | ✅ |
| Fiche : textes FR/EN, icône 512 × 512, image de présentation 1024 × 500, captures | ✅ textes (`listing.md`) ; ✅ visuels (`docs/store/assets/`) |
| Test fermé avant la production (nouveaux comptes personnels : au moins 12 testeurs pendant 14 jours) | ⬜ |
| Déploiement progressif en production | ⬜ (recommandé : 10 %, puis 50 %, puis 100 %) |

## App Store

| Exigence | État |
|----------|------|
| Build signé avec Xcode, envoyé par TestFlight | ⬜ nécessite un Mac (question Q3 du plan) |
| Suppression du compte dans l'app (5.1.1 v) | ✅ |
| Contenus numériques vendus par achat intégré (3.1.1), restauration des achats | ⏸️ Inc-4b ; ✅ bouton « Restaurer » |
| Abonnements : informations sur l'écran d'offres, liens vers les conditions et la confidentialité dans l'app et dans la fiche (3.1.2) | ✅ app ; ⬜ liens dans la fiche |
| Confidentialité de l'app (étiquettes) | ✅ réponses prêtes ; ⬜ saisie |
| Déclaration d'exportation (`ITSAppUsesNonExemptEncryption`) | ✅ |
| Micro et reconnaissance vocale expliqués | ✅ `Info.plist` |
| Suivi publicitaire : pas de demande ATT, identifiant SKAdNetwork de Google | ✅ |
| Connexion avec Apple si une connexion Google est proposée (4.8) | ✅ sans objet tant qu'Inc-1b n'est pas livré |
| Captures iPhone 6,9" (1320 × 2868) | ✅ `docs/store/assets/` |

## Avant chaque version

- [ ] `flutter analyze`, `flutter test`, `supabase test db`, tests d'intégration et CI verts.
- [ ] `grep -rn "À COMPLÉTER\|TO COMPLETE" assets/legal docs/store` ne renvoie rien.
- [ ] Version incrémentée dans `pubspec.yaml` (`1.0.0+1` → `1.0.1+2`) et `CHANGELOG.md` complété.
- [ ] Migrations appliquées en production (`supabase db push`) avant la sortie de l'app.
- [ ] Build de publication installé et essayé sur un vrai téléphone.
