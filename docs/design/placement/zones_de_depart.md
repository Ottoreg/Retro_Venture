# Zones de départ tirées au hasard en combat : document de conception

Préparé le 25/11/2026 à la demande de l'auteur. Rien n'est codé. **Décisions de l'auteur du 25/11/2026 reportées**
(voir « Décisions de l'auteur ») ; les valeurs chiffrées (écarts, cases) restent des propositions.

## Le but

Aujourd'hui, chaque carte a un seul jeu de cases de départ, dessiné à la main dans son calque `placement`
(6 cases `j` à gauche, 6 cases `m` à droite). La seule variation est le côté : une fois sur deux, les camps
échangent leurs cases (`World._create_combat`). Sur une même carte, tous les combats commencent donc de la
même façon.

La demande : au début de chaque combat, tirer au hasard deux choses, indépendantes l'une de l'autre :

1. une **disposition**, qui fixe l'écart entre les deux camps : **distance** ou **corps à corps** ;
2. une **forme** pour chaque zone, c'est-à-dire le motif que dessinent les cases d'une même couleur (une ligne,
   un damier…).

Le combat se joue ensuite comme aujourd'hui : le joueur choisit sa case parmi celles de son camp, et les
monstres sont répartis au hasard sur les leurs.

## Principe proposé : des zones générées, plus des zones dessinées

Dessiner à la main toutes les combinaisons sur ~100 cartes demanderait des centaines de calques. Je propose
donc que le jeu **génère les zones au début du combat**, à partir des cases praticables de la carte :

1. tirer la disposition, puis la forme de chaque camp ;
2. choisir un **centre** pour chaque camp, à l'écart voulu par la disposition ;
3. poser la forme autour de chaque centre, dans l'une de ses orientations (4 rotations, et leurs miroirs) ;
4. vérifier les règles de validité (voir plus bas). Si ça ne marche pas, essayer d'autres centres et
   orientations, puis une autre forme. En dernier recours, prendre le calque `placement` actuel de la carte.

Le calque `placement` reste donc obligatoire, comme zone de secours. Il peut aussi servir de zone fixe pour les
cartes où l'on veut garder la main (voir la décision 4).

Les distances sont comptées en cases de combat, comme la portée des sorts (déplacement en ligne droite, sans
diagonale).

## Les dispositions

| Disposition | Écart entre les deux centres | Case alliée la plus proche d'une case ennemie | Idée |
|---|---|---|---|
| **Distance** | 12 à 16 cases | 8 cases au moins | Les camps s'approchent ou se tirent dessus. Bon pour les classes à distance et les pièges |
| **Moyenne** | 8 à 11 cases | 5 cases au moins | L'écart des calques actuels : un ou deux tours pour se rejoindre |
| **Corps à corps** | 4 à 6 cases | 2 à 3 cases (jamais collées) | Le combat commence au contact. Bon pour les classes de mêlée, la poussée, le tacle |

Tirage (décision 1) : **distance 33 %, moyenne 34 %, corps à corps 33 %**, sans pondération selon les classes ou
les monstres (décision 5). Plus tard, un roulement par semaine pourra favoriser une disposition (voir le lot 4).

## Les formes

Chaque forme compte **8 cases, rangées dans un ordre** : on en garde autant qu'il en faut au camp, **6 au moins**
(un groupe de monstres va jusqu'à 6, un groupe de joueurs jusqu'à 8). Les cases du début de la liste font déjà
la forme reconnaissable. La première case est celle où le joueur commence avant de choisir.

Schémas sur la grille de combat (`X` = case de départ, `·` = case vide), pour une orientation. Le jeu les
tourne et les retourne.

**1. Ligne** : les cases côte à côte sur une seule ligne. Tout le camp fait face à l'ennemi.
```
X X X X X X (X X)
```

**2. Double rang** : deux lignes serrées, l'une derrière l'autre (3 + 3, puis 4 + 4). Un front et un arrière.
```
X X X X
X X X X
```

**3. Damier** : une case sur deux, sur 3 lignes. Serré, mais sans cases collées : on se gêne moins.
```
X · X · X
· X · X ·
X · X · ·
```

**4. Colonne** : deux cases de large, en profondeur vers l'ennemi. Une pointe exposée et une file derrière.
```
X X
X X
X X
X X
```

**5. Coin de flèche (triangle)** : 1, puis 2, puis 3 cases (puis 2 de plus). Un meneur devant.
```
· · X · ·
· X · X ·
X · X · X
```

**6. Arc (croissant)** : un demi-cercle ouvert vers l'ennemi. Les flancs avancent sur le centre ennemi.
```
X · · · X
X · · · X
· X X X ·
```

**7. Deux flancs** : deux paquets de 3 (puis 4), séparés de 4 cases. Le camp est coupé en deux.
```
X X · · · · X X
X · · · · · · X
```

**8. Dispersé** : cases tirées dans un rayon de 5 autour du centre, à 2 cases les unes des autres au moins.
Pas de motif, c'est la forme de secours quand les autres ne tiennent pas dans le décor.

Tirage : **une forme tirée au hasard pour chaque camp**, indépendamment (décision 3), même chance pour chaque
forme, sauf *Dispersé*, gardé pour le secours. D'autres formes viendront plus tard (décision 2).

## Règles de validité d'une zone

Une zone tirée n'est gardée que si :

- toutes ses cases sont praticables (pas d'obstacle, pas d'eau) et dans la carte, sans la rangée du bord ;
- tous les combattants peuvent se rejoindre à pied : les deux zones sont dans le même ensemble de cases reliées ;
- les deux zones ne se touchent pas, et l'écart respecte la disposition ;
- pour le corps à corps, au moins une case de chaque camp voit une case de l'autre (sinon le corps à corps n'en
  est pas un).

