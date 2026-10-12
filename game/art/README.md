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
  à défaut. Les jauges du bandeau (cœur des PV, étoile des PA, case des PM, cadre de sort) et les
  icônes des menus sont dans `interface/`.

## Conventions de dessin

- 1 unité SVG = 1 pixel à l'écran (le jeu rend les SVG en 2× puis les réduit).
- Case : losange de 64 × 32. Personnage : dessiné sur environ 82 px, affiché à 80 % (`echelle`),
  soit environ 66 px ; tête d'environ 1/5,5 de la hauteur (proportions normales, pas de « chibi »).
- Contours `#3a2618`, d'environ 1 px ; lumière venant d'en haut à gauche (côté droit plus sombre).

## Outils

```sh
# Planche de toutes les images (sans affichage) :
godot --headless --path game -s res://tools/art_sheet.gd -- planche.png 1.5
# Capture d'écran du jeu (avec un serveur X virtuel) ; carte et combat facultatifs :
xvfb-run -s "-screen 0 1280x720x24" godot --path game --rendering-driver opengl3 \
  -s res://tools/screenshot.gd -- capture.png [carte ou scène] [images] [combat|inventaire|metiers|sorts|pierre]
```
