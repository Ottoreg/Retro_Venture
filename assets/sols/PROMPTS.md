# Sols et cases : prompts PixelLab

Tous les sols et toutes les cases dessinés sur les cartes d'extérieur, pour les passer du SVG au pixel art.
Les **intérieurs** (parquet, paillasson) ne sont pas traités, comme demandé.

## Ce que le jeu dessine aujourd'hui (`MapView._draw_ground`)

1. Un **fond uni** de la couleur `herbe` de la palette de la carte, sans liseré entre les cases.
2. Des **détails semés** toujours aux mêmes endroits : taches claires et sombres, touffes (fougères à
   Sylvebrume), fleurs (champignons à Crasse-Roc, braises aux Forges et en zone de cendre), cailloux.
3. Les **chemins** (`:`) : d'abord un bord un peu plus grand sous chaque case de chemin (`chemin_bord`), puis
   l'intérieur (`chemin`) : le bord ne reste visible qu'au contour du chemin. Même chose pour l'**eau** (`E`) :
   `eau_rive` puis `eau`. Ces 4 images font 96 × 48 px, ancre (48, 24), plus larges que la case.
4. Les coins de pêche (remous sur l'eau) et, en combat, les cases changées par les sorts (eau gelée, gravats,
   cases embrasées ou calcinées).

Une case fait **64 × 32 px** (losange vu de dessus). Les arbres, rochers, murs, barrières, minerais et plantes
sont des **objets** posés sur la case, pas des sols : ils ne sont pas dans ce fichier. La grille, les cases de
placement, la portée et les glyphes sont dessinés par le jeu par-dessus et n'ont pas besoin d'image.

## Palettes des zones (couleurs actuelles, à garder comme repère)

| Palette | Cartes | Herbe (claire / sombre / tige) | Terre (bord) | Eau / rive / reflet |
|---|---|---|---|---|
| `brumerive` (défaut) | Brumerive, Grandes Plaines, Grange | `8db54d` (`a9cc62` / `6f9a3a` / `5d8a32`) | `cfae74` (`a8844e`) | `4b93c4` / `d9c58f` / `bfe3f2` |
| `hautepierre` | Hautepierre | `93a860` (`adc07a` / `768c48` / `667a3e`) | `c8b898` (`a0906e`) | `5a8aaa` / `cfc4a0` / `c8dce8` |
| `cendree` | Hautepierre cendrée | `7c8460` (`929a74` / `616848` / `52583c`) | `8e8270` (`6a6052`) | `5e7078` / `7a705e` / `98a8ae` |
| `crasse_roc` | Crasse-Roc (terne et sombre, voulu) | `6e7247` (`858a57` / `53572f` / `45492a`) | `86704f` (`584634`) | `4d6b5e` / `6a5a44` / `8fa898` |
| `sylvebrume` | Sylvebrume | `7fb85c` (`a6d77d` / `5e9a48` / `4d8d3d`) | `cbb27c` (`9c8456`) | `4aa6cc` / défaut / défaut |
| `forges` | Forges de Crasse-Roc | `5a5048` (`6e645a` / `433a34`) | `6a5a4a` (`584634`) | **lave** `e2622a` / `2b2522` / `ffd36a` |
| `cendre` | Cendre (Hautepierre) | `4a4440` (`5e5650` / `35302c` / `2a2522`) | `5c4e44` (`3a302a`) | **lave** `e2622a` / `2b2522` / `ffd36a` |
| `celeste` | Tour céleste | `e8eef8` (`ffffff` / `cfd8e8` / `b8c4d8`) | `f0e6c8` (`d0c49c`) | `8fc0ec` / `dfe8f4` / `ffffff` |

## Réglages communs

- Outil : **tuile isométrique** de PixelLab pour les sols pleins (herbe, terre, eau), largeur **64 px**
  (dessus de 64 × 32, la taille de nos cases). Choisir la forme **la plus fine** (tuile plate, sans épaisseur) :
  la première planche d'herbe (`assets/sol_herbe/`) avait des flancs de terre que le jeu ne peut pas utiliser.
