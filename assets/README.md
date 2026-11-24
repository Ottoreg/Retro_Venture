# Assets bruts

Fichiers sources déposés par l'auteur (personnages, monstres, etc.), tels qu'ils sortent de l'outil de
dessin (ex. PixelLab : `<direction>.png` et GIF de course). Hors de `game/` pour que Godot ne les importe
pas et qu'ils ne soient pas publiés avec le jeu. Les planches utilisées par le jeu en sont tirées par
`game/tools/planche_sprites.py` vers `game/art/sprites/` (voir `game/art/README.md`).

`sol_herbe/` : planche de 16 tuiles d'herbe isométriques (32 × 16 px de dessus, ×2 pour nos cases de 64 × 32) ;
`retirer_contours.py` en tire `planche_sans_contour.png` (contour noir remplacé par les couleurs voisines).
Pas encore utilisée par le jeu.

`arkhes/PROMPT.md` : prompts PixelLab des 4 variantes des Arkhés (Flamme, Acier, Tempête, Givre), race d'élémentaires
à l'étude ; les sprites sont rangés dans `arkhes/<variante>/` comme ceux de l'orc (`arkhes/flamme/` déposé le 19/11/2026).

`PROMPTS_RACES.md` : prompts PixelLab de l'humain et du gobelin (regénérés le 20/11/2026, dossiers `humain/` et `gobelin/`).
`PROMPTS_ANIMATIONS.md` : prompts PixelLab des animations des races (touché, mort, assis, travailler, attente).

`elfe/strike/` : coup de poing de l'elfe (20/11/2026), ajouté à la planche existante de l'elfe (mêmes proportions).

`geante/` : géante (race Géants, Phase 3), déposée le 19/11/2026 ; images fixes de 96 px et animations de 136 px,
plus grandes que l'orc (planche à cases plus grandes à prévoir). Chaque dossier PixelLab garde son `metadata.json` (prompt utilisé).
`ampa/` : l'ampa (monture des Grandes Plaines), déposé le 24/11/2026 en zip, rangé comme l'orc : `Idle_rotations_8dir.gif`
(fait des 8 images de `rotations/`), `running/` (course, 8 directions) et `strike/` (cou rejeté en arrière, 4 diagonales),
plumage gris neutre. Planche `game/art/sprites/ampa.png` par `tools/planche_sprites.py`, puis une planche par robe
(`ampa_<couleur>.png`), recoloriée par `docs/design/grandes_plaines/ampas.py`.
