# Design system

> Source : **brand kit fourni par l'éditeur le 2026-11-19** (ADR-019), interface refaite
> d'après la maquette validée le 2026-11-20 (ADR-038). Material 3.
> Tout passe par `lib/core/theme/` : aucun écran ne contient de couleur, de rayon ou de
> police en dur.

## Marque

- **Nom** : Journal de Langue
- **Signature** : « Écris chaque jour. Progresse à chaque phrase. »
- **Personnalité** : moderne, rassurante, intelligente, accessible, motivante. Un carnet
  personnel, pas une application scolaire.

## Couleurs

| Nom | Valeur | Usage |
|-----|--------|-------|
| Vert profond | `#174D43` | Identité, boutons principaux, éléments importants (`primary`) |
| Ivoire | `#F7F4EA` | Arrière-plans (`surface`) ; texte des boutons principaux |
| Corail | `#F2A38A` | Accents visuels et progression (`AppColors.accent`) |
| Texte foncé | `#20332E` | Texte (`onSurface`) |
| Blanc | `#FFFFFF` | Cartes, boutons ronds, barre d'onglets |
| Gris doux | `#788680` | Contours, séparateurs, texte secondaire de grande taille |

Couleurs de fonction, hors brand kit : faute `#B3261E` (toujours barrée), correction en
vert profond (toujours soulignée). Teintes dérivées : vert clair `#D7E6E0` (pastilles,
onglet actif, version choisie), corail doux `#FBE3D9` (cartes d'offre et de limite,
étiquettes de fautes), fond des champs `#FBF9F2`.

### Contrastes mesurés (WCAG, seuil 4,5 pour le texte courant)

| Paire | Rapport | Conséquence |
|-------|---------|-------------|
| Vert profond / ivoire | 8,8 | Boutons et titres : conforme |
| Texte foncé / ivoire | 12,1 | Conforme |
| Gris doux / ivoire | 3,5 | **Insuffisant pour du petit texte** : le texte secondaire utilise `#5C6B65` (5,1) ; le gris du brand kit sert aux contours |
| Corail / ivoire | 1,8 | **Jamais de texte en corail** : aplats et barres de progression uniquement |
| Texte foncé / corail | 6,6 | Texte ou icône posé sur un aplat corail : conforme |

### Mode sombre

Le brand kit ne définit que le mode clair. Le mode sombre en reprend les teintes : fond
`#111A17`, vert éclairci `#8FCDBD` pour les éléments principaux, corail inchangé, texte
ivoire. À faire valider par l'éditeur.

## Typographie