Dans un décor chargé, une forme peut ne pas tenir. On garde alors **jusqu'à 2 cases de la forme qui tombent sur
un obstacle**, remplacées par la case libre la plus proche. Au-delà, on essaie la forme suivante.

## Ce que voit le joueur

Au début du placement, une ligne dans l'historique de combat (et une bulle au-dessus de la carte) annonce le
tirage, par exemple « Corps à corps : Damier contre Coin de flèche ». Les cases restent bleues pour son camp et
rouges pour l'autre, comme aujourd'hui.

## Décisions de l'auteur (25/11/2026)

1. **Trois dispositions** : distance, moyenne et corps à corps, tirées à 33 / 34 / 33 %.
2. **Les 8 formes proposées** sont validées ; d'autres viendront plus tard.
3. **Une forme tirée au hasard pour chaque camp**, pour plus de variété.
4. **Zones dessinées pour les combats à vision propre** : les combats contre un mini-boss et toutes les cartes de
   donjon (Tour céleste comprise) gardent leur calque `placement`, dessiné pour ce combat. Rien n'y est tiré.
   Confirmé par l'auteur : sur un repaire de mini-boss, seul le combat contre le groupe du mini-boss est fixe ; les autres
   groupes de la carte ont des zones tirées.
5. **Pas de pondération** selon les classes ou les monstres. Idée pour plus tard : un **roulement par semaine** où
   une disposition sort plus souvent (lot 4).
6. **L'échange de côté est gardé** (une fois sur deux), sauf pour les donjons et les mini-boss.

## Lots pour le coder

Même méthode que les autres chantiers : chaque lot se code, se teste et se pousse sur `main` à part, et l'auteur
valide avant le suivant.

### Lot 1 : la génération dans le noyau
- `core/combat/placement.gd` (nouveau) : formes (listes de cases, orientations), dispositions, choix des
  centres, règles de validité, secours sur le calque de la carte ; rien de tiré (ni échange de côté) contre un
  mini-boss ni dans un donjon (décision 4).
- `World._create_combat` l'appelle avec la graine du combat (même tirage pour tous les joueurs en ligne, et
  combats rejouables dans les tests).
- La disposition et les formes tirées vont dans l'instantané du combat (protocole suivant).
- Tests du noyau : chaque forme dans chaque orientation, l'écart de chaque disposition, les règles de validité,
  le secours, la même graine donne le même tirage.
- Contrôle mécanique sur toutes les cartes à groupes : combien de combinaisons tiennent sans secours, carte par
  carte, dans un rapport (`docs/design/placement/controle.md`).

### Lot 2 : l'affichage
- Ligne dans l'historique et bulle au début du placement.
- Captures d'un même combat avec plusieurs tirages (`docs/captures/placement/`), en ajoutant une action à
  `tools/screenshot.gd` si la capture d'un placement est possible (le lancement d'un combat n'y marche plus
  depuis le 23/11/2026).

### Lot 3 : l'ajustement
- Cartes où trop de combinaisons tombent en secours : décor à aérer, ou cartes passées en zone fixe.
- `tools/simulation.gd` lancé sur les trois dispositions, pour voir l'écart de victoires entre mêlée et distance.

### Lot 4, plus tard : le roulement des semaines
- Chaque semaine, une disposition sort plus souvent, à tour de rôle sur 3 semaines : semaine de la distance
  (60 / 20 / 20), de la moyenne (20 / 60 / 20), puis du corps à corps (20 / 20 / 60). La semaine est lue sur
  l'horloge réelle (`World.wall_clock`), la même pour tous les joueurs.
- Annonce de la semaine en cours (bulle à la connexion ou ligne dans l'historique), à décider avec ce lot.
