# Retro Venture — Game Design Document (GDD)

> **Version :** 0.1 (document de cadrage)
> **Statut :** brouillon vivant, à faire évoluer à chaque jalon
> **Dernière mise à jour :** 2026-10-12

Tous les noms propres de ce document (monde, lieux, peuples, personnages) sont **provisoires**.
Voir [§ 15 Propriété intellectuelle](#15-propriété-intellectuelle) avant de les figer.

---

## Sommaire

1. [Vision](#1-vision)
2. [Piliers de design](#2-piliers-de-design)
3. [Univers et scénario](#3-univers-et-scénario)
4. [Personnage : races, classes, caractéristiques](#4-personnage--races-classes-caractéristiques)
5. [Système des Voies (classes mixtes)](#5-système-des-voies-classes-mixtes)
6. [Exploration et monde](#6-exploration-et-monde)
7. [Combat tactique](#7-combat-tactique)
8. [Monstres, butin et raretés](#8-monstres-butin-et-raretés)
9. [Équipement](#9-équipement)
10. [Métiers](#10-métiers)
11. [Quêtes](#11-quêtes)
12. [Donjons](#12-donjons)
13. [Multijoueur en ligne](#13-multijoueur-en-ligne)
14. [Direction artistique, audio, interface](#14-direction-artistique-audio-interface)
15. [Propriété intellectuelle](#15-propriété-intellectuelle)
16. [Architecture technique](#16-architecture-technique)
17. [Périmètre par phase](#17-périmètre-par-phase)
18. [Risques](#18-risques)
19. [Glossaire](#19-glossaire)
20. [Annexes : formats de données](#20-annexes--formats-de-données)

---

## 1. Vision

**Pitch :** un RPG tactique au tour par tour, vu en 2D isométrique, dans la lignée de *Dofus Rétro*,
plongé dans une **parodie affectueuse** du *Seigneur des Anneaux* : on en rit, mais on y croit. Les aventuriers
parcourent le monde à la recherche des **Reliques de l'Aube**, des objets légendaires dispersés depuis
des siècles, seules armes capables de vaincre le **Souverain Cendré** avant qu'il n'asservisse le monde.

| | |
|---|---|
| **Genre** | RPG tactique au tour par tour, puis MMORPG |
| **Vue** | 2D isométrique, carte découpée en écrans |
| **Plateforme cible** | PC (Windows / Linux / macOS) ; navigateur à étudier |
| **Mode** | Solo d'abord, puis en ligne sur serveur global avec instances |
| **Public** | Joueurs nostalgiques de Dofus Rétro et amateurs de fantasy épique, 15 ans et + |
| **Inspirations** | Dofus Rétro (gameplay, rendu), Wakfu (tactique), Le Seigneur des Anneaux (ton, thèmes), Final Fantasy Tactics |

**Ce qui doit rester vrai à chaque version :**

- Un combat se gagne par le placement et les choix, pas par les réflexes.
- Le monde donne envie d'aller voir l'écran d'à côté.
- Chaque objet rare a une histoire (lieu, monstre ou quête d'origine).

---

## 2. Piliers de design

1. **Tactique lisible.** Grille, PA/PM, portée, ligne de vue : toutes les règles se voient à l'écran.
   Aucune mécanique cachée en combat.
2. **Une quête épique, des histoires locales.** La quête principale (les Reliques) structure le monde ;
   chaque région a ses propres conflits et personnages.
3. **Progression horizontale autant que verticale.** Monter de niveau compte, mais apprendre les sorts
   d'autres Voies, maîtriser des métiers et réunir des panoplies comptent autant.
4. **Économie portée par les joueurs.** Les ressources viennent des métiers et du butin ; les meilleurs
   objets non légendaires sont fabriqués, pas achetés à un PNJ.
5. **Conçu pour le multi dès le jour 1.** Même en solo, la logique de jeu tourne comme un serveur
   (voir [§ 16](#16-architecture-technique)).

---

## 3. Univers et scénario

### 3.1 Le monde : les Terres de Varn

Un continent ancien, marqué par une guerre oubliée. Les peuples libres (Humains, Elfes, Nains,
Géants, Semi-hommes, Lutins et d'autres) vivent séparés, méfiants les uns envers les autres. À l'est, au-delà des montagnes, s'étendent
les **Marches Cendrées**, une terre morte où quelque chose se réveille.

### 3.2 Histoire

- **L'Âge de l'Aube.** Les premiers peuples forgent ensemble huit **Reliques de l'Aube** : huit
  bagues, chacune porteuse d'une part de la lumière originelle.
- **La Première Ombre.** Vorhak, un roi-sorcier, veut s'approprier la lumière des Reliques pour régner
  sur toute chose. Les peuples s'unissent, le vainquent au prix d'une guerre terrible, et l'enferment
  dans sa citadelle de **Nocthrône**.
- **La Dispersion.** Pour qu'aucun peuple ne puisse un jour devenir à son tour un tyran, les Reliques
  sont séparées et cachées aux quatre coins du monde. Leur emplacement se perd dans les légendes.
- **Aujourd'hui.** Les cendres recommencent à tomber sur les terres de l'est. Des créatures corrompues
  descendent des montagnes. Vorhak, devenu le **Souverain Cendré**, s'éveille : ses servants ont
  retrouvé les huit bagues avant les peuples libres, et chacune est désormais portée par l'un de ses
  plus puissants sbires, les **Hérauts Cendrés**, dispersés aux quatre coins du monde.

### 3.3 Les Reliques de l'Aube (quête principale)

Les Reliques sont **huit bagues légendaires**. Chacune est liée à une région, un peuple, une chaîne de
quêtes et un donjon final, et elle est détenue par un **Héraut Cendré** (boss du donjon). Le joueur
les reprend une à une ; chacune donne un pouvoir unique.

**Gameplay :** les huit Reliques s'équipent **toutes en même temps**, dans huit emplacements
« Reliques » qui s'ajoutent aux deux anneaux de base du personnage (voir § 9.1). Ces emplacements
sont visibles dans l'inventaire dès le début, vides tant que la Relique n'a pas été reprise : ils
montrent au joueur ce qui reste à conquérir.

| # | Relique (bague) | Région | Peuple lié | Pouvoir envisagé |
|---|---|---|---|---|
| 1 | L'Anneau-Lanterne | Collines de Brumerive | Semi-hommes | Révèle les invisibles, bonus de prospection |
| 2 | La Chevalière Sans-Rouille | Hautepierre | Humains | Dégâts sacrés, brise les boucliers |
| 3 | L'Anneau de la Feuille d'Argent | Sylvebrume | Elfes | Soins de zone, résistance impie |
| 4 | L'Anneau-Enclume | Forges de Durhal | Nains | Améliore les objets, armure |
| 5 | La Bague des Cimes | Montagnes des Géants *(région à nommer)* | Géants | +PM aux alliés, poussée renforcée |
| 6 | Le Grelot Farfelu | Bois des Lutins *(région à nommer)* | Lutins | Échange de place, esquive |
| 7 | Le Sceau du Contremaître | Fosses de Crasse-Roc *(à définir)* | Gobelins et Orcs | +PA au premier tour, intimidation |
| 8 | L'Anneau des Morts | Marais Gris | Squelettes | Domine les morts-vivants |

L'ordre d'obtention est libre pour les six premières, puis imposé pour les deux dernières ; les huit
sont requises pour affronter le Souverain Cendré à Nocthrône.

### 3.4 Les trois camps et l'arc de l'alliance

Au début du jeu, les peuples sont loin d'être unis. Chaque race jouable appartient à un **camp**, et
les premières quêtes des trois camps **s'opposent**. Elles se rejoignent quand tous les peuples
comprennent qu'ils veulent la même chose : abattre le Souverain Cendré.

| Camp | Race de l'alpha | Races de Phase 3 | Situation au départ |
|---|---|---|---|
| **Allié** | Humains | Nains, Géants | Défendent leurs terres contre les raids gobelins et pensent que les gobelins sont *le* problème. |
| **Ennemi** | Gobelins | Orcs, Squelettes (morts-vivants) | Main-d'œuvre corvéable du Souverain Cendré : raids et pillages sur ordre, contremaîtres tyranniques, aucune reconnaissance. |
| **Neutre** | Elfes | Semi-hommes, Lutins | « Ce n'est pas notre guerre. » Se tiennent à l'écart, observent, et ne s'en mêlent que si leur forêt est menacée. |

Trois races par camp : une dès l'alpha, deux en Phase 3. Les Nains, Orcs et Semi-hommes jouent leur
cliché attendu (bourrus, brutaux, gourmands) ; les trois autres peuples de Phase 3 :

- **Géants (allié)** : anciens gardiens des montagnes, alliés historiques des humains. Lents à se
  décider, impossibles à arrêter une fois lancés ; ils cognent les plafonds des maisons humaines.
- **Squelettes (ennemi)** : soldats de la Première Ombre relevés par le Souverain Cendré. Ils servent
  par habitude plus que par conviction, réclament en vain leur retraite et découvrent à l'acte II
  qu'on ne leur a jamais demandé leur avis… même pas pour mourir.
- **Lutins (neutre)** : petit peuple farceur des bois et des collines, qui joue des tours à tout le
  monde sans distinction de camp. Ne prennent rien au sérieux, sauf qu'on leur vole une blague.

**Arc narratif :**

1. **Acte I — Chacun pour soi** (niveaux 1 à ~12). Une zone de départ et une chaîne de quêtes par
   camp. Les objectifs se croisent et s'opposent : les humains doivent repousser le raid que les
   gobelins ont pour mission de mener, pendant que les elfes chassent les deux de leur lisière. On
   affronte des **PNJ** de l'autre camp, jamais d'autres joueurs.
2. **Acte II — La révélation** (~12 à 25). Chaque camp découvre, par son propre chemin, le vrai plan
   du Cendré : retrouver les Reliques et asservir tout le monde, ses propres troupes comprises. Les
   gobelins comprennent qu'ils seront sacrifiés les premiers, les elfes que la forêt ne sera pas
   épargnée, les humains que les raids gobelins n'étaient qu'un symptôme.
3. **Acte III — L'alliance** (25 et plus). Les chaînes de quêtes convergent à Hautepierre : naissance
   du **Conseil des Peuples Libres** (avec un siège pour les gobelins, au grand désarroi de tout le
   monde) et début de la vraie quête des Reliques.

Ressorts parodiques : le syndicat gobelin qui découvre ses droits, le conseil elfe qui délibère
depuis trois siècles sur l'opportunité de délibérer, les humains persuadés d'être les héros de
l'histoire.

**Conséquences de gameplay :**

- Chaque race porte un `camp` dans ses données ; la zone de départ et la chaîne de quêtes en dépendent.
- Avant l'acte III, les villes des autres camps sont hostiles (gardes PNJ agressifs) ; ensuite, libre
  accès.
- Réputation par camp : envisagée dès que les quêtes de l'acte I le demandent, sinon en Phase 3.
- Multijoueur : voir § 13.3 (groupes entre camps).

#### Antagoniste et factions

- **Le Souverain Cendré (Vorhak)** : boss final. Il n'apparaît que par ses lieutenants jusqu'à la fin.
- **Les Hérauts Cendrés** : les huit plus puissants sbires du Souverain, chacun porteur d'une Relique
  et boss de son donjon. Ce sont aussi les supérieurs directs des gobelins pendant l'acte I.
- **Les Corrompus** : monstres touchés par les cendres (versions plus fortes des monstres normaux).
- **Le Conseil des Peuples Libres** : formé à l'acte III, « hub » de la quête principale ensuite.

### 3.5 Régions (provisoires)

| Région | Ambiance | Niveaux | Phase |
|---|---|---|---|
| Collines de Brumerive | Campagne humaine, village de départ du camp allié | 1–12 | Alpha |
| Galeries de Crasse-Roc *(nom provisoire)* | Campement et mines gobelins au pied des montagnes, départ du camp ennemi | 1–12 | Alpha |
| Lisière de Sylvebrume | Avant-poste elfe en bordure de forêt, départ du camp neutre | 1–12 | Alpha |
| Zones de départ de Phase 3 *(à nommer)* | Une par race : Nains et Géants (allié), Orcs et Squelettes (ennemi), Semi-hommes et Lutins (neutre) | 1–12 | Long terme |
| Hautepierre et ses environs | Cité humaine fortifiée ; terrain d'affrontement (acte II) puis de l'alliance (acte III) | 12–30 | Alpha |
| Sylvebrume (cœur de la forêt) | Forêt elfique ancienne et brumeuse | 25–40 | Long terme |
| Forges de Durhal | Montagnes et cités naines souterraines | 25–45 | Long terme |
| Montagnes des Géants *(à nommer)* | Cimes, forteresses taillées à la mesure des Géants | 30–50 | Long terme |
| Plaines d'Orvent | Steppes de cavaliers | 35–55 | Long terme |
| Marais Gris | Marécages hantés, ruines | 50–70 | Long terme |
| Marches Cendrées / Nocthrône | Terre désolée, citadelle | 70–100 | Long terme |

#### Paliers de niveau des zones de départ

- Chaque zone de départ couvre **toute la plage 1–12**, par paliers de 3 niveaux : **1–3, 4–6, 7–9,
  10–12**. Chaque palier a des monstres dans chaque zone : un personnage peut toujours progresser
  dans sa zone, quelle que soit sa race.
- **Pas de symétrie imposée** : une zone peut compter plus ou moins de monstres (espèces, groupes,
  cartes) d'un palier que les autres. C'est voulu : chaque race a sa propre progression (une zone
  généreuse en bas niveau et rude à la fin, une autre l'inverse…). La seule règle est qu'aucun palier
  ne soit vide.
- Les élites restent au-dessus du palier de leur famille (environ +3 à +5 niveaux).
- **Niveaux variables dans une famille** : les membres d'une famille (élites exceptées) apparaissent
  à n'importe quel niveau de la tranche de leur palier, avec une **répartition propre à chaque
  famille**. Une famille « faible » du palier tire surtout des niveaux bas, une famille « forte »
  surtout des niveaux hauts. Exemple à Crasse-Roc (palier 1–3) :

  | Famille | Niveau 1 | Niveau 2 | Niveau 3 |
  |---|---|---|---|
  | Rat des galeries (faible) | souvent | un peu | parfois |
  | Grouilleur (fort) | rarement | un peu | souvent |

  Voir § 8.1 pour ce que le niveau change sur le monstre.
- **État actuel (à corriger)** : les zones ne sont pas au même niveau. Crasse-Roc couvre le palier
  1–3 (rat et grouilleur de niveau 1 à 3, avec les poids de l'exemple ci-dessus), Brumerive va de 3 à
  4 (loup 3, frondeur 4), Sylvebrume de 4 à 5 (cerf 4, arbre vivant 5) : rien au palier 1–3 chez les
  elfes, et aucune zone n'a encore de monstres de 7 à 12. Seules les deux familles de Crasse-Roc ont
  déjà des niveaux variables ; les autres gardent un niveau fixe en attendant leur palier.

### 3.6 Ton

**Parodique, mais un minimum sérieux.** Le jeu détourne les codes du *Seigneur des Anneaux*
(la quête interminable, les prophéties, les elfes hautains, les nains bourrus, les géants pas très
fins, les semi-hommes qui pensent surtout à manger, les lutins farceurs, les orcs braillards, les morts-vivants qui ne savent plus pourquoi ils se battent, les méchants très méchants), à la manière dont Dofus joue sur les mots et
les références.

- **L'humour** passe par les noms (jeux de mots, détournements, comme les classes de Dofus), les
  dialogues des PNJ, les quêtes secondaires, les descriptions d'objets.
- **Le sérieux** est réservé à la quête principale et aux enjeux du monde : le Souverain Cendré est
  une vraie menace, les combats et la progression ne sont jamais tournés en dérision.
- **Règle d'or :** on se moque des clichés, jamais du joueur ; une blague ne doit pas casser la
  cohérence du monde ni le gameplay.
- Parodier ne veut pas dire copier : aucun nom, personnage ou citation de Tolkien (voir § 15).

---

## 4. Personnage : races, classes, caractéristiques

### 4.1 Création de personnage

Le joueur choisit : **race**, **Voie de départ** (classe), **sexe/apparence** (couleurs, quelques
variantes de tête), **nom**. Race et classe sont indépendantes : toute combinaison est autorisée.

### 4.2 Races

Une race apporte : un bonus de caractéristiques, un passif racial et un sort racial. Elle ne bloque
aucune classe. L'impact doit rester modéré (environ 5 à 10 % de puissance) pour ne pas imposer de
combinaisons « optimales ».

**Les 9 races du jeu** (validées) : trois par camp (voir § 3.4). Une par camp dès l'alpha, les six
autres (Nains, Orcs, Semi-hommes, Géants, Squelettes, Lutins) en Phase 3.

| Race | Camp | Bonus | Passif | Sort racial | Phase |
|---|---|---|---|---|---|
| **Humain** | Allié | +Vitalité, +Sagesse | *Polyvalence* : +10 % d'XP de métier | *Ralliement* : +2 PA ce tour (sur soi en solo ; sur un allié en multi) | Alpha |
| **Gobelin** | Ennemi | +Agilité, +Chance | *Chapardeur* : +20 prospection et +20 % d'écus en fin de combat | *Coup bas* : dégâts Tempête au contact et −1 PM au prochain tour de la cible | Alpha |
| **Elfe** | Neutre | +Agilité, +Intelligence | *Œil perçant* : +1 portée sur les sorts à distance | *Pas léger* : téléportation jusqu'à 3 cases | Alpha |
| **Nain** | Allié | +Force, +Vitalité | *Peau de pierre* : +5 % de résistances | *Fureur des profondeurs* : bonus de dégâts quand PV < 50 % | Phase 3 |
| **Orc** | Ennemi | +Force, +Vitalité | *Peau épaisse* : réduction des dégâts de mêlée | *Cri de guerre* : bonus de dégâts aux alliés proches | Phase 3 |
| **Semi-homme** | Neutre | +Chance, +Agilité | *Petit mais discret* : +prospection, esquive accrue | *Second petit-déjeuner* : se soigne, une fois par combat | Phase 3 |
| **Géant** | Allié | +Force, +Vitalité | *Carrure* : +10 % de PV max | *Coup de semelle* : dégâts Acier au contact, repousse la cible de 2 cases | Phase 3 |
| **Squelette** (mort-vivant) | Ennemi | +Intelligence, +Sagesse | *Déjà mort* : une fois par combat, survit à un coup fatal avec 1 PV | *Remonter les os* : se soigne de 15 % de ses PV (relance tous les 3 tours) | Phase 3 |
| **Lutin** | Neutre | +Chance, +Agilité | *Farceur* : +prospection, esquive accrue | *Tour de passe-passe* : échange sa place avec une créature à 4 cases au plus | Phase 3 |

Les bonus, passifs et sorts sont des propositions, à équilibrer (certains se ressemblent, par exemple
Nain et Orc, ou Semi-homme et Lutin : à différencier). Trois races par camp.

Graphisme : les Géants sont dessinés plus grands (environ 1,25×) et les Lutins plus petits (environ
0,8×), mais toutes les races occupent une seule case en combat. Les Squelettes ont leur propre
assemblage (os, armure rouillée) plutôt qu'une couleur de peau.

**Noms de peuple** — à la manière des classes de Dofus (jeux de mots, verlan, détournements),
le nom de race générique sert dans les règles et le nom de peuple dans le jeu. Propositions, à choisir :

| Race | Pistes de noms de peuple |
|---|---|
| Humain | **Lambdas** (les « gens normaux »), **Moyen-Terriens**, **Bonhommes** |
| Nain | **Barbichus**, **Naindustriels**, **Trapus** |
| Semi-homme | **Grignotins**, **Bedonnets**, **Deux-Déjeuners** |
| Géant | **Grandiloques** (grand + grandiloquent), **Colossaux**, **Hauts-Perchés** |
| Lutin | **Farfadingues**, **Lutineurs**, **Malicieux** |
| Elfe | **Elfiers** (elfe + fier), **Éternelfes**, **Pointus** |
| Orc | **Grognards**, **Orcharnés** (orc + acharnés), **Bourrus** |
| Squelette | **Osseux**, **Squelettards**, **Désossés** |
| Gobelin | **Gobe-Tout**, **Chapardins**, **Ricaneurs** |

Plus de races qu'aujourd'hui n'est pas exclu à très long terme, mais la charge graphique (races ×
sexes × équipements × animations) impose de s'en tenir à ces 9.

### 4.3 Classes (Voies)

**Court terme (4 classes) :**

| Classe | Rôle | Éléments principaux | Style |
|---|---|---|---|
| **Guerrier** | Mêlée, encaisse | Acier (Force) | Charges, coups de zone en mêlée, réduction de dégâts |
| **Rôdeur** | Distance, mobilité | Acier / Tempête (Force / Agilité) | Arc, pièges, poussée, gestion de distance |
| **Arcaniste** | Dégâts magiques, contrôle | Flamme / Givre (Intelligence / Chance) | Sorts de zone, ralentissements, un petit soin |
| **Théologue** | Soigneur sacré | Sacré (Force + Intelligence) | Soins, boucliers, dégâts sacrés modestes |

Le **Théologue** est jouable dans l'alpha (✅) : une classe de soin rend le solo plus confortable et
permet de tester le Sacré dès maintenant. Arme de départ : le Sceptre de novice (Sacré, 4 à 7). Ses
4 sorts sont tous Sacrés (ils grandissent avec la Force et l'Intelligence) :

| Sort | PA | Portée | Effet |
|---|---|---|---|
| *Châtiment* | 4 | 2 à 5, ligne de vue | 8 à 12 dégâts Sacré (2 fois par tour) |
| *Imposition des mains* | 3 | 0 à 3 | Soin Sacré de 12 à 18 (1 fois par tour) |
| *Rempart de foi* | 2 | 0 à 3 | Bouclier Sacré de 12 à 16, jusqu'au prochain tour du porteur (tous les 2 tours) |
| *Sermon* | 4 | 1 à 4, **en ligne** | Zone en croix latine : 4 cases dans le sens du lancer depuis la case visée, et une de chaque côté de la 3e (la tête de la croix au loin). Ennemis : 4 à 7 dégâts Sacré ; alliés : soin Sacré de 4 à 7 (1 fois par tour) |

Les soins des autres classes restent modestes (le Guerrier et l'Arcaniste en ont un petit) pour
que le Théologue garde son rôle.

**Long terme (9 Voies)** : trois familles de trois classes, selon la distance de combat.

| Famille | Classe | Rôle | Éléments principaux | Style |
|---|---|---|---|---|
| **Corps à corps** | **Guerrier** | Mêlée polyvalente | Acier (Force) | *(voir plus haut)* |
| | **Paladin** | Guerrier sacré : mêlée et soutien | Sacré, Acier (Force / Intelligence) | Coups bénis, auras qui protègent les alliés proches, petits soins, protège un allié |
| | **Myrmidon** | Guerrier tank | Acier (Force), Vitalité | Bouclier, provocation (attire les coups), réduction de dégâts, poussée, garde un allié |
| **Mixte** | **Rôdeur** | Distance et mobilité | Acier / Tempête (Force / Agilité) | *(voir plus haut)* |
| | **Ombre** | Assassin invisible | Tempête / Acier (Agilité / Force) | Invisibilité, coups dans le dos, téléportations courtes, coups critiques |
| | **Venomancien** | Maître des poisons | Givre / Tempête, un peu d'Impie (Chance / Agilité) | Poisons (dégâts à chaque tour), pièges empoisonnés, affaiblissements, mi-distance |
| **Distance** | **Arcaniste** | Dégâts magiques, contrôle | Flamme / Givre (Intelligence / Chance) | *(voir plus haut)* |
| | **Théologue** *(dès l'alpha)* | Soigneur sacré | Sacré (Force + Intelligence) | Soins, boucliers, retrait des états, résurrection (multi), dégâts sacrés modestes |
| | **Démoniste** | Dégâts impies | Impie, Givre (Chance / Agilité) | Malédictions, sacrifice de PV contre des dégâts, invocation d'un démon mineur |

Le Sacré et l'Impie sont des éléments à part entière (voir § 4.4) : le Sacré s'appuie sur l'Acier et
la Flamme, l'Impie sur la Tempête et le Givre.

Mécaniques à ajouter pour ces classes : invisibilité, poisons et dégâts sur la durée, provocation,
auras, invocations, sacrifice de PV, résurrection (multi).

### 4.4 Caractéristiques

| Carac. | Effet |
|---|---|
| **Vitalité** | Points de vie |
| **Sagesse** | Bonus d'XP, résistance au retrait de PA/PM |
| **Force** | Dégâts, soins et boucliers Acier (physique) |
| **Intelligence** | Dégâts, soins et boucliers Flamme |
| **Chance** | Dégâts, soins et boucliers Givre ; prospection |
| **Agilité** | Dégâts, soins et boucliers Tempête ; esquive, initiative |

**Les 6 éléments :** 4 éléments de base et 2 éléments composés, chacun appuyé sur deux éléments de
base.

| Élément | Caractéristique | Résistance de la cible |
|---|---|---|
| Acier | Force | Acier |
| Flamme | Intelligence | Flamme |
| Givre | Chance | Givre |
| Tempête | Agilité | Tempête |
| **Sacré** | Force + Intelligence | (Acier + Flamme) / 2 + Sacré |
| **Impie** | Agilité + Chance | (Tempête + Givre) / 2 + Impie |

**Règle :** chaque effet chiffré a un élément (dégâts, soins, boucliers, et plus tard poisons,
pièges, invocations…) et grandit avec la caractéristique de cet élément, jamais avec une
caractéristique fixe : un soin Sacré profite de la Force et de l'Intelligence, un bouclier Tempête de
l'Agilité, un soin Acier de la Force. Chaque point d'une caractéristique donne 1 % à tous les effets
qui en bénéficient. Un sort Sacré profite donc autant de 100 d'Intelligence seule que de 50 de Force et 50
d'Intelligence (10 à 20 de base → 20 à 40 dans les deux cas) ; le second profil aura en plus des
bonus sur les sorts d'Acier, le premier plus de bonus en Flamme : c'est au joueur de choisir.

**Résistances combinées :** la résistance au Sacré est la moyenne des résistances à l'Acier et à la
Flamme, plus la résistance propre au Sacré. Exemples : 10 % Flamme, 5 % Acier et 5 % Sacré donnent
(10 + 5) / 2 + 5 = 12,5 % ; avec une faiblesse, 10 % Flamme, −5 % Acier et 15 % Sacré donnent
(10 − 5) / 2 + 15 = 17,5 %. Idem pour l'Impie avec la Tempête et le Givre. Les demi-points sont
gardés.

**Statistiques dérivées :** PV, PA (6 de base), PM (3 de base), Initiative, Portée (+0), Prospection
(100 de base), **Dommages** (+0), Coups critiques %, Résistances % par élément, Soins, Invocations max.

**Dommages :** bonus de dégâts **brut**, sans élément, surtout apporté par les objets. +5 Dommages
ajoutent 5 dégâts à chaque ligne de dégâts de n'importe quel sort ou arme, quel que soit son
élément ; ils ne sont multipliés par aucune caractéristique et ne sont réduits par aucune résistance
élémentaire. Ils ne s'appliquent pas aux soins.

**Formules en place (alpha) :**

- Dégâts = base du sort × (100 + caractéristique de l'élément) % × (100 − résistance de la cible) %
  + Dommages. Pour le Sacré et l'Impie : somme des deux caractéristiques ; résistance = moyenne des
  deux résistances de base + résistance propre à l'élément composé.
- Soins et boucliers = base × (100 + caractéristique de leur élément) % (somme des deux pour le
  Sacré et l'Impie). Ni résistance ni Dommages ne s'y appliquent.
- Bouclier : points qui absorbent les dégâts reçus avant les PV ; plusieurs boucliers s'additionnent ;
  ce qui reste disparaît au début du prochain tour du porteur.
- PV max = PV de la Voie + 5 par niveau au-delà du 1er + Vitalité.
- Initiative = initiative de la Voie + Force + Intelligence + Chance + Agilité (pas Vitalité ni Sagesse)
  + bonus d'équipement. XP gagnée × (100 + Sagesse) %, y compris pour les monstres vaincus avant
  une défaite.
- Les bonus des objets équipés s'ajoutent aux caractéristiques (et à PA, PM, portée, initiative,
  prospection).
- Les bonus de race s'ajoutent aux points investis (+10 dans deux caractéristiques par race).

### 4.5 Progression

- **Niveau max :** 30 en alpha solo, 100 à terme.
- **Par niveau :** 5 points de caractéristique à répartir, 1 point de sort.
- **Rendement décroissant** (à décider) : au-delà de certains paliers, un point de caractéristique
  coûte plus de points à répartir, comme dans Dofus. Exemple : 1 point de capital = 1 point de Force
  jusqu'à 100 de Force, puis il faut 2 points de capital par point de Force jusqu'à 200, puis 3.
  Seuls les points répartis sont concernés (pas l'équipement ni les panoplies). But : rendre
  intéressant de monter une deuxième caractéristique au lieu de tout mettre dans une seule.
- **Courbe d'XP** (en place) : passer du niveau n à n+1 coûte 60·n + 20·n² XP (80 pour le niveau 2,
  200 de plus pour le 3, environ 8 400 au total pour le niveau 10). À ajuster selon les tests, cible :
  niveau 10 en environ 2 h, niveau 30 en environ 15 h pour l'alpha.
- **Restat :** possible via un objet ou une quête, pour ne pas punir l'expérimentation.

---

## 5. Système des Voies (classes mixtes)

**Objectif long terme :** tout personnage peut apprendre les sorts de base de toutes les classes, mais
seule la Voie dans laquelle il est **spécialisé** donne accès aux sorts les plus puissants.

### 5.1 Règles

1. Chaque sort appartient à une **Voie** et a un **rang** :
   - **Rang I — Fondamentaux** : apprenables par tous, auprès d'un maître de la Voie.
   - **Rang II — Avancés** : réservés aux spécialistes de la Voie.
   - **Rang III — Maîtrise** : réservés aux spécialistes, débloqués par une quête de Voie.
2. Le personnage commence spécialisé dans sa Voie de départ.
3. Apprendre un Fondamental d'une **autre** Voie coûte plus cher (×1,5 point de sort, plus une petite
   quête d'apprentissage auprès du maître).
4. **Changer de spécialisation** est possible mais coûteux (quête, temps, monnaie). Les sorts de rang
   II et III de l'ancienne Voie sont désactivés, pas perdus.
5. **Barre de sorts limitée** (par ex. 12 emplacements actifs) : on choisit ce qu'on emporte au combat,
   le nombre de sorts connus n'est pas limité.
6. **Maîtrise de Voie** (passif) : +X % d'efficacité sur les sorts de sa Voie de spécialisation, pour que
   le mono-Voie reste attractif face aux combinaisons.

### 5.2 Garde-fous d'équilibrage

- Les Fondamentaux sont volontairement **utiles mais modestes**.
- Les combinaisons interdites ou dangereuses (par ex. deux sorts de vol de PA) sont limitées par des
  **états** incompatibles plutôt que par des interdictions d'apprentissage.
- Un outil de simulation de combat (voir TODO) permettra de détecter les combos abusifs.

### 5.3 Voies Miroir (long terme)

À terme, chaque Voie aura une **spécialisation opposée** qui retourne son élément, comme son reflet
dans un miroir : la **Voie Miroir**. Exemples :

- une classe sacrée (Paladin, Théologue) devient impie, et le Démoniste devient sacré ;
- une classe de Givre joue avec la Flamme, et inversement ;
- une classe d'Acier passe à la Tempête, et inversement.

La Voie Miroir garde le rôle de la classe (un Théologue Miroir soigne toujours) mais change
l'élément de ses sorts, et donc les caractéristiques et l'équipement à privilégier. Elle se débloque
par une quête de Voie, comme le rang III, et suit les mêmes règles de changement de spécialisation.

### 5.4 Implication court terme

Les classes sont **fixes** dans l'alpha (pas d'apprentissage croisé), mais **le modèle de données
prévoit déjà `voie` et `rang` sur chaque sort** pour que le système s'ajoute plus tard sans refonte.

---

## 6. Exploration et monde

- Le monde est découpé en **cartes** (un écran chacune), reliées par leurs bords et par des portes ou
  escaliers. Chaque carte extérieure a des coordonnées sur la carte du monde, tirées de son id
  (`<zone>_<x>_<y>`) ; les intérieurs n'en ont pas.
- **Déplacement au clic** sur une grille isométrique ; recherche de chemin (A*).
- Sur une carte : PNJ, groupes de monstres visibles qui errent, ressources récoltables, éléments
  interactifs (portes, coffres, panneaux).
- **Pierres de Passage** (les zaaps du jeu) : une sur la première carte de chaque zone de départ
  (Brumerive, Crasse-Roc, Sylvebrume) ; c'est pour l'instant le seul lien entre les zones.
  - *Fait :* une pierre se **découvre** en la touchant (clic dessus, à pied ; arriver par un voyage
    ne compte pas). On ne voyage que vers une pierre découverte, et le voyage se **paie** en écus,
    au prix de la pierre d'arrivée (10 écus vers une zone de départ). La pierre de la zone de départ
    de la race est connue dès la création ; la carte d'élite de test (Trône de Cendre) est gratuite
    et connue de tous (`toujours_connue`). La fenêtre de voyage montre le prix de chaque
    destination et grise les pierres pas encore découvertes.
  - *À venir :* des pierres dans les autres zones (Hautepierre…), des prix qui grandissent avec la
    distance. Tant que les zones de départ ne sont pas reliées à pied (par Hautepierre), un
    personnage ne peut découvrir que la pierre de sa propre zone.
- **Carte du monde** et **minicarte** consultables. *Fait :* le personnage retient les cartes où il
  est allé (`cartes_visitees` dans la sauvegarde). La carte du monde (touche M) a un onglet par
  zone visitée ; les coordonnées d'une carte viennent de son id (`<zone>_<x>_<y>`, x vers l'est,
  y vers le sud). Seules les cartes visitées sont nommées ; leurs voisines (par une sortie) sont des
  « ? », le reste est caché, et la grille s'adapte à la taille de la zone. Les Pierres de Passage y
  figurent (découvertes ou non) ; les intérieurs, sans coordonnées, n'y sont pas. La minicarte, en
  haut à droite en exploration, montre la carte actuelle, le joueur, les groupes de monstres (élites
  en doré) et les PNJ ; un clic dessus ouvre la carte du monde, un bouton la replie pour dégager le
  coin de la carte qu'elle recouvre.
- **Point de résurrection** : la dernière Pierre de Passage touchée (au départ, celle de la zone de
  départ). *Fait :* après une défaite, on se réveille à côté d'elle avec 1 PV, même si elle est sur
  une autre carte que le combat ; la fenêtre de voyage la rappelle. *À venir :* les temples.
- **Maison du joueur** : chaque personnage a la sienne (une porte du village mène à une carte
  personnelle, instanciée par joueur en multijoueur). Elle contient un **coffre** (stockage, 100
  places) et un **lit** (tous les PV d'un coup). Prototype : à Brumerive.
- **Points de vie** : ils se gardent d'un combat à l'autre et remontent lentement hors combat
  (1 PV toutes les 2 s) ; après une défaite, on se relève avec 1 PV.
- **Monstres du prototype** : deux par zone de départ — loup des collines et frondeur gobelin
  (Brumerive), rat des galeries et grouilleur, mille-pattes vert qui crache de l'acide (Crasse-Roc),
  cerf enchanté et arbre vivant (Sylvebrume). Le Souverain Cendré attend sur une carte d'élite de
  test, le Trône de Cendre, accessible par la Pierre de Passage : c'est le monstre le plus puissant
  du jeu (900 PV, 12 PA).
- **Monstres** : un groupe vaincu réapparaît à sa place au bout de 2 à 3 minutes (réglable par groupe).
- **Cycle jour/nuit** : optionnel, long terme (certains monstres ou ressources seulement la nuit).

---

## 7. Combat tactique

### 7.1 Déroulement

1. **Engagement :** le joueur clique sur un groupe de monstres visible (ou se fait agresser par un
   groupe agressif).
2. **Placement :** la carte devient la grille de combat. Chaque camp dispose de cases de départ ; le
   joueur choisit la sienne (temps limité en multi).
3. **Tours :** ordre fixé par l'**Initiative**, visible dans une frise (timeline). À son tour, chaque
   combattant dépense ses **PA** (sorts, armes) et ses **PM** (déplacement case par case), dans
   n'importe quel ordre.
4. **Fin :** victoire quand tous les ennemis sont vaincus ; défaite si tous les alliés le sont, ou en
   cas d'abandon.
5. **Récompenses :** écran de fin avec XP, monnaie et butin pour chaque participant.

### 7.2 Règles

- **Portée** min/max par sort, éventuellement modifiable par les bonus de portée.
- **Ligne de vue** bloquée par les obstacles et (selon les sorts) par les combattants.
- **Zones d'effet :** case, cercle, croix, ligne, cône.
- **Relances :** nombre d'utilisations par tour et par cible, délai de récupération en tours.
- **Coups critiques :** chaque sort a sa chance (5 % par défaut, `critique` dans ses données), plus le
  bonus « % Critique » du lanceur (équipement, états). Un coup critique multiplie par 1,5 la valeur
  tirée des dégâts, soins, boucliers et poisons du sort ; « Coup critique ! » s'affiche.
- **Éléments :** Acier, Flamme, Givre, Tempête, et les deux éléments composés Sacré (Acier + Flamme)
  et Impie (Tempête + Givre), voir § 4.4. Chaque combattant a des résistances en %.
- **Effets :** dégâts, soin, bouclier, bonus/malus (PA, PM, portée, résistances…), poussée/attirance,
  téléportation, invocation, pièges et glyphes, états (*Enraciné*, *Invisible*, *Porté*…).
  Faits pour l'alpha (§ 7.4) : bonus/malus temporaires, poisons, poussée, attirance, glyphes et
  pièges ; à venir : invocations et états spéciaux.
- **Tacle / fuite** (quitter une case adjacente à un ennemi coûte des PM selon l'Agilité) : prévu,
  activable par réglage pour tester son intérêt.
- **Temps par tour :** illimité en solo (option), 30 s en multi.
- **Mort :** le personnage vaincu retourne à son point de résurrection avec 1 PV ; pas de perte
  d'objets (à rediscuter pour d'éventuelles zones dangereuses à terme).

### 7.3 IA des monstres

Comportements configurables par donnée (`ia`), et non codés par monstre :

- `basique` (fait) : se rapproche par le plus court chemin et frappe.
- `distance` (fait) : tire depuis la case la plus éloignée des ennemis, puis recule avec les PM qui
  restent (frondeurs).
- `soutien` (fait) : se déplace comme `distance` ; ses soins, boucliers et glyphes passent avant
  quand ils valent plus que ses attaques.
- `summoner` : invoque puis se protège (à venir).
- **Boss à phases** (moteur fait, contenu à venir) : pas un comportement d'IA à part, mais des
  `phases` dans les données du monstre (seuils de PV, voir § 8.1) ; le boss garde son `ia` et
  gagne de nouveaux sorts à chaque phase.

L'IA note chaque sort possible sur chaque cible utile (fait) : dégâts attendus (achever compte
double), soins utiles (PV manquants seulement), boucliers, bonus et malus (un PA ou un PM vaut
5 PV), poisons, poussées, glyphes (ce qu'elles feraient à ceux qui sont dedans), pièges (posés près
d'un ennemi) ; ce qui touche son propre camp compte en négatif. Elle lance le meilleur sort tant qu'il
vaut quelque chose ; pas de recherche profonde.

### 7.4 Effets durables, glyphes et pièges

- **Bonus et malus** (`bonus`, `malus`) : changent une caractéristique (Force, Intelligence, Chance,
  Agilité, PA, PM, portée, Dommages, % Critique, résistance à un élément) pendant `duree` tours de la
  cible ; un état perd un tour à la fin de chaque tour de celui qui le porte. Un bonus ou malus de PA
  ou de PM compte tout de suite (PM retirés pendant son tour : il marche moins loin).
- **Poison** : dégâts d'un élément au début de chaque tour de la cible, pendant `duree` tours ;
  comme tous les effets chiffrés, ils montent avec la caractéristique de l'élément du lanceur et
  baissent avec la résistance de la cible (pas de Dommages ajoutés).
- **Poussée / attirance** : la cible glisse en ligne droite, en s'éloignant du lanceur (ou du centre
  d'un piège) ou vers lui. Un obstacle, le bord ou un combattant l'arrête ; une poussée arrêtée inflige
  4 dégâts de choc par case manquée.
- **Glyphe** : les cases de la zone du sort gardent des effets pendant `duree` tours du lanceur ; ils
  s'appliquent à chaque combattant qui **commence son tour** dessus (selon leurs `cibles`). Exemple :
  le *Cercle de sève* de l'Arbre millénaire (cercle de 2 autour de lui, 2 tours) le soigne, lui et
  ses alliés, et retire 2 PM aux ennemis qui y commencent leur tour.
- **Piège** : posé sur une case libre, **invisible pour l'équipe adverse** (le joueur voit seulement
  le nom du sort). Le premier ennemi qui entre sur la case (en marchant, poussé, attiré ou téléporté)
  s'y arrête et le déclenche : ses effets touchent la zone du piège, puis il disparaît. Exemple : la
  *Chausse-trape* du Frondeur vétéran (8 à 12 dégâts d'Acier et −2 PM pour le tour).
- Un combattant vaincu emporte ses glyphes et ses pièges.

---

## 8. Monstres, butin et raretés

### 8.1 Monstres

- Chaque monstre a : niveau (plage), caractéristiques, résistances, sorts, comportement IA, table de
  butin, XP et monnaie de base.
- **Niveaux :** chaque zone de départ a des monstres à chaque palier de 3 niveaux (1–3, 4–6, 7–9,
  10–12), en nombre libre selon la zone (voir § 3.5, *Paliers de niveau des zones de départ*).
- **Niveau d'un membre de famille** (fait) : tiré à l'apparition dans la tranche du palier, selon les
  poids de la famille (une famille faible tire surtout bas, une forte surtout haut ; élites et boss à
  niveau fixe). Tiré à nouveau à chaque réapparition, gardé dans la sauvegarde, montré dans la bulle
  du groupe (« Niv. 2 Rat des galeries ») et dans le cadre du combattant survolé.
  - Le niveau change les **caractéristiques** (fait) : PV, initiative, Force, Intelligence, Chance,
    Agilité, résistances et XP gagnée, d'une valeur fixe par niveau au-dessus du niveau de base
    (`par_niveau` dans les données). Comme pour les joueurs, chaque point de Force, Intelligence,
    Chance ou Agilité donne +1 % de dégâts de son élément.
  - Le niveau **ne change pas le butin** : même table, mêmes taux, mêmes quantités et mêmes écus pour
    toute la famille, quel que soit le niveau.
  - **PA et PM identiques dans toute la famille**, sauf exception pour une famille dont la mécanique
    repose sur ces caractéristiques (par exemple, une espèce qui gagne des PM en vieillissant).
  - Fait pour les deux familles de Crasse-Roc (rat des galeries 1–3 surtout bas, grouilleur 1–3
    surtout haut) ; les autres familles suivront avec les paliers de leur zone.
- **Mini-boss à phases** (moteur fait, contenu à venir) : un monstre unique (`boss` : ni famille ni
  élite, niveau fixe, comme le Souverain Cendré) ou n'importe quel monstre peut avoir des **phases**.
  Quand ses PV tombent sous un seuil (en % de ses PV max), après n'importe quels dégâts, la phase se
  déclenche une seule fois : il annonce la couleur (message de combat et texte flottant), apprend de
  nouveaux sorts et s'applique des effets (bonus, soin, bouclier…). Plusieurs seuils franchis d'un
  coup : toutes les phases, dans l'ordre. Les mini-boss de fin de région et leurs scripts viendront
  avec le contenu.
- **Groupes :** de 1 à 8 monstres (3 au plus pendant l'alpha), d'une ou plusieurs espèces, tous visibles
  sur la carte ; composition fixe ou aléatoire dans une liste par zone.
- **Variantes Corrompues :** versions plus fortes avec un butin spécifique (cendres, fragments).
- **Archimonstres** (long terme) : variantes rares nommées, au butin amélioré.

### 8.2 Butin (drop)

- Chaque monstre a une **table de butin** : objet, taux de base, quantité, et des écus.
- **Chance effective** = `taux_base × (prospection / 100)`, plafonnée à 100 %. Prospection = 100 +
  Chance / 10 + bonus d'équipement + passif de race (Gobelin : +20).
- **Pas de seuil de prospection** : un personnage seul peut obtenir tous les objets, comme un groupe.
  La prospection augmente seulement les chances.
- **Limite par monstre et par joueur :** chaque ligne de la table donne au plus sa quantité maximale
  par monstre vaincu, tous joueurs confondus. Chaque joueur tire la ligne à son tour, **le plus
  prospecteur d'abord** (au hasard entre égaux) ; ce qu'il obtient est retiré de ce qui reste pour
  les suivants. Exemple : croc de loup `[1, 2]` ; si le premier joueur a eu 1 croc de ce loup, le
  deuxième ne peut plus en avoir qu'un. Chaque monstre du groupe a sa propre limite.
- Les ressources de monstres alimentent les recettes des métiers.

### 8.3 Raretés

| Rareté | Couleur | Source typique |
|---|---|---|
| Commun | Gris | Monstres, PNJ |
| Peu commun | Vert | Monstres, artisanat |
| Rare | Bleu | Artisanat avancé, monstres forts |
| Épique | Violet | Boss, donjons |
| Légendaire | Orange | Butin très rare, quêtes longues |
| Relique | Or | Quête principale uniquement (uniques) |

---

## 9. Équipement

### 9.1 Emplacements

| Emplacement | Court terme | Long terme |
|---|---|---|
| Arme (à une ou deux mains) | ✅ | ✅ |
| Coiffe | ✅ | ✅ |
| Cape | ✅ | ✅ |
| Amulette | ✅ | ✅ |
| Anneau ×2 | ✅ | ✅ |
| Ceinture | ✅ | ✅ |
| Bottes | ✅ | ✅ |
| Bouclier / main gauche | — | ✅ |
| Familier / monture | — | ✅ |
| Reliques ×8 (bagues) | Cases visibles, vides | ✅ (les 8 en même temps, en plus des 2 anneaux) |

### 9.2 Règles

- Chaque objet a un **niveau requis**, éventuellement des **conditions** (caractéristique minimale,
  Voie, quête accomplie).
- **Jets aléatoires :** les objets fabriqués ou ramassés ont des statistiques tirées dans une plage
  (par ex. Force 10–15).
- **Armes :** une arme est un « sort » particulier (coût en PA, portée, zone, dégâts par élément).
- **Panoplies :** bonus de panoplie qui augmente avec le nombre de pièces du même ensemble équipées
  (voir § 9.3).
- **Apparence :** coiffe, cape et arme sont visibles sur le personnage.
- **Long terme :** forgemagie (modification des jets avec des runes), objets légendaires à effets
  uniques liés au butin rare et aux quêtes, objets liés au compte.

### 9.3 Panoplies de l'alpha test

Pour l'alpha test, huit panoplies qui permettent de tester chaque façon de jouer. Chaque panoplie a
un **bonus de panoplie** qui grandit avec le nombre de pièces équipées (à partir de 2).

| Panoplie *(noms provisoires)* | Orientation | Pièces |
|---|---|---|
| Panoplie du Forgeron Hargneux | Acier (Force) | 6 |
| Panoplie du Pyromane Repenti | Flamme (Intelligence) | 6 |
| Panoplie du Bonhomme de Neige | Givre (Chance) | 6 |
| Panoplie du Courant d'Air | Tempête (Agilité) | 6 |
| Panoplie de l'Enfant de Chœur | Sacré (Force et Intelligence) | 6 |
| Panoplie du Mauvais Œil | Impie (Agilité et Chance) | 6 |
| Panoplie du Pressé | Initiative et Dommages | 3 |
| Panoplie du Fouineur | Prospection | 3 |

- **Panoplies élémentaires (6 pièces)** : coiffe, cape, amulette, anneau, ceinture, bottes.
- **Panoplies d'initiative et de prospection (3 pièces)** : courtes, pour se mélanger avec une
  panoplie élémentaire incomplète. Le Pressé prend l'anneau, les bottes et la ceinture ; le Fouineur
  la coiffe, l'amulette et la cape : les deux se portent ensemble, ou chacune avec 3 pièces
  élémentaires (par exemple coiffe, cape et amulette de Flamme + le Pressé).
- **Règle des paliers** : le palier atteint remplace le précédent, et chaque palier donne au moins
  autant que le précédent pour chaque bonus (rien ne baisse quand on ajoute une pièce).
- **Bonus en place** (à équilibrer) pour une panoplie élémentaire, dans sa caractéristique (moitié
  dans chacune pour le Sacré et l'Impie) : 2 pièces : +10 ; 3 : +20 et +2 Dommages ; 4 : +30,
  +4 Dommages, +20 Vitalité ; 5 : +40, +6 Dommages, +30 Vitalité ; 6 : +50, +8 Dommages,
  +40 Vitalité et +1 PA. Pressé : 2 pièces : +20 Initiative, +2 Dommages ; 3 : +50 Initiative,
  +5 Dommages. Fouineur : 2 pièces : +20 Prospection ; 3 : +50 Prospection, +10 Chance.
- Pièces de niveau 3, communes, vendues par les marchands (pour l'alpha test).

---

## 10. Métiers

### 10.1 Court terme (3 métiers)

| Métier | Type | Ressources / produits |
|---|---|---|
| **Bûcheron** | Récolte | Bois (frêne, chêne, if…) sur des arbres de la carte |
| **Mineur** | Récolte | Minerais (fer, cuivre, argent…), pierres |
| **Forgeron** | Artisanat | Armes et pièces d'armure à partir de bois, minerais et ressources de monstres |

### 10.2 Fonctionnement

- Chaque métier a son **niveau** (1 à 100) et son **XP** propres.
- **Récolte :** clic sur la ressource → animation pendant un temps fixe → gain ; la ressource
  réapparaît après un délai. Le niveau débloque de nouvelles ressources.
- **Artisanat :** atelier en ville ; recettes débloquées par niveau ; nombre de cases d'ingrédients
  croissant avec le niveau ; résultat éventuellement aléatoire (jets).
- Un personnage peut apprendre plusieurs métiers (limite à définir, par ex. 3 au court terme).
- **Prototype actuel :** les trois métiers sont connus d'office. Les ressources (frêne, chêne,
  cuivre, fer) repoussent 1 à 2 minutes après la récolte ; XP pour le niveau n = 5 × n × (n − 1).
  Célébrimbert, le forgeron de Brumerive, propose 10 recettes (bois, minerai, peaux et crocs de loup).

### 10.3 Long terme

Herboriste → Alchimiste (potions), Tailleur (capes, coiffes), Joaillier (anneaux, amulettes),
Cordonnier (bottes, ceintures), Pêcheur et Cuisinier, Éleveur (montures), forgemages (amélioration).
En multi : ateliers publics, commandes entre joueurs, artisanat assisté (le client fournit les
ingrédients).

---

## 11. Quêtes

### 11.1 Court terme : système simple

- **Types d'objectifs :** parler à un PNJ, vaincre N monstres d'un type, récolter ou apporter N objets,
  aller à un lieu, vaincre un groupe précis.
- **Structure :** une quête = une suite d'**étapes**, chaque étape = un ou plusieurs **objectifs**.
- **Récompenses :** XP, monnaie, objets, déblocage de quête suivante.
- **Journal de quêtes** consultable, objectif courant affiché, PNJ marqués d'une icône (`!` / `?`).
- **Conditions d'accès :** niveau, quête précédente terminée, race ou Voie (optionnel).
- **Conditions de camp** : une quête peut être réservée à un camp (acte I), ou demander d'avoir
  atteint un acte de la quête principale.
- Contenu cible de l'alpha : un tutoriel par camp, environ 15 quêtes secondaires (5 par zone de
  départ), les actes I et II de la quête principale (une chaîne par camp) et le début de l'acte III.

### 11.2 Long terme : quêtes complexes

- **Embranchements et choix** avec conséquences (drapeaux de monde persistants par personnage).
- **Chaînes multi-régions** (une chaîne par Relique, plus une chaîne finale).
- **Dialogues ramifiés** avec conditions (caractéristiques, réputation, objets).
- **Réputation** auprès des camps, des peuples et des factions.
- **Quêtes de Voie** (débloquer les sorts de rang III).
- **Événements de monde** (invasion cendrée d'une région, en multi : objectif collectif).
- **Mise en scène :** cinématiques légères dans le moteur (déplacements scriptés, bulles, caméra).

---

## 12. Donjons

- **Entrée :** une **clé** (fabriquée ou lootée) consommée à l'entrée ; condition de niveau ou de quête.
- **Structure :** une suite de salles (3 à 6), chacune un combat imposé ; on ne peut pas sortir sans
  abandonner la progression.
- **Salle finale :** boss avec mécaniques propres (phases, invocations, zones dangereuses).
- **Récompenses :** butin exclusif au donjon (ressources de boss → panoplie du donjon), XP bonus,
  progression de quête.
- **Solo :** les donjons sont faisables seul (avec équilibrage dédié), ou avec des **compagnons PNJ**
  (long terme) ; en multi, conçus pour 4 à 8 joueurs.
- **Donjons de Relique :** un par Relique, boss = un Héraut Cendré.

---

## 13. Multijoueur en ligne

### 13.1 Principes

- **Serveur global** unique (un seul monde, pas de « serveurs » séparés pour les joueurs), découpé en
  **instances** pour limiter la densité.
- **Serveur autoritaire :** toutes les règles (combat, butin, inventaire, échanges) sont calculées
  côté serveur ; le client n'envoie que des intentions.

### 13.2 Instances

- Chaque carte (ou zone de cartes) peut exister en plusieurs **instances** (aussi appelées canaux).
- **Plafond par instance** (par ex. 50 joueurs dans une grande ville, 20 en extérieur), avec création
  automatique d'une nouvelle instance quand le plafond est atteint.
- **Attribution :** priorité à l'instance où se trouvent les amis ou le groupe, puis à la moins remplie
  au-dessus d'un seuil (pour que les cartes ne paraissent pas vides).
- **Rejoindre un ami :** commande ou bouton dans la liste d'amis → transfert vers son instance s'il
  reste de la place (dépassement léger toléré pour les membres d'un groupe).
- **Groupe :** les membres d'un groupe sont toujours placés dans la même instance.
- **Fusion :** les instances sous-peuplées sont fusionnées progressivement.
- **Donjons :** instance privée par groupe.

**Séparation par avancement dans la quête principale.** Les instances sont réparties en deux
« mondes » selon l'avancement de chaque joueur :

- **Pendant les actes I et II** (quêtes de camp, voir § 3.4) : le joueur ne peut rejoindre que des
  instances où **personne n'a commencé l'acte III**. Les nouveaux joueurs se retrouvent entre eux pour
  faire leurs premières quêtes tranquillement, et les zones de départ restent des **havres de paix**
  pour leurs combats et leurs métiers : aucun joueur de haut niveau ne vient y vider les monstres et
  les ressources en un éclair.
- **Dès le début de l'acte III** (la première quête de l'alliance contre le Cendré, à la fin de
  l'acte II) : le joueur bascule dans les instances communes, où tous les joueurs qui ont passé ce
  cap sont mélangés, quel que soit leur camp ou leur niveau.
- La bascule est définitive et annoncée au joueur au moment où il commence la première quête de
  l'alliance.
- Les règles d'attribution ci-dessus (amis, groupe, remplissage) s'appliquent à l'intérieur de
  chaque monde.
- **Mode mentor** : un joueur qui a commencé l'acte III peut rejoindre l'instance d'un ami débutant,
  seulement en groupe avec lui. En mentor, il ne récolte pas de ressources et ne gagne pas de butin,
  pour que le havre de paix reste intact.
- **Passer les actes I et II** (multi, long terme) : un joueur peut choisir de sauter les quêtes de
  camp pour commencer directement l'acte III, par exemple pour être aidé par des amis ou par un autre
  de ses personnages de haut niveau. Il est prévenu avant de confirmer : il renonce aux récompenses
  de ces quêtes (expérience, objets, écus) et bascule tout de suite dans les instances communes. Le
  choix est définitif.

### 13.3 Fonctionnalités multi

| Domaine | Fonctionnalités |
|---|---|
| **Social** | Chat (local, groupe, commerce, recrutement, privé), liste d'amis, ignorés, émotes |
| **Groupe** | Jusqu'à 8 joueurs, partage d'XP, suivi du chef, marqueurs de quête partagés |
| **Combat** | Rejoindre le combat d'un ami, combats de groupe, mode spectateur, verrouillage du combat |
| **Quêtes** | Objectifs partagés en groupe (« vaincre X » compte pour tous), événements de monde |
| **Métiers** | Échange sécurisé entre joueurs, artisanat assisté, commandes, hôtel des ventes |
| **Guildes** | Création, rangs, banque, niveau de guilde (long terme) |
| **Camps** | Opposition en PvE uniquement. **À décider avant la Phase 5 :** deux joueurs de camps opposés peuvent-ils grouper avant l'acte III ? (Pistes : interdit jusqu'à l'acte III ; ou autorisé, mais quêtes de camp non partagées.) |
| **PvP** | Hors périmètre initial ; duels éventuels plus tard |

### 13.4 Comptes et persistance

- Compte avec plusieurs personnages ; sauvegarde serveur (base de données).
- Le mode solo utilise **le même format de sauvegarde** (fichier local), ce qui permet d'envisager la
  migration d'un personnage solo vers le serveur (à décider : risque de triche).

### 13.5 Sécurité et modération

- Validation serveur de toutes les actions, limitation de débit, journal des transactions
  (anti-duplication), signalement de joueurs, outils de modération de base.

---

## 14. Direction artistique, audio, interface

### 14.1 Graphisme

- **2D isométrique**, tuiles en losange de **64×32 px** ([décision 0004](decisions/0004-grille-isometrique.md)).
- Style **dessiné, couleurs chaudes et saturées**, contours marqués, proche du vectoriel de Dofus
  Rétro ; palette par région (verts doux à Brumerive, gris et ocre à Hautepierre, noir et braise dans
  les Marches Cendrées).
- **Couleurs par zone :** Brumerive verte et lumineuse, Crasse-Roc (gobelins) terne et sombre,
  Sylvebrume (elfes) fraîche ; la densité d'arbres s'ajuste à chaque zone.
- **Personnages :** proportions **normales** (pas de style « chibi » : tête d'environ 1/5,5 de la
  hauteur, comme dans Dofus Rétro), environ 66 px de haut à l'écran pour des cases de 64 × 32. Animés en 8 directions (4 dessinées + symétrie), animations :
  repos, marche, course, attaque, sort, dégât, mort, récolte.
- **Personnalisation :** couleurs du personnage par zones de teinte ; équipements visibles.
- **Pipeline (prototype) :** images vectorielles SVG dans `game/art/`, rendues par le jeu. Les SVG
  sont des modèles à couleurs remplaçables (peau, tunique, cheveux…), ce qui donne races, tenues et
  PNJ à partir des mêmes dessins. Les personnages sont **articulés** (jambes, torse, bras, tête, arme,
  accessoires) et animés par le code, à la manière des animations Flash de Dofus Rétro : repos
  (respiration), marche, attaque. Pas de quadrillage hors combat. Voir `game/art/README.md`.

### 14.2 Audio

- Musique orchestrale et folk (cordes, flûtes, cornemuses, chœurs pour les moments épiques), un thème
  par région, un thème de combat, un thème de boss.
- Bruitages courts et lisibles pour chaque type de sort et d'impact.

### 14.3 Interface (inspirée de Dofus Rétro)

- **Bandeau bas :** chat à gauche, PV dans un cœur rouge qui se vide, PA dans une étoile bleue, PM
  dans une case verte, barre de sorts (icônes avec raccourci et coût en PA) et d'objets, boutons de
  menus (inventaire, caractéristiques, sorts, quêtes, métiers, carte, amis, guilde). Le bandeau
  reste affiché en exploration ; un clic sur un sort hors combat ouvre sa fiche.
- **Fenêtres :** inventaire avec poupée d'équipement, fiche de caractéristiques, grimoire de sorts,
  journal de quêtes, fenêtre de métier, carte du monde (touche M).
- **Minicarte** en haut à droite, sous le bandeau du haut, en exploration seulement (en combat, la
  place revient à l'ordre de jeu) ; un clic dessus ouvre la carte du monde, et un bouton « – » la
  replie (il ne reste que sa barre) quand elle cache un monstre ou un PNJ.
- **En combat :** frise d'initiative, prévisualisation de portée et de zone, dégâts estimés au survol,
  bouton « fin de tour ». Au survol d'un combattant, ses informations (nom, niveau, PV, PA, PM,
  résistances aux 6 éléments) remplacent la barre de sorts, comme dans Dofus Rétro.
- Interface redimensionnable, lisible en 1280×720 minimum.

### 14.4 Encyclopédie (long terme)

Une fenêtre qui regroupe tout ce que le joueur peut vouloir vérifier sans quitter le jeu, avec une
recherche et des liens entre les fiches (un objet renvoie aux monstres qui le lâchent, un monstre à
ses objets) :

- **Objets** : icône, type, niveau, rareté, jets possibles, conditions, attaque des armes, panoplie
  et ses bonus, et comment l'obtenir (butin de quels monstres, recette de quel métier, marchand).
- **Monstres** : apparence, niveau, PV, PA, PM, résistances, sorts, butin avec les taux, zones où
  il vit, son élite et son butin.
- **Classes (Voies) et races** : rôle, éléments, sorts avec leur fiche, passif et sort racial ;
  plus tard les Voies Miroir.
- **Bestiaire** : la fiche d'un monstre se remplit un peu plus à chaque combat contre lui
  (silhouette et « ? » tant qu'on ne l'a pas croisé). Elle est complète en une dizaine de combats au
  plus, pour ne jamais devoir farmer une famille pendant des heures. Paliers proposés (combats
  gagnés contre ce monstre) :

  | Combats | Ce qui se révèle |
  |---|---|
  | 1 | Nom, apparence, niveau, description |
  | 2 | PV, PA, PM, initiative |
  | 3 | Résistances aux 6 éléments |
  | 5 | Sorts (avec leur fiche) |
  | 7 | Objets du butin (sans les taux) |
  | 10 | Taux de butin, zones où il vit, son élite (fiche complète) |

  Les objets et les classes restent visibles d'emblée.

Les fiches sont générées à partir des données du jeu (`game/data/`), sans texte à tenir à jour à
la main.

---

## 15. Propriété intellectuelle

Le jeu est **inspiré** de Dofus et du Seigneur des Anneaux, il ne doit **rien en reprendre
directement** :

- **Pas de noms, lieux ou personnages de Tolkien** (Hobbit, Mordor, Sauron, Gondor, Anneau unique,
  etc.). Certains termes sont des marques déposées (par ex. « Hobbit », « Ent ») ; les termes
  génériques (Elfe, Nain, Orque, Géant, Lutin, Squelette…) peuvent être utilisés.
- **Pas d'assets, noms ou mécaniques nommées d'Ankama** (Kamas, Zaap, Iop, Wabbit…). Les mécaniques
  génériques (PA/PM, grille, prospection) ne sont pas protégeables en tant que telles, mais leurs noms
  et leur présentation exacte doivent être les nôtres.
- Avant toute publication : vérifier les noms retenus (recherche de marques, moteurs de recherche) et
  tenir un registre des assets tiers et de leurs licences (`game/assets/CREDITS.md`).

---

## 16. Architecture technique

### 16.1 Principe directeur

> **Le solo est un serveur local.** La logique de jeu (règles de combat, inventaire, quêtes, butin)
> vit dans un **noyau** indépendant de l'affichage. Le client affiche et envoie des **commandes** ; le
> noyau les valide et renvoie des **événements**. En solo, le noyau tourne dans le même processus ; en
> multi, il tourne sur le serveur. Ce choix est la condition pour passer en ligne sans tout réécrire.

```
┌────────────── Client ───────────────┐        ┌──────────── Serveur (multi) ────────────┐
│ Rendu iso, UI, audio, entrées       │        │ Passerelle (auth, sessions, websocket)  │
│        │ commandes   ▲ événements   │ réseau │ Gestionnaire d'instances                │
│        ▼             │              │ ◄────► │ Noyau de jeu (même code que le solo)    │
│  Noyau de jeu (solo, en local)      │        │ Persistance (PostgreSQL), cache (Redis) │
└─────────────────────────────────────┘        └──────────────────────────────────────────┘
                 ▲                                          ▲
                 └──── Données de contenu (JSON / YAML) ────┘
```

### 16.2 Choix de moteur

> **Décision : Godot 4 + GDScript** — voir [0001](decisions/0001-moteur-godot-4.md) et
> [0002](decisions/0002-langage-gdscript.md).

| Option | Avantages | Inconvénients |
|---|---|---|
| **Godot 4 (GDScript ou C#)** — ✅ *retenu* | Gratuit et libre, très bon en 2D/isométrique (TileMap), export PC et web, serveur sans affichage possible, même langage côté client et serveur | Réseau MMO à construire soi-même |
| TypeScript : Phaser (client) + Node/Colyseus (serveur) | Code partagé client/serveur trivial, natif navigateur, Colyseus gère salles et instances | Outils d'édition de niveaux moins intégrés, performances 2D moindres |
| Unity (C#) | Écosystème énorme | Licence, lourd pour de la 2D iso, historique de changements de licence |

### 16.3 Contenu piloté par les données

Races, classes, sorts, monstres, objets, recettes, quêtes, cartes et tables de butin sont décrits dans
des **fichiers JSON** (`game/data/`, [décision 0003](decisions/0003-donnees-json.md)), vérifiés en CI, éditables sans recompiler. Voir les
exemples en [annexe](#20-annexes--formats-de-données).

### 16.4 Qualité

- Tests automatisés du noyau (règles de combat, calculs de dégâts, butin, quêtes).
- **Combat déterministe** à partir d'une graine aléatoire, pour rejouer et déboguer un combat.
- Intégration continue (GitHub Actions) : tests + validation des fichiers de données à chaque push.

---

## 17. Périmètre par phase

| Phase | Contenu | Critère de sortie |
|---|---|---|
| **0. Pré-production** | Choix techniques, GDD validé, prototypes papier | Moteur choisi, structure du dépôt en place |
| **1. Prototype** | Une carte, déplacement, un combat 1 contre 1 | Un combat jouable de bout en bout |
| **2. Alpha solo** (court terme) | 3 races (une par camp), 4 classes (avec le Théologue), combat + butin, quêtes simples, 3 métiers, équipement, 3 zones de départ + Hautepierre | Environ 10 à 15 h de jeu solo de niveau 1 à 30 |
| **3. Solo étendu** (long terme) | 6 races de plus (Nains, Orcs, Semi-hommes, Géants, Squelettes, Lutins ; 9 au total), 5 classes de plus (Paladin, Myrmidon, Ombre, Venomancien, Démoniste ; 9 au total), Voies, donjons, quêtes complexes, légendaires, scénario complet | Quête des Reliques jouable jusqu'au boss final |
| **4. Fondations réseau** | Serveur autoritaire, comptes, une instance, synchronisation | Deux joueurs se voient et combattent ensemble |
| **5. Multi** | Instances, groupe, amis, chat, échanges, hôtel des ventes, guildes | Bêta fermée |

> Les phases 3 et 4 peuvent se chevaucher : la phase 4 peut démarrer dès que l'alpha solo est stable.
> Détail des tâches : voir [TODO.md](TODO.md).

---

## 18. Risques

| Risque | Impact | Parade |
|---|---|---|
| Périmètre trop large (MMO) | Projet jamais terminé | Phases strictes, chaque phase doit être jouable et livrable |
| Charge graphique (races × équipements × animations) | Élevé | Personnages modulaires, recolorisation, nombre de races limité tant que le pipeline n'est pas rodé |
| Équilibrage des Voies mixtes | Combinaisons abusives | Simulateur de combat, Fondamentaux modestes, passif de Maîtrise |
| Passage au multi | Réécriture | Noyau séparé, commandes/événements dès la phase 1 |
| Propriété intellectuelle | Juridique | § 15, noms originaux, registre des assets |
| Coût serveur | Financier | Combat au tour par tour (peu de bande passante), instances, montée en charge progressive |

---

## 19. Glossaire

| Terme | Définition |
|---|---|
| **PA** | Points d'Action, dépensés pour lancer sorts et attaques |
| **PM** | Points de Mouvement, dépensés pour se déplacer d'une case |
| **Voie** | Classe / école de sorts |
| **Spécialisation** | Voie principale donnant accès aux rangs II et III |
| **Prospection** | Statistique augmentant les chances de butin |
| **Instance** | Copie d'une carte ou zone, limitée en nombre de joueurs |
| **Relique** | Objet légendaire unique de la quête principale |
| **Corrompu** | Variante renforcée d'un monstre, touchée par les cendres |
| **Sacré / Impie** | Éléments composés : Acier + Flamme, Tempête + Givre |
| **Dommages** | Bonus de dégâts brut, sans élément, ajouté à chaque ligne de dégâts |
| **Panoplie** | Ensemble d'objets dont le bonus grandit avec le nombre de pièces équipées |
| **Voie Miroir** | Spécialisation opposée d'une Voie : même rôle, élément retourné |

---

## 20. Annexes : formats de données

Exemples indicatifs : le format final dépendra du moteur choisi.

**Sort :**

```json
{
  "id": "guerrier.charge",
  "nom": "Charge",
  "voie": "guerrier",
  "rang": 1,
  "niveau_requis": 1,
  "cout_pa": 3,
  "portee": { "min": 2, "max": 4, "modifiable": false, "ligne_de_vue": true, "en_ligne": true },
  "zone": { "type": "case" },
  "relance": { "par_tour": 1, "par_cible": 1, "delai": 0 },
  "effets": [
    { "type": "deplacement_vers_cible" },
    { "type": "degats", "element": "acier", "min": 8, "max": 12 }
  ],
  "critique": { "chance": 5, "effets": [{ "type": "degats", "element": "acier", "min": 12, "max": 16 }] }
}
```

**Monstre :**

```json
{
  "id": "loup_des_collines",
  "nom": "Loup des collines",
  "niveaux": [3, 7],
  "caracs": { "pv": 40, "pa": 6, "pm": 4, "initiative": 120 },
  "resistances": { "acier": 5, "flamme": -10, "givre": 10, "tempete": 0 },
  "sorts": ["monstre.morsure", "monstre.hurlement"],
  "ia": "melee",
  "xp": 35,
  "butin": [
    { "objet": "ressource.croc_de_loup", "taux": 0.30 },
    { "objet": "ressource.peau_de_loup", "taux": 0.20 },
    { "objet": "equipement.cape_du_loup", "taux": 0.01 }
  ]
}
```

**Quête :**

```json
{
  "id": "brumerive.loups_affames",
  "nom": "Les loups affamés",
  "conditions": { "niveau_min": 3, "quetes_terminees": ["brumerive.tutoriel"] },
  "etapes": [
    { "objectifs": [{ "type": "vaincre", "monstre": "loup_des_collines", "nombre": 5 }] },
    { "objectifs": [{ "type": "parler", "pnj": "berger_alric" }] }
  ],
  "recompenses": { "xp": 400, "monnaie": 150, "objets": [{ "id": "equipement.bottes_du_berger", "nombre": 1 }] }
}
```

**Recette :**

```json
{
  "id": "forgeron.epee_de_fer",
  "metier": "forgeron",
  "niveau_requis": 5,
  "ingredients": [
    { "objet": "ressource.minerai_de_fer", "nombre": 5 },
    { "objet": "ressource.bois_de_frene", "nombre": 2 },
    { "objet": "ressource.croc_de_loup", "nombre": 1 }
  ],
  "resultat": "equipement.epee_de_fer",
  "xp_metier": 20
}
```
