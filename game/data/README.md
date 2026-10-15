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

### Cases de placement en combat

Comme dans Dofus, le combat démarre sur des cases prévues par la carte, où que le groupe ait été
engagé. Elles sont données par un **calque** `placement`, de même taille que le plan (même nombre
de lignes, mêmes longueurs, espace en tête des lignes décalées) :

```json
"placement": [
  "...................",
  " ....j........m....",
  "......j.....m......"
]
```

| Caractère | Case |
|---|---|
| `j` | Case de départ d'un joueur (le joueur commence sur la première, dans l'ordre du calque, et choisit parmi toutes pendant le placement) |
| `m` | Case de départ d'un monstre (les monstres du groupe y sont répartis au hasard) |
| `.` | Rien |

- **Obligatoire** sur une carte qui a des groupes de monstres : au moins une case `j` et au moins
  3 cases `m` (la taille maximale d'un groupe) ; facultatif ailleurs (maisons).
- Chaque case `j` ou `m` doit être praticable dans le plan (`.`, `@`, `:` ou un chiffre de groupe).
- Conseil : 6 cases par camp, non voisines, les deux camps face à face à 6–8 cases d'écart, sans
  ligne de vue directe partout. `python3 tools/placement.py <carte.json>` (depuis `game/`) propose
  un calque de ce genre ; `--ecrire` l'ajoute au fichier.

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
2 à 3 minutes par défaut), mais jamais sous les pieds du joueur ni sur un autre groupe.

En exploration, les groupes se promènent : toutes les 8 à 20 secondes, quelques pas (3 au plus)
sans s'éloigner de plus de 3 cases de leur place d'origine, ni aller sur le joueur, un autre groupe,
une porte, un bord de sortie ou derrière un bâtiment. La sauvegarde garde la composition et la place
de chaque groupe, et le niveau de chaque monstre (tiré à nouveau s'il ne peut plus l'avoir : hors de
sa tranche ou de poids nul, après un changement des données).

