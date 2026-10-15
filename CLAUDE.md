# Retro Venture — consignes pour Claude

RPG tactique au tour par tour (Dofus Rétro × parodie du Seigneur des Anneaux), Godot 4.5 / GDScript.
Solo d'abord, multijoueur plus tard. Vision et règles : [docs/GDD.md](docs/GDD.md) ; tâches : [docs/TODO.md](docs/TODO.md).

## Langue et ton

- L'auteur écrit en français : répondre, committer et documenter en français.
- Le contenu du jeu est parodique (gobelins syndiqués, elfes snobs, humains persuadés d'être les héros…).

## Méthode de travail

- Développer sur la branche de session, la pousser, attendre la CI verte (onglet Actions ou API GitHub),
  puis pousser sur `main` : chaque push sur `main` publie le jeu sur GitHub Pages.
- Pas de pull request sauf demande explicite.
- Garder les tests verts et en ajouter pour chaque règle du noyau ; mettre à jour GDD, TODO,
  `game/data/README.md` et `docs/GUIDE_TESTEURS.md` quand un système ou un contenu change.
- **Économiser les tokens** (demande de l'auteur) :
  - pas de vérification par plusieurs agents : préférer un script de contrôle mécanique, et les tests ;
  - écrire soi-même quand c'est faisable, plutôt que de lancer un workflow ;
  - surveillance de la limite de session : un relevé de temps en temps (toutes les ~20 min), pas de
    réveils à la minute ; s'arrêter proprement (commit + push) vers 85 %, l'auteur fixe la limite à 90 % ;
  - ne pas reprendre automatiquement un travail interrompu sans accord.
- Ne rien laisser seulement dans la session (scratchpad, worktrees) : le conteneur est éphémère,
  tout ce qui compte est commité et poussé.

## Commandes

Depuis `game/` (binaire Godot 4.5.1 standard) :

```sh
godot --headless --path . --import                           # une fois, dans un nouveau clone
godot --headless --path . -s res://tests/run_tests.gd        # tous les tests
xvfb-run -a godot --path . -s res://tools/screenshot.gd -- sortie.png [carte] [secondes] [action]
```

`tools/screenshot.gd` fait des captures en jeu (actions : glyphe, survol, phase, reveil, carte, sermon,
cible…) ; `tools/art_sheet.gd` fait une planche des dessins.

## Architecture

- `game/core/` : règles sans affichage (partagées avec le futur serveur). Commandes → événements,
  constantes dans `Protocol`. Combat : `combat.gd`, `fighter.gd`, `spell.gd`, `combat_ai.gd` ;
  butin : `items/loot.gd` ; données : `data/game_data.gd` (validation des JSON).
- `game/client/` : rendu isométrique, interface, fenêtres.
- `game/data/` : contenu en JSON (cartes, monstres, sorts, objets, panoplies, passages, races, voies,
  métiers), format décrit dans `game/data/README.md`.
- Dessins : SVG `.svgt` paramétrés, manifeste `art.json` + fragments `art/manifestes/*.json`
  fusionnés par `Art.manifest()` (un fragment par lot de production, pour éviter les conflits).

## Où en est le projet

Phase 2 (alpha solo). Plan par chantiers :

1. Fondations du combat — **fait** (crits, bonus/malus, poison, poussée/attirance, glyphes, pièges
   invisibles, IA distance et soutien), sauf le modèle de sorts voie/rang.
2. Progression 1 → 30 (10 à 12 sorts par Voie, rendement décroissant, tableur d'équilibrage) —
   **reporté**.
3. Contenu du monde — **systèmes faits** (niveaux variables, mini-boss à phases, Pierres de Passage
   à découvrir et payantes, point de résurrection, carte du monde et minicarte). **Conception du
   contenu terminée, en attente de validation** : `docs/design/chantier3_brouillon/`
   (document, JSON par lot, scripts `src/build.py` et `src/controle.py`).
   **Ne pas lancer la production avant l'accord de l'auteur.**
   Question ouverte : 1 → 12 dure 2,7 h dans le modèle, le brief visait 3 à 4 h (formule dans `src/balance.py`).
4. Interface et confort. 5. Art et son. 6. **Quêtes : en tout dernier pour l'alpha** (choix de l'auteur).

## Règles de design à respecter (détails dans le GDD)

- Zones de départ : paliers 1–3 / 4–6 / 7–9 / 10–12, asymétriques entre zones (§ 3.5).
- Niveau variable dans une famille, pondéré ; élites à niveau fixe, au-dessus de la famille.
- Le niveau d'un monstre change ses stats, jamais son butin ; PA/PM fixes par famille sauf exception.
- Butin : limite par monstre partagée entre joueurs, tirage du plus prospecteur au moins prospecteur.
