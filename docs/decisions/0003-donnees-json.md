# 0003 — Format des données de contenu : JSON

**Date :** 2026-10-12 · **Statut :** acceptée

## Contexte

Races, classes, sorts, monstres, objets, recettes, quêtes et cartes sont décrits par des fichiers de
données (voir [GDD § 16.3](../GDD.md#163-contenu-piloté-par-les-données)). Options : JSON, YAML,
ressources Godot (`.tres`).

## Décision

**JSON**, dans `game/data/`, un sous-dossier par type de contenu (`cartes/`, `sorts/`…).

- Lisible et modifiable directement dans GitHub, sans éditeur Godot.
- Lu nativement par Godot (pas de dépendance) et par n'importe quel outil ou futur serveur.
- Vérifié automatiquement par la CI (`game/tests/data/`) : syntaxe, puis règles par type de contenu.

## Conventions

- Clés en français, en minuscules, sans accents (`largeur`, `depart`, `niveau_requis`).
- Une case = `[x, y]`.
- Un fichier = un élément ; l'`id` est égal au nom du fichier sans extension (`brumerive_0_0.json`
  a pour id `brumerive_0_0`).

## Conséquences

- Pas d'édition visuelle dans l'inspecteur Godot ; un éditeur de cartes dédié pourra venir plus
  tard (voir backlog de la TODO).
- Les nombres JSON sont lus comme des flottants : le code convertit explicitement en entiers.
