# Retro Venture

[![CI](https://github.com/Ottoreg/Retro_Venture/actions/workflows/ci.yml/badge.svg)](https://github.com/Ottoreg/Retro_Venture/actions/workflows/ci.yml)

▶️ **Jouer dans le navigateur : https://ottoreg.github.io/Retro_Venture/** (dernière version de la branche par défaut)
— commandes et contenu de l'alpha : [guide des testeurs](docs/GUIDE_TESTEURS.md)

RPG tactique au tour par tour en 2D isométrique, inspiré de *Dofus Rétro* pour le rendu et le gameplay
et du *Seigneur des Anneaux* pour l'univers, sur un ton parodique. Les aventuriers parcourent le monde à la recherche des
**Reliques de l'Aube**, des objets légendaires dispersés, seules armes capables de vaincre le
**Souverain Cendré** avant qu'il n'asservisse le monde.

Le jeu se développe d'abord **en solo**, puis évolue vers un **multijoueur en ligne** sur un serveur
global découpé en instances.

## Statut

🟢 **Phase 1 — Prototype** : deux cartes reliées, PNJ avec dialogues, combat tactique jouable contre des loups et des gobelins.

## Documentation

| Document | Contenu |
|---|---|
| [docs/GDD.md](docs/GDD.md) | Game Design Document : vision, univers, systèmes, architecture, phases |
| [docs/TODO.md](docs/TODO.md) | Liste des tâches par phase |
| [docs/design/](docs/design/) | Documents de design détaillés (équilibrage, formules, tableurs) |
| [docs/lore/](docs/lore/) | Univers, histoire, personnages, régions |
| [docs/decisions/](docs/decisions/) | Journal des décisions techniques et de design |

## Feuille de route

| Phase | Objectif |
|---|---|
| 0. Pré-production | Moteur choisi, GDD validé |
| 1. Prototype | Un combat jouable de bout en bout |
| 2. Alpha solo | 3 races (une par camp : allié, ennemi, neutre), 3 classes, combat + butin, quêtes simples, 3 métiers, équipement |
| 3. Solo étendu | 9 races (+ Nains, Orcs, Semi-hommes, Géants, Squelettes, Lutins), 9 classes (+ Paladin, Myrmidon, Ombre, Venomancien, Théologue, Démoniste), système des Voies, donjons, quêtes complexes, légendaires |
| 4. Fondations réseau | Serveur autoritaire, comptes, combat à plusieurs |
| 5. Multijoueur | Instances, groupe, amis, chat, échanges, guildes |

## Structure du dépôt

```
Retro_Venture/
├── docs/          # GDD, TODO, design, lore, décisions
├── .github/       # Intégration continue (tests Godot)
└── game/          # Projet Godot 4
    ├── core/      # Noyau de jeu : règles, sans affichage (partagé solo / futur serveur)
    ├── client/    # Scènes, rendu isométrique, interface, audio
    ├── data/      # Contenu piloté par les données (sorts, monstres, objets, quêtes…)
    ├── assets/    # Graphismes, sons, musiques, polices
    └── tests/     # Tests automatisés
```

## Démarrer

**Sans rien installer :** chaque push déclenche la CI, qui lance les tests, exporte le jeu pour le
web et le publie sur GitHub Pages (lien ci-dessus) en quelques minutes. Les résultats des tests sont
visibles dans l'onglet [Actions](https://github.com/Ottoreg/Retro_Venture/actions) (résumé en bas
de chaque exécution).

**Avec l'éditeur :**

1. Installer [Godot 4.5](https://godotengine.org/download) (version standard, pas .NET).
2. Ouvrir `game/project.godot` dans l'éditeur, puis lancer avec **F5**.
3. Tests en ligne de commande :
   ```sh
   godot --headless --path game --import
   godot --headless --path game -s res://tests/run_tests.gd
   ```

Choix techniques : [moteur Godot 4](docs/decisions/0001-moteur-godot-4.md),
[langage GDScript](docs/decisions/0002-langage-gdscript.md),
[données JSON](docs/decisions/0003-donnees-json.md),
[grille 64×32](docs/decisions/0004-grille-isometrique.md).
