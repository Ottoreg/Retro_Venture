# Données de contenu

Le contenu du jeu est décrit en JSON ([décision 0003](../../docs/decisions/0003-donnees-json.md)),
modifiable sans recompiler et vérifié par les tests à chaque push
(voir [GDD § 16.3](../../docs/GDD.md#163-contenu-piloté-par-les-données) et les exemples en
[annexe du GDD](../../docs/GDD.md#20-annexes--formats-de-données)).

Conventions : clés en français sans accents, une case = `[x, y]`, un fichier par élément, `id` égal au
nom du fichier.

## Cartes (`cartes/`)

```json
{
  "id": "brumerive_0_0",
  "nom": "Brumerive — Place du village",
  "largeur": 16,
  "hauteur": 16,
  "depart": [6, 6],
  "obstacles": {
    "arbre": [[0, 0], [1, 0]],
    "mur": [[10, 6]],
    "rocher": [[7, 8]],
    "eau": [[3, 10]]
  }
}
```

| Clé | Rôle |
|---|---|
| `id` | Identifiant, égal au nom du fichier. Convention : `<region>_<x>_<y>` (position sur la carte du monde) |
| `nom` | Nom affiché |
| `largeur`, `hauteur` | Taille en cases |
| `depart` | Case d'apparition du joueur (doit être praticable) |
| `obstacles` | Cases bloquantes, groupées par type. Types affichés : `arbre`, `mur`, `rocher`, `eau` (plat) |

Le repère des cases est décrit dans la [décision 0004](../../docs/decisions/0004-grille-isometrique.md).

## À venir

`races/`, `voies/`, `sorts/`, `monstres/`, `objets/`, `butin/`, `recettes/`, `quetes/`.
