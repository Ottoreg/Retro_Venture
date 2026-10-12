# Retro Venture

RPG tactique au tour par tour en 2D isométrique, inspiré de *Dofus Rétro* pour le rendu et le gameplay
et du *Seigneur des Anneaux* pour l'univers. Les aventuriers parcourent le monde à la recherche des
**Reliques de l'Aube**, des objets légendaires dispersés, seules armes capables de vaincre le
**Souverain Cendré** avant qu'il n'asservisse le monde.

Le jeu se développe d'abord **en solo**, puis évolue vers un **multijoueur en ligne** sur un serveur
global découpé en instances.

## Statut

🟡 **Phase 0 — Pré-production** : cadrage du design, choix techniques.

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
| 2. Alpha solo | 3 races, 3 classes, combat + butin, quêtes simples, 3 métiers, équipement |
| 3. Solo étendu | ~10 races et classes, système des Voies, donjons, quêtes complexes, légendaires |
| 4. Fondations réseau | Serveur autoritaire, comptes, combat à plusieurs |
| 5. Multijoueur | Instances, groupe, amis, chat, échanges, guildes |

## Structure du dépôt

```
Retro_Venture/
├── docs/          # GDD, TODO, design, lore, décisions
├── data/          # Contenu du jeu piloté par les données (sorts, monstres, objets, quêtes…)
├── assets/        # Graphismes, sons, musiques, interface
└── game/          # Projet du moteur (créé en Phase 0, après le choix du moteur)
```
