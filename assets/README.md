# Assets bruts

Fichiers sources déposés par l'auteur (personnages, monstres, etc.), tels qu'ils sortent de l'outil de
dessin (ex. PixelLab : `<direction>.png` et GIF de course). Hors de `game/` pour que Godot ne les importe
pas et qu'ils ne soient pas publiés avec le jeu. Les planches utilisées par le jeu en sont tirées par
`game/tools/planche_sprites.py` vers `game/art/sprites/` (voir `game/art/README.md`).

`sol_herbe/` : planche de 16 tuiles d'herbe isométriques (32 × 16 px de dessus, ×2 pour nos cases de 64 × 32) ;
`retirer_contours.py` en tire `planche_sans_contour.png` (contour noir remplacé par les couleurs voisines).
Pas encore utilisée par le jeu.

`arkhes/PROMPT.md` : prompts PixelLab des 4 variantes des Arkhés (Flamme, Acier, Tempête, Givre), race d'élémentaires
à l'étude ; les sprites seront rangés dans `arkhes/<variante>/` comme ceux de l'orc.
