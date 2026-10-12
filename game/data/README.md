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
| `@` | Case d'apparition par défaut (exactement une) |
| `1`…`9` | Groupe de monstres (voir ci-dessous) |
| `a`…`z` | PNJ (voir ci-dessous) |
| `A` | Arbre |
| `M` | Mur / bâtiment |
| `R` | Rocher |
| `E` | Eau (bloque le passage, mais pas la vue) |
| `:` | Chemin de terre (praticable) |
| `#` | Case bloquée invisible, sous un grand décor (bâtiment) |
| `+` | Porte vers une autre carte (voir « Portes » ci-dessous), praticable |
| `*` | Pierre de Passage (voir `passages/`) |
| `$` | Coffre (maison du joueur) |
| `=` | Lit (maison du joueur) |
| Autres majuscules | Ressource de métier, définie dans `metiers/` : `F` frêne, `C` chêne, `U` cuivre, `I` fer |

Les tests vérifient chaque carte : format du plan, `id` égal au nom du fichier, et **toutes les cases
praticables accessibles** depuis le départ.

### Groupes de monstres

Les chiffres `1` à `9` dans le plan placent les groupes décrits dans la liste `groupes` (le chiffre
`1` correspond au premier groupe). Chaque groupe apparaît une seule fois et compte 1 à 3 monstres,
d'une ou de plusieurs espèces, tous dessinés sur la carte. Un groupe est soit une liste fixe
(`monstres`), soit tiré au sort à chaque apparition (`parmi` : les espèces possibles, `nombre` :
[min, max], 3 au plus) ; on ne peut pas mettre les deux.

```json
"groupes": [
  {"monstres": ["loup_des_collines"]},
  {"monstres": ["gobelin_frondeur", "loup_des_collines"], "reapparition": [60, 90]},
  {"parmi": ["rat_des_galeries", "grouilleur"], "nombre": [2, 3]}
]
```

Un groupe vaincu réapparaît à sa place au bout d'un délai tiré dans `reapparition` (en secondes,
2 à 3 minutes par défaut), mais jamais sous les pieds du joueur.

### PNJ

Les lettres minuscules (`a` à `z`) du plan placent les PNJ décrits dans la liste `pnj`, par leur
`marqueur`. Un PNJ bloque sa case ; un clic dessus fait venir le joueur à côté, puis le PNJ dit ses
répliques une par une, dans une bulle.

```json
"pnj": [
  {
    "marqueur": "a",
    "id": "alric_le_berger",
    "nom": "Alric le berger",
    "repliques": ["Ah, un aventurier ! Enfin !", "Méfiez-vous des frondeurs gobelins."]
  }
]
```

Avec `"marchand": true`, le PNJ ouvre une **boutique** au lieu de la bulle (sa première réplique sert
de salut). Il vend tous les objets de `objets/` et rachète tout objet non porté. Les prix dépendent de
la rareté (`Item.EQUIPMENT_PRICES` et `Item.RESOURCE_PRICES` dans `core/items/item.gd`) ; la
revente rapporte un quart du prix d'achat (`Item.RESALE_RATE`), au moins 1 écu.

| Rareté | Équipement | Ressource |
|---|---|---|
| Commun | 40 | 4 |
| Peu commun | 120 | 12 |
| Rare | 350 | 35 |
| Épique | 900 | 90 |
| Légendaire | 2 500 | 250 |
| Relique | 6 000 | 600 |

Avec `"atelier": "forgeron"` (id d'un métier d'artisanat), le PNJ ouvre l'**atelier** de ce métier :
la liste de ses recettes, les ingrédients possédés et la fabrication.

### Grands décors (bâtiments)