- Outil **objet de carte / image fixe**, fond transparent, pour les détails semés et les bords (canevas indiqués).
- **Raccord sans couture** : les bords du losange doivent se continuer d'une case à l'autre (pas de liseré, pas de
  bord plus clair ou plus sombre). **Aucun contour sur les bords de la tuile** : le contour sombre `#3a2618`
  ne sert qu'autour des petits détails en relief (cailloux, touffes, champignons). Sur la planche d'herbe, il a
  fallu retirer le contour noir après coup (`retirer_contours.py`).
- **4 à 8 variantes** par sol, de même teinte moyenne : le jeu les tirera au hasard par case (comme les
  détails aujourd'hui), sans motif répété visible.
- Lumière venant d'en haut à gauche, palette réduite, texture granuleuse façon fantasy, même vue de 3/4
  plongeante que les personnages.

### Début commun des prompts de tuile

```
Pixel art isometric floor tile, 64x32 top face, flat tile with no side thickness, 3/4 top-down view,
seamless edges that tile perfectly with identical neighbours, no outline on the tile edges, light
from the top left, limited palette, gritty fantasy style matching the characters.
```

### Début commun des prompts d'objet au sol

```
Pixel art RPG ground detail, transparent background, 3/4 top-down view, lying flat on the ground,
dark brown-black outline (#3a2618) only around raised details, light from the top left, limited
palette, gritty fantasy style matching the characters.
```

## 1. Herbe (case `.`, fond de la carte), une série par palette

Mettre le début commun des tuiles, puis la ligne de la zone.

**Brumerive (aussi Grandes Plaines et Grange)**
```
Short fresh meadow grass, warm medium green (#8db54d) with lighter (#a9cc62) and darker (#6f9a3a)
blades, a few tiny dark stems (#5d8a32), gentle and welcoming countryside.
```

**Grandes Plaines (facultatif, si l'on veut les distinguer de Brumerive)**
```
Dry steppe grass, slightly yellowed green (#8db54d mixed with straw #c8b86a), wind-combed blades
all leaning the same way, a few bare earth specks.
```

**Hautepierre**
```
Well-kept town lawn, soft olive green (#93a860) with pale (#adc07a) and darker (#768c48) blades,
short and even, a few trampled spots.
```

**Hautepierre cendrée**
```
Dull grey-green grass dusted with fine ash (#7c8460, #929a74, #616848), tired and dry, a few
grey flakes on the blades.
```

**Crasse-Roc**
```
Sparse, dirty, muddy grass, drab khaki green (#6e7247) with darker (#53572f) and pale (#858a57)
blades, patches of brown mud showing through, gloomy and neglected.
```

**Sylvebrume**
```
Lush bright forest grass, vivid green (#7fb85c) with pale (#a6d77d) and deep (#5e9a48) blades,
soft moss between them, slightly magical and pristine.
```

**Forges de Crasse-Roc**
```
Scorched volcanic ground, dark grey-brown ash (#5a5048) with lighter (#6e645a) and darker
(#433a34) grit, small cracks, no grass at all.
```

**Cendre**
```
Cold black ash field (#4a4440), darker cinders (#35302c) and pale grey flakes (#5e5650), fine
cracks, no grass, dead and silent.
```

**Tour céleste**
```
Floor of soft white cloud (#e8eef8) with pure white highlights (#ffffff) and pale blue-grey hollows
(#cfd8e8), puffy but flat enough to walk on, heavenly and slightly kitsch.
```

## 2. Détails semés sur l'herbe (objets au sol)

Mettre le début commun des objets, puis la ligne. Couleurs : celles de la palette (série Brumerive ici ;
refaire une série par palette, ou les livrer en gris et laisser le jeu les teinter).

**Tache claire** (`tache_claire`, canevas 80 × 36, ancre (40, 18))
```
80x36 canvas. A soft irregular oval patch of lighter, sun-bleached grass (#a9cc62) fading into
transparency at its edges, no outline, very subtle.
```

**Tache sombre** (`tache_sombre`, canevas 80 × 36)
```
80x36 canvas. A soft irregular oval patch of darker, damp grass (#6f9a3a) fading into transparency
at its edges, no outline, very subtle.
```

**Touffes** (`touffes`, canevas 40 × 20, ancre (20, 10))
```
40x20 canvas. Two small tufts of taller grass blades, dark green stems (#5d8a32) with light green
tips (#a9cc62).
```

**Fougères** (Sylvebrume, à la place des touffes ; canevas 40 × 24)
```
40x24 canvas. A small low fern with three curled fronds, bright green (#77c47e) with deep green
shadow (#357846).
```

**Fleurs** (`fleurs`, canevas 64 × 32, ancre (32, 16))
```
64x32 canvas. Three or four tiny wildflowers scattered in the grass, white, yellow and soft pink
petals, very small (2 to 3 pixels each).
```

**Champignons** (Crasse-Roc, à la place des fleurs ; canevas 40 × 20)
```
40x20 canvas. A cluster of three tiny sickly mushrooms, dirty beige caps with brown spots, pale
stems.
```

**Cailloux** (`cailloux`, canevas 64 × 32, ancre (32, 16))
```
64x32 canvas. Three small flat grey pebbles (#9a958c) of different sizes half sunk in the ground.
```

**Braises** (Forges, Cendre, Hautepierre cendrée ; canevas 40 × 20)
```
40x20 canvas. A few glowing embers lying on ash, orange-red cores (#e2622a) with yellow hot spots
(#ffd36a) and dark charcoal around them.
```

## 3. Chemin de terre (case `:`)

Deux images par palette, canevas **96 × 48**, ancre (48, 24) : le **bord** (dessiné d'abord, un peu plus grand)
et l'**intérieur** (posé par-dessus). Outil objet de carte, fond transparent.

**Bord de chemin** (`chemin_bord`)
```
96x48 canvas, transparent background, 3/4 top-down view. An irregular flattened diamond of packed
darker earth (#a8844e), about 80x40 pixels, centred, with ragged soft edges where a few grass
blades overlap it, no outline.
```

**Chemin** (`chemin`)
```
96x48 canvas, transparent background, 3/4 top-down view. A flattened diamond of dry packed dirt path
(#cfae74), about 72x36 pixels, centred, with small pebbles, faint cart ruts and footprints,
slightly irregular edges, no outline. Must tile seamlessly with identical copies placed on
neighbouring isometric cells.
```

Lignes à ajouter selon la zone :
- Hautepierre : `pale cobbled path, worn light grey-beige paving stones (#c8b898, joints #a0906e)` (rue pavée).
- Hautepierre cendrée : `grey dusty dirt (#8e8270, edge #6a6052) with ash`.
- Crasse-Roc : `dark muddy track (#86704f, edge #584634) with puddles and boot prints`.
- Sylvebrume : `soft sandy forest path (#cbb27c, edge #9c8456) with a few fallen leaves`.
- Forges et Cendre : `cracked black basalt slabs (#6a5a4a or #5c4e44) with faint glowing seams`.
- Tour céleste : `polished cream marble slabs (#f0e6c8, edge #d0c49c) with thin gold joints`.

## 4. Eau bordée de chaque sol (case `E`) : jeux de 16 tuiles

Toutes les palettes ont de l'eau sur au moins une carte : Brumerive (10 cartes, Grandes Plaines comprises),
Tour céleste (7), Hautepierre (6), Sylvebrume (5), Crasse-Roc (4), Forges (2), Hautepierre cendrée (2) et
Cendre (1). Il faut donc **un jeu de transition par palette**.

### Réglages

- Outil : **tileset** de PixelLab (transitions « Wang »), en vue **isométrique** si l'outil la propose,
  tuiles de **64 px de large** (dessus de 64 × 32, notre case). Si l'outil ne fait que du 32 px, le faire en 32
  et agrandir ×2, comme la planche d'herbe.
- Trois champs à remplir : **terrain du bas** (l'eau, plus bas), **terrain du haut** (le sol de la zone),
  **transition** (la rive). Les prompts ci-dessous sont rangés ainsi.
- L'outil produit **16 tuiles** : chacun des 4 coins du losange (N, E, S, O) est soit eau, soit sol. Les 16
  combinaisons couvrent les rives droites, les angles extérieurs et les angles intérieurs, sans escalier.
- Raccord sans couture, **pas de contour sur les bords des tuiles**, lumière d'en haut à gauche, palette réduite.
- Le sol du haut doit être **le même que la tuile d'herbe de la zone** (section 1), avec les mêmes couleurs,
  pour que les tuiles de rive se raccordent à l'herbe pleine.

### Ordre des tuiles à garder au dépôt

Nommer chaque tuile par ses coins en eau, avec N = 1, E = 2, S = 4, O = 8 (somme des coins en eau) :
`0.png` = tout en sol, `15.png` = tout en eau, `1.png` = seul le coin nord est en eau, `3.png` = nord et est
en eau (rive droite côté sud-ouest), etc. Dossier : `assets/sols/eau_<palette>/0.png` à `15.png`. Le jeu
choisira la tuile d'après les 4 cases qui touchent chaque coin.

### Début commun du champ « transition »

```
Natural irregular shoreline, the water edge follows a soft wavy line, not a straight grid line,
a thin wet darker band of ground right at the waterline, small foam or ripple pixels where the
water touches the bank, seamless, no outline on tile edges.
```

### Par palette

**Brumerive (aussi Grandes Plaines et Grange)**
- Bas : `Calm clear river water (#4b93c4), darker in the deep middle, a few short light reflection lines (#bfe3f2).`
- Haut : `Short fresh meadow grass, warm medium green (#8db54d) with lighter (#a9cc62) and darker (#6f9a3a) blades.`
- Transition : `Wet sandy bank (#d9c58f, darker edge #b9a26a) with a few small pebbles and reeds.`

**Hautepierre**
- Bas : `Town canal water (#5a8aaa), calm, with pale reflection lines (#c8dce8).`
- Haut : `Well-kept town lawn, soft olive green (#93a860) with pale (#adc07a) and darker (#768c48) blades.`
- Transition : `Cut-stone canal edge (#cfc4a0, joints #a89c78), neat straight-ish blocks with moss in the joints.`

**Hautepierre cendrée**
- Bas : `Murky grey water (#5e7078) with ash flakes floating on it, dull reflections (#98a8ae).`
- Haut : `Dull grey-green grass dusted with fine ash (#7c8460, #929a74, #616848).`
- Transition : `Grey muddy bank (#7a705e, edge #5a5246) with ash and a few dead reeds.`

**Crasse-Roc**
- Bas : `Stagnant greenish swamp water (#4d6b5e), scum patches and a few bubbles, dim reflections (#8fa898).`
- Haut : `Sparse dirty muddy grass, drab khaki green (#6e7247) with darker (#53572f) blades and mud patches.`
- Transition : `Sticky brown mud bank (#6a5a44, edge #4a3e30) with boot prints, rusty junk and rotten reeds.`

**Sylvebrume**
- Bas : `Clear turquoise forest stream (#4aa6cc) with visible pebbles under the surface, bright reflections.`
- Haut : `Lush bright forest grass, vivid green (#7fb85c) with pale (#a6d77d) and deep (#5e9a48) blades, soft moss.`
- Transition : `Mossy bank with smooth round stones, small ferns and a few water lilies at the edge.`

**Forges de Crasse-Roc (lave)**
- Bas : `Molten lava (#e2622a) with bright yellow cracks (#ffd36a) and patches of dark crust.`
- Haut : `Scorched volcanic ground, dark grey-brown ash (#5a5048) with lighter (#6e645a) and darker (#433a34) grit.`
- Transition : `Black cooled basalt rim (#2b2522, edge #1a1512) with glowing orange seams near the lava, no foam.`

**Cendre (lave)**
- Bas : `Molten lava (#e2622a) with bright yellow cracks (#ffd36a), slower and darker than a forge.`
- Haut : `Cold black ash field (#4a4440), darker cinders (#35302c) and pale grey flakes (#5e5650).`
- Transition : `Black cooled rock rim (#2b2522) with a faint orange glow, cinders, no foam.`

**Tour céleste**
- Bas : `A gap in the clouds showing pale blue sky far below (#8fc0ec), with tiny distant clouds.`
- Haut : `Floor of soft white cloud (#e8eef8) with white highlights (#ffffff) and pale blue-grey hollows (#cfd8e8).`
- Transition : `Puffy rounded cloud edge (#dfe8f4, shadow #a8b8d0) curling over the void, no foam.`

Pour la lave, une animation facultative de 4 images : `the lava slowly bubbles and the cracks glow brighter
and dimmer, seamless loop, the shoreline does not move.` Pour l'eau : `the reflection lines slowly drift,
seamless loop, the shoreline does not move.`

## 5. Cases de récolte au sol

**Coin de pêche** (`remous`, posé sur l'eau ; canevas 60 × 30, ancre (30, 15))
```
60x30 canvas, transparent background, 3/4 top-down view. Three concentric white ripple rings on
water (#e8f4ff, fading outward) and a small fish fin breaking the surface, no water drawn, only the
ripples and the fin.
```
Animation facultative : `The ripples slowly widen and fade, the fin dips and comes back, seamless loop.`

**Coin de pêche épuisé** (`remous_calme`, même canevas)
```
60x30 canvas, transparent background. A single faint white ripple ring on water, no fish, very calm.
```

**Champ moissonné** (`chaume`, champ en attente de repousse ; canevas 64 × 32)
```
64x32 canvas, transparent background, 3/4 top-down view. A flattened diamond of ploughed earth
furrows (#a8844e) covered with short cut yellow stubble (#d8c070), no outline on the edges.
```
(Les épis, plantes et arbres sur pied sont des objets, hors de ce lot.)

## 6. Cases changées en combat

Aujourd'hui des losanges de couleur unie ; une tuile de 64 × 32 (outil tuile isométrique, début commun) les
remplacerait.

**Eau gelée** (Myrmidon, *gel* : l'eau devient praticable 3 tours)
```
Frozen pond surface, pale blue ice (#cfe8f5) with white frost streaks and darker blue cracks
(#7aaed0), a few trapped bubbles, slippery and solid.
```

**Gravats** (Myrmidon, *démolition* d'un rocher ; canevas 64 × 32, objet au sol)
```
64x32 canvas. A low pile of broken grey rock fragments (#9a958c) and dust lying flat on the ground,
nothing taller than 8 pixels.
```
(Un arbre démoli devient la souche existante.)

**Case embrasée** (Démoniste, 3 niveaux de plus en plus vifs ; faire 3 versions)
```
Ground covered with small licking flames and glowing embers, level 1: a few dim orange sparks (#c0602a);
level 2: more flames, bright orange (#e2822a); level 3: intense yellow-orange fire (#ffb340) almost
covering the tile. Semi-transparent so the ground stays visible underneath.
```

**Case calcinée** (Démoniste, niveau 4)
```
Burnt-out ground, black charcoal (#1a1414) with grey ash (#7a726c) and a few thin wisps of smoke
rising, no flames left.
```

## Après le dépôt

Déposer les images dans `assets/sols/<type>/` (eau : `assets/sols/eau_<palette>/0.png` à `15.png`) (par exemple `assets/sols/herbe_brumerive/1.png` … `8.png`), puis
demander de les brancher dans le jeu : il faudra remplacer le fond uni par des tuiles tirées au hasard par case
(changement de `MapView._draw_ground`), et les SVG de `game/art/sol/` resteraient en secours.
