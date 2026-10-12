# 0004 — Grille isométrique : cases de 64×32 px

**Date :** 2026-10-12 · **Statut :** acceptée

## Décision

- **Cases en losange de 64×32 px** (ratio 2:1), constante `IsoGrid.TILE_SIZE` (`game/core/grid/iso_grid.gd`).
- **Coordonnées :** le centre de la case `(x, y)` est à `((x − y) × 32, (x + y) × 16)` pixels.
  Augmenter `x` descend vers la droite à l'écran, augmenter `y` descend vers la gauche.
- **Déplacements :**
  - en **exploration**, 8 directions (sans couper les coins d'un obstacle) ;
  - en **combat**, 4 directions seulement : les voisins directs de la grille, qui apparaissent en
    diagonale à l'écran comme dans Dofus. Un pas coûte 1 PM ; la portée et le coût se mesurent en
    distance de Manhattan (`IsoGrid.distance`).
- **Ordre d'affichage :** un objet est d'autant plus devant que `x + y` est grand.

## Conséquences

- À 1280×720, une carte de 16×16 cases occupe environ 1024×512 px, avec de la place pour l'interface.
- Les graphismes du sol seront produits à 64×32 (ou 128×64 pour les écrans haute densité).
- Changer de taille plus tard reste possible : seule `IsoGrid` dépend des dimensions.
