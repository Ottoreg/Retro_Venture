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
cible, tactique, pause, options…) ; `tools/art_sheet.gd` fait une planche des dessins ; `tools/simulation.gd` simule des
combats sur chaque groupe des cartes (`-- [combats] [rapport.md] [préfixes de cartes] [detail]`,
~7 min pour tout à 10 combats).
`python3 tools/catalogue.py` regénère `docs/CATALOGUE.md` (objets, monstres par niveau et lieux, sorts, avec leurs
détails et comment les obtenir) : à relancer après tout changement d'objets, de sorts ou de monstres.

## Architecture

- `game/core/` : règles sans affichage (partagées avec le futur serveur). Commandes → événements,
  constantes dans `Protocol`. Combat : `combat.gd`, `fighter.gd`, `spell.gd`, `combat_ai.gd` ;
  butin : `items/loot.gd` ; données : `data/game_data.gd` (validation des JSON).
- `game/client/` : rendu isométrique, interface, fenêtres.
- `game/data/` : contenu en JSON (cartes, monstres, sorts, objets, panoplies, passages, races, voies,
  métiers, quêtes), format décrit dans `game/data/README.md`. Quêtes : `core/quests/`.
- Dessins : SVG `.svgt` paramétrés, manifeste `art.json` + fragments `art/manifestes/*.json`
  fusionnés par `Art.manifest()` (un fragment par lot de production, pour éviter les conflits).

## Où en est le projet

Phase 2 (alpha solo), en deux tests :

- **Alpha test 1 : les mécaniques.** Chantiers dans l'ordre : contenu du monde (3), puis
  interface (4) et quêtes (6) en derniers avant le lancement. XP de combat ×3,5
  (`Character.XP_RATE`) : tout le contenu en 4 à 5 h.
- **Alpha test 2 : la progression.** Progression 1 → 30 (2 : sorts par niveau, modèle voie/rang,
  rendement décroissant, XP ×1 soit ~15 h pour 1 → 30) et art et son (5).

État des chantiers :

1. Fondations du combat — **fait** (crits, bonus/malus, poison, poussée/attirance, glyphes, pièges
   invisibles, IA distance et soutien). Le modèle de sorts voie/rang passe à l'alpha 2.
3. Contenu du monde — **systèmes faits** (niveaux variables, mini-boss à phases, Pierres de Passage
   payantes — toutes connues dès le début pendant la phase de test, `World.ALL_PASSAGES_KNOWN` —,
   point de résurrection, carte du monde qui montre tout dès le début, minicarte façon Dofus Rétro).
   **Conception entièrement validée par l'auteur** (mini-boss révisés compris) :
   `docs/design/chantier3_brouillon/` (document, JSON par lot, scripts `src/build.py` et
   `src/controle.py`). Cases de placement prédéfinies par carte **faites** (calque `placement`,
   GDD § 7.1, outil `game/tools/placement.py`). **Production par lots en cours** : les trois zones de départ
   faites (Brumerive, Crasse-Roc, Sylvebrume ; `src/produire.py`, `src/cartes.py`,
   `src/plans_<lot>.py`), Hautepierre (`src/plans_hautepierre.py`, `peupler` pour les groupes et
   PNJ), les variantes et les métiers (`src/metiers_production.py`) : **tout le contenu est produit**.
   Décors de ville dessinés. Variantes dans les repaires des mini-boss une fois vaincus (groupes
   `apres_boss`). Intégration faite (`tools/simulation.gd`, `docs/design/simulation_combats.md`) :
   ajustements d'équilibrage reportés après l'alpha test 1, d'après les retours des joueurs (TODO).
4. Interface et confort : **mode tactique en combat** (GDD § 14.3), menu pause et options
   (`client/options.gd`, `user://options.cfg`) **faits** ; reste la fenêtre des quêtes (avec le
   chantier 6, faite) et les petits conforts (infobulles comparées, raccourcis).
6. Quêtes : conception validée (`docs/design/chantier6_quetes.md`). **Lots 1 (système :
   `core/quests/`, journal Q, suivi, marques `!`/`?`) et 2 (tutoriels et acte I, script
   `docs/design/chantier6/produire_lot2.py`), 3 (15 secondaires, `produire_lot3.py`) et 4 (acte II,
   Conseil et Brèche, `produire_lot4.py`) faits** : tout le contenu de quêtes de l'alpha 1 est
   produit. Option restante : secondaires de Hautepierre, marqueur de quête sur la carte du monde.

**Lancement de l'alpha test 1 en préparation** (version 0.6.0, GitHub Pages) : guide des testeurs à
jour, questionnaire de référence `docs/FORMULAIRE_ALPHA1.md` (à reporter à la main dans le Google
Forms : le connecteur Drive ne lit pas les formulaires), bouton « Donner son avis » en jeu
(`Session.FEEDBACK_URL`). Checklist : TODO, Phase 2, « Lancement de l'alpha test 1 ».

## Règles de design à respecter (détails dans le GDD)

- Zones de départ : paliers 1–3 / 4–6 / 7–9 / 10–12, asymétriques entre zones (§ 3.5).
- Niveau variable dans une famille, pondéré ; élites à niveau fixe, au-dessus de la famille.
- Le niveau d'un monstre change ses stats, jamais son butin ; PA/PM fixes par famille sauf exception.
- Butin : limite par monstre partagée entre joueurs, tirage du plus prospecteur au moins prospecteur.
- Combat : cases de placement prédéfinies par carte, pour chaque camp (comme Dofus), calque
  `placement` obligatoire sur toute carte à groupes.
- Mini-boss : réapparition ≤ 60 s pendant l'alpha, phases de profils différents selon leur thème,
  jamais de soin à un changement de phase.
