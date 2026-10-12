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

### Groupes de monstres

Les chiffres `1` à `9` dans le plan placent les groupes décrits dans la liste `groupes` (le chiffre
`1` correspond au premier groupe). Chaque groupe apparaît une seule fois et compte 1 à 8 monstres.

```json
"groupes": [
  {"monstres": ["loup_des_collines"]},
  {"monstres": ["gobelin_frondeur", "loup_des_collines"]}
]
```

## Sorts (`sorts/`)

```json
{
  "id": "guerrier_frappe",
  "nom": "Frappe",
  "description": "Un bon coup d'épée.",
  "cout_pa": 3,
  "portee": {"min": 1, "max": 1},
  "ligne_de_vue": true,
  "zone": {"type": "case"},
  "lanceur_exclu": false,
  "relance": {"par_tour": 2, "delai": 0},
  "effets": [{"type": "degats", "element": "acier", "min": 8, "max": 12}]
}
```

| Clé | Rôle |
|---|---|
| `cout_pa` | Points d'action dépensés |
| `portee` | Distance en cases (4 directions) ; `0` = sur soi |
| `ligne_de_vue` | La cible doit être visible (défaut : `true`). Arbres, rochers, murs et combattants bloquent la vue ; l'eau non |
| `zone` | `case` ou `cercle` avec `taille` (rayon) |
| `lanceur_exclu` | Le lanceur n'est pas touché par sa propre zone |
| `relance.par_tour` | Lancers maximum par tour (`0` = illimité) |
| `relance.delai` | Tours à attendre avant de relancer |
| `effets` | `degats` (avec `element` : `acier`, `flamme`, `givre`, `tempete`) ou `soin`, avec `min` et `max` |

## Monstres (`monstres/`)

```json
{
  "id": "loup_des_collines",
  "nom": "Loup des collines",
  "niveau": 3,
  "caracteristiques": {"pv": 26, "pa": 6, "pm": 4, "initiative": 110},
  "resistances": {"acier": 0, "flamme": -10},
  "sorts": ["loup_morsure"],
  "ia": "basique",
  "xp": 30
}
```

`resistances` en % par élément (négatif = faiblesse). `ia` : seul `basique` existe pour l'instant
(frappe si possible, sinon se place pour tirer, sinon se rapproche).

## Voies / classes (`voies/`)

```json
{
  "id": "guerrier",
  "nom": "Guerrier",
  "caracteristiques": {"pv": 60, "pa": 6, "pm": 3, "initiative": 100},
  "sorts": ["guerrier_frappe", "guerrier_hache", "guerrier_tourbillon", "guerrier_second_souffle"]
}
```

Les tests vérifient tous ces fichiers (format, `id` égal au nom du fichier, sorts et monstres
référencés existants).

## À venir

`races/`, `objets/`, `butin/`, `recettes/`, `quetes/`.