À chaque apparition (première visite, réapparition, arrivée d'une élite), chaque monstre du groupe
reçoit son niveau, tiré dans la tranche de sa famille (voir `niveaux` dans *Monstres*) ; la bulle du
groupe le montre devant son nom (« Niv. 2 Rat des galeries »).

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

- `palette` : couleurs de la zone (`brumerive`, `crasse_roc`, `sylvebrume`, `forges` (lave),
  `hautepierre`, `cendree`, `cendre` ; voir `game/art/art.json` et `game/art/manifestes/`). Crasse-Roc est volontairement terne et sombre.
- `sol` : `herbe` (par défaut) ou `parquet` pour un intérieur.
- `instance` : `""` (par défaut, carte partagée) ou `joueur` pour une carte personnelle, comme la
  maison : en multijoueur, chaque joueur aura sa propre copie (et son coffre).
- Chaque zone de départ a sa maison (`maison_joueur` à Brumerive, `maison_crasse_roc`,
  `maison_sylvebrume`) ; le coffre est le même partout (il appartient au personnage).
- La maison contient un coffre `$` (on y range des objets non portés) et un lit `=`
  (dormir rend tous les PV). On les utilise depuis une case voisine.

### Sorties

`sorties` relie les bords de la carte aux cartes voisines (`haut`, `bas`, `gauche`, `droite`).
Un clic sur une case praticable du bord concerné (ou juste derrière) fait passer sur la carte
voisine ; on arrive sur le bord opposé, à la même hauteur. Chaque sortie doit avoir sa réciproque
(si A mène à B par la droite, B mène à A par la gauche) : les tests le vérifient.

```json
"sorties": {"droite": "brumerive_1_0"}
```

### Coordonnées sur la carte du monde

L'id d'une carte extérieure est `<zone>_<x>_<y>` (`brumerive_1_0`, `crasse_roc_0_-2`) : x vers la
droite (l'est), y vers le bas (le sud), éventuellement négatifs. La carte du monde (touche M) place
les cartes d'une zone en grille d'après ces coordonnées et nomme la zone d'après sa Pierre de
Passage (à défaut, d'après ce qui précède « — » dans le nom de ses cartes) ; la case affiche ce qui
suit « — » (`"Brumerive — Champs de l'est"` → « Champs de l'est »). Une carte sans coordonnées
(maison, intérieur, comme `maison_joueur`) n'y figure pas. Les sorties doivent relier des cartes
voisines de la même zone dans la grille (droite : x + 1, bas : y + 1) ; c'est vérifié par
`tests/data/test_donnees.gd`.

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
| `zone` | `case`, `cercle` avec `taille` (rayon), ou `croix_latine` : 4 cases dans le sens du lancer depuis la case visée, plus une de chaque côté de la 3e (tête de la croix au loin) (demande `lancer_en_ligne` et une portée minimale d'au moins 1) |
| `lancer_en_ligne` | La cible doit être sur la même ligne ou la même colonne de la grille que le lanceur (défaut : `false`) |
| `lanceur_exclu` | Le lanceur n'est pas touché par sa propre zone |
| `relance.par_tour` | Lancers maximum par tour (`0` = illimité) |
| `relance.delai` | Tours à attendre avant de relancer |
| `critique` | Chance de coup critique en % (défaut : 5 ; `0` = jamais). Critique : dégâts, soins, boucliers et poisons × 1,5 |
| `effets` | `degats`, `soin` ou `bouclier`, avec `min`, `max` et `element` (`acier`, `flamme`, `givre`, `tempete`, ou les éléments composés `sacre` et `impie`) |

Chaque effet chiffré grandit avec la caractéristique de son élément : un soin `sacre` avec la Force
et l'Intelligence, un bouclier `tempete` avec l'Agilité, etc. `bouclier` donne à la cible des points
qui absorbent les dégâts avant ses PV ; ils s'additionnent et disparaissent au début de son
prochain tour.

Chaque effet peut avoir `cibles` : `tous` (défaut), `ennemis` ou `allies` (le camp du lanceur). Le
Sermon blesse ainsi les ennemis de sa zone et soigne les alliés.

Effets sans dégâts : `teleportation` (le lanceur saute sur la case visée, qui doit être libre ;
pas de `min`/`max`), `gain_pa` (PA en plus tout de suite), `retrait_pm` (PM en moins au prochain
tour de la cible).

Effets durables (`duree` : tours de la cible ; un état perd un tour à la fin de chacun de ses tours) :

```json
{"type": "bonus", "carac": "force", "min": 20, "max": 30, "duree": 2}
{"type": "malus", "carac": "resistance", "element": "givre", "min": 10, "max": 10, "duree": 2}
{"type": "poison", "element": "givre", "min": 4, "max": 6, "duree": 3}
```

- `bonus` / `malus` : `carac` parmi `force`, `intelligence`, `chance`, `agilite`, `pa`, `pm`,
  `portee`, `dommages`, `critique`, `resistance` (avec `element`). PA et PM comptent tout de suite.
- `poison` : dégâts de l'élément au début de chaque tour de la cible (Dommages non ajoutés).
- `poussee` / `attirance` (`min`, `max` en cases) : en ligne droite, depuis le lanceur ou vers lui ;
  une poussée arrêtée par un obstacle inflige 4 dégâts de choc par case manquée.

Au sol :

```json
{"type": "glyphe", "duree": 2, "effets": [
  {"type": "soin", "element": "tempete", "min": 8, "max": 12, "cibles": "allies"},
  {"type": "malus", "carac": "pm", "min": 2, "max": 2, "duree": 1, "cibles": "ennemis"}]}
{"type": "piege", "zone": {"type": "cercle", "taille": 1}, "effets": [
  {"type": "degats", "element": "acier", "min": 8, "max": 12, "cibles": "ennemis"}]}
```

- `glyphe` : couvre la `zone` du sort pendant `duree` tours du lanceur ; ses `effets` s'appliquent à
  qui commence son tour dessus.
- `piege` : posé sur la case visée (libre, sans autre piège), invisible pour l'autre équipe ; le
  premier ennemi qui y entre s'arrête et le déclenche, ses `effets` touchent la `zone` du piège
  (`case` par défaut, ou `cercle`). Un sort de piège n'a que cet effet et une zone `case`.
- Les effets d'une glyphe ou d'un piège ne peuvent pas être une glyphe, un piège ou une téléportation.

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

`caracteristiques` : `pv`, `pa`, `pm`, `initiative`, et en option `force`, `intelligence`, `chance`,
`agilite` (entiers ≥ 0, 0 par défaut) : comme pour les joueurs, +1 % de dégâts de l'élément par point
(Force pour l'Acier, Intelligence pour la Flamme, etc.).

`resistances` en % par élément (négatif = faiblesse). La résistance au Sacré est la moyenne des
résistances à l'Acier et à la Flamme, plus la résistance au Sacré (`sacre`, facultatif) : 10 % Flamme,
5 % Acier et 5 % Sacré donnent 12,5 %. Celle à l'Impie : moyenne de la Tempête et du Givre, plus
`impie`. De même, le bonus de dégâts Sacré est
Force + Intelligence, et l'Impie Agilité + Chance. `ia` : `basique` (se rapproche par
le plus court chemin pour frapper), `distance` (tire depuis la case la plus éloignée des ennemis, puis
recule) ou `soutien` (comme `distance`, pour les soigneurs). Dans tous les cas, l'IA note chaque sort
sur chaque cible utile et lance le meilleur tant qu'il vaut quelque chose.

Un monstre **élite** a `"elite": true` et sa `famille` (l'id du monstre normal dont il est la version
forte, par exemple `"famille": "loup_des_collines"` pour le Loup alpha). Il est plus haut niveau,
a au moins deux fois plus de PV, un sort d'attaque en plus, et lâche plus souvent les objets rares
de sa famille. Il est dessiné plus grand, avec un halo doré, et « (élite) » suit son nom au survol.
Chaque famille de monstres a son élite, sauf les boss.

Les élites ne se placent pas dans les `groupes` des cartes : le monde les fait apparaître lui-même
(voir `World` : toutes les 5 à 6 minutes de jeu, sur une carte au hasard où vit leur famille, une
seule en vie par espèce, avec un rang d'ancienneté qui augmente leur butin).

### Niveaux d'une famille

Les membres d'une famille (élites exceptées) apparaissent à n'importe quel niveau de la tranche de
leur palier (1–3, 4–6, 7–9, 10–12 dans une zone de départ), tiré à chaque apparition selon les poids
de la famille : une famille faible tire surtout bas, une forte surtout haut.

```json
"niveau": 1,
"niveaux": {"min": 1, "max": 3, "poids": [6, 3, 1]},
"caracteristiques": {"pv": 14, "pa": 5, "pm": 4, "initiative": 60},
"par_niveau": {"pv": 3, "initiative": 5, "xp": 4, "force": 5}
```

| Clé | Rôle |
|---|---|
| `niveau` | Niveau de base : celui des `caracteristiques`, `resistances` et `xp` écrits dans le fichier |
| `niveaux` | Facultatif. `min` (égal à `niveau`), `max` (≥ `min`) et `poids` : un entier ≥ 0 par niveau de `min` à `max`, de somme non nulle (un poids nul n'est jamais tiré). Sans `niveaux`, le niveau est fixe. Interdit sur une élite et un boss (niveau fixe) |
| `par_niveau` | Facultatif. Ajouté pour chaque niveau au-dessus de `niveau` : `pv`, `initiative`, `xp`, `force`, `intelligence`, `chance`, `agilite` (entiers ≥ 0), `resistances` (`{élément: entier}`, ajouté aux résistances) et, par exception, `pa` et `pm` |

Dans l'exemple, un rat de niveau 3 a 20 PV, 70 d'initiative, 20 XP et 10 de Force. Le niveau ne
change **pas** le butin : même table, mêmes taux, mêmes quantités et mêmes écus à tous les niveaux.
PA et PM restent les mêmes dans toute la famille ; `pa` et `pm` dans `par_niveau` sont réservés à une
famille dont la mécanique en dépend. Les élites restent au-dessus de toute la tranche de leur
famille.

### Boss et phases

Un **boss** (`"boss": true`) est un monstre unique : ni `famille` ni `elite`, pas d'élite à lui, et un
niveau fixe (le Souverain Cendré).

Tout monstre peut avoir des `phases`, déclenchées quand ses PV tombent à un seuil :

```json
"phases": [
  {"pv": 50, "message": "Le Gardien des ronces perd patience !",
   "sorts": ["millenaire_ronces"],
   "effets": [{"type": "bonus", "carac": "force", "min": 40, "max": 40, "duree": 3},
              {"type": "bouclier", "element": "acier", "min": 60, "max": 60}]},
  {"pv": 20, "message": "« Vous ne m'aurez pas si facilement ! »",
   "effets": [{"type": "bonus", "carac": "pm", "min": 2, "max": 2, "duree": 3},
              {"type": "malus", "carac": "resistance", "element": "acier", "min": 20, "max": 20, "duree": 3}]}
]
```

| Clé | Rôle |
|---|---|
| `pv` | Seuil en % des PV max (1 à 99), strictement plus bas d'une phase à la suivante |
| `message` | Affiché comme message de combat et en texte flottant au-dessus du monstre |
| `sorts` | Facultatif. Sorts qu'il apprend pour le reste du combat |
| `effets` | Facultatif. Effets qu'il s'applique (il en est le lanceur) : mêmes formats que les effets des sorts (`bonus`, `malus`, `bouclier`, `gain_pa`, `poison`…), sans glyphe, piège, téléportation, poussée ni attirance, et **sans soin** |

Pas de soin à un changement de phase, ni dans `effets` ni dans les `sorts` appris (même dans une
glyphe ou un piège) : refusé à la validation, car un monstre qui remonte ses PV à chaque seuil peut
rendre un combat sans fin. Un mini-boss (`boss`) réapparaît vite pendant l'alpha : `reapparition`
de son groupe à 60 s au plus (règle de conception, vérifiée par le script de contrôle du chantier 3).

Une phase se déclenche une seule fois par combat, dès que les PV du monstre passent au seuil ou
dessous, quels que soient les dégâts (sort, poison, glyphe, piège, choc) ; s'il en franchit
plusieurs d'un coup, elles se déclenchent toutes, dans l'ordre. Un monstre vaincu ne change plus de
phase.

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
| `bonus` | Plages `[min, max]` tirées au hasard à l'obtention (« jets ») : les 6 caractéristiques, `prospection`, `initiative`, `portee`, `pa`, `pm`, `dommages` (dégâts bruts ajoutés à chaque ligne de dégâts, ni multipliés ni réduits par les résistances, pas sur les soins) |
| `conditions` | Caractéristiques minimales pour l'équiper (optionnel) |
| `boutique` | `false` : les marchands ne le vendent pas (trophée de boss, objet de butin rare) ; défaut `true` |
| `attaque` | Armes seulement : attaque utilisable en combat, décrite comme un sort |

## Panoplies (`panoplies/`)

```json
{
  "id": "pyromane_repenti",
  "nom": "Panoplie du Pyromane Repenti",
  "orientation": "flamme",
  "objets": ["coiffe_pyromane_repenti", "cape_pyromane_repenti", "…"],
  "bonus": {
    "2": {"intelligence": 10},
    "3": {"intelligence": 20, "dommages": 2}
  }
}
```

`objets` : au moins deux équipements, chacun dans une seule panoplie. `bonus` : par nombre de
pièces portées (de 2 au nombre de pièces), les bonus du palier (mêmes clés que le `bonus` des objets,
valeurs fixes). Le palier le plus haut atteint s'applique seul : il doit reprendre ce que donnaient
les précédents. `orientation` sert à l'affichage.

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
Prospection = 100 + Chance / 10 + bonus d'équipement + passif de race. Le butin n'est donné qu'en cas
de victoire.

**Limite par monstre** : chaque ligne donne au plus `quantite[1]` unités par monstre vaincu, tous
joueurs confondus. Chaque joueur tire la ligne à son tour, le plus prospecteur d'abord ; ce qu'il
obtient est retiré de ce qui reste (croc `[1, 2]` : si le premier joueur a eu 1 croc de ce loup, le
suivant ne peut plus en avoir qu'un). Deux loups ont chacun leur propre limite.

Dans chaque Voie : `equipement_depart` (liste d'objets donnés et équipés à la création).

## Races (`races/`)

```json
{
  "id": "elfe",
  "nom": "Elfe",
  "camp": "neutre",
  "description": "« Ce n'est pas notre guerre. »",
  "bonus": {"agilite": 10, "intelligence": 10},
  "passif": {"nom": "Œil perçant", "description": "+1 portée…", "effets": [{"type": "portee", "valeur": 1}]},
  "sort": "elfe_pas_leger",
  "carte_depart": "brumerive_0_0"
}
```

`camp` : `allie`, `ennemi` ou `neutre`. `bonus` : points ajoutés aux caractéristiques (`vitalite`,
`sagesse`, `force`, `intelligence`, `chance`, `agilite`). `passif.effets` est optionnel (liste de
`{type, valeur}`) ; types gérés : `portee` (portée des sorts à distance), `xp_metier` (% d'XP de
métier), `prospection` (points de prospection) et `ecus` (% d'écus de fin de combat). `sort` : sort racial, ajouté aux sorts de la Voie.

Les tests vérifient tous ces fichiers (format, `id` égal au nom du fichier, sorts et monstres
référencés existants).

## Pierres de Passage (`passages/`)

Une Pierre de Passage par fichier ; on voyage de n'importe laquelle vers les autres, déjà
découvertes. La carte indiquée doit avoir une pierre `*` dans son plan : on arrive à côté.

```json
{"id": "crasse_roc", "nom": "Crasse-Roc", "carte": "crasse_roc_0_0", "prix": 10}
```

| Champ | Obligatoire | Description |
| --- | --- | --- |
| `id`, `nom` | oui | Identifiant (nom du fichier) et nom affiché dans la fenêtre de voyage |
| `carte` | oui | Carte de la pierre (un `*` dans son plan) |
| `prix` | non (0) | Écus à payer pour voyager **vers** cette pierre (entier ≥ 0 ; 0 : gratuit) |
| `toujours_connue` | non (`false`) | `true` : on peut y voyager sans l'avoir découverte (carte d'élite de test) |

- **Découverte** : une pierre se découvre en la touchant (clic dessus, à pied) ; arriver par un
  voyage ne compte pas. La pierre de la zone de départ de la race (celle dont la `carte` est sa
  `carte_depart`) est connue dès la création du personnage. **Phase de test** : toutes les pierres
  sont connues dès le début (`World.ALL_PASSAGES_KNOWN`), tant que les zones ne sont pas reliées à
  pied ; `toujours_connue` et la découverte reprendront leur rôle ensuite.
- **Point de résurrection** : la dernière pierre touchée (au départ, celle de la zone de départ).
  Après une défaite, on se réveille à côté d'elle, avec 1 PV.
- Le personnage sauvegarde ses pierres découvertes (`pierres_connues`), son point de résurrection
  (`point_de_resurrection`) et les cartes où il est allé (`cartes_visitees`).

Les tests vérifient que chaque zone de départ a sa pierre (10 écus, à découvrir) et que le Trône de
Cendre reste gratuit et toujours connu.

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
d'XP de métier en plus (effet de passif `{"type": "xp_metier", "valeur": 10}`).

## À venir

`quetes/`.
