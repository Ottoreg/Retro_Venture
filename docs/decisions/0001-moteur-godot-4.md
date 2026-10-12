# 0001 — Moteur : Godot 4

**Date :** 2026-10-12 · **Statut :** acceptée

## Contexte

Il faut un moteur adapté à un RPG tactique 2D isométrique, jouable d'abord en solo puis en ligne
avec un serveur autoritaire (voir [GDD § 16](../GDD.md#16-architecture-technique)).

## Options envisagées

Godot 4, Phaser + Node/Colyseus (TypeScript), Unity — comparatif au
[GDD § 16.2](../GDD.md#162-choix-de-moteur).

## Décision

**Godot 4**, version de référence **4.5.x** (`config/features` dans `game/project.godot`, variable
`GODOT_VERSION` dans `.github/workflows/ci.yml`).

- Projet dans `game/` ; documentation hors projet dans `docs/`.
- Moteur de rendu **Compatibility** (OpenGL) : suffisant pour de la 2D, plus large compatibilité
  matérielle, requis pour l'export web.
- Résolution de référence 1280×720, mise à l'échelle `canvas_items` / `expand`.
- Le serveur multijoueur sera un export **sans affichage** (headless) du même projet, réutilisant `core/`.

## Conséquences

- La couche réseau MMO (instances, comptes, persistance) est à construire nous-mêmes (Phase 4).
- Monter de version de Godot = mettre à jour `config/features`, `GODOT_VERSION` dans la CI, et
  ouvrir le projet dans le nouvel éditeur pour convertir les fichiers.
