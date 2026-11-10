# Données de contenu

Le contenu du jeu est décrit en JSON ([décision 0003](../../docs/decisions/0003-donnees-json.md)),
modifiable sans recompiler et vérifié par les tests à chaque push
(voir [GDD § 16.3](../../docs/GDD.md#163-contenu-piloté-par-les-données) et les exemples en
[annexe du GDD](../../docs/GDD.md#20-annexes--formats-de-données)).

Conventions : clés en français sans accents, une case = `[x, y]`, un fichier par élément, `id` égal au
nom du fichier.

Catalogue lisible de tous les objets, monstres (stats par niveau, lieux) et sorts : [`docs/CATALOGUE.md`](../../docs/CATALOGUE.md),
regénéré par `python3 game/tools/catalogue.py` (à relancer après un changement de contenu). Variables d'équilibrage
des métiers et de la forge, des classes et des races : [`docs/METIERS.md`](../../docs/METIERS.md) et
[`docs/CLASSES.md`](../../docs/CLASSES.md), regénérés par `python3 game/tools/equilibrage.py`.

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
| `&` | Enclume (maison du joueur) : la forge |
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

- Les côtés sont **tirés au sort** à chaque combat : une fois sur deux, les camps échangent leurs
  cases (le joueur part des `m`, les monstres des `j`). Il faut donc au moins 3 cases `j` pour que
  l'échange soit possible (sinon le joueur reste côté `j`).
- **Obligatoire** sur une carte qui a des groupes de monstres : au moins une case `j` et au moins
  3 cases `m` (la taille maximale d'un groupe) ; facultatif ailleurs (maisons).
- Chaque case `j` ou `m` doit être praticable dans le plan (`.`, `@`, `:` ou un chiffre de groupe).
- Conseil : 6 cases par camp, non voisines, les deux camps face à face à 6–8 cases d'écart, sans
  ligne de vue directe partout. `python3 tools/placement.py <carte.json>` (depuis `game/`) propose
  un calque de ce genre ; `--ecrire` l'ajoute au fichier.

### Groupes de monstres

Les chiffres `1` à `9` dans le plan placent les groupes décrits dans la liste `groupes` (le chiffre
`1` correspond au premier groupe). Chaque groupe apparaît une seule fois et compte 1 à 3 monstres,
d'une ou de plusieurs espèces, tous dessinés sur la carte (4 au plus pour une liste fixe, comme les
salles de la Tour céleste ; il faut alors autant de cases `m` dans le calque `placement`). Un groupe est soit une liste fixe
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
2 à 3 minutes par défaut), mais jamais sous les pieds du joueur ni sur un autre groupe. Avec
`"reapparition_au_combat": true` (salles de la Tour céleste), le délai part du **début** du combat :
le groupe combattu se détache de la carte et un nouveau revient à sa place pendant la bataille.

Un groupe `"apres_boss": "<id d'un boss>"` n'apparaît qu'une fois ce boss vaincu (au moins une fois,
c'est sauvegardé) : tout de suite sur les cartes déjà visitées, à la première visite sur les autres.
C'est ainsi que les variantes corrompues arrivent dans les zones de départ après leur mini-boss.

```json
{"monstres": ["loup_cendreux", "loup_des_collines"], "apres_boss": "krasbouk"}
```

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
`marqueur`. Un PNJ bloque sa case en exploration (pas en combat : il n'y prend pas part, sa case
est libre) ; un clic dessus fait venir le joueur à côté, puis le PNJ dit ses
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
la rareté (`Item.EQUIPMENT_PRICES` et `Item.RESOURCE_PRICES` dans `core/items/item.gd`) et, pour
un équipement, de son palier (`niveau`) : × palier / 3 au-delà du palier 3 (`Item.tier_price_factor`) ; la
revente rapporte un quart du prix d'achat (`Item.RESALE_RATE`), au moins 1 brume.

| Rareté | Équipement | Ressource |
|---|---|---|
| Commun | 40 | 4 |
| Peu commun | 120 | 12 |
| Rare | 350 | 35 |
| Épique | 900 | 90 |
| Légendaire | 2 500 | 250 |
| Relique | 6 000 | 600 |

`entree` (facultatif, `{"carte": id, "cle": id d'objet}`) : un **portier**. Le joueur qui a la clé la
lui donne et entre sur cette carte (à son `@`) ; sans clé, le PNJ dit ses répliques (Saint Pierrot,
Tour céleste). Sans `cle`, le PNJ fait passer tout le monde (le Gardien des marches de chaque étage
ramène au parvis).

`don` (facultatif, id d'objet) : le PNJ donne cet objet une fois par visite de sa carte, puis dit ses
répliques (Raphaël et le Calice toujours ruisselant, au sommet de la Tour céleste).

`secret` (facultatif, `{"objets": [ids], "ecus": n, "repliques": [textes]}`) : si le joueur a au moins un
exemplaire de chacun de ces objets, le PNJ les lui reprend, lui donne `ecus` brumes et dit ces répliques
(easter egg de l'alpha et de la bêta sur Saint Pierrot, **à retirer avant la sortie**).

`explication` (facultatif, liste de textes) : à la dernière réplique, la bulle propose « Oui,
expliquez-moi » et montre ces textes si le joueur accepte (un clic ailleurs refuse). Les forgerons
indiquent ainsi l'enclume de la maison et expliquent la forge.

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
- `etage_suivant` : id d'une carte. Les vainqueurs d'un combat sur cette carte y montent aussitôt
  (étages de la Tour céleste ; le dernier mène au Chœur de Raphaël).
- `reveil` : id d'une carte. Les vaincus d'un combat sur cette carte s'y réveillent, à côté de sa
  Pierre de Passage, au lieu de leur point de résurrection (étages de la Tour céleste : le parvis).
- `instance` : `""` (par défaut, carte partagée) ou `joueur` pour une carte personnelle, comme la
  maison : en multijoueur, chaque joueur aura sa propre copie (et son coffre).
- Chaque zone de départ a sa maison (`maison_joueur` à Brumerive, `maison_crasse_roc`,
  `maison_sylvebrume`) ; le coffre est le même partout (il appartient au personnage).
- La maison contient un coffre `$` (on y range des objets non portés), un lit `=` (dormir rend tous
  les PV) et une enclume `&` (la forge, ci-dessous). On les utilise depuis une case voisine.

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
| `zone` | `case`, `cercle` avec `taille` (rayon), ou `croix_latine` : croix centrée sur la case visée (le croisement), une case de chaque côté et au-delà (la tête, au loin), deux en deçà vers le lanceur (le pied, qui n'atteint jamais sa case) (demande `lancer_en_ligne` et une portée minimale d'au moins 1) |
| `lancer_en_ligne` | La cible doit être sur la même ligne ou la même colonne de la grille que le lanceur (défaut : `false`) |
| `lanceur_exclu` | Le lanceur n'est pas touché par sa propre zone |
| `relance.par_tour` | Lancers maximum par tour (`0` = illimité) |
| `relance.delai` | Tours à attendre avant de relancer |
| `critique` | Chance de coup critique en % (défaut : 5 ; `0` = jamais). Critique : dégâts, soins, boucliers et poisons × 1,5 |
| `effets` | `degats`, `soin` ou `bouclier`, avec `min`, `max` et `element` (`acier`, `flamme`, `givre`, `tempete`, ou les éléments composés `sacre` et `impie`) |
| `maitrise` | Rangs de maîtrise (sorts des Voies, GDD § 4.5), facultatif : `{ "3": {…}, "5": {…} }` (rangs 1 à 5). Chaque rang donne déjà +10 % aux valeurs de base des effets élémentaires ; un rang listé ajoute ses changements : `critique` et `portee_max` (ajoutés), `cout_pa`, `delai` et `zone_taille` (nouvelles valeurs), `effets` (effets en plus, sans glyphe, piège ni effet du lanceur) |

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

- `bonus` / `malus` : `carac` parmi `force`, `intelligence`, `perception`, `agilite`, `pa`, `pm`,
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
  qui commence son tour dessus. À l'écran, elle prend la couleur de l'élément de son premier effet
  chiffré (dégâts, soin, bouclier, poison), sinon celle du camp de son lanceur.
- `piege` : posé sur la case visée (libre, sans autre piège), invisible pour l'autre équipe ; le
  premier ennemi qui y entre s'arrête et le déclenche, ses `effets` touchent la `zone` du piège
  (`case` par défaut, ou `cercle`). Un sort de piège n'a que cet effet et une zone `case`.

Mécaniques des Voies :

```json
{"type": "etat_elementaire", "element": "flamme"}
{"type": "composition_etats", "elements": ["flamme", "givre"]}
{"type": "creer_sort", "combinaisons": {"flamme+flamme+givre": "arcaniste_choc_thermique"}}
{"type": "charge"}
{"type": "retrait_etats", "etats": ["malus", "poison"], "cibles": "allies"}
```

- `etat_elementaire` (`flamme`, `givre` ou `tempete`) : le lanceur garde l'état tout le combat,
  3 au plus (le 4e remplace le plus ancien), +4 % de dégâts dans son élément ; il ne peut pas être
  retiré. Avec `gain_pa` 1 dans un sort à 1 PA, le PA est rendu aussitôt. (Plus utilisé par
  l'Arcaniste : *Braise* et *Frimas* restent en trace.)
- `composition_etats` (`elements` : liste sans doublon parmi `flamme`, `givre`, `tempete`) : le
  lanceur choisit d'un coup ses 3 états parmi toutes les combinaisons des `elements` (2 éléments :
  4 combinaisons, 3 : 10). La commande de lancer porte la combinaison dans `etats` (clé triée, comme
  pour `creer_sort`) ; sans combinaison proposée : refusé (`composition_invalide`). Dans le jeu, le
  sort ouvre une grille des combinaisons au lieu de demander une case.
- `creer_sort` : avec 3 états élémentaires, le lanceur reçoit le sort de leur combinaison (clé : les
  3 éléments **triés**, joints par `+`) ; il en garde 2 (`Fighter.CREATED_SPELL_SLOTS`), un 3e
  chasse le plus ancien. Les sorts nommés
  doivent exister et ne rien créer eux-mêmes ; sinon le sort qui crée est écarté au chargement.
  Sans 3 états, ou pour une combinaison absente : refusé (`combinaison_inconnue`).
- `charge` : demande `lancer_en_ligne` et une portée minimale d'au moins 2. Le lanceur fonce en
  ligne droite jusqu'au contact du combattant visé (ou jusqu'à la case si elle est libre) ; un
  obstacle, un combattant ou un piège ennemi l'arrête avant. Les autres effets du sort ne touchent
  la cible que s'il arrive au contact.
- `retrait_etats` : retire à la cible ses états des types de `etats` (`bonus`, `malus`, `poison`),
  sauf ceux qui ne peuvent pas être retirés (effets des phases des boss).
- Ces effets n'ont ni `min` ni `max` ; `etat_elementaire`, `composition_etats`, `creer_sort` et `charge` sont interdits
  dans une glyphe, un piège et une phase de monstre.

Chronomancien (Voie Impie) :

```json
{"type": "horloge", "duree": 3, "cibles": "ennemis", "heures": {"1": [{"type": "degats", "element": "givre", "min": 10, "max": 10}], "3": []}}
{"type": "decalage_horaire", "heures": -3}
{"type": "etat", "etat": "insoignable", "duree": 1}
{"type": "malus", "carac": "degats_infliges", "min": 10, "max": 10, "duree": 1}
```

- `horloge` : pose un cadran au sol autour de la cible (les 12 cases à 2 pas, sans les coins du carré
  5 × 5, `Combat.CLOCK_RING`) pendant `duree` tours du lanceur. 12 h est à 2 pas du centre dans la
  direction du lancer, puis les heures suivent le sens des aiguilles d'une montre vu à l'écran. La
  cible est aussitôt envoyée à 12 h (avec son effet) et passe dans l'état `manipulation_temps` (non
  retirable), qui tombe avec l'horloge ; tant qu'elle l'a, un sort d'horloge est refusé sur elle
  (`deja_manipule`). Une seule horloge par cible : une
  nouvelle remplace l'ancienne. `heures` : de `"1"` à `"12"`, les effets appliqués à la cible quand un
  décalage l'amène sur cette heure (le poseur de l'horloge en est le lanceur) ; une liste vide ou une
  heure absente : sans effet.
- `decalage_horaire` (`heures` : entier non nul de −11 à 11) : la cible avance (ou recule) d'autant
  d'heures sur son horloge, à partir de la dernière heure atteinte (même poussée hors du cadran).
  Une heure hors de la carte ou sur un obstacle est sautée (heure suivante dans le sens du
  décalage) ; un combattant sur la case d'arrivée échange sa place avec la cible. Sans horloge,
  rien ne bouge (les autres effets du sort restent). Placé après les dégâts du sort.
- `etat` : état nommé pendant `duree` tours : `insoignable` (aucun soin ne lui rend de PV),
  `exorcisme` (les prochains dégâts Sacré l'achèvent, bouclier compris ; l'état tombe alors) ou
  `inblocable` (ni taclé, ni tacleur).
- `"vol": true` sur un effet `degats` : vol de vie, le lanceur reprend les PV qu'il a fait perdre.
- `portee_fixe` (sort, `true`) : portée non modifiable, les bonus de portée ne s'y ajoutent pas.
- Caractéristique `degats_infliges` (bonus ou malus) : % de tous les dégâts infligés, poisons compris.
- Caractéristiques `retrait_pa` et `retrait_pm` (bonus ou malus) : chance en % d'esquiver les retraits de PA / PM
  d'un adversaire (moins la sienne) et de faire passer les siens ; un malus de PA ou de PM et l'effet `retrait_pm`
  d'un adversaire sont esquivés point par point (90 % au plus).
- `horloge` et `decalage_horaire` n'ont ni `min` ni `max` et sont interdits dans une glyphe, un piège,
  une heure d'horloge et une phase de monstre.
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

`caracteristiques` : `pv`, `pa`, `pm`, `initiative`, et en option `force`, `intelligence`, `perception`,
`agilite` (entiers ≥ 0, 0 par défaut) : comme pour les joueurs, +1 % de dégâts de l'élément par point
(Force pour l'Acier, Intelligence pour la Flamme, etc.). En option aussi, les statistiques de combat de
l'équipement (`tacle`, `fuite`, `retrait_pa`, `retrait_pm`, `reduction_degats`, `dommages_melee`, épines,
dégâts spectraux et dévastateurs : voir les `bonus` des objets), sans plafond.

`resistances` en % par élément (négatif = faiblesse). La résistance au Sacré est la moyenne des
résistances à l'Acier et à la Flamme, plus la résistance au Sacré (`sacre`, facultatif) : 10 % Flamme,
5 % Acier et 5 % Sacré donnent 12,5 %. Celle à l'Impie : moyenne de la Tempête et du Givre, plus
`impie`. De même, le bonus de dégâts Sacré est
Force + Intelligence, et l'Impie Agilité + Perception. `ia` : `basique` (se rapproche par
le plus court chemin pour frapper), `distance` (tire depuis la case la plus éloignée des ennemis, puis
recule), `soutien` (comme `distance`, pour les soigneurs), `corps_a_corps` (va d'abord au contact d'un
ennemi s'il peut l'y frapper, puis comme `basique`) `chasseur` (va frapper l'ennemi qui a le moins
de PV parmi ceux qu'il peut atteindre ce tour) ou `tireur` (comme `distance`, mais reste où il a tiré, sans reculer : Cupidon). Un monstre qui ne peut frapper personne bondit vers
l'ennemi le plus proche s'il a un sort de `teleportation`, puis se rapproche avec ses PM (demande de l'auteur du 06/11/2026). Dans tous les cas, l'IA note chaque sort
sur chaque cible utile et lance le meilleur tant qu'il vaut quelque chose.

Un monstre **élite** a `"elite": true` et sa `famille` (l'id du monstre normal dont il est la version
forte, par exemple `"famille": "loup_des_collines"` pour le Loup alpha). Il est plus haut niveau,
a au moins deux fois plus de PV, un sort d'attaque en plus, et lâche plus souvent les objets rares
de sa famille. Il est dessiné plus grand, avec un halo doré, et « (élite) » suit son nom au survol.
Chaque famille de monstres a son élite, sauf les boss et les monstres de donjon (`"donjon": true`,
ceux de la Tour céleste).

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
| `par_niveau` | Facultatif. Ajouté pour chaque niveau au-dessus de `niveau` : `pv`, `initiative`, `xp`, `force`, `intelligence`, `perception`, `agilite` (entiers ≥ 0), `resistances` (`{élément: entier}`, ajouté aux résistances) et, par exception, `pa` et `pm` |

Dans l'exemple, un rat de niveau 3 a 20 PV, 70 d'initiative, 20 XP et 10 de Force. Le niveau ne
change **pas** le butin : même table, mêmes taux, mêmes quantités et mêmes brumes à tous les niveaux.
PA et PM restent les mêmes dans toute la famille ; `pa` et `pm` dans `par_niveau` sont réservés à une
famille dont la mécanique en dépend. Les élites restent au-dessus de toute la tranche de leur
famille.

### Boss et phases

Une **variante corrompue** (`"corrompu": true`, `"base": "<famille d'origine>"`) est un monstre à
part entière, plus fort, aux éléments de Flamme, qu'on croise près de la Cendre (Hautepierre), et
dans les zones de départ une fois leur mini-boss vaincu (groupes `apres_boss`) : ce
n'est pas une famille, elle n'a donc pas d'élite (les tests le vérifient, et que sa `base` est une
famille existante).

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

`seul` (facultatif) : `{"message": texte, "remplace": {"sort du monstre": "autre sort"}}`. Quand le
monstre reste le dernier en vie de son camp, ces sorts sont remplacés (une fois) et le message
s'affiche comme celui d'une phase (l'Archange Raphaël troque sa Bénédiction pour le Jugement dernier).

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
  "sorts": ["guerrier_frappe", "guerrier_hache", "guerrier_tourbillon", "guerrier_second_souffle"],
  "sorts_rang_2": {"guerrier_cri_de_guerre": 5000, "guerrier_fendoir": 15000}
}
```

`sorts` : les sorts de rang I, connus dès qu'on commence la Voie. `sorts_rang_2` (facultatif) : les
sorts de rang II et la réputation de la classe qui les débloque (GDD § 5.1 ; Compagnon 5 000,
Vétéran 15 000).

## Objets (`objets/`)

```json
{
  "id": "marteau_enclume_rancuniere",
  "nom": "Marteau de l'Enclume Rancunière",
  "type": "arme",
  "rarete": "peu_commun",
  "niveau": 15,
  "description": "…",
  "bonus": {"force": [6, 9], "vitalite": [8, 12]},
  "attaque": {"cout_pa": 4, "portee": {"min": 1, "max": 1}, "effets": [{"type": "degats", "element": "acier", "min": 14, "max": 20}]}
}
```

| Clé | Rôle |
|---|---|
| `type` | `ressource` (s'empile), `quete` (objet de quête : s'empile, ni vendu, ni vendable, ni jetable), `recette` (plan de forge, ci-dessous) ou équipement : `arme`, `coiffe`, `cape`, `amulette`, `anneau`, `ceinture`, `bottes` |
| `rarete` | `commun`, `peu_commun`, `rare`, `epique`, `legendaire`, `relique` (couleur dans l'interface) |
| `niveau` | Palier de l'objet (puissance indicative, prix, catalogue) : plus une condition pour l'équiper (GDD § 4.5) |
| `bonus` | Plages `[min, max]` tirées au hasard à l'obtention (« jets ») : les 5 caractéristiques, `prospection`, `initiative`, `portee`, `pa`, `pm`, `dommages` (dégâts bruts ajoutés à chaque ligne de dégâts, ni multipliés ni réduits par les résistances, pas sur les soins), `dommages_<élément>` (pareil, seulement pour les dégâts de cet élément : `acier`, `flamme`, `givre`, `tempete`, `sacre`, `impie` ; Sacré et Impie : la moyenne de leurs deux éléments plus les leurs), `soins` et `soins_<élément>` (soins ajoutés à chaque soin, même règle), `resistance_<élément>` (% de résistance, Sacré et Impie compris), `degats_devastateurs` et `degats_devastateurs_fixes` (% et fixe des dégâts infligés qui baisse aussi les PV max de la cible, 50 % des dégâts au plus, jamais sous 40 % de ses PV max du début du combat ; GDD § 4.4), `degats_spectraux` et `degats_spectraux_fixes` (part des dégâts infligés, 50 % au plus, qui ne compte pas pour les épines de la cible), `epines_<sorte>` (%) et `epines_<sorte>_fixes` (sorte : `brutes` ou un élément ; renvoi à l'adversaire d'une part des dégâts subis, 60 % au plus en tout ; l'épine élémentaire est réduite par la résistance de l'attaquant), `reduction_degats` (retirée de chaque coup reçu et de chaque épine), `dommages_melee` (% des dégâts finaux au contact), `tacle` et `fuite` (en plus d'un point par 10 d'Agilité : quitter le contact d'ennemis garde (fuite + 2) / (2 × (tacle + 2)) des PM), `retrait_pa` et `retrait_pm` (esquive des retraits, voir les sorts) |
| `boutique` | `false` : les marchands ne le vendent pas (trophée de boss, objet de butin rare) ; défaut `true` |
| `attaque` | Armes seulement : attaque utilisable en combat, décrite comme un sort |
| `caracteristique` | Ressources de monstres et matières récoltées (minerais et bois élémentaires, leurs rares en `dommages_` / `resistance_` de l'élément ; chanvre, lin et rares en Portée) : ce qu'elles donnent à la forge (une des 12 statistiques ; la valeur dépend du `niveau`, voir « Forge ») |
| `valeur` | Facultatif : valeur fixe de chaque caractéristique de la ressource à la forge, à la place du calcul par palier (sans × 3 des rares) ; ressources de la Tour céleste |
| `matiere` | `cuir`, `tissu`, `minerai` ou `bois` : matière obligatoire de certains types d'objets forgés |
| `recette` | Plans seulement : `{ "nom": nom de l'objet, "type": type de forge, "ressources": { id: quantité } }` |

**Équipement** (02/11/2026, demande de l'auteur) : seules les **panoplies** restent des objets
prédéfinis ; tout le reste se forge. `forge_<type>` sont les modèles des objets forgés (un par type
de la forge, `boutique: false`), à ne pas donner tels quels.

### Forge (`core/items/forge.gd`, GDD § 10.4)

À l'enclume, on choisit un **type** (`coiffe`, `cape`, `amulette`, `anneau`, `ceinture`, `bottes`,
`epee`, `arc`, `baton`, `dague`, `masse`, `sceptre`) et on pose au plus **8 ressources différentes** (quantité libre), dont les
**matières obligatoires** du type : tissu (coiffe, cape), cuir (ceinture, bottes), minerai (anneau,
amulette), minerai et bois (armes). Chaque ressource de monstre ajoute sa caractéristique :
`max(1, arrondi((1 + palier / 8) × poids))`, poids 1 pour les élémentaires, 4 Vitalité,
10 Initiative, 0,34 Prospection et Dommages, 0,5 Dommages d'un élément, 0,125 % Résistance, 0,1 Critique,
**× 3 pour une ressource `rarete: rare`** (`Forge.RARE_FACTOR`) ; **PA, PM et Portée valent toujours 1**
et une seule ligne de chacun par objet. Une ligne vaut au plus 20 points de score par palier de réputation de
forgeron (`Forge.tier`, Apprenti 1 à Légende 5, Inconnu compté 1 ; `Forge.line_cap` : 100 Force, 400 Vitalité… au palier 5 ;
PA 100, PM 80 et Portée 60 points de score, perdus avant leur palier) et un objet a au plus 8 lignes (`Forge.MAX_LINES`). `caracteristique` peut
être une liste (ressource de haut palier à plusieurs caractéristiques). Chaque ligne se tire entre 75 % et 100 % de son total ; le
palier de l'objet est la moyenne des paliers des ressources ; une arme forgée a les dégâts de son
modèle × (1 + (palier − 1) / 20), dans l'élément de sa caractéristique élémentaire la plus forte
(Force Acier, Intelligence Flamme, Perception Givre, Agilité Tempête ; celui du modèle à égalité ou sans ;
Sacré si Force et Intelligence, Impie si Agilité et Perception sont à 10 % au plus de la plus forte). Le nom se compose d'un nom du type et de deux adjectifs au plus,
pris dans les lignes de l'objet (`Forge.TYPES`, `Forge.WORDS`), et l'objet est signé « Créé par
<pseudo> ». Les caractéristiques des ressources sont **cachées** tant qu'on n'a jamais forgé, puis
lues jusqu'au palier égal au niveau équivalent de la réputation de forgeron (5 de base par palier de
l'objet forgé, voir « Métiers »). Un **plan**
(récompense de quête, ou vendu par les marchands) donne type, ressources et nom, et montre tout.
Production des données : `docs/design/forge/produire.py` (déjà lancé ; répartition des
caractéristiques par tourniquet pondéré, PA, PM et Portée sur des butins de mini-boss).

**Infusion** (`core/items/infusion.gd`, GDD § 10.4) : le modèle `essence` (`boutique: false`) reçoit, comme un objet
forgé, un champ `forge` avec `essence` : `{ caracteristique, valeur, parfaite }`. Ressources par essence selon la
`rarete` (`Infusion.QUANTITIES` : 20, 10 ou 2, × 5 pour une parfaite). Un équipement infusé garde dans son entrée
d'inventaire `exo` : `{ caractéristique: valeur }` (part de ses jets ajoutée en exo).

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

`objets` : au moins deux équipements (l'arme peut en faire partie), chacun dans une seule panoplie. `bonus` : par nombre de
pièces portées (de 2 au nombre de pièces), les bonus du palier (mêmes clés que le `bonus` des objets,
valeurs fixes). Le palier le plus haut atteint s'applique seul : il doit reprendre ce que donnaient
les précédents. `orientation` sert à l'affichage.

## Butin des monstres

Dans chaque monstre : `butin` (liste) et `ecus` (`[min, max]`, en brumes, la monnaie du jeu : la clé garde
l'ancien nom des écus pour ne pas casser les sauvegardes ni les données).

```json
"butin": [
  {"objet": "croc_de_loup", "taux": 0.5, "quantite": [1, 2]},
  {"objet": "cape_en_peau_de_loup", "taux": 0.03}
],
"ecus": [2, 6]
```

Chance = `taux × prospection / 100` (au plus 100 %), sans seuil : un personnage seul peut tout obtenir.
Prospection = 100 + bonus d'équipement + passif de race (plus de lien avec une caractéristique). Le butin n'est donné qu'en cas
de victoire.

**Limite par monstre** : chaque ligne donne au plus `quantite[1]` unités par monstre vaincu, tous
joueurs confondus. Chaque joueur tire la ligne à son tour, le plus prospecteur d'abord ; ce qu'il
obtient est retiré de ce qui reste (croc `[1, 2]` : si le premier joueur a eu 1 croc de ce loup, le
suivant ne peut plus en avoir qu'un). Deux loups ont chacun leur propre limite. Une ligne
`"par_joueur": true` n'a pas de limite partagée : chaque joueur la tire pour lui (la clé de Cupidon).

Une Voie n'a plus d'`equipement_depart` (refusé par la validation) : on commence sans équipement,
avec 20 brumes (`GameData.STARTING_ECUS`).

## Races (`races/`)

```json
{
  "id": "elfe",
  "nom": "Elfe",
  "camp": "neutre",
  "description": "« Ce n'est pas notre guerre. »",
  "passif": {"nom": "Œil perçant", "description": "+1 portée…", "effets": [{"type": "portee", "valeur": 1}]},
  "sort": "elfe_pas_leger",
  "carte_depart": "brumerive_0_0"
}
```

`camp` : `allie`, `ennemi` ou `neutre`. Une race ne donne plus de caractéristiques (`bonus` refusé
par la validation depuis le 29/10/2026) : seulement son passif et son sort. `passif.effets` est optionnel (liste de
`{type, valeur}`) ; types gérés : `portee` (portée des sorts à distance), `reputation_metier` (% de réputation de
métier), `prospection` (points de prospection) et `ecus` (% de brumes de fin de combat). `sort` : sort racial, ajouté aux sorts de la Voie.

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

Les tests vérifient que chaque zone de départ a sa pierre (10 brumes, à découvrir) et que le Trône de
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

- `objet` : ressource obtenue (`quantite` : [min, max] par récolte) ; `niveau` : palier de la ressource (indicatif, rien n'est verrouillé) ;
  `xp` : réputation de métier de base par récolte. Une récolte dure 1,5 s + 0,25 s par palier
  (`Profession.harvest_time`).
- `apparence` : `arbre`, `rocher`, `champ` (céréales), `plante` ou `peche` ; `couleur` : feuillage de
  l'arbre ou veines du minerai. Un coin de pêche (`peche`) a un marqueur de `GameMap.FISHING_CHARS`
  (Â Ê Î Ô Û) : sa case reste de l'eau, on pêche depuis la berge. Les autres marqueurs sont des
  majuscules hors de la légende (B, J, K, S, V : agriculteur ; O, Q, P, W, Z : herboriste).
- `rare` (facultatif) : id d'une autre ressource, sa **version rare**. Chaque récolte a 1 % de chance
  (`Profession.RARE_CHANCE`) de donner **un** exemplaire de cette ressource à la place de la récolte
  normale (même réputation de métier). Les ressources rares servent aux recettes améliorées et ne sont pas en
  boutique (`"boutique": false`). Les 10 bois et minerais et les 15 ressources d'agriculteur, d'herboriste et de pêcheur en ont une (cœur de frêne, chêne des
  Anciens, if funèbre, hêtre centenaire, malorme ensorcelée, cuivre vert-de-gris, fer météorique,
  étain chantant, argent lunaire, obsidienne sanglante) ; tout futur métier de récolte en aura aussi.

Un métier d'**artisanat** n'a plus de recettes (`{"id": "forgeron", "nom": "Forgeron", "type":
"artisanat"}`) : le forgeron forge à l'enclume (voir « Forge »).

Plus de niveaux de métier (lot 4, GDD § 10.2) : réputation, points de maîtrise et compétences
(`Profession.SKILLS`) par métier ; gain = base × 2 × facteur de difficulté du palier contre la
réputation (`Profession.reputation_gain`). Les Humains gagnent 10 % de réputation de métier en plus
(effet de passif `{"type": "reputation_metier", "valeur": 10}`).

## Quêtes (`quetes/`)

Conception : `docs/design/chantier6_quetes.md` ; production : `docs/design/chantier6/produire_lot<n>.py`.

```json
{
  "id": "brumerive_verger",
  "nom": "Le verger de Mère Pomponne",
  "categorie": "principale",
  "acte": 1,
  "niveau": 6,
  "pnj": "mere_pomponne",
  "description": "Texte du journal.",
  "conditions": {"camp": "allie", "quetes_terminees": ["brumerive_aux_armes"]},
  "donne": [{"objet": "bonnet_de_berger", "nombre": 1}],
  "etapes": [
    {"objectifs": [
      {"type": "vaincre", "monstre": "gobelin_pillard", "nombre": 4},
      {"type": "apporter", "objet": "panier_de_pommes", "nombre": 5, "pnj": "mere_pomponne",
       "butin": {"monstres": ["gobelin_pillard"], "taux": 0.4}}
    ]},
    {"objectifs": [{"type": "parler", "pnj": "pere_pomponne", "texte": "Retrouver le Père Pomponne"}]}
  ],
  "dialogues": {"mere_pomponne": {"proposition": ["…"], "en_cours": ["…"], "objectif": ["…"], "fin": ["…"]}},
  "recompenses": {"xp_cr": 5, "ecus": 90, "objets": [{"objet": "ceinturon_rivete", "nombre": 1}]}
}
```

| Clé | Rôle |
|---|---|
| `categorie` | `tutoriel`, `principale` (avec `acte`), `secondaire` |
| `niveau` | Niveau de la quête (affiché, et base de l'XP) |
| `pnj` | Le PNJ qui la propose (« ! » au-dessus de lui) |
| `conditions` | `camp`, `race`, `voie`, `quetes_terminees` (toutes), `une_quete_terminee` (une au moins) |
| `donne` | Objets remis à l'acceptation |
| `etapes` | Liste d'étapes ; les objectifs d'une étape se font dans n'importe quel ordre |
| `dialogues` | Par PNJ : `proposition` et `en_cours` (donneur), `objectif` (son objectif rempli, la quête continue ; à défaut `fin`), `fin` (quête terminée en lui parlant) |
| `recompenses` | `xp_cr` (combats de référence : l'XP d'un combat contre 2 monstres du niveau de la quête, donnée en **réputation** de la classe active), `ecus`, `objets` |

Objectifs (champ `texte` optionnel pour remplacer le texte affiché) :

| Type | Champs | Rempli quand… |
|---|---|---|
| `parler` | `pnj` | on parle au PNJ, une fois les autres objectifs de l'étape remplis |
| `apporter` | `objet`, `nombre`, `pnj`, `butin` (option) | on parle au PNJ avec les objets (ils sont pris), une fois les autres objectifs remplis |
| `vaincre` | `monstre`, `nombre` | chaque monstre vaincu (combat gagné) ; l'élite compte pour sa famille |
| `vaincre_groupe` | `monstre` (un boss) | la victoire contre son groupe |
| `recolter` | `objet`, `nombre` | les récoltes faites pendant l'étape |
| `fabriquer` | `objet` ou `metier`, `nombre` | les fabrications faites pendant l'étape |
| `equiper` | `objet` ou `emplacement` | l'objet porté (tout de suite s'il l'est déjà) |
| `aller` | `carte` | être sur cette carte |

`butin` : pendant l'étape, l'objet tombe de ces monstres à ce taux (en plus de leur butin, sans
prospection ni limite), jusqu'au nombre demandé. Dans les zones de départ, `recolter` ne demande que
des ressources de niveau 1 de métier. Les tests vérifient que chaque quête est faisable (PNJ, cartes,
monstres de la zone du donneur, chaîne de conditions).