| Rôle | Police | Graisse | Tailles |
|------|--------|---------|---------|
| Titres | DM Sans | Bold (700) | 34 (accueil), 30 (titre d'onglet), 24, 20, 17 |
| Texte | Inter | Regular (400) | 16 (journal), 14, 12 |
| Libellés, boutons | Inter | Medium (500), boutons en 600 | 16 |

Polices embarquées dans l'app (`assets/fonts/`, fichiers variables, licence SIL OFL) :
aucun téléchargement depuis le téléphone de l'utilisateur. Leurs licences figurent dans la
page « Licences » de l'app. Le texte du journal a un interligne de 1,5. Toutes les tailles
suivent le réglage d'accessibilité du téléphone.

## Formes

| Élément | Style |
|---------|-------|
| Boutons principaux | Vert profond, texte ivoire, rayon 18, hauteur 56 |
| Boutons secondaires | Fond transparent, bordure vert profond à 30 %, rayon 18, hauteur 52 |
| Boutons ronds | Blancs, ombre légère : retour, fermeture, signalement, export |
| Cartes de contenu | Blanches, rayon 24, ombre douce teintée de vert ; listes et tuiles rayon 20, à plat |
| Cartes mises en avant | Aplat vert profond, texte ivoire, accents corail : accueil du Journal, bilan d'une correction, série, offre, résultats |
| Cartes d'offre ou de limite | Corail doux, pastille corail pleine |
| Champs | Fond `#FBF9F2`, bordure `#E4E0D3`, rayon 18 ; bordure verte de 2 au focus |
| Étiquettes | Rayon 12, vert clair ou corail doux |
| Barre d'onglets | Flottante : blanche, rayon 26, à 16 des bords, ombre douce ; l'onglet actif sur une pastille vert clair |
| Arrière-plan | Ivoire |
| Icônes | Contour (jeu « outlined » de Material), souvent sur une pastille teintée |
| Animations | Courtes (≤ 200 ms), désactivées si le système le demande |

Espacements : 4, 8, 12, 16, 24, 32 (`AppSpacing`). Rayons : 12, 18, 20, 24, 28
(`AppRadius`). Ombre douce : `AppColors.softShadow`.

## Mise en page

- **Onglets** : grand titre à gauche, actions à droite (`TabAppBar`), contenu en cartes ;
  la barre d'onglets flotte au-dessus du fond, le contenu s'arrête avant elle.
- **Journal** : en-tête vert aux coins arrondis (date, langue, « Bonjour ! », série et
  semaine d'écriture du lundi au dimanche), puis la carte de rédaction.
- **Écrans ouverts par-dessus** (correction, exercices, examen, boutique, offres, textes
  légaux) : titre centré, retour ou fermeture et actions en boutons ronds (`SoftAppBar`).
  L'action qui termine l'écran reste visible en bas (« Terminer » de la correction).
- **Accueil** (première page sans compte) : logo, nom et signature sur l'aplat vert,
  puis une feuille ivoire aux coins arrondis : « Apprends en écrivant », trois atouts,
  « Créer mon compte » et « J'ai déjà un compte ».
- **Compte** (connexion, inscription, code, mot de passe, langue) : titre sur un en-tête
  vert arrondi, formulaire sur l'ivoire (`FormPage`). Le chargement du compte se fait
  sur l'aplat vert.

## Logo et icône

Symbole : **carnet ouvert ivoire + bulle de dialogue corail**, sur fond vert profond, sans
texte. Il est dessiné une seule fois, dans `tool/generate_app_icons.py`, qui produit :

| Fichier | Usage |
|---------|-------|
| `android/…/mipmap-*/ic_launcher_foreground.png` | Icône adaptative Android 8+ (fond `#174D43`), aussi utilisée en silhouette monochrome |
| `android/…/mipmap-*/ic_launcher.png` | Icône pleine, Android 7 |
| `assets/brand/logo.png` | Logo affiché dans l'app (accueil), sur un vert plus foncé `#0E332C` qui le détache de l'aplat |
| `ios/…/AppIcon.appiconset/*.png` | Icône iOS, toutes tailles (non contrôlée sur appareil) |
| `design/app_icon_1024.png` | Original 1024 × 1024 pour les fiches des stores (Inc-9) |

C'est une première exécution du concept du brand kit, à remplacer par le logo définitif
quand il existera : il suffira de changer le dessin dans le script.

## Ton

Un accompagnateur bienveillant, qui tutoie et ne culpabilise jamais.

| Moment | Texte |
|--------|-------|
| Accueil du journal | « Bonjour ! » · « Une phrase à la fois. » |
| Journal corrigé | « Ton journal est corrigé. Découvre ce que tu as appris. » |
| Lecture de la correction | « Chaque erreur est une occasion d'apprendre. » |
| Échec technique | Dit ce qui s'est passé et que rien n'est débité, sans reproche |

Les textes vivent dans `lib/l10n/` (français et anglais).

## Composants partagés (`lib/shared/widgets/`)

| Composant | Rôle |
|-----------|------|
| `SoftCard`, `HeroCard` | Carte blanche à l'ombre douce ; aplat vert dont textes, icônes et bouton principal passent en ivoire |
| `TabAppBar`, `SoftAppBar`, `roundButtonStyle` | Barre des onglets, barre des écrans ouverts par-dessus, bouton rond |
| `IconBadge`, `Tag`, `SoftProgressBar` | Pastille d'icône, étiquette, barre de progression corail |
| `SettingsGroup`, `SettingsTile` | Lignes de réglages regroupées sur une carte |
| `SectionTitle` | Titre de section, annoncé comme tel par les lecteurs d'écran |
| `BrandHeader` | Logo, nom et signature, sur l'aplat vert |
| `PrimaryButton` | Action principale d'un écran, avec état de chargement |
| `FormPage` | Mise en page des écrans de compte |
| `AsyncView` | Chargement, erreur avec « Réessayer », contenu |
| `ErrorMessage` | Erreur dans la page, annoncée par les lecteurs d'écran |
| `EmptyState` | État vide, icône sur une pastille |

## Règles

- Zones tactiles ≥ 48 dp ; `SafeArea` sur tous les écrans ; portrait uniquement.
- Chaque écran traite : chargement, vide, erreur (avec nouvelle tentative), succès.
- Une information n'est jamais portée par la couleur seule.
- Tous les textes passent par `l10n`.

## Écart relevé avec le brand kit

L'aperçu d'écran du brand kit indique « 10 phrases maximum ». La limite gratuite validée
est de **7 phrases** (ADR-008) ; l'app affiche la valeur fournie par le serveur. L'aperçu
montre aussi un bouton « Écrire mon journal » : dans l'app, l'onglet Journal ouvre
directement la rédaction, sans écran intermédiaire.
