# Arkhés : prompts PixelLab

Race d'élémentaires qui remplace le semi-homme (décision de l'auteur du 19/11/2026). Le personnage commence en **feu** ;
les 4 variantes remplacent le choix mâle / femelle et suivent les éléments du jeu : **feu (Flamme)**,
**métal (Acier)**, **orage (Tempête)**, **glace (Givre)**.

## Réglages (les mêmes que l'orc et le squelette)

- Personnage **64 × 64 px**, **8 directions**, même vue de 3/4 plongeante que `assets/orc/` et `assets/skeleton/`.
- Animations à exporter, rangées comme l'orc : `Idle_rotations_8dir.gif`, `walking/<direction>/frame_00N.png`,
  `running/<direction>/frame_00N.png` (8 directions, 92 × 92 px) et, si possible, `strike/` (4 diagonales).
- Un dossier par variante : `assets/arkhes/flamme/`, `acier/`, `tempete/`, `givre/`.
- Créer d'abord **flamme**, puis les trois autres à partir de la même silhouette (même squelette, même tenue),
  pour qu'elles restent une seule race.

## Contraintes du jeu à garder dans le prompt

- **Pieds posés au sol**, bien lisibles : le jeu cale les pieds en (48, 80) de chaque case. Pas de bas du corps
  en flamme ou en nuage qui flotte.
- **Tenue en vert mousse terne** (tunique, ceinture, brassards) : le jeu recolore le vêtement aux couleurs de la
  Voie en le repérant par sa teinte. Le vert n'est la couleur d'aucun des 4 éléments, donc le corps ne sera pas
  recoloré par erreur.
- **Pas d'arme** (les planches actuelles n'en ont pas, l'arme de la Voie viendra plus tard).
- Taille d'un humain moyen, un peu élancé ; contour sombre, ombrages francs, palette réduite comme l'orc.

## Prompt commun (à mettre en tête de chaque variante)

```
Pixel art RPG character, 64x64, 3/4 top-down view, dark outline, limited palette, same style as a
gritty fantasy orc. A humanoid elemental of the Arkhe race: an adult, slightly slender body made of
living element, with a calm but slightly smug expression and glowing eyes. Wears a simple dull
moss-green linen tunic, a brown leather belt and plain wrist wraps. Two solid legs with clearly
visible feet standing on the ground, no floating lower body. No weapon, empty hands.
```

## Variantes

**Flamme (départ)**
```
Body of molten rock cracked with glowing orange-red magma veins, hair and shoulders made of
small licking flames, ember-yellow eyes, faint sparks. Warm palette: deep red, orange, yellow,
dark basalt.
```

**Acier**
```
Body of forged steel plates riveted together like a living statue, polished grey with darker
iron joints and a few rust-brown scratches, hair shaped like a crest of thin metal blades,
cold white eyes. Neutral palette: steel grey, gunmetal, small bronze accents.
```

**Tempête**
```
Body of dark violet storm cloud held in a humanoid shape, crackling with small electric-yellow
lightning arcs, hair of swirling wind wisps, bright white-yellow eyes. Palette: deep violet,
slate blue, electric yellow.
```

**Givre**
```
Body of translucent pale-blue ice with sharp frost crystals on the shoulders and head, frozen
cracks inside, hair of icicles, icy cyan eyes, a little cold mist at the feet. Palette: white,
pale blue, cyan, deep navy shadows.
```

## Après le dépôt

Tirer les planches comme pour l'orc : `python3 game/tools/planche_sprites.py assets/arkhes/flamme/ game/art/sprites/arkhe_flamme.png`
(une planche par variante), puis régler la recoloration de la tenue dans `game/art/art.json`.
