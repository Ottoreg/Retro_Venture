# Données de contenu

Le contenu du jeu est décrit en JSON ([décision 0003](../../docs/decisions/0003-donnees-json.md)),
modifiable sans recompiler et vérifié par les tests à chaque push
(voir [GDD § 16.3](../../docs/GDD.md#163-contenu-piloté-par-les-données) et les exemples en
[annexe du GDD](../../docs/GDD.md#20-annexes--formats-de-données)).

Conventions : clés en français sans accents, une case = `[x, y]`, un fichier par élément, `id` égal au
nom du fichier.

## Cartes (`cartes/`)

Une carte est un rectangle entièrement couvert de cases en losange, en rangées décalées comme dans
Dofus. Elle est décrite par un **plan texte** : une ligne par rangée, un caractère par case.

```json
{
  "id": "brumerive_0_0",
  "nom": "Brumerive — Place du village",
  "plan": [
    "AAA..AA.....AA..AAA",
    " AA..............AA",
    "A.....M............",
    " .....MM......@....",
    "......M....R......A"
  ]
}
```

- Toutes les lignes ont la même longueur (le nombre de cases par rangée).
- Les lignes **paires** (2e, 4e…) sont décalées d'une demi-case vers la gauche : elles commencent par
  un **espace**, qui représente la demi-case coupée par le bord.
- Le nombre de lignes est **impair**. Les demi-cases du haut, du bas et des côtés sont ajoutées
  automatiquement pour remplir le cadre ; elles sont décoratives et non jouables.
- Taille de référence : **19 caractères × 33 lignes** (1216 × 544 px à l'écran).

| Caractère | Case |
|---|---|
| `.` | Sol praticable |
| `@` | Case d'apparition du joueur (exactement une) |
| `A` | Arbre |
| `M` | Mur / bâtiment |
| `R` | Rocher |
| `E` | Eau (bloque le passage, mais pas la vue) |

Les tests vérifient chaque carte : format du plan, `id` égal au nom du fichier, et **toutes les cases
praticables accessibles** depuis le départ.

## À venir

`races/`, `voies/`, `sorts/`, `monstres/`, `objets/`, `butin/`, `recettes/`, `quetes/`.
