# Prompts PixelLab des animations des races

Mêmes réglages que les personnages (vue de 3/4, contour sombre). À générer pour chaque race, depuis le personnage
déjà créé, et à ranger dans `assets/<race>/<animation>/<direction>/frame_00N.png` comme `strike/`.

| Animation | Dossier | Directions | Images | Prompt |
|---|---|---|---|---|
| Attaque (corps à corps et sorts) | `strike/` | 4 diagonales | 6 à 9 | *Lean forward rapidly and throw a hard forward punch* (déjà utilisé) |
| Touché | `hit/` | 4 diagonales | 3 | *Flinch backward from a hit to the chest, head snapping back, then recover to standing* |
| Mort / KO | `death/` | 4 diagonales | 5 à 6 | *Stagger, drop to the knees, then fall forward flat on the ground and stay still* (la dernière image est tenue) |
| Assis | `sit/` | 4 diagonales | 1 à 4 | *Sit down on the ground with legs crossed, hands resting on the knees, relaxed* |
| Travailler (récolte, forge…) | `work/` | 4 diagonales | 6 | *Bend forward slightly and work with both hands in front at waist height, short repeated chopping motions, then straighten a little* |
| Attente qui respire | `idle/` | 8 directions | 4 | *Stand still and breathe slowly, chest and shoulders gently rising and falling, tiny weight shift, feet stay planted* |

Notes :

- **Travailler** : un geste de mains à hauteur de taille, sans outil, se lit aussi bien comme couper, cueillir, battre le
  métal ou pétrir ; l'outil pourra être ajouté plus tard en calque. La pêche demandera peut-être sa propre animation.
- **Attente** : 4 images suffisent (une respiration lente en boucle, ~0,25 s par image). En 8 directions parce que les
  joueurs s'arrêtent dans toutes les directions sur la carte ; en combat, seules les 4 diagonales servent.
- **Côté ouest facultatif** : pour une animation symétrique, ne fournir que l'est (east, south-east, north-east) ;
  `planche_sprites.py` fait west, south-west et north-west en miroir. Fournir l'ouest seulement si un détail est
  asymétrique (sacoche, tresse, arme d'un côté).
- Garder les pieds au même endroit d'une image à l'autre (le jeu les cale en bas au centre de la case).