`decors` pose de grandes images (voir `game/art/art.json`) sur la carte. `case` est la case
**avant** du bâtiment (la plus proche du bas de l'écran), en `[ligne, colonne]` du plan ; l'emprise
(3 × 3 cases pour la maison et l'auberge) doit être remplie de `#` dans le plan.

```json
"decors": [{"image": "maison", "case": [11, 5]}]
```

### Portes, intérieurs et maison

Chaque `+` du plan est une porte : la liste `portes` donne, dans l'ordre du plan (de haut en bas,
puis de gauche à droite), l'id de la carte où elle mène. On arrive sur la porte de cette carte qui
ramène d'où l'on vient (les tests vérifient que chaque porte a sa réciproque).

```json
"portes": ["maison_joueur"]
```

- `palette` : couleurs de la zone (`brumerive`, `crasse_roc`, `sylvebrume` ; voir
  `game/art/art.json`). Crasse-Roc est volontairement terne et sombre.
- `sol` : `herbe` (par défaut) ou `parquet` pour un intérieur.
- `instance` : `""` (par défaut, carte partagée) ou `joueur` pour une carte personnelle, comme la
  maison : en multijoueur, chaque joueur aura sa propre copie (et son coffre).
- La maison (`maison_joueur`) contient un coffre `$` (on y range des objets non portés) et un lit `=`
  (dormir rend tous les PV). On les utilise depuis une case voisine.

### Sorties

`sorties` relie les bords de la carte aux cartes voisines (`haut`, `bas`, `gauche`, `droite`).
Un clic sur une case praticable du bord concerné (ou juste derrière) fait passer sur la carte
voisine ; on arrive sur le bord opposé, à la même hauteur. Chaque sortie doit avoir sa réciproque
(si A mène à B par la droite, B mène à A par la gauche) : les tests le vérifient.

```json
"sorties": {"droite": "brumerive_1_0"}
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

Effets sans dégâts : `teleportation` (le lanceur saute sur la case visée, qui doit être libre ;
pas de `min`/`max`), `gain_pa` (PA en plus tout de suite), `retrait_pm` (PM en moins au prochain
tour de la cible).

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

## Objets (`objets/`)

```json
{
  "id": "epee_de_fer",
  "nom": "Épée de fer",
  "type": "arme",
  "rarete": "commun",
  "niveau": 1,
  "description": "Une épée honnête.",
  "bonus": {"force": [2, 5]},
  "conditions": {"force": 10},
  "attaque": {"cout_pa": 4, "portee": {"min": 1, "max": 1}, "effets": [{"type": "degats", "element": "acier", "min": 7, "max": 11}]}
}
```

| Clé | Rôle |
|---|---|
| `type` | `ressource` (s'empile) ou équipement : `arme`, `coiffe`, `cape`, `amulette`, `anneau`, `ceinture`, `bottes` |
| `rarete` | `commun`, `peu_commun`, `rare`, `epique`, `legendaire`, `relique` (couleur dans l'interface) |
| `niveau` | Niveau requis pour l'équiper |
| `bonus` | Plages `[min, max]` tirées au hasard à l'obtention (« jets ») : les 6 caractéristiques, `prospection`, `initiative`, `portee`, `pa`, `pm` |
| `conditions` | Caractéristiques minimales pour l'équiper (optionnel) |
| `attaque` | Armes seulement : attaque utilisable en combat, décrite comme un sort |

## Butin des monstres

Dans chaque monstre : `butin` (liste) et `ecus` (`[min, max]`).

```json
"butin": [
  {"objet": "croc_de_loup", "taux": 0.5, "quantite": [1, 2]},
  {"objet": "cape_en_peau_de_loup", "taux": 0.03}
],
"ecus": [2, 6]
```

Chance = `taux × prospection / 100` (au plus 100 %), sans seuil : un personnage seul peut tout obtenir.
Prospection = 100 + Chance / 10 + bonus d'équipement. Le butin n'est donné qu'en cas de victoire.

Dans chaque Voie : `equipement_depart` (liste d'objets donnés et équipés à la création).

## Races (`races/`)

```json
{
  "id": "elfe",
  "nom": "Elfe",
  "camp": "neutre",
  "description": "« Ce n'est pas notre guerre. »",
  "bonus": {"agilite": 10, "intelligence": 10},
  "passif": {"nom": "Œil perçant", "description": "+1 portée…", "effet": {"type": "portee", "valeur": 1}},
  "sort": "elfe_pas_leger",
  "carte_depart": "brumerive_0_0"
}
```

`camp` : `allie`, `ennemi` ou `neutre`. `bonus` : points ajoutés aux caractéristiques (`vitalite`,
`sagesse`, `force`, `intelligence`, `chance`, `agilite`). `passif.effet` est optionnel ; seul
`portee` est géré pour l'instant. `sort` : sort racial, ajouté aux sorts de la Voie.

Les tests vérifient tous ces fichiers (format, `id` égal au nom du fichier, sorts et monstres
référencés existants).

## Pierres de Passage (`passages/`)

Une Pierre de Passage par fichier ; on voyage de n'importe laquelle vers les autres. La carte
indiquée doit avoir une pierre `*` dans son plan : on arrive à côté.

```json
{"id": "crasse_roc", "nom": "Crasse-Roc", "carte": "crasse_roc_0_0"}
```

## Métiers (`metiers/`)

Un métier de **récolte** décrit les ressources qu'on trouve sur les cartes. Chacune a son caractère
dans le plan (`marqueur`, une majuscule hors de la légende), bloque sa case et se récolte depuis une
case voisine. Une fois récoltée, elle repousse au bout d'un temps tiré dans `repousse` (en secondes).

```json
{
  "id": "bucheron", "nom": "Bûcheron", "type": "recolte",
  "ressources": [
    {"marqueur": "F", "nom": "Frêne", "objet": "bois_de_frene", "niveau": 1, "quantite": [1, 3],
     "xp": 5, "repousse": [60, 120], "apparence": "arbre", "couleur": "79a845"}
  ]
}
```

- `objet` : ressource obtenue (`quantite` : [min, max] par récolte) ; `niveau` : niveau de métier requis.
- `apparence` : `arbre` ou `rocher` ; `couleur` : feuillage de l'arbre ou veines du minerai.

Un métier d'**artisanat** liste ses recettes ; on fabrique auprès d'un PNJ qui tient son `atelier`.
Les équipements fabriqués ont des jets tirés au hasard.

```json
{
  "id": "forgeron", "nom": "Forgeron", "type": "artisanat",
  "recettes": [
    {"objet": "epee_de_fer", "niveau": 2, "xp": 15, "ingredients": {"minerai_de_fer": 4, "bois_de_frene": 2}}
  ]
}
```

Niveaux de métier : 1 à 100, XP totale pour le niveau n = 5 × n × (n − 1). Les Humains gagnent 10 %
d'XP de métier en plus (passif `{"type": "xp_metier", "valeur": 10}`).

## À venir

`quetes/`.
