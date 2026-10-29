# Images du jeu

Tout est en **SVG** (dessin vectoriel), rendu par le jeu au chargement : pas d'import dans
l'éditeur, et les images restent nettes. Les fichiers ont l'extension `.svgt` (« modèle SVG ») :
ce sont des SVG ordinaires où certaines couleurs sont écrites `{{nom}}`, remplacées au moment du
rendu (peau, cheveux, tunique, feuillage…). Un même dessin sert ainsi à toutes les races, Voies,
PNJ ou essences d'arbres.

## `art.json`

- `couleurs` : couleur par défaut de chaque `{{nom}}` (sans `#`).
- `images` : nom → `fichier`, `ancre` (le point posé au sol, ou le pivot d'une pièce, en pixels du
  SVG), `couleurs` (remplacements propres à l'image), `emprise` (cases couvertes par un bâtiment).
- `personnages` : assemblages articulés, une liste de pièces par vue (`face` : de 3/4 vers le bas de
  l'écran, `dos` : vers le haut), dans l'ordre de dessin. Chaque pièce a un `role` (`jambe_avant`,
  `jambe_arriere`, `torse`, `tete`, `bras_arme`, `bras_libre`), une `image`, la `position` de son
  pivot par rapport aux pieds, et une `teinte` facultative (pièces du côté éloigné, plus sombres).
  Un assemblage peut reprendre un autre (`base`) en changeant des images (`remplacer`) et sa taille
  (`echelle`).
- `armes`, `accessoires` : objets tenus en main ou portés (chapeau, tablier, barbe), avec leur point
  d'attache sur la pièce parente.
- `tenues` (par Voie), `races`, `pnj`, `monstres` : apparence de chacun (assemblage ou image,
  couleurs, arme, accessoires).
- `palettes` : couleurs par zone (`couleurs`), couleurs propres à une image dans cette zone
  (`images`), et images remplacées (`remplacer` : des champignons au lieu des fleurs à Crasse-Roc,
  des fougères au lieu des touffes à Sylvebrume). La carte choisit sa palette (`"palette"`).
- `ressources` (caractère du plan → image), `epuisees` (image après récolte), `decor` (variantes des
  arbres et rochers de décor).
- `icones_armes` : objet arme → icône de son attaque dans la barre de sorts. Les icônes de sorts
  sont les images `sort_<id du sort>` (`sorts/`, 44 × 44, fond de la couleur de l'élément : acier
  brun, flamme rouge, givre bleu, tempête vert, soin doré, utilitaire violet) ; `sort_inconnu` sert
  à défaut. Chaque objet a son icône `objet_<id de l'objet>` (`objets/`, 44 × 44, fond
  transparent), `objet_inconnu` à défaut. Les jauges du bandeau (cœur des PV, étoile des PA, case des PM, cadre de sort) et les
  icônes des menus sont dans `interface/`.

## Pixel art (`sprites/`)

Une race peut avoir une **planche** de pixel art (`"planche": "sprites/gobelin.png"` et son
`echelle` dans `races`) : sur la carte, debout et en course, le personnage est dessiné avec elle en
8 directions (`client/art/sprites.gd`) ; l'assemblage reste pour ce qui n'a pas encore d'images
(attaque, assis, portraits, écran de création). La planche a une ligne par direction (sud, sud-est,
est, nord-est, nord, nord-ouest, ouest, sud-ouest) et 5 cases de 96 × 96 (image fixe puis 4 images
de course), pieds en (48, 80). Elle est assemblée à partir des PNG fixes et des GIF de course par
`python3 tools/planche_sprites.py dossier/ art/sprites/<nom>.png`. À l'essai pour l'instant : les
races gobelin, humaine et elfe (sprites fournis par l'auteur). Chaque race a aussi une planche
par Voie, `sprites/<race>_<voie>.png`, où le vêtement prend la couleur de tunique de la Voie : la
`recoloration` de la race choisit ses pixels (teinte en degrés, saturation et valeur de 0 à 1,
`force` du mélange) et `python3 tools/couleurs_sprites.py` regénère ces planches, à relancer après
tout changement de planche, de recoloration ou de tenue.

Un monstre dessiné d'un bloc peut aussi avoir une `planche` dans `monstres` (à côté de son `image`,
gardée en secours) : sur la carte il est dessiné en 8 directions, à son `echelle` et sous sa
`teinte`, et l'ordre de jeu montre son image fixe de trois quarts. Fournis en images fixes seulement
(pas de GIF de course), `planche_sprites.py` recopie l'image fixe dans les cases de la course et le
monstre garde son petit saut en marchant. Pour l'instant : loup (`loup.png` : Loup des collines,
Loup alpha, Loup cendreux), rat (`rat.png` : Rat des galeries, Rat-roi) et morille (`morille.png` :
Morille grincheuse, Vieille morille rancunière). Les `couleurs` des variantes (pelage du Loup alpha,
ventre de braise du Loup cendreux) ne s'appliquent pas aux planches. L'élite d'une famille en pixel
art fait 1,2 fois l'`echelle` de sa famille (vérifié par `tests/data/test_art.gd`) ; en combat, la
barre de vie se place juste au-dessus du sprite (`Sprites.height`).

## Conventions de dessin

- 1 unité SVG = 1 pixel à l'écran (le jeu rend les SVG en 2× puis les réduit).
- Case : losange de 64 × 32. Personnage : dessiné sur environ 82 px, affiché à 80 % (`echelle`),
  soit environ 66 px ; tête d'environ 1/5,5 de la hauteur (proportions normales, pas de « chibi »).
- Contours `#3a2618`, d'environ 1 px ; lumière venant d'en haut à gauche (côté droit plus sombre).

## Outils

```sh
# Planche de toutes les images (sans affichage) :
godot --headless --path game -s res://tools/art_sheet.gd -- planche.png 1.5
# Seulement les icônes d'objets (ou « sort_ »…) :
godot --headless --path game -s res://tools/art_sheet.gd -- icones.png 1 objet_
# Capture d'écran du jeu (avec un serveur X virtuel) ; carte et combat facultatifs :
xvfb-run -s "-screen 0 1280x720x24" godot --path game --rendering-driver opengl3 \
  -s res://tools/screenshot.gd -- capture.png [carte ou scène] [images] [combat|inventaire|metiers|sorts|pierre|carte|repliee]
```

## Fragments du manifeste (`manifestes/`)

Pour éviter que tout le monde modifie le même fichier, chaque zone ou lot de contenu peut décrire
ses images dans son propre fichier `art/manifestes/<nom>.json`, avec les mêmes sections que
`art.json` (`images`, `monstres`, `pnj`, `palettes`, `ressources`, `icones_armes`…). Au chargement,
leurs entrées sont ajoutées à celles d'`art.json` ; un nom déjà défini ailleurs est une erreur
(signalée par les tests).

```json
{
  "images": {"sanglier": {"fichier": "monstre/sanglier.svgt", "ancre": [34, 44]}},
  "monstres": {"sanglier_des_landes": {"image": "sanglier", "echelle": 0.85}}
}
```
