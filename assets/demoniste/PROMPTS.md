# Serviteurs du Démoniste : prompts PixelLab

Trois serviteurs invoqués par le Démoniste (codé le 20/11/2026, GDD § 4.3). En attendant ces planches, le jeu
recolore des dessins existants (`game/art/manifestes/demoniste.json` : gargouille pour le Diablotin, loup pour le
Molosse, gabarit humain avec des ailes pour la Succube).

## Réglages (les mêmes que l'orc et les Arkhés)

- **64 × 64 px**, **8 directions**, même vue de 3/4 plongeante que `assets/orc/`.
- Animations, rangées comme l'orc : `Idle_rotations_8dir.gif`, `walking/<direction>/frame_00N.png`
  (8 directions, 92 × 92 px) et, si possible, `strike/` (4 diagonales).
- Un dossier par serviteur : `assets/demoniste/diablotin/`, `molosse/`, `succube/`.
- **Pieds (ou pattes) posés au sol**, bien lisibles : le jeu cale les pieds en (48, 80) de chaque case.
- Couleurs propres au serviteur (le jeu ne les recolore pas) ; rappel discret de l'orange et du noir du Démoniste.
- Ton parodique : des démons employés de bureau des Enfers.

## Prompt commun

```
Pixel art RPG creature, 64x64, 3/4 top-down view, dark outline, limited palette, same style as a
gritty fantasy orc. A minor demon working as a contracted servant of hell, slightly comical,
clearly standing on the ground. Accents of ember orange and charcoal black.
```

## Diablotin stagiaire (petit, à distance)

```
A small red imp, knee-high to a human, with tiny horns, bat wings too small to fly, a pointed tail
and a bored intern expression. Holds a little iron pitchfork. Wears a crooked name badge on a cord.
```

## Molosse de garde (gros, tank)

```
A massive hellhound, stocky and muscular, charcoal-black fur with glowing orange cracks, spiked
iron collar with a security guard tag, smoke coming out of its nostrils. Four solid paws on the
ground, low and wide stance.
```

## Succube des RH (soutien, soins)

```
A tall elegant succubus in a strict charcoal office suit and skirt, small curved horns, folded dark
bat wings, glasses on a chain, holding a clipboard. Purple-grey skin, calm professional smile.
Plain flat shoes clearly visible on the ground.
```
