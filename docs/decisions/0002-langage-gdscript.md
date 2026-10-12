# 0002 — Langage : GDScript

**Date :** 2026-10-12 · **Statut :** acceptée

## Contexte

Godot 4 propose GDScript et C#.

## Décision

**GDScript**, avec **typage statique** systématique (`var x: int`, `-> void`).

- Aucune dépendance .NET : installation et CI plus simples.
- Export web possible (les projets C# ne s'exportent pas vers le web sous Godot 4).
- Intégration maximale avec l'éditeur et rechargement à chaud.
- Un même langage pour le client et le futur serveur headless.

## Conséquences

- Si un calcul devient trop coûteux côté serveur (IA, simulation d'équilibrage), il pourra être
  réécrit ponctuellement en C++ (GDExtension) sans changer le reste du code.
- Tests : lanceur maison minimal (`game/tests/run_tests.gd`), sans dépendance externe. À remplacer
  par GUT si les besoins grandissent.
