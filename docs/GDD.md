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
5. [Système des Voies](#5-système-des-voies)
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
   les rangs de sa Voie, maîtriser des métiers et réunir des panoplies comptent autant.
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
- **État actuel** : **Brumerive est produite** (lot du chantier 3) avec ses quatre paliers : loups
  1–3, frondeurs 4–6, pillards et épouvantails 7–9, briseurs 10–12, une élite par famille et le
  mini-boss Krasbouk (niveau 12). **Crasse-Roc aussi** : rats et grouilleurs 1–3, vampipistrelles
  4–6, miliciens de Hautepierre 7–9, contremaîtres zélés 10–12, élites et le Balourd des Abîmes
  (niveau 12). **Sylvebrume aussi** : morilles 1–3, cerfs et arbres vivants 4–6, bûcherons 7–9,
  tisseuses 10–12, élites et la Mère-Toile (niveau 12). Les trois zones de départ sont produites.
  **Hautepierre (13–30) aussi** : 19 cartes reliées aux zones de départ par trois portes et une
  Pierre de Passage (20 brumes), une famille par palier (détrousseurs, trolls, corbacs, gargouilles,
  Cendrillons, olifants), leurs élites, trois variantes corrompues et le boss Grondin (niveau 30).
  Le lot Métiers a posé les nouvelles ressources sur les cartes : **tout le contenu du chantier 3
  est produit**.

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
Un personnage garde **une seule classe** (décision de l'auteur, 25/10/2026 ; § 5).

### 4.2 Races

Une race apporte : un bonus de caractéristiques, un passif racial et un sort racial. Elle ne bloque
aucune classe. L'impact doit rester modéré (environ 5 à 10 % de puissance) pour ne pas imposer de
combinaisons « optimales ».

**Les 9 races du jeu** (validées) : trois par camp (voir § 3.4). Une par camp dès l'alpha, les six
autres (Nains, Orcs, Semi-hommes, Géants, Squelettes, Lutins) en Phase 3.

| Race | Camp | Bonus | Passif | Sort racial | Phase |
|---|---|---|---|---|---|
| **Humain** | Allié | +Vitalité, +Sagesse | *Polyvalence* : +10 % d'XP de métier | *Ralliement* : +2 PA ce tour (sur soi en solo ; sur un allié en multi) | Alpha |
| **Gobelin** | Ennemi | +Agilité, +Chance | *Chapardeur* : +20 prospection et +20 % de brumes en fin de combat | *Coup bas* : dégâts Tempête au contact et −1 PM au prochain tour de la cible | Alpha |
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
| **Arcaniste** | Dégâts magiques, contrôle | Flamme / Givre (Intelligence / Chance) | États élémentaires et sorts créés selon leur combinaison : zones, ralentissements, bouclier |
| **Théologue** | Soigneur sacré | Sacré (Force + Intelligence) | Soins, boucliers, dégâts sacrés modestes |

Le **Théologue** est jouable dans l'alpha (✅) : une classe de soin rend le solo plus confortable et
permet de tester le Sacré dès maintenant. Arme de départ : le Sceptre de novice (Sacré, 4 à 7). Ses
4 sorts sont tous Sacrés (ils grandissent avec la Force et l'Intelligence) :

| Sort | PA | Portée | Effet |
|---|---|---|---|
| *Châtiment* | 4 | 2 à 5, ligne de vue | 8 à 12 dégâts Sacré (2 fois par tour) |
| *Imposition des mains* | 3 | 0 à 3 | Soin Sacré de 12 à 18 (1 fois par tour) |
| *Rempart de foi* | 2 | 0 à 3 | Bouclier Sacré de 12 à 16, jusqu'au prochain tour du porteur (tous les 2 tours) |
| *Sermon* | 4 | 1 à 5, **en ligne** | Zone en croix latine centrée sur la case visée (le croisement, sous la souris) : une case de chaque côté, une au-delà (la tête) et deux en deçà vers le lanceur (le pied, qui s'arrête avant sa case). Ennemis : 4 à 7 dégâts Sacré ; alliés : soin Sacré de 4 à 7 (1 fois par tour) |

Les soins des autres classes restent modestes (le Guerrier en a un petit, l'Arcaniste un bouclier)
pour que le Théologue garde son rôle.

**Identité des Voies pour l'alpha test 1** (fait) : une mécanique de plus par Voie, pour qu'elles
se jouent différemment et donnent envie de rejouer. Le reste de leur kit ne change pas, sauf pour
l'Arcaniste, dont le kit est entièrement remplacé.

| Voie | Ajout | Sort |
|---|---|---|
| **Arcaniste** | Version Flamme / Givre de la refonte (plus bas) : états élémentaires et *Fusion arcanique*, à la place de ses anciens sorts | *Composition* (1 PA rendu aussitôt : choisit ses 3 états Flamme / Givre dans une grille), *Fusion arcanique* (2 PA, 1 fois par tour) |
| **Guerrier** | Charge | *Charge* : 3 PA, 2 à 4 cases **en ligne**, ligne de vue, relance 2 tours ; fonce jusqu'au contact (ou jusqu'à la case si elle est libre ; un obstacle ou un combattant l'arrête avant) et frappe 6 à 9 Acier, seulement s'il arrive au contact |
| **Rôdeur** | Piège | *Collet* : 3 PA, 1 à 4 cases, relance 2 tours ; piège invisible, 7 à 10 Acier et −2 PM au prochain tour du premier ennemi qui y entre |
| **Théologue** | Retrait des états | *Absolution* : 3 PA, 0 à 5 cases, relance 2 tours ; retire aux ennemis leurs bonus, aux alliés leurs malus et leurs poisons |

**Arcaniste de l'alpha 1** : les états élémentaires Flamme et Givre seulement (ses caractéristiques
et son équipement ne changent pas). Ses anciens sorts (*Boule de feu*, *Éclat de givre*,
*Étincelle*, *Soin mineur*) ne lui sont plus reliés : leurs fichiers restent dans `data/sorts/`
comme trace de l'ancienne version. Son kit : *Composition* (1 PA rendu aussitôt, sans limite par
tour) ouvre une **grille flottante** des combinaisons de 3 états (Flamme ×3, Flamme ×2 + Givre,
Flamme + Givre ×2, Givre ×3, chacune avec le nom du sort qu'elle donnera ; celle en cours encadrée) :
au-dessus du sort quand on le clique, au-dessus de la souris quand on le lance par raccourci ; un
clic sur une case, ou sa touche (1 à 4), la choisit, Échap ou un clic ailleurs referme la grille.
Le choix remplace d'un coup les 3 états, permanents (+4 % de dégâts dans leur élément chacun, ne
peuvent pas être retirés). Elle remplace *Braise* et *Frimas* (un état par lancer, 3 lancers pour
une combinaison), jugés fastidieux par les testeurs ; leurs fichiers restent dans `data/sorts/`. Avec 3 états, *Fusion arcanique* (2 PA, 1 fois par tour) donne le sort de la
combinaison, qui prend l'une des **2 places** de sorts créés de la barre ; quand les deux sont
prises, le nouveau chasse le plus ancien (chaque sort créé garde ses propres relances). Tous les
sorts créés coûtent **4 PA** pendant l'alpha 1 (équilibrage ensuite). Dès le premier tour : 3 états
(Composition, 0 PA), création (2 PA), sort créé (4 PA). Dans la barre du bas : **3 petites orbes** à côté des
jauges, à la couleur de ses états (grises quand la place est libre), et les **2 places de sorts
créés** au bout des sorts, marquées « ? » tant qu'elles sont vides.

| Combinaison | Sort | Effet |
|---|---|---|
| Flamme ×3 | *Fournaise* | 4 PA, 2 à 6 cases, cercle de 1 : 9 à 13 Flamme aux ennemis et glyphe brûlante 2 tours (3 à 5 Flamme) |
| Flamme ×2 + Givre | *Choc thermique* | 4 PA, 1 à 5 cases : 7 à 10 Flamme, 4 à 6 Givre, −10 % de résistance Flamme 2 tours |
| Givre ×2 + Flamme | *Armure de givre* | 4 PA, 0 à 3 cases, relance 1 tour : bouclier Givre 14 à 20 et +20 Intelligence 2 tours à un allié |
| Givre ×3 | *Blizzard* | 4 PA, 1 à 5 cases, cercle de 1 : 6 à 9 Givre et −2 PM au prochain tour aux ennemis |

La **Tempête** viendra après l'alpha 1 (6 combinaisons de plus) : la description de *Fusion
arcanique* et le guide des testeurs la laissent deviner. Les effets des phases des boss ne peuvent
pas être retirés par *Absolution*. L'IA ne sait pas encore composer les états : dans
`tools/simulation.gd`, l'Arcaniste joue sans ses sorts créés.

**Long terme (9 Voies)** : trois familles de trois classes, selon la distance de combat.

| Famille | Classe | Rôle | Éléments principaux | Style |
|---|---|---|---|---|
| **Corps à corps** | **Guerrier** | Mêlée polyvalente | Acier (Force) | *(voir plus haut)* |
| | **Paladin** | Guerrier sacré ou électrique : mêlée, soutien, distance | Sacré / Tempête (Force + Intelligence / Agilité) | Voie Sacrée : coups bénis, glyphes en aura qui le suivent et renforcent les alliés. Voie Tempête : sorts électrisants à distance, balises reliées par des arcs électriques |
| | **Myrmidon** | Guerrier tank | Acier / Givre, chacun pur (Force / Chance), Vitalité | Bouclier, provocation (attire les coups), réduction de dégâts, poussée, garde un allié |
| **Mixte** | **Rôdeur** | Distance et mobilité | Acier / Flamme (Force / Intelligence) ; Acier / Tempête dans l'alpha | *(voir plus haut)* ; à terme, Voie Flamme tournée vers les pièges et les explosifs |
| | **Ombre** | Assassin | Tempête / Acier (Agilité / Force) | Voie Tempête : mobilité, frappe et repli, clones de foudre qui explosent. Voie Acier : invisibilité, cumul de bonus et de malus, armes d'obscurité à retardement. Les deux : entrer dans l'ombre d'un combattant |
| | **Chronomancien** | Maître du temps : contrôle, mi-distance | Impie / Givre pur (Agilité + Chance / Chance) | Voie Impie : glyphe Horloge, cible téléportée sur le cadran, un effet par heure. Voie Givre : retour à une position passée, envoi dans le futur, pulsions temporelles |
| **Distance** | **Arcaniste** | Dégâts magiques, contrôle | Flamme / Givre (Intelligence / Chance) ; après la refonte, Flamme / Tempête / Givre (+ Agilité) | *(voir plus haut)* ; après la refonte : états élémentaires cumulés et sort créé selon leur combinaison |
| | **Théologue** *(dès l'alpha)* | Soigneur sacré | Sacré (Force + Intelligence) | Soins, boucliers, retrait des états, résurrection (multi), dégâts sacrés modestes |
| | **Démoniste** | Dégâts impies ou ardents | Impie / Flamme (Agilité + Chance / Intelligence) | Voie Impie : armée de serviteurs invoqués (offensif, tank, soutien). Voie de Flamme : embrasement du terrain (niveaux 1 à 3 puis calciné), sorts qui varient selon l'embrasement |

Le Sacré et l'Impie sont des éléments à part entière (voir § 4.4) : le Sacré s'appuie sur l'Acier et
la Flamme, l'Impie sur la Tempête et le Givre.

**Répartition des éléments entre les classes** (à terme, Arcaniste refondu) :

| Classe | Acier | Tempête | Flamme | Givre | Sacré | Impie |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Guerrier | ● | | | | | |
| Paladin | | ● | | | ● | |
| Myrmidon | ● | | | ● | | |
| Rôdeur | ● | | ● | | | |
| Ombre | ● | ● | | | | |
| Chronomancien | | | | ● | | ● |
| Arcaniste | | ● | ● | ● | | |
| Théologue | | | | | ● | |
| Démoniste | | | ● | | | ● |
| **Total** | **4** | **3** | **3** | **3** | **2** | **2** |

Par caractéristique (le Sacré compte pour la Force et l'Intelligence, l'Impie pour l'Agilité et la
Chance) : Force 6 classes, Intelligence 5, Chance 5, Agilité 5. L'Acier a une classe de plus, en
accord avec ses 33 % chez les monstres (§ 8.1).

Dans l'alpha 1 (4 classes) : Acier 2 (Guerrier, Rôdeur), Tempête 1 (la Flèche du Rôdeur), Flamme 1
et Givre 1 (Arcaniste), Sacré 1 (Théologue), Impie 0. Points à suivre : aucune classe de l'alpha 1 ne
joue l'Impie (la Panoplie du Mauvais Œil ne sert encore à personne) ; quand le Rôdeur passera de la
Tempête à la Flamme, la Tempête n'aura plus de classe de départ en attendant l'Arcaniste refondu, le
Paladin et l'Ombre.

Mécaniques à ajouter pour ces classes : invisibilité, poisons et dégâts sur la durée, provocation,
auras, invocations, sacrifice de PV, résurrection (multi).

#### Pistes de l'auteur pour les classes à venir (idées, non validées)

Chaque classe aurait **deux Voies principales**, une par élément, qui se jouent différemment (le
tableau ci-dessus en tient compte : Paladin Tempête au lieu d'Acier, Démoniste Flamme au lieu de
Givre, Rôdeur Flamme au lieu de Tempête, Myrmidon Acier pur ou Givre pur, Chronomancien (qui
remplace le Venomancien) Impie ou Givre pur). Ces pistes recoupent les Voies Miroir (§ 5.3), à articuler le moment venu.

**Paladin — Sacré ou Tempête**

- *Paladin Sacré* : dégâts Sacrés et soutien. Il booste ses alliés par des **glyphes autour de lui
  qui le suivent comme une aura**.
- *Paladin Tempête* : sorts électrisants à distance. Ses sorts déposent des **balises** : des
  sortes de pièges qui ne se déclenchent pas au passage (allié ou ennemi) mais servent de points
  d'ancrage pour créer des **arcs électriques** entre elles (comme les lignes de bombes du Roublard
  de Dofus 2.0). Un ennemi qui touche ou traverse un arc subit des dégâts. Un sort de projectile du
  Paladin qui passe par un arc est **renforcé**. Les ennemis peuvent **casser** une balise en
  marchant dessus ou en lui infligeant 1 point de dégâts.

**Myrmidon — Acier pur ou Givre pur**

Un tank dans ses deux Voies. Il a beaucoup de moyens d'**arriver au contact**, mais peu ou pas pour
en sortir. Il peut **forcer les ennemis à l'attaquer** (par exemple une aura de provocation autour
de lui). Il n'a pas de rôle de soutien : il ne partage pas ses résistances avec ses alliés, comme
pourrait le faire un Paladin.

- *Myrmidon Acier* : force brute et résistances élémentaires. Il inflige plus de dégâts que la Voie
  Givre et augmente ses propres résistances. Sa force lui permet de **modifier le terrain** en
  démolissant certains obstacles (arbres, rochers…, mais pas les gros obstacles sur plusieurs cases
  comme les bâtiments), pour rejoindre le combat encore plus vite.
- *Myrmidon Givre* : il entrave ses ennemis, surtout en leur **retirant des PM**, tout en encaissant
  correctement les coups. Il peut **assommer** un ennemi pour l'empêcher de jouer son prochain tour
  (avec un temps de relance important). Il peut **geler l'eau ou l'air d'un trou** de la carte pour
  y passer en marchant.

**Démoniste — Impie ou Flamme**

- *Démoniste Impie* : il **invoque des serviteurs** qui l'aident à se battre, de plusieurs types
  (offensif, tank, soutien…), qui viennent renforcer les rangs de son armée de démons.
- *Démoniste de Flamme* : sorts à cumul. Chaque sort lancé **embrase le terrain** des cases
  touchées : niveaux d'embrasement 1 à 3, puis la case devient **calcinée** si elle est embrasée
  une 4e fois. Chaque sort a des **variantes selon l'embrasement** de la ou des cases touchées.
  Exemple : *Mur de flammes* dure un tour par niveau d'embrasement ; sur une case calcinée, il ne
  dure pas et inflige seulement des dégâts supplémentaires dans la zone du sort.

**Ombre — Tempête ou Acier**

- *Ombre Tempête* : s'appuie sur l'Agilité et la vitesse de déplacement, le repositionnement,
  l'engagement rapide : appliquer des dégâts puis repartir en lieu sûr. Elle crée des **images
  rémanentes** : en quittant une case, elle laisse derrière elle un clone à son image, fait de
  foudre, qui **explose au contact d'un ennemi** ou après être resté un tour complet sur le terrain.
- *Ombre Acier* : s'appuie sur l'**invisibilité fréquente** ; elle cumule les bonus sur elle et
  les malus sur l'adversaire pour lui infliger de très lourds dégâts. Une fois dans la mêlée et
  révélée, elle a moins d'échappatoires que l'Ombre Tempête. Elle crée des **armes faites
  d'obscurité** qu'elle cache dans l'ombre d'un ennemi : l'arme le suit et il en subit les effets
  **à son prochain tour** (dégâts à retardement).
- *Les deux Voies* : l'Ombre peut **entrer dans l'ombre d'un allié ou d'un ennemi** et en ressortir
  au moment de son choix.

**Rôdeur — Voie Flamme : pièges et explosifs**

La Voie Flamme s'articule autour de **pièges explosifs** qui se déclenchent au passage. Le Rôdeur
de Flamme doit prévoir à l'avance le chemin des ennemis, tout en cachant l'emplacement exact de ses
pièges pour être efficace. Pièges principaux :

- *Mâchoire de loup* : piège sur une case. Le personnage qui passe dessus subit des dégâts et se
  retrouve relié au centre du piège par une **chaîne** qui l'empêche de s'en éloigner de plus de
  3 cases.
- *Piège à fil* : piège sur **4 cases en ligne**, perpendiculaire au Rôdeur. Les deux cases
  extérieures contiennent des explosifs, qui sautent si un combattant traverse les fils (les deux
  cases du centre) ou marche directement sur un explosif.

**Chronomancien — Impie ou Givre pur** (remplace le Venomancien)

- *Chronomancien Impie* : il utilise les pouvoirs impies pour dérégler le temps. Un sort spécial
  pose une **glyphe Horloge** au sol autour de la cible, qui passe dans l'état **Manipulation du
  temps**. Ses autres sorts **téléportent** la cible sur les cases du cadran, en la faisant
  **avancer ou reculer** d'un certain nombre d'heures. Chaque heure applique un **effet propre** à
  la cible téléportée sur sa case (exemples : 1 h, −1 PA ; 2 h, poison Impie pendant 2 tours ;
  etc.). Le cadran : les 12 cases à 2 cases de la cible, sans les coins du carré 5 × 5 (C = la
  cible ; 12 h vers le haut de la grille, sens d'affichage en isométrique à fixer) :

  ```
  .  11 12  1  .
  10  .  .  .  2
   9  .  C  .  3
   8  .  .  .  4
  .   7  6  5  .
  ```

- *Chronomancien Givre* : l'entrave par le déplacement des cibles **dans le temps**. Des sorts
  ramènent une cible à **sa position d'il y a X tours**. D'autres l'**envoient dans le futur** : ses
  temps de relance diminuent, mais ses effets en cours s'écoulent d'un coup (bonus retirés) et les
  poisons qu'elle aurait subis lui sont **infligés en une fois**. Il fait surtout ses dégâts par des
  **pulsions temporelles**, qui frappent à chaque tour ou une seule fois à un moment du futur ou du
  passé. Exemple : une pulsion de Givre « passé » inflige des dégâts pour chaque manipulation
  temporelle que la cible a subie dans le passé.

**Arcaniste — refonte : une seule Voie multi-élément** (version Flamme / Givre dans l'alpha 1,
voir plus haut ; la Tempête après)
(inspirée du kit de l'Invoker de Dota)

- Trois petits **sorts d'état élémentaire** (Flamme, Tempête, Givre), « gratuits » : ils coûtent
  1 PA, remboursé aussitôt (le coût empêche seulement de les lancer sans PA).
- Lancer un sort d'état donne un **effet élémentaire permanent** (sans limite de durée). On en
  garde **3 au plus**, identiques ou mélangés dans n'importe quelle combinaison des trois
  éléments, soit **10 combinaisons**.
- Chaque effet élémentaire donne un passif de **+4 % de dégâts dans son élément**.
- Un quatrième sort de classe, *Fusion arcanique*, donne un sort qui dépend de la combinaison
  d'effets : toujours le même sort pour une même combinaison, avec des effets qui reflètent les
  éléments qui le composent.
- **Progression par niveau** : l'Arcaniste a déjà 4 sorts dès le départ (*Composition* et *Fusion
  arcanique*), plus ses sorts créés ; il n'apprend donc pas un sort tous les X niveaux comme les autres
  Voies. Ses niveaux débloquent les **fusions**, en 4 paliers (niveaux à fixer avec la progression
  de l'alpha 2). À la création, le joueur choisit **2 éléments sur 3** (A et B) ; le troisième (C)
  arrive ensuite par petites touches, et reste secondaire une bonne partie de la progression.

  | Palier | Débloque | Sorts créables |
  |---|---|:-:|
  | Niveau 1 | A et B : AAA, BBB, AAB, ABB | 4 |
  | Palier 2 | C en appoint, seulement en « +1 » : AAC, BBC | 6 |
  | Palier 3 | C en élément principal : CCC, CCA, CCB | 9 |
  | Palier 4 | La fusion 1 + 1 + 1 : ABC | 10 |

  L'alpha 1 correspond au premier palier, avec Flamme et Givre imposés.
- **Points de sort** (1 par niveau, § 4.5) : l'Arcaniste les place dans ses **éléments** (Flamme,
  Tempête, Givre). Le niveau d'un élément renforce son passif (+4 % de dégâts par état au départ,
  davantage ensuite) et les sorts créés qui contiennent cet élément, comme les trois orbes de
  l'Invoker. Chaque niveau reste un choix, et les éléments de départ peuvent rester les plus forts.

**Effets et états qu'on ne peut pas retirer.** Certains effets et états ne peuvent pas être
retirés (ni par un sort de retrait des états, comme ceux du Théologue, ni par un envoi dans le
futur du Chronomancien Givre), entre autres les états élémentaires de l'Arcaniste et l'état
Manipulation du temps. Chaque effet ou état dira s'il peut être retiré.

Mécaniques que ces pistes demandent : glyphes qui suivent leur lanceur (aura), balises et arcs
entre deux cases (dégâts à la traversée, renfort des projectiles), état du terrain cumulable
(embrasement, calciné), clones qui explosent, armes à dégâts différés, entrée dans l'ombre d'un
combattant, états élémentaires cumulables et sort généré selon une combinaison ; aura de
provocation, assommer (tour passé), terrain modifiable (obstacles démolis, eau et trous gelés),
piège qui enchaîne sa victime (rayon de 3 cases), piège sur plusieurs cases déclenché par un fil ; glyphe cadran et téléportation d'une heure à
l'autre, mémoire des positions passées, avance du temps sur une cible (relances, durées, poisons),
pulsions temporelles différées.

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
  200 de plus pour le 3, environ 8 400 au total pour le niveau 10). Cible de la vraie progression :
  niveau 10 en environ 2 h, niveau 30 en environ 15 h.
- **Vitesse d'XP de l'alpha 1** (en place) : l'XP de combat est multipliée par 3,5
  (`Character.XP_RATE`), pour finir tout le contenu (1 → 30) en 4 à 5 h : l'alpha 1 teste les
  mécaniques, pas la progression. On remettra ×1 pour l'alpha 2, qui testera le leveling.
- **Restat :** à terme via un objet ou une quête, pour ne pas punir l'expérimentation. Pendant
  l'alpha, bouton « Réinitialiser » gratuit sur la fiche (touche C) : tous les points investis
  sont rendus, les objets portés le restent même si leurs conditions ne sont plus remplies.

---

## 5. Système des Voies

**Décision de l'auteur (25/10/2026) : un personnage = une seule classe.** On reste sur du classique :
un personnage n'apprend que les sorts de sa Voie, jamais ceux des autres classes (pour le moment).
La profondeur vient des rangs des sorts de sa Voie, de sa Voie Miroir (§ 5.3), des caractéristiques
et de l'équipement.

### 5.1 Règles

1. Chaque sort appartient à une **Voie** et a un **rang** :
   - **Rang I — Fondamentaux** : appris avec la Voie, en montant de niveau.
   - **Rang II — Avancés** : plus puissants, débloqués plus tard dans la progression.
   - **Rang III — Maîtrise** : débloqués par une quête de Voie.
2. Le personnage est lié à sa Voie de départ ; il ne la change pas (seule la Voie Miroir, § 5.3,
   change l'élément de ses sorts).
3. **Barre de sorts limitée** (par ex. 12 emplacements actifs) : on choisit ce qu'on emporte au combat,
   le nombre de sorts connus n'est pas limité.

### 5.2 Option écartée : apprendre les sorts des autres classes

L'objectif long terme initial (tout personnage apprend les Fondamentaux de toutes les Voies, seule
la Voie de spécialisation donne les rangs II et III) est **écarté pour l'instant**. Gardé comme piste :

- **Pour** : beaucoup de builds et de liberté (rétention des joueurs expérimentés), moins de reroll,
  un objectif de progression horizontale (quêtes, maîtres de Voie, coût en brumes), un solo plus
  confortable (un peu de soin ou de mobilité pour tous).
- **Contre** : les classes perdent leur identité ; le jeu en groupe compte moins si chacun fait tout ;
  équilibrage bien plus dur (combos imprévus, méta « meilleurs sorts » où tout le monde a la même
  barre) ; combat moins lisible (on ne devine plus ce qu'un adversaire peut faire) ; plus de sorts à
  produire et un grimoire plus lourd.
- **Compromis possibles si on y revient** : 1 ou 2 emplacements seulement pour les sorts d'autres
  classes ; puissance réduite hors de sa classe (pas de montée de rang) ; seulement des sorts
  utilitaires de base, les sorts emblématiques restant à leur classe ; ou seulement dans les combats
  d'essai (§ 7.5), pour tester. Garde-fous alors prévus : Fondamentaux modestes, états incompatibles
  plutôt qu'interdictions, passif de Maîtrise de Voie, détection des combos par
  `game/tools/simulation.gd`.

### 5.3 Voies Miroir (long terme)

À terme, chaque Voie aura une **spécialisation opposée** qui retourne son élément, comme son reflet
dans un miroir : la **Voie Miroir**. Exemples :

- une classe sacrée (Paladin, Théologue) devient impie, et le Démoniste devient sacré ;
- une classe de Givre joue avec la Flamme, et inversement ;
- une classe d'Acier passe à la Tempête, et inversement.

La Voie Miroir garde le rôle de la classe (un Théologue Miroir soigne toujours) mais change
l'élément de ses sorts, et donc les caractéristiques et l'équipement à privilégier. Elle se débloque
par une quête de Voie, comme le rang III.

### 5.4 Implication court terme

Les classes sont **fixes** (pas d'apprentissage croisé, § 5.2) ; **le modèle de données prévoit déjà
`voie` et `rang` sur chaque sort** pour les rangs (alpha 2) et, si on y revient un jour, l'option
écartée.

---

## 6. Exploration et monde

- Le monde est découpé en **cartes** (un écran chacune), reliées par leurs bords et par des portes ou
  escaliers. Chaque carte extérieure a des coordonnées sur la carte du monde, tirées de son id
  (`<zone>_<x>_<y>`) ; les intérieurs n'en ont pas. Les cases praticables du bord qui mènent à la
  carte voisine portent un **halo blanc léger** ; la flèche jaune de chaque sortie se place en face
  de l'une d'elles (jamais devant une case bloquée).
- Le monde **continue de tourner sans le focus** (fenêtre en arrière-plan, onglet caché) : le temps
  réel écoulé est rattrapé au retour (10 min au plus) ; seul le menu pause arrête le temps.
- **Déplacement au clic** sur une grille isométrique ; recherche de chemin (A*).
- Sur une carte : PNJ, groupes de monstres visibles qui errent, ressources récoltables, éléments
  interactifs (portes, coffres, panneaux).
- **Pierres de Passage** (les zaaps du jeu) : une sur la première carte de chaque zone de départ
  (Brumerive, Crasse-Roc, Sylvebrume) ; c'est pour l'instant le seul lien entre les zones.
  - *Fait :* une pierre se **découvre** en la touchant (clic dessus, à pied ; arriver par un voyage
    ne compte pas). On ne voyage que vers une pierre découverte, et le voyage se **paie** en brumes,
    au prix de la pierre d'arrivée (10 brumes vers une zone de départ). La pierre de la zone de départ
    de la race est connue dès la création ; la carte d'élite de test (Trône de Cendre) est gratuite
    et connue de tous (`toujours_connue`). La fenêtre de voyage montre le prix de chaque
    destination et grise les pierres pas encore découvertes.
  - **Phase de test** (en place) : tant que les zones ne sont pas reliées à pied, **toutes les
    pierres sont connues dès le début** (`World.ALL_PASSAGES_KNOWN`) ; le voyage reste payant.
    Toucher une pierre en fait toujours le point de résurrection. On repassera à la découverte quand
    les zones seront reliées (par Hautepierre).
  - *À venir :* des pierres dans les autres zones (Hautepierre…), des prix qui grandissent avec la
    distance.
- **Carte du monde** et **minicarte** consultables. *Fait :* le personnage retient les cartes où il
  est allé (`cartes_visitees` dans la sauvegarde). La carte du monde (touche M), comme dans
  Dofus, **montre tout le monde dès le début** (décision de l'auteur) : un onglet par zone du jeu
  (les zones visitées d'abord), toutes les cartes nommées, le nombre de cartes visitées par zone ;
  les coordonnées d'une carte viennent de son id (`<zone>_<x>_<y>`, x vers l'est, y vers le sud),
  et la grille s'adapte à la taille de la zone. Les Pierres de Passage y figurent ; les
  intérieurs, sans coordonnées, n'y sont pas. (`WorldMapLayout` sait encore cacher les cartes non
  visitées, en « ? » pour leurs voisines, si l'on en veut un jour.) La minicarte, comme dans Dofus
  Rétro, est la carte du monde en réduit : une fenêtre fixe de 5 × 3 cartes centrée sur la carte
  actuelle (cadre doré, point bleu), avec les cartes, les chemins et les Pierres de Passage ; une
  carte tient sur un écran, inutile de la redessiner en petit. Survol : le nom de la carte ; un clic ouvre la carte du monde. Elle
  est dans la barre du bas, jamais sur la zone de jeu (§ 14).
- **Point de résurrection** : la dernière Pierre de Passage touchée (au départ, celle de la zone de
  départ). *Fait :* après une défaite, on se réveille à côté d'elle avec 1 PV, même si elle est sur
  une autre carte que le combat ; la fenêtre de voyage la rappelle. *À venir :* les temples.
- **Maison du joueur** : chaque personnage a la sienne (une porte du village mène à une carte
  personnelle, instanciée par joueur en multijoueur). Elle contient un **coffre** (stockage, 100
  places) et un **lit** (tous les PV d'un coup). Prototype : à Brumerive.
- **Points de vie** : ils se gardent d'un combat à l'autre et remontent lentement hors combat
  (1 PV toutes les 2 s, **trois fois plus vite assis** : bouton « S'asseoir » ou touche A, on se
  relève en marchant ou en entrant en combat) ; après une défaite, on se relève avec 1 PV.
- **Course** : un trajet de plus de 3 cases se fait en courant (vitesse × 1,4), en exploration
  comme en combat, pour le joueur comme pour les monstres.
- **Monstres du prototype** : deux par zone de départ — loup des collines et frondeur gobelin
  (Brumerive, désormais complétée par son lot de production : voir § 3.5), rat des galeries et grouilleur, mille-pattes vert qui crache de l'acide (Crasse-Roc),
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
   joueur choisit la sienne (temps limité en multi). **Cases de placement prédéfinies par carte**,
   comme dans Dofus : chaque carte décrit dans ses données ses cases de départ pour chaque camp
   (joueurs d'un côté, monstres de l'autre), choisies par le level design (obstacles, lignes de vue,
   distance). Où que le groupe soit engagé sur la carte, le combat démarre sur ces cases. *Fait :*
   calque `placement` de chaque carte (`j` joueurs, `m` monstres, obligatoire dès qu'elle a des
   groupes) ; à chaque combat, le côté de chaque camp est tiré au sort (une fois sur deux, les
   joueurs partent des cases `m` et les monstres des cases `j`) ; les monstres sont répartis au
   hasard sur les cases de leur côté, le joueur commence sur la première case du sien et choisit
   parmi les autres. Après le combat, il reprend l'exploration là où
   il a engagé. `game/tools/placement.py` propose un calque (joueurs à gauche, monstres à droite,
   cases non voisines), à retoucher à la main si le décor s'y prête mal.
3. **Tours :** ordre fixé par l'**Initiative**, visible dans une frise (timeline). À son tour, chaque
   combattant dépense ses **PA** (sorts, armes) et ses **PM** (déplacement case par case), dans
   n'importe quel ordre.
4. **Fin :** victoire quand tous les ennemis sont vaincus ; défaite si tous les alliés le sont, ou en
   cas d'abandon.
5. **Récompenses :** écran de fin avec XP, monnaie et butin pour chaque participant, en tableau façon Dofus Rétro : bandeaux « Gagnants » et « Perdants », une ligne par combattant (nom, niveau et montée de niveau, jauge d'expérience, XP, brumes, butin ; les combattants tombés grisés), durée du combat en tours. Une seconde après le dernier coup (victoire ou défaite, `MapView.COMBAT_END_DELAY`), le temps de voir la dernière perte de vie, et plus tard l'animation de mort, le combat se termine (retour en exploration, réveil compris) ; le récap s'affiche ensuite sans rien bloquer : le joueur peut se déplacer dessous, « Fermer », Échap ou le combat suivant le referment.

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

### 7.5 Combats d'essai (idée de l'auteur, inspirée du Kanojedo de Dofus)

Conception seulement, rien n'est codé. But : laisser le joueur **essayer un personnage qu'il n'a
pas encore** (un niveau, des caractéristiques, des sorts et un équipement de son choix) dans des
combats fictifs, pour voir ses dégâts futurs et préparer sa progression, sans rien risquer ni rien
gagner. C'est aussi un outil d'équilibrage pour les testeurs de l'alpha 2 (progression).

- **Lieu** : la *Salle des Songes héroïques*, une par capitale (et à Hautepierre), tenue par
  **Maître Esbroufe**, un illusionniste humain qui vend du rêve (« Ici, tout le monde est niveau
  100. Dehors, je ne garantis rien. »). Gratuit ; le joueur garde son personnage réel, intact, à la
  sortie.
- **Choix du personnage fictif** (une fenêtre avant le combat, façon fiche C) :
  - **niveau** de 1 au niveau max du jeu (30 pendant l'alpha, 100 à terme), pas seulement le sien ;
  - **caractéristiques** : les points qu'aurait un personnage de ce niveau, répartis librement
    (rendement décroissant compris, § 4.5), ou « comme mon personnage » mis à l'échelle ;
  - **sorts** : tous ceux de sa Voie disponibles à ce niveau, avec les rangs qu'il choisit (points
    de sort de ce niveau) ;
  - **équipement** : n'importe quel objet de niveau inférieur ou égal au niveau choisi, **même
    jamais obtenu** (liste issue du catalogue, filtres par emplacement, élément et panoplie), bonus
    de panoplie compris ; les objets légendaires et personnalisés (§ 10.4) seulement s'il les
    possède ;
  - **préréglages** : quelques profils enregistrés (« Arcaniste Givre 30 », « Guerrier tank »…) à
    recharger, et un bouton « Partir de mon personnage ».
- **Adversaires** :
  - **mannequins d'entraînement** (épouvantails syndiqués en grève, qui « encaissent par contrat »)
    : PV illimités, ne jouent pas ou jouent un tour basique, résistances réglables par élément ;
  - **monstres déjà rencontrés** (bestiaire, § 14.4) au niveau choisi dans leur famille, en groupe
    de 1 à 3 ; les mini-boss vaincus avec leurs phases. Pas de monstre jamais vu, pour ne rien
    gâcher de la découverte.
  - Une carte d'essai simple (dojo) et, plus tard, le choix d'une carte déjà visitée pour tester
    lignes de vue et placement.
- **Règles** : les règles de combat normales (§ 7.1 à 7.4), avec en options : PA et PM illimités,
  relances sans délai, critiques forcés ou désactivés (pour lire les fourchettes). **Aucune
  conséquence** : ni XP, ni brumes, ni butin, ni avancement de quête, de métier ou de succès ;
  aucune usure, aucun consommable dépensé ; la défaite ne renvoie pas au point de résurrection.
- **Résultats** : à la fin (ou à tout moment), un tableau par sort : dégâts min / moyen / max,
  avec et sans critique, dégâts par PA, dégâts totaux et par tour, soins et boucliers ; comparaison
  avec un autre préréglage (le même combat rejoué avec deux équipements). L'historique de combat
  (touche H) reste le détail ligne à ligne.
- **Multijoueur (à terme)** : instance privée ; un groupe peut y entrer ensemble, chacun avec son
  personnage fictif, pour tester des combinaisons ; duels fictifs entre amis possibles, sans
  classement (le PvP reste une idée en attente).
- **Technique** : le noyau construit un `Fighter` à partir d'un profil fictif (niveau,
  caractéristiques, sorts, équipement) sans toucher au `Character` réel ; le `Combat` est le même,
  avec un drapeau `fictif` qui coupe les récompenses et les conséquences. Le même profil peut
  servir à `tools/simulation.gd` pour équilibrer avec des personnages de tous niveaux.
- **Garde-fous** : le dojo ne révèle pas le contenu caché (monstres non rencontrés, objets
  légendaires) ; en multijoueur, le profil fictif n'existe que dans l'instance et ne peut rien
  échanger ni vendre.
- **Quand** : après l'alpha test 1 ; utile dès l'alpha test 2 (sorts par rang, progression 1 → 30).

### 7.6 Défis (idée de l'auteur, inspirée des idoles de Dofus)

Conception seulement, rien n'est codé. But : laisser le joueur rendre ses combats **plus durs**
quand il le veut, contre plus de récompenses. **Règle de l'auteur : on ne restreint jamais le
joueur** (pas de malus sur lui, pas de contrainte du type « ne pas bouger » ou « un seul sort par
tour ») : la difficulté vient uniquement des **monstres renforcés**.

- **Forme** : des **Fétiches** (nom provisoire ; parodie : des porte-bonheur de gobelins vendus
  comme « certifiés maudits »), objets qu'on active hors combat dans une fenêtre dédiée, pas dans
  l'équipement. Jusqu'à 4 actifs à la fois (2 pendant l'alpha). Ils valent pour tous les combats
  tant qu'ils sont actifs ; en groupe, ceux de tous les membres s'additionnent (comme les idoles).
- **Effets (sur les monstres seulement)**, chacun avec un **score** de difficulté :
  - statistiques : +X % de PV, +X % de dégâts, +X % de résistance à un élément ou à tous, +1 PA ou
    +1 PM, + % Critique, + Initiative (ils jouent avant) ;
  - comportements : bouclier au début du combat, soin d'un allié quand un monstre tombe, renvoi
    d'une part des dégâts, glyphe ou piège posé au premier tour, poison sur leurs coups,
    poussée sur leurs coups de mêlée ;
  - groupe : un monstre de plus dans le groupe (dans la limite de taille), élite qui remplace un
    monstre de la famille, phase de plus pour les mini-boss (jamais de soin au changement de phase,
    règle du § 8.1).
  - Interdit : tout ce qui retire au joueur des PA, des PM, de la portée, des sorts ou des cases ;
    tout ce qui le punit d'une action (« perdre des PV si on frappe à distance »). Un monstre qui
    lance déjà des malus avec ses sorts garde ses sorts ; le Fétiche n'en ajoute pas sur le joueur.
- **Récompenses** : le score total des Fétiches actifs donne un bonus d'XP et de **prospection**
  (butin) en %, plafonné (ex. +100 % chacun au plus) et réduit si le groupe est bien plus haut que
  les monstres (pas de défi gratuit en tapant des monstres faciles : comme les idoles, le bonus
  dépend de l'écart de niveau). Pas d'objet exclusif réservé aux défis au début, pour ne pas les
  rendre obligatoires ; plus tard, des titres ou des cosmétiques.
- **Obtention** : quelques Fétiches de base vendus en ville, les plus forts en butin de mini-boss,
  de donjon ou fabriqués par un métier (joaillier, § 10.3) ; chaque Fétiche a un niveau minimum.
- **Lisibilité** : en combat, une icône sur chaque monstre renforcé, avec la liste des Fétiches
  actifs à son survol (comme les états) ; l'écran de fin de combat montre le bonus gagné ; le
  combat d'essai (§ 7.5) permet de les essayer sans risque.
- **IA et équilibrage** : les effets passent par les mécanismes existants (bonus, glyphes,
  pièges, phases), donc l'IA les utilise sans code dédié ; `tools/simulation.gd` pourra mesurer
  la difficulté de chaque Fétiche pour fixer son score.
- **Quand** : après l'alpha test 1 (l'équilibrage de base d'abord) ; peut servir à l'alpha test 2
  pour les joueurs qui trouvent le jeu trop facile.

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
  - Le niveau **ne change pas le butin** : même table, mêmes taux, mêmes quantités et mêmes brumes pour
    toute la famille, quel que soit le niveau.
  - **PA et PM identiques dans toute la famille**, sauf exception pour une famille dont la mécanique
    repose sur ces caractéristiques (par exemple, une espèce qui gagne des PM en vieillissant).
  - Fait pour les deux familles de Crasse-Roc (rat des galeries 1–3 surtout bas, grouilleur 1–3
    surtout haut) ; les autres familles suivront avec les paliers de leur zone.
- **Mini-boss à phases** (moteur fait, contenu à venir) : un monstre unique (`boss` : ni famille ni
  élite, niveau fixe, comme le Souverain Cendré) ou n'importe quel monstre peut avoir des **phases**.
  Quand ses PV tombent sous un seuil (en % de ses PV max), après n'importe quels dégâts, la phase se
  déclenche une seule fois : il annonce la couleur (message de combat et texte flottant), apprend de
  nouveaux sorts et s'applique des effets (bonus, malus, bouclier…). Plusieurs seuils franchis d'un
  coup : toutes les phases, dans l'ordre. **Jamais de soin** à un changement de phase, ni en effet
  ni en sort appris (refusé à la validation des données) : un monstre qui remonte ses PV à chaque
  seuil peut enfermer le joueur dans un combat sans fin. Les phases d'un mini-boss suivent son
  thème et ont des **profils différents** (agressif, défensif, mobilité, contrôle), dans un ordre
  propre à chacun, et peuvent lui coûter quelque chose (rage qui baisse ses résistances, roues
  cassées qui le clouent sur place). Un mini-boss **réapparaît en 60 s au plus** pendant l'alpha,
  pour qu'on puisse retester ses mécaniques. Les quatre mini-boss de l'alpha sont conçus
  (`docs/design/chantier3_brouillon/`) et viendront avec le contenu.
- **Menace des monstres lents** : la *menace* d'un monstre est le nombre de cases qu'il peut
  toucher dans son tour (ses PM plus la plus grande portée de ses sorts). Un monstre à **moins de
  3 PM** a une menace d'**au moins 7**, par la portée de ses sorts à distance (pas en allongeant ses
  attaques de mêlée) : sinon un personnage qui frappe de loin et recule le bat sans être touché.
  Aujourd'hui : arbres (Racines, Pluie de cendres et Ronces à 6 cases, 1 PM), morilles (Spores et
  Nuage de rancune à 5 cases, 2 PM), épouvantails, trolls et Grondin.
- **Éléments des dégâts** : chaque zone a un élément dominant, qui suit son thème, l'Acier venant
  en second : Brumerive la Tempête (≈ 50 %), Crasse-Roc la Flamme (≈ 45 %), Sylvebrume le Givre
  (≈ 40 %, Acier ≈ 35 %), Hautepierre mélangée (aucun élément au-dessus de 35 %), la Cendre la
  Flamme. Aucun élément ne dépasse 60 % d'une zone ni 35 % du jeu entier, pour qu'une résistance
  unique ne suffise jamais. Relevé et alertes dans `docs/CATALOGUE.md` (`tools/catalogue.py`).
  Quand un sort change d'élément, le monstre reçoit la caractéristique de ce nouvel élément à la
  valeur de l'ancienne (mêmes dégâts) et résiste mieux à son nouvel élément.
- **Groupes :** de 1 à 8 monstres (3 au plus pendant l'alpha), d'une ou plusieurs espèces, tous visibles
  sur la carte ; composition fixe ou aléatoire dans une liste par zone.
- **Variantes Corrompues :** versions plus fortes avec un butin spécifique (cendres, fragments). On
  les croise sur les cartes cendrées de Hautepierre, et dans chaque zone de départ une fois son
  mini-boss vaincu : la cendre gagne son repaire (loup cendreux chez Krasbouk, grouilleur de braise
  chez le Balourd, arbre calciné chez la Mère-Toile ; groupes `apres_boss` des cartes).
- **Archimonstres** (long terme) : variantes rares nommées, au butin amélioré.

### 8.2 Butin (drop)

- Chaque monstre a une **table de butin** : objet, taux de base, quantité, et des brumes.
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
- **Monnaie : la brume** (« 1 brume », « 40 brumes » ; nom provisoire choisi pour l'alpha). Nom court
  qui se lit bien à côté d'un nombre, tiré du lieu de frappe : les premières pièces ont été frappées à
  Brumerive, dans des ateliers noyés de brouillard, et Sylvebrume revendique (sans preuve) l'invention
  du procédé. Les gobelins de Crasse-Roc les appellent « les pâles » et les acceptent quand même.
  Dans le code et les sauvegardes, la clé reste `ecus` (`Inventory.ecus`, `"ecus"` des monstres, des
  quêtes et des événements) : la renommer casserait les sauvegardes et les données existantes.

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
- **Objets parodiques :** quelques objets ridicules mais vraiment utiles dans un cas précis. Premier
  à faire : la **Cape en peau d'ananas** (« la peau d'ananas résiste à une bille d'acier chauffée à
  1000 °C » : l'armure anti-dragon), faible en caractéristiques mais avec une **forte résistance
  Flamme**, pour la Cendre, le Souverain Cendré et les variantes corrompues. Il faut pour cela des
  **bonus de résistance par élément** sur l'équipement (les objets ne donnent aujourd'hui que des
  caractéristiques). *(À faire, TODO.)*
- **Long terme :** forgemagie (modification des jets avec des runes), objets légendaires à effets
  uniques liés au butin rare et aux quêtes, objets liés au compte.

### 9.3 Panoplies de l'alpha test

Pour l'alpha test, huit panoplies de départ qui permettent de tester chaque façon de jouer. Chaque panoplie a
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

**Panoplies élémentaires de niveau 15 et 30** : une panoplie par élément à chaque niveau, de
**7 pièces** (les six emplacements et l'**arme**), vendues aussi par les marchands pendant l'alpha et
tombées sur des monstres de leur niveau (coiffe, cape, amulette et arme sur une famille, le reste sur
une autre). Pièces peu communes au niveau 15, rares au niveau 30 ; l'**amulette donne 1 PA** aux deux
niveaux, les **bottes de niveau 30 donnent 1 PM**.

| Élément | Niveau 15 | Niveau 30 | Arme |
|---|---|---|---|
| Acier (Force) | Enclume Rancunière | Seigneur des Enclumes | Marteau |
| Flamme (Intelligence) | Pyromane Récidiviste | Dragon Retraité | Sceptre |
| Givre (Chance) | Yéti Frileux | Hiver Qui Vient | Bâton |
| Tempête (Agilité) | Coup de Vent | Tornade Mal Lunée | Arc |
| Sacré (Force et Intelligence) | Bedeau Zélé | Inquisiteur Bienveillant | Masse |
| Impie (Agilité et Chance) | Chat Noir | Porte-Malheur | Dague |

- **Bonus de niveau 15** (caractéristique, moitié dans chacune pour le Sacré et l'Impie) : 2 pièces :
  +15 ; 3 : +30, +3 Dommages ; 4 : +45, +6 Dommages, +30 Vitalité ; 5 : +60, +9 Dommages,
  +45 Vitalité, +1 Portée ; 6 : +80, +12 Dommages, +60 Vitalité, +1 PM, +1 Portée ; 7 : +100,
  +15 Dommages, +80 Vitalité, **+1 PA, +1 PM, +1 Portée**.
- **Bonus de niveau 30** : 2 pièces : +30 ; 3 : +60, +5 Dommages ; 4 : +90, +10 Dommages,
  +60 Vitalité ; 5 : +120, +15 Dommages, +90 Vitalité, +1 Portée ; 6 : +160, +20 Dommages,
  +120 Vitalité, +1 PA, +1 PM, +1 Portée ; 7 : +200, +25 Dommages, +160 Vitalité, **+2 PA, +1 PM,
  +2 Portée**.
- Panoplie complète : +2 PA au niveau 15 (amulette comprise), +3 PA et +2 PM au niveau 30 (amulette
  et bottes comprises). Chiffres à équilibrer après les retours de test. Production :
  `docs/design/panoplies_15_30/produire.py` (objets, panoplies, icônes, butin).

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
  Le lot Métiers du chantier 3 ajoute trois bois (if, hêtre, malorme) et trois minerais (étain,
  argent, obsidienne), aux niveaux 8, 15 et 22, et 13 recettes (23 en tout) qui mêlent ressources et
  butins de plusieurs zones, pour pousser à voyager.
- **Chaque zone de départ a les deux métiers de récolte** (demande de l'auteur) : bois et minerais
  des niveaux 1, 3 et 8 partout, en gardant le caractère de la zone (Sylvebrume boisée, Crasse-Roc
  minière, Brumerive mixte) : les ressources de bas niveau vers l'entrée de la zone, celles de
  niveau 8 vers ses cartes les plus difficiles (`docs/design/chantier3_brouillon/src/recolte_zones.py`).
- **Ressources rares** (en place, demande de l'auteur) : chaque ressource de récolte a une version
  rare (cœur de frêne, fer météorique, étain chantant, argent lunaire…), obtenue avec 1 % de chance
  par récolte, **un** exemplaire **à la place** de la récolte normale. Elles ne se vendent pas et
  servent à des **recettes améliorées** plus puissantes (rares ou épiques, pas en boutique non plus) :
  anneau vert-de-gris, arc du Cœur de frêne, masse météorique, amulette chantante, épée lunaire,
  sceptre de malorme. Les futurs métiers de récolte (agriculteur, herboriste, pêcheur, § 10.3) suivront la même règle.

### 10.3 Les onze métiers (conception, demande de l'auteur)

Conception validée en grandes lignes par l'auteur le 23/10/2026 (liste des métiers, terrains
instanciés, montures tirées des monstres du jeu) ; **tous les chiffres sont des pistes à
équilibrer**, rien n'est codé au-delà du prototype (§ 10.1, § 10.2). Cette liste remplace l'ancienne
piste (Tailleur, Cordonnier, Alchimiste, Cuisinier) : le **Costumier** reprend le Tailleur et le
Cordonnier, le **Maître des potions** l'Alchimiste, le **Boulanger** le Cuisinier.

| Famille | Métier | Produit ou récolte | Principaux clients |
|---|---|---|---|
| Récolte | **Mineur** | minerais, pierres, sel gemme, gemmes | Forgeron, Joaillier, Boulanger (sel) |
| Récolte | **Bûcheron** | bois, écorces, sève | Forgeron, Costumier, Maître des potions |
| Récolte | **Agriculteur** | céréales, fibres (lin, chanvre, coton) | Boulanger, Costumier, Éleveur (fourrage) |
| Récolte | **Herboriste** | plantes, champignons, fleurs | Maître des potions, Éleveur (soins) |
| Récolte | **Pêcheur** | poissons, coquillages, perles | Boulanger, Maître des potions, Joaillier (perles), Éleveur |
| Artisanat | **Forgeron** | armes, pièces d'armure (heaumes, plastrons, ceinturons, solerets), boucliers, outils, lingots | tous |
| Artisanat | **Costumier** | coiffes, capes, ceintures, bottes en tissu et cuir ; licols et selles | tous, Éleveur |
| Artisanat | **Joaillier** | anneaux, amulettes ; taille des gemmes | tous |
| Artisanat | **Boulanger** | pains (regain de vie, bonus de caractéristiques) | tous |
| Artisanat | **Maître des potions** | potions (bonus de combat, utilitaires) | tous |
| Élevage | **Éleveur de montures** | montures apprivoisées, engrais (fumier) | tous, métiers de récolte |

#### Règles communes

- Niveaux 1 à 100, XP propre à chaque métier (formule du prototype, § 10.2), passif humain +10 %.
- **Nombre de métiers** : tous connus pendant les tests ; à terme, **3 métiers de récolte et
  3 métiers d'artisanat** au plus par personnage (l'éleveur compte comme artisanat), pour que les
  joueurs échangent entre eux en multijoueur. Une *potion d'oubli de métier* (Maître des potions)
  permet d'en changer, en perdant son niveau.
- **Paliers de ressources** : une nouvelle ressource aux niveaux **1, 3, 8, 15, 22** (déjà en place
  pour le bois et le minerai), puis **30, 40, 55, 70, 85, 100**, soit 11 ressources par métier de
  récolte. Les cinq premières se trouvent dans les zones de départ, les suivantes dans les régions à
  venir (§ 3.5). Chaque ressource a sa **version rare** (1 %, à la place de la récolte, § 10.2).
- **Outils** : chaque métier de récolte a son outil (pioche, hache, faucille, serpe, canne à pêche),
  porté dans un emplacement d'outil hors combat (pas une arme). Fabriqués par le **Forgeron** (le
  manche par le bûcheron, la lame par le mineur) : un outil meilleur raccourcit la récolte et ajoute
  une chance de ressource en plus. Sans outil, on récolte quand même, plus lentement (pas de mur
  pour un nouveau joueur).
- **Produits intermédiaires** fabriqués à l'atelier du métier qui les utilise, sans recette à
  apprendre : **lingots** (Forgeron, 5 minerais → 1 lingot, à partir du palier 30), **farines**
  (Boulanger, 5 grains → 1 farine), **toiles et fils** (Costumier, 5 fibres → 1 toile), **gemmes
  taillées** (Joaillier). Ils allègent l'inventaire et les recettes de haut niveau.
- **Ateliers** : chaque capitale de camp a les six ateliers, avec un maître PNJ par métier, dans le
  ton de son camp (forge humaine qui se croit légendaire, chaudron gobelin aux normes syndicales,
  atelier elfe « collection Automne Éternel »). Les villes secondaires n'en ont que deux ou trois.
- **Recettes classiques** données par le jeu jusqu'au niveau 100, puis **Chef-d'œuvre** (§ 10.4) au
  niveau 100 pour tous les métiers d'artisanat, Éleveur compris (sous une forme propre, plus bas).
- **Récolte sauvage et terrains instanciés** : les ressources de la carte restent la source normale
  (et la seule pour les semences de haut niveau) ; les terrains achetés (plus bas) servent à
  produire régulièrement ce qu'on a déjà trouvé.

#### Mineur

Minerais sur les rochers de la carte, comme aujourd'hui. Paliers : **cuivre** (1), **fer** (3),
**étain** (8), **argent** (15), **obsidienne** (22), puis **charbon de pierre** (30), **or de
pacotille** (40, « brille, mais pas trop »), **cristal de brume** (55), **adamantoc** (70, gobelin),
**pierre de Cendre** (85, Marches Cendrées), **fer-étoile** (100).

- **Sous-produits** : le **sel gemme** (5 % sur les rochers de bas niveau, pour le Boulanger) et les
  **gemmes brutes** à partir de l'argent (5 % par récolte, en plus) : une gemme par élément
  (hématite Acier, rubis Flamme, saphir Givre, émeraude Tempête, opale Sacré, onyx Impie), pour le
  Joaillier.
- **Mine instanciée** : voir plus bas ; on n'y plante rien.

#### Bûcheron

Arbres de la carte, comme aujourd'hui. Paliers : **frêne** (1), **chêne** (3), **if** (8), **hêtre**
(15), **malorme** (22), puis **saule pleureur** (30, il pleure vraiment, la sève sert au Maître des
potions), **érable** (40), **séquoia** (55), **barbe-souche** (70, un vieil arbre qui parle très,
très lentement et proteste à la coupe), **ébène de Cendre** (85), **bois de l'Aube** (100).

- **Sous-produits** : **écorce** et **sève** (10 %, Maître des potions, Costumier pour les teintures),
  **glands et pousses** (semences, voir terrains).

#### Agriculteur (nouveau)

Champs sauvages sur les cartes de campagne (Brumerive surtout, Hautepierre), épis à faucher.
Chaque céréale correspond à une ligne des pains du Boulanger (§ 10.4) ; les fibres vont au Costumier.

| Niveau | Ressource | Usage principal |
|---|---|---|
| 1 | Blé | regain de vie (Boulanger) |
| 3 | Lin | toile (Costumier) |
| 8 | Avoine | Force (Boulanger) |
| 15 | Seigle | durée en combats (Boulanger) |
| 22 | Chanvre | cordes, licols (Costumier, Éleveur) |
| 30 | Maïs flamboyant | Intelligence (Boulanger) |
| 40 | Riz des marais | Chance (Boulanger) |
| 55 | Sarrasin | Agilité (Boulanger) |
| 70 | Coton de brume | soie légère (Costumier) |
| 85 | Orge noire | Sagesse (Boulanger) |
| 100 | Épeautre de l'Aube | Vitalité (Boulanger) |

Le **fourrage** (paille, 1 par récolte de céréale) nourrit les montures herbivores de l'Éleveur.

#### Herboriste (nouveau)

Plantes à cueillir dans les sous-bois, au bord de l'eau et dans les ruines (Sylvebrume surtout).
Chaque plante correspond à une ligne des potions du Maître des potions.

| Niveau | Ressource | Usage principal (potions) |
|---|---|---|
| 1 | Ortie | soin (regain en combat ou hors combat, voir Maître des potions) |
| 3 | Trèfle | Chance |
| 8 | Menthe poivrée | Agilité |
| 15 | Sauge | Sagesse |
| 22 | Piment des forges | Intelligence |
| 30 | Mandragore | Force (elle hurle à la cueillette : petit étourdissement comique, sans effet) |
| 40 | Herbe-à-pipe | Initiative (ou son contraire) |
| 55 | Pavot de brume | Prospection |
| 70 | Feuille-de-roy | Soins (« elle s'en croit une ») |
| 85 | Edelweiss de Cendre | résistances |
| 100 | Fleur de l'Aube | effets majeurs (dommages, critiques) |

Les **champignons** ne sont pas récoltés : ils sont lâchés par les morilles (monstres), ce qui garde
le lien avec le combat.

#### Pêcheur (nouveau)

Coins de pêche sur les cases d'eau (remous animés), la pêche se fait depuis une case de bord.
Paliers : **goujon** (1), **perche** (3), **truite** (8), **brochet** (15), **anguille des
galeries** (22, Crasse-Roc), puis **silure** (30), **poisson-lanterne** (40, eaux profondes),
**poisson précieux** (55, « on l'arrache à une créature des cavernes qui le réclame »), **kraken de
bocal** (70), **léviathan nain** (85), **saumon de l'Aube** (100).

- **Sous-produits** : **coquillages** et **perles** (2 %, Joaillier), **alevins** (petits poissons
  « trop petits, relâchés » : semences de l'étang instancié).
- **Usages** : tourtes et pâtés du Boulanger (regain de vie plus fort), huiles du Maître des potions
  (résistances), nourriture des montures carnivores (loups).

#### Terrains instanciés (idée de l'auteur)

Les joueurs **achètent des cartes instanciées** (personnelles, comme la maison du joueur, § 6) pour
y planter puis récolter les ressources des métiers de récolte. Une carte par métier :

| Terrain | Métier | On y met | Contenu de départ |
|---|---|---|---|
| **Champ** | Agriculteur | graines | 12 sillons |
| **Jardin** | Herboriste | boutures | 12 plates-bandes |
| **Bosquet** | Bûcheron | glands et pousses | 6 emplacements d'arbre |
| **Étang** | Pêcheur | alevins | 4 coins de pêche |
| **Mine** | Mineur | rien : les filons repoussent seuls | 1 galerie (6 filons) |

- **Achat** en brumes, auprès d'un PNJ du cadastre dans chaque capitale (parodie : un notaire
  humain, le Syndicat gobelin des Terrassiers, le Conservatoire elfique des Sylves qui vous loue
  « la permission d'exister près d'un arbre »). Accès par une porte ou un panneau, comme la maison.
  Pistes de prix : **2 000 brumes** le terrain, puis des **agrandissements** (5 000, 15 000,
  40 000) qui ajoutent des emplacements ; pas de loyer (ne pas punir l'absence).
- **Planter** : on pose une semence sur un emplacement libre ; elle **pousse en temps réel**, même
  déconnecté (piste : 10 min pour une ressource de niveau 1, jusqu'à 4 h au niveau 100), puis on la
  récolte comme une ressource de la carte (même XP, même chance de rare). Il faut le **niveau de
  métier** de la ressource pour la planter.
- **Rendement** : une plante cultivée donne le **double** d'une récolte sauvage, et rend sa semence
  avec **80 %** de chance : le stock de semences s'use lentement, il faut revenir en récolter dans
  la nature. Les **semences** viennent de la récolte sauvage (10 % par récolte) ; celles des cinq
  premiers paliers s'achètent aussi chez les marchands.
- **Engrais** (lien avec l'Éleveur) : le fumier des montures, posé sur un emplacement, raccourcit la
  pousse de moitié ou ajoute une récolte. Aucun arrosage ni corvée : on plante, on revient, on récolte.
- **Mine** : on n'y plante rien (demande de l'auteur) : on achète la mine, et ses filons repoussent
  seuls, plus lentement que sur la carte. Chaque **galerie** achetée en plus (agrandissement) ouvre
  un étage plus profond, aux minerais d'une tranche de paliers (étage 1 : cuivre à étain ; étage 2 :
  argent à charbon ; etc.), à condition d'avoir le niveau de mineur. Le minerai de chaque filon est
  tiré dans la tranche de l'étage à chaque repousse. Piste parodique : de temps en temps, un **rat
  des galeries squatte** la mine (petit combat facultatif, il emporte un filon tant qu'il est là).
- **Multijoueur** : un terrain appartient à un personnage (question ouverte : au compte) ; on peut
  y **inviter** des amis, qui récoltent pour le propriétaire (la ressource va dans son coffre ou au
  récoltant, à trancher). Les terrains sont hors du havre de paix des actes I et II (§ 13.2) : ils
  ne vident pas les ressources communes, ce qui est le but.
- **Solo** : même fonctionnement ; la carte instanciée suit le modèle de la maison du joueur.

#### Forgeron

**Armes** (toutes : épées, haches, marteaux, bâtons, arcs, sceptres…) et **armures**. Une pièce
d'armure est un équipement comme les autres (décision de l'auteur, 23/10/2026) : elle prend un
emplacement existant (§ 9.1), il n'y a pas d'emplacement de plus. Le partage avec le Costumier se
fait par la **matière** : le métal au Forgeron, le tissu et le cuir au Costumier.

| Emplacement | Forgeron (métal) | Costumier (tissu, cuir) |
|---|---|---|
| Coiffe | heaume, casque, bassinet | chapeau, bonnet, capuche |
| Cape | plastron, cotte de mailles, cuirasse | cape, manteau, pèlerine |
| Ceinture | ceinturon riveté, tassette | ceinture, écharpe, cordelière |
| Bottes | solerets, grèves | bottes, sandales, chaussons |
| Main gauche (long terme) | bouclier, écu, targe | — |

- Les deux métiers couvrent donc les mêmes emplacements, avec des recettes et des noms différents.
  Piste de différence de profil (à équilibrer) : le métal penche vers la Vitalité et les
  résistances, le tissu et le cuir vers les caractéristiques, la Sagesse et l'Initiative ; aucune
  règle n'interdit une ligne à l'un ou à l'autre.
- Une pièce d'armure se voit sur le personnage comme la pièce qu'elle remplace (heaume à la place
  du chapeau, plastron à la place de la cape, § 9.2).

- En plus : **outils de récolte** (tous les métiers) et **lingots**.
- **Bascule depuis le prototype** : le Forgeron fait aujourd'hui aussi anneaux, amulettes,
  ceintures et bottes (23 recettes). Quand le Joaillier et le Costumier arrivent, les bijoux passent
  au Joaillier et les pièces de cuir ou de corde au Costumier (objets et ingrédients inchangés) ; le
  Forgeron garde ses armes et les pièces de métal (ceinturon riveté…) ; l'XP déjà gagnée reste au
  Forgeron. Rien ne change pendant l'alpha test 1.
- **Chef-d'œuvre** : armes, pièces d'armure de métal et boucliers (question ouverte de § 10.4 sur les armes, qui sont des
  sorts : piste, les dégâts de base suivent le niveau, le score sert aux lignes de statistiques).

#### Costumier (nouveau)

Tous les équipements qui ne sont **ni armes, ni armures, ni bijoux** : **coiffes, capes, ceintures,
bottes** en tissu et en cuir (les versions de métal sont au Forgeron, tableau plus haut), et plus tard les emplacements de cosmétique. Matières : **toiles** (lin, coton, chanvre),
**cuirs et fourrures** (peaux de monstres), **soie** (fil de tisseuse de brume), **plumes**
(corbacs), **teintures** (écorces, sève, fleurs).

- Fabrique aussi les **licols** (apprivoisement) et les **selles** (montures) de l'Éleveur.
- **Apparences** (piste) : coiffe et cape se voient sur le personnage (§ 9.2) ; le Costumier peut
  coudre une apparence (sans statistiques) à poser par-dessus une pièce. Le ton : « haute couture
  héroïque », où les elfes jugent tout le monde.
- **Chef-d'œuvre** : coiffes, capes, ceintures, bottes (en tissu et en cuir).

#### Joaillier (nouveau)

**Anneaux** et **amulettes**. Matières : métaux précieux (cuivre, étain, argent, or de pacotille,
cristal de brume), **gemmes** (mineur, taillées à l'atelier), **perles** et coquillages (pêcheur),
crocs et yeux de monstres.

- La **gemme** porte l'élément : un anneau de Flamme demande un rubis taillé, ce qui suit la règle
  des ressources élémentaires de § 10.4.
- **Sertissage** (piste, après le Chef-d'œuvre) : ajouter une gemme sur un bijou déjà fait pour une
  petite ligne en plus, une fois par bijou.
- Les **Reliques** (bagues légendaires, § 3.3) ne se fabriquent pas.
- **Chef-d'œuvre** : anneaux et amulettes.

#### Boulanger (nouveau)

**Pains** : surtout du **regain de vie** et des **bonus de caractéristiques temporaires** (§ 10.4).
Ingrédients : **farines** (céréales de l'agriculteur, une par caractéristique), **poissons** pour
les tourtes, et des ingrédients obligatoires : **eau** (puits gratuit en ville), **sel** (sel gemme du
mineur ou marchand), **levure** (marchand, ou sève fermentée du bûcheron).

- **Hors combat seulement**, depuis la barre d'objets (§ 14.3). Le regain rend des PV tout de suite
  (le pain de base : 20 PV ; les tourtes : beaucoup plus).
- Un **bonus de pain** dure un **nombre de combats** (de 1 à 5) ; un seul **repas** actif à la
  fois : manger un autre pain fortifiant remplace le précédent.
- Recettes classiques jusqu'au niveau 100, puis **Chef-d'œuvre** (exemple du pain fortifiant majeur,
  § 10.4).

#### Maître des potions (nouveau)

**Potions** : ce que le pain ne fait pas. Ingrédients : **plantes** de l'herboriste (une par effet,
tableau plus haut), **fioles** (achetées aux marchands : un des puits à brumes du jeu), **sève**,
**huiles de poisson**, ressources de monstres (champignons des morilles, venin, ailes).

- **Bonus de combat** pour un nombre de combats : Sagesse, Prospection, Initiative, Dommages, Soins,
  critiques, **résistances par élément** (huiles de poisson, edelweiss). Un seul **élixir** actif à
  la fois, cumulable avec un repas du Boulanger : deux familles de bonus, pas plus.
- **Utilitaires** : *potion de rappel* (retour à la dernière Pierre de Passage touchée), *potion
  d'oubli* (réinitialise les caractéristiques : le restat « par un objet » de § 4.5), *potion
  d'oubli de métier*, *potion de sagesse du métier* (+XP de métier pendant une heure).
- **En combat** : pas pendant l'alpha (piste : une potion de soin par combat, 2 PA, depuis la barre
  de sorts) ; à décider quand les potions existeront.
- **Chef-d'œuvre** : même principe que le Boulanger (score par effet, niveau = score / 5).

#### Éleveur de montures (nouveau)

On **apprivoise des monstres du jeu** qui peuvent porter un cavalier, et on les élève. Ils vont dans
l'emplacement **Familier / monture** (§ 9.1).

**Espèces** (pas tous les monstres : seulement ceux qui peuvent porter, demande de l'auteur) :

| Monstre (famille) | Zone | Niveau d'éleveur | Bonus de la monture (piste) |
|---|---|---|---|
| Loup des collines | Brumerive | 1 | Agilité, Force |
| Cerf enchanté | Sylvebrume | 1 | Chance, Sagesse |
| Grouilleur (mille-pattes) | Crasse-Roc | 1 | Vitalité, Intelligence (« on n'arrête pas de lui acheter des bottes ») |
| Loup cendreux | Brumerive, Hautepierre | 20 | Agilité, résistance Flamme |
| Grand cerf de la Lisière | Sylvebrume (élite) | 30 | Chance, PM hors combat |
| Olifant de guerre | Hautepierre | 60 | Vitalité, Force (énorme, lent à monter) |
| Gargouille | Hautepierre | 80 | Intelligence, Initiative (piste : vol décoratif) |

Exclus : les créatures qui parlent ou se croient des personnes (trolls, gobelins, épouvantails,
arbres vivants, morilles), et celles trop petites (rats, vampipistrelles, corbacs). Chaque camp a
une monture de départ, dans sa zone.

- **Apprivoisement** : il faut un **licol** (Costumier, ou l'atelier de l'éleveur) dans
  l'inventaire. En combat contre un monstre de l'espèce, quand il est le **dernier ennemi** et sous
  **25 % de ses PV**, le sort *Apprivoiser* (3 PA, au contact) le capture avec une chance qui monte
  avec le niveau d'éleveur et baisse avec le niveau du monstre ; en cas de succès, le monstre quitte
  le combat (victoire, sans butin de ce monstre) et devient une **monture sauvage** envoyée à
  l'enclos. Les élites et mini-boss ne s'apprivoisent pas (sauf le grand cerf, plus haut).
- **Enclos** : un **terrain instancié** de plus (même achat que les terrains), avec des **objets
  d'élevage** fabriqués par les métiers : mangeoire (céréales ou poissons selon l'espèce), abreuvoir,
  brosse, et un épouvantail « motivant » qui fait progresser la docilité. Une monture sauvage doit
  être **dressée** à l'enclos (temps réel, comme les plantes) avant d'être montée.
- **Monture** : elle a un **niveau** (1 à 100, XP prise sur une part de l'XP de combat du cavalier,
  au choix de 0 à 50 %) qui fait monter ses bonus, et de l'**énergie** qui baisse à chaque combat et
  se recharge à la mangeoire : à 0, elle ne donne plus de bonus (elle boude). Hors combat, monté, on
  se déplace plus vite (course × 1,8 au lieu de × 1,4) ; en combat, le cavalier reste un seul
  combattant (la monture ne joue pas).
- **Robes** : chaque monture a une couleur tirée parmi celles de l'espèce (recoloration des dessins
  `.svgt`, sans dessin de plus) ; certaines robes sont rares.
- **Reproduction** : deux montures adultes de la même espèce (mâle et femelle) à l'enclos donnent
  un petit, qui hérite de la robe et d'une partie des bonus de ses parents ; nombre de portées
  limité par monture. C'est la principale source d'XP du métier avec l'apprivoisement et le dressage.
- **Fumier** : les montures à l'enclos en produisent ; c'est l'**engrais** des terrains (lien avec
  les métiers de récolte, et ressort parodique assumé).
- **Chef-d'œuvre de l'éleveur** (niveau 100) : une **lignée de maître** : pour un petit à naître,
  l'éleveur choisit ses bonus dans un budget de score (barème de § 10.4), au lieu du tirage ; le
  petit porte le nom de l'élevage (« de l'élevage de [pseudo] »).

#### Ordre de production proposé

1. **Agriculteur et Boulanger** : les plus simples, ils remplissent la barre d'objets hors combat.
2. **Herboriste et Maître des potions** : potions de bonus et utilitaires (rappel, oubli).
3. **Costumier et Joaillier** : reprennent les recettes de bijoux, ceintures et bottes du Forgeron.
4. **Pêcheur** : coins de pêche, tourtes et huiles.
5. **Terrains instanciés** : champ, jardin, bosquet, étang, mine (modèle de la maison du joueur).
6. **Éleveur et montures** : apprivoisement, enclos, emplacement monture.
7. **Chef-d'œuvre** pour tous les métiers d'artisanat (§ 10.4).

**Questions ouvertes** : terrains par personnage ou par
compte ; potions utilisables en combat ; noms des maîtres d'atelier ; part des recettes du Forgeron
qui passe au Costumier et au Joaillier ; montures échangeables entre joueurs (multi).

### 10.4 Objets personnalisés (long terme, idée de l'auteur)

Les artisans de haut niveau (métier d'artisanat proche du niveau 100, le maximum actuel) peuvent
**créer leurs propres objets** : ils choisissent l'emplacement, le niveau et les lignes de
statistiques, dans des limites fixées par un **score**, et le coût de fabrication découle des
statistiques choisies. Rien n'est codé ; toutes les valeurs ci-dessous sont des **pistes à équilibrer**.

**Nom de la compétence** (à choisir) : **Chef-d'œuvre** (l'objet créé est « un chef-d'œuvre de
Krogma » ; proposition retenue par défaut dans ce document), **Pièce de maître**, ou **Façonnage
libre**. Côté parodie, l'objet peut porter la signature de son artisan (« fait main par… »).

**Tous les métiers d'artisanat** (demande de l'auteur) : chaque métier de craft, une fois au niveau
maximum, débloque cette compétence pour ses propres emplacements (forgeron pour les armes, les
pièces d'armure de métal et les boucliers, costumier pour les coiffes, capes, ceintures et bottes
en tissu et en cuir, joaillier pour les
anneaux et amulettes, éleveur pour les montures, § 10.3). Aucun métier de craft ne doit en être privé.

**Métiers de consommables** (boulanger, maître des potions) : **même principe que pour les
équipements**. Chaque métier a sa liste d'effets possibles, chacun avec son **coût en score**, une
**limite de lignes** et une **limite de score par ligne** (et par objet). Les ingrédients suivent les
lignes choisies, plus des **ingrédients obligatoires** propres au métier. Exemple du boulanger, tous
les chiffres étant provisoires (*à équilibrer*, pas des règles fixées) :

- surtout du **regain de vie** et des **bonus de caractéristiques temporaires** ;
- regain : +1 Vitalité (point de vie rendu) coûte **1 point** de score et demande 1 blé ou 1 farine ;
- bonus temporaire : **5 points** de score par point de Force, multipliés par le nombre de combats
  de durée, puis par un coefficient de durée qui ne joue qu'après le premier combat (×1 pour 1
  combat, puis +0,25 par combat en plus : ×1,25, ×1,5, ×1,75, ×2 pour 5 combats) ;
- **niveau du consommable** = score / 5 : 500 points font un objet de niveau 100 à son plein
  potentiel, 200 points un objet de niveau 40 ;
- ingrédients : la Force demande de l'**avoine** (1 avoine par 2 points, ou 1 farine d'avoine par
  10 points), le regain de vie du **blé**, la durée du **seigle** (5 seigles ou 1 farine de seigle
  par combat de durée) ;
- ingrédients obligatoires de toute recette : levure, eau, sel…

*Exemple, le pain fortifiant majeur* : +50 Force pendant 5 combats. Score 50 × 5 = 250, × 2 (durée)
= **500**, donc niveau 100. Recette : 5 farines d'avoine, 5 farines de seigle, 1 litre d'eau,
1 levure boulangère.

Le maître des potions suit la même logique avec ses potions (effets, durées et plantes : § 10.3).

**Score des statistiques.** Chaque point de statistique vaut un nombre de points de score, d'après sa
rareté et sa puissance (§ 4.4) :

| Statistique | Points par unité *(à équilibrer)* |
|---|---|
| Force, Intelligence, Chance, Agilité | 1 |
| Vitalité | 0,25 |
| Sagesse | 3 |
| Initiative | 0,1 |
| Prospection | 3 |
| Dommages | 3 |
| Soins | 3 |
| Coups critiques % | 10 |
| Résistance % (un élément) | 6 |
| Invocations max | 30 |
| Portée | 50 |
| PM | 90 |
| PA | 100 |

**Limites** (valeurs au niveau 100, à équilibrer) :

- **par ligne** : une ligne de statistique ne dépasse pas **100 points** de score ;
- **par objet** : la somme des lignes ne dépasse pas **1 000 points** ;
- **par statistique** : plafond propre à certaines statistiques, en plus du score (par exemple
  +1 PA, +1 PM, +1 Portée au plus par objet, quel que soit le budget restant) ;
- **nombre de lignes** maximal par objet.

**Barème par niveau d'objet.** L'artisan choisit le niveau de l'objet (au plus son niveau de métier) ;
plus le niveau est bas, plus les limites sont basses, pour qu'un objet personnalisé de niveau 50 reste
comparable aux objets de niveau 50 du jeu. Piste de départ :

| Niveau de l'objet | Score max par objet | Score max par ligne | Lignes max |
|---|---|---|---|
| 20 | 200 | 20 | 3 |
| 50 | 500 | 50 | 4 |
| 80 | 800 | 80 | 5 |
| 100 | 1 000 | 100 | 6 |

(formule possible : objet = 10 × niveau, ligne = niveau, lignes = 2 + niveau / 20 arrondi, 6 au plus ;
PA et PM réservés aux objets de haut niveau, par exemple à partir du niveau 80.)

**Coût de fabrication lié aux statistiques.** Les ingrédients dépendent des lignes choisies :

- **Statistiques élémentaires** : chaque caractéristique demande des ressources de **son élément**,
  lâchées par les monstres de cet élément (§ 8.1, un élément dominant par zone) : Force → Acier,
  Intelligence → Flamme, Chance → Givre, Agilité → Tempête ; une résistance demande des ressources de
  l'élément résisté (moitié-moitié pour le Sacré et l'Impie). Exemple : +100 Force et
  +100 Intelligence demandent des ressources d'Acier et de Flamme, à raison de **1 ressource par
  10 points** (« 1 roche en fusion par 10 points d'Intelligence »), soit 10 d'Acier et 10 de Flamme.
- **Statistiques sans élément** (Vitalité, Sagesse, Initiative, Prospection, Dommages, Soins,
  critiques, PA, PM, Portée) : ressources neutres ou rares, par exemple les ressources rares de
  récolte (§ 10.2) ou des butins de mini-boss pour PA, PM et Portée.
- **Base de l'objet** : quelques ressources fixes selon l'emplacement (bois et métal pour une arme,
  cuir ou soie pour une cape…), pour que les métiers de récolte restent utiles.
- La quantité suit le **score** de la ligne (plutôt que la valeur brute), pour que 1 PA ne coûte pas
  autant qu'1 point d'Agilité.

**Patrons.** Un artisan qui sait créer des objets personnalisés garde une **liste de patrons** : un
patron enregistre l'emplacement, le niveau, les lignes de statistiques et la recette d'ingrédients
qui en découle. Les patrons s'ajoutent aux **recettes classiques** données par le jeu (§ 10.2) ; on
les refabrique sans tout redéfinir.

**Nom de l'objet.** Le joueur ne tape pas un nom libre : le jeu lui propose des **listes de mots**
tirées de l'objet, qu'il combine.

- **Type d'objet** (selon l'emplacement) : pour une coiffe, « Coiffe », « Chapeau », « Bonnet »,
  « Couvre-chef »… ;
- **une liste par statistique ajoutée** : Intelligence → « flamboyant », « torride », « chaleureux »,
  « enflammé »… ; PA → « rapide », « agile », « fulgurant »… ;
- **une liste par ressource du craft** : si la recette demande des morilles, « de la Morille »,
  « grincheux »… (les mots suivent le nom et le ton parodique de la ressource).

Exemple : une coiffe d'Intelligence et +1 PA fabriquée avec des morilles peut s'appeler « Bonnet
fulgurant de la Morille » ou « Chapeau torride grincheux ». Les mots s'accordent en genre avec le
type choisi. Le nom est enregistré dans le patron.

**Signature de l'artisan.** Un objet personnalisé est **toujours signé** : à la place du texte
d'ambiance habituel, sa fiche affiche « Créé par [pseudo de l'artisan] ».

**Copie, maîtrise et économie** (multijoueur) : un chef-d'œuvre peut être recopié par un autre
artisan, c'est accepté ; le nom déposé, la maîtrise par patron et les garde-fous économiques sont
décrits au § 13.6.

**Questions ouvertes :**

- les objets personnalisés ont-ils des **jets** (§ 9.2) ou des valeurs fixes ? piste : valeurs
  fixes, puisque l'artisan a choisi ;
- les **armes** (qui sont des sorts : PA, portée, dégâts) entrent-elles dans le système, ou seulement
  les pièces d'équipement ?
- objets **liés** au personnage ou échangeables (en multijoueur : commandes entre joueurs, patrons
  vendus ou partagés) ;
- rapport avec la **forgemagie** (§ 9.2, long terme) : un objet personnalisé peut-il être forgemagé ?
- ~~quels métiers d'artisanat y ont droit~~ : tous (Forgeron, Costumier, Joaillier, Boulanger,
  Maître des potions, Éleveur sous forme de lignée de maître, § 10.3), au niveau 100 de métier.

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
- **État** : le système est fait (conception validée : `docs/design/chantier6_quetes.md`) avec
  8 types d'objectifs (parler, vaincre, vaincre un boss, récolter, fabriquer, apporter, équiper,
  aller), le **butin de quête** (un objet qui ne tombe que pendant la quête qui le demande), les
  objets de quête, l'XP comptée en « combats de référence » (× `Character.XP_RATE`), les marques
  `!` / `?`, la proposition (Accepter / Plus tard), le journal (Q) et le suivi dans la bande gauche.
  Les objectifs « parler » et « apporter » se remplissent en dernier (on rend la quête). Contenu
  produit : les 3 tutoriels, l'acte I et l'acte II des trois camps, et le début de l'acte III
  (le Conseil des Peuples Libres, puis Grondin à la Brèche ; la Chevalière Sans-Rouille disparaît :
  fin de l'histoire de l'alpha), les 15 quêtes secondaires des zones de départ et 3 à
  Hautepierre (ouvertes à tous les camps) : **tout le contenu de quêtes de l'alpha 1 est produit**.

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
  de ces quêtes (expérience, objets, brumes) et bascule tout de suite dans les instances communes. Le
  choix est définitif.

### 13.3 Fonctionnalités multi

| Domaine | Fonctionnalités |
|---|---|
| **Social** | Chat (local, groupe, commerce, recrutement, privé), liste d'amis, ignorés, émotes |
| **Groupe** | Jusqu'à 8 joueurs, partage d'XP, suivi du chef, marqueurs de quête partagés |
| **Combat** | Rejoindre le combat d'un ami, combats de groupe, mode spectateur, verrouillage du combat |
| **Quêtes** | Objectifs partagés en groupe (« vaincre X » compte pour tous), événements de monde |
| **Métiers** | Échange sécurisé entre joueurs, artisanat assisté, commandes, hôtel des ventes, Trésor des villes (§ 13.6) |
| **Guildes** | Création, rangs, banque, métier de guilde (§ 13.7) |
| **Camps** | Opposition en PvE uniquement. **À décider avant la Phase 5 :** deux joueurs de camps opposés peuvent-ils grouper avant l'acte III ? (Pistes : interdit jusqu'à l'acte III ; ou autorisé, mais quêtes de camp non partagées.) |
| **PvP** | Hors périmètre initial ; duels éventuels plus tard |

### 13.4 Comptes et persistance

- Compte avec plusieurs personnages ; sauvegarde serveur (base de données).
- Le mode solo utilise **le même format de sauvegarde** (fichier local), ce qui permet d'envisager la
  migration d'un personnage solo vers le serveur (décidé : pas de migration, § 16.5).
- Plan technique (serveur, protocole, comptes, base, hébergement, jalons) : § 16.5.

### 13.5 Sécurité et modération

- Validation serveur de toutes les actions, limitation de débit, journal des transactions
  (anti-duplication), signalement de joueurs, outils de modération de base.

### 13.6 Économie des artisans et guildes (pistes, discussion avec l'auteur)

Pistes validées dans leur principe le 23/10/2026 (avis de design sur les chefs-d'œuvre) ; rien
n'est codé, tous les chiffres sont *à équilibrer*.

**Copie des chefs-d'œuvre (§ 10.4).** Les statistiques d'un objet sont visibles et la recette en
découle : un autre artisan au niveau maximum peut refaire un chef-d'œuvre. **C'est accepté** : on
ne cache pas les statistiques et on n'interdit pas les objets identiques (contournable avec un point
de différence). On protège plutôt ce qui fait la valeur du créateur :

- **le nom et la signature sont une propriété** : le premier qui enregistre un patron dépose son
  nom ; un copieur fait le même objet sous un autre nom. Version parodique : un **Bureau des brevets
  de Hautepierre** tenu par un gobelin syndiqué, exclusivité de quelques jours puis domaine public ;
- **maîtrise par patron** (comme la spécialisation d'Albion) : chaque fabrication d'un patron fait
  monter sa maîtrise, qui donne une petite marge (quelques pour cent de budget ou un ingrédient de
  moins). L'artisan établi fait un peu mieux ou un peu moins cher que le copieur ;
- plus tard, **vente de copies de patron** à N fabrications (comme les plans d'EVE).

Garde-fous : un chef-d'œuvre a **le même budget** que les objets du jeu de même niveau (plus souple,
jamais plus fort) ; il faut un **puits d'équipement** en plus des consommables (brisage qui rend
une partie des ressources, ou usure légère réparée par un artisan) pour que la demande se renouvelle.

**Artisans et profits.** Rien n'empêche un artisan au maximum de farmer lui-même et de revendre
cher : c'est sa récompense. Les limites viennent de la concurrence des autres artisans, du temps
(les ressources de plusieurs éléments et zones l'obligent à en acheter, ce qui fait vivre les
joueurs sans métier), du plafond de prix (le butin offre une alternative à puissance égale) et des
taxes. L'artisan gagne de l'argent sans en créer : la surveillance économique porte sur les brumes
créées par les monstres et les PNJ, pas sur la richesse des joueurs.

**Monter ses métiers soi-même.** Possible, mais plus lent qu'acheter : ressources croisées entre
éléments et zones, niveau 100 long, marge de maîtrise du spécialiste. Une limite du nombre de
métiers à haut niveau reste en réserve si le marché ne prend pas. En solo (alphas), le joueur monte
ses métiers lui-même ; ces leviers ne valent qu'en multijoueur.

**Taxes et Trésor des villes.** La taxe de vente **détruit** les brumes (puits), mais le **montant
réellement perçu** est compté dans le **Trésor** de la ville du marché (Brumerive, Crasse-Roc,
Sylvebrume, Hautepierre). À des seuils, le Trésor débloque des **chantiers** (pont, boutique, décor
de fête) ou une semaine de **bonus** (récolte, XP de métier, Pierres de Passage moins chères), jamais
des brumes redistribuées. Précédents : la reconstruction d'Ishgard (FFXIV), les projets de Guild
Wars 2. Parodie : le Trésor est géré par le syndicat des gobelins, qui fait grève quand les recettes
baissent et organise un banquet quand elles montent. Aucun service de base ne dépend d'un chantier.

Pour éviter qu'une seule ville rafle tout :

1. **bonus utiles sur place seulement** (le bonus d'une ville vaut pour sa zone) ;
2. **marchés à spécialités** (Flamme à Crasse-Roc, Givre et Acier à Sylvebrume, Tempête à
   Brumerive), comme les hôtels de vente par catégorie de Dofus Rétro ;
3. en réserve : **taxe progressive selon l'affluence**, **seuils croissants** et Trésor qui baisse
   un peu chaque semaine, **événement de relance** pour la ville la plus pauvre.

Hautepierre peut rester la capitale commerçante, avec les bonus de sa zone.

### 13.7 Métiers de guilde (pistes)

Une guilde choisit **un seul métier de guilde** à la fois : elle prend une identité, et les guildes
ont besoin les unes des autres. Un métier de guilde n'a sa place que s'il **vend un service aux
autres guildes**. Ses bonus sont de **prestige et de confort**, pas de puissance de combat (les
avantages de guilde de World of Warcraft, retirés en 2014, poussaient tout le monde vers les grosses
guildes). Métiers retenus par l'auteur :

- **Commerçant** : ouvre un **comptoir** dans une **galerie marchande instanciée** (comme les
  maisons de Dofus) : un bâtiment en ville, une porte, et à la porte le choix du commerce (enseignes,
  recherche, favoris). Coût : **loyer fixe** par semaine plus une **taxe réduite** (rentable seulement
  au-delà d'un certain volume ; loyer impayé, comptoir fermé), versés au Trésor de la ville. L'avantage
  du comptoir n'est pas le prix mais la vitrine, les commandes sur mesure de chefs-d'œuvre et la
  réputation. Un étal partagé à loyer bas reste accessible aux petites guildes. Enseigne composée
  comme les noms d'objets (« Aux Haches Grincheuses »), vendeur PNJ gobelin syndiqué qui réclame ses
  pauses.
  - **Registre commun des commerces** (borne en ville puis interface) : on cherche un produit, le
    registre dit qui le vend, à quel prix et où ; bouton « s'y rendre » qui pose une épingle (comme
    les liens de quête) ; pas d'achat à distance. Les consommables du quotidien restent à l'hôtel de
    vente public.
  - **Avis des clients** : seul un **achat vérifié** permet de noter, une fois par boutique et par
    période ; **pas de texte libre** mais une note et des phrases toutes faites (« Prix de gobelin »,
    « Le vendeur m'a regardé de haut ») ; la guilde répond (phrases toutes faites) mais ne masque
    rien. À côté, des mesures automatiques : clients différents, part de clients qui reviennent.
    Contre le sabotage : le poids d'une note suit le montant de l'achat ; membres et guildes rivales
    de la même catégorie, comptes récents ou de bas niveau comptent peu ; médiane et répartition
    affichées, notes anciennes moins lourdes ; vagues suspectes mises de côté par le serveur.
- **Raid** : progresse par accomplissements en donjon (donjons terminés, puis exploits : premier du
  serveur, sans mort, en temps limité, à peu de joueurs). Bonus : titres, trophées de boss dans la
  maison de guilde, classement, accès direct aux entrées de donjon, réparations moins chères ; un
  éventuel bonus de combat reste petit, plafonné et limité aux donjons. Les butins de boss servent
  aux lignes PA, PM et Portée des chefs-d'œuvre : **contrats** de livraison avec les guildes
  commerçantes. Le passage de donjon peut être proposé comme service dans le registre des commerces.
  Parodie : une « Compagnie des Héros Autoproclamés » aux trophées « légèrement exagérés ».
- **Académie** : parrainage des nouveaux joueurs, bonus quand un filleul progresse ou termine un
  donjon (lien avec le mode mentor, § 13.2). Diplômes remis par des elfes snobs.
- **Exploitants** : terrains instanciés communs (champs, jardins, mines du § 10.3), rendement accru,
  contrats de livraison de ressources. « Coopérative agricole », réunion de bureau obligatoire avant
  chaque récolte.

**Coffre et cotisation de guilde** (décision de l'auteur, 23/10/2026) : une **cotisation
automatique en brumes**, un pourcentage des brumes gagnées par chaque membre, fixé par la guilde
(plafonné), plutôt qu'une cotisation manuelle (personne ne court après les retardataires ; même
principe que les taxes de guilde d'Albion et d'EVE ou le don d'XP de Dofus). Le coffre a des
**limites de retrait par rang et par jour** et un **journal** visible de tous les membres, contre le
vol par un officier. Usages selon le métier de guilde : loyer du comptoir (commerçant), réparations
et rééquipement après les donjons (raid), kits de départ des filleuls (académie), semences et
engrais des terrains (exploitants). Parodie : le journal est tenu par un gobelin trésorier syndiqué.

**Utilisation de l'argent de guilde** (demande de l'auteur) :

- **Achats de guilde** : le meneur ou les officiers achètent avec l'argent de guilde des
  **consommables** et des **ressources de guilde**, rangés dans le coffre. Ils ne vont pas dans
  l'inventaire personnel des membres, sauf sous condition : les consommables ne se récupèrent que
  **pendant un raid** (ou une sortie de guilde), les ressources que **lors d'un craft** pour la
  guilde, etc. Ce qui n'est pas utilisé revient au coffre ; rien ne se revend.
- **Registre d'utilisation** : le coffre note **qui utilise quoi et quand** (achat, retrait,
  consommation en raid, ressource employée dans un craft), consultable par tous les membres.
- **Frais de guilde** : l'argent de guilde paie la **cotisation du métier de guilde**, le **loyer**
  du comptoir et la **location des terrains d'exploitation** (§ 10.3). Si le coffre ne suffit pas à
  l'échéance, le service est suspendu jusqu'au paiement.

Autres pistes, non retenues pour l'instant : caravaniers (transport entre villes, escortes),
écuries (location de montures), chasseurs de primes (tableau de contrats), cartographes (chasses aux
trésors), bâtisseurs (chantiers du Trésor), taverniers (tournois, festins). On officialisera de
préférence ce que les joueurs feront déjà d'eux-mêmes.
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

- **Mode tactique en combat** (comme dans Dofus) : un bouton du combat bascule vers une vue
  simplifiée de la grille, pour lire le terrain sans le décor : cases à plat bien délimitées,
  obstacles en blocs pleins (ceux qui bloquent la vue distingués de ceux qui ne bloquent que le
  passage, comme l'eau, dessinée en trou), arbres et grands décors masqués, combattants en pions ou silhouettes
  lisibles ; portées, zones et glyphes restent affichées. Le choix est retenu d'un combat à l'autre.
  *Fait* : icône en damier gris de la barre de combat ou touche T, aussi dans les options. Les combattants
  restent dessinés par défaut ; l'option « Pions en mode tactique » les remplace par des pions
  (cercle de la couleur du camp, initiale, PV).
- **Menu pause** (Échap quand aucune fenêtre n'est ouverte) : le jeu s'arrête ; reprendre, options,
  retour au menu principal (sauvegardé, pas pendant un combat), quitter. **Options** (menu principal
  ou pause) : volume, plein écran, taille de la fenêtre, mode tactique, pions en mode tactique ; gardées hors sauvegarde.

- **Bandeau bas** (180 px) **:** historique (futur chat) à gauche, PV dans un cœur rouge qui se vide, PA dans une étoile bleue, PM
  dans une case verte, barre de sorts en combat (icônes avec raccourci et coût en PA), **barre
  d'objets hors combat** (8 emplacements, pour les consommables : seulement montrée tant qu'il n'y
  en a pas ; ni objet ni équipement utilisable en combat), boutons de menus (inventaire,
  caractéristiques, sorts, quêtes, métiers, carte, amis, guilde). Le bandeau reste affiché en
  exploration, avec le bouton « S'asseoir » ; les sorts s'y consultent dans leur fenêtre (S). Raccourcis des
  sorts : 1 à 0, ou la même rangée d'un clavier AZERTY sans Maj (& é " ' ( - è _ ç à).
- **Rythme du combat :** pendant son tour, le joueur n'attend pas la fin des textes flottants et
  des animations de ses sorts (seules ses marches se jouent jusqu'au bout ; les textes au même
  endroit se décalent un peu). Pendant une marche, il peut déjà choisir ses sorts et leurs cibles,
  un déplacement ou la fin du tour : jusqu'à 5 actions gardées, envoyées dans l'ordre à l'arrivée
  et jugées par le noyau à ce moment-là (`MapView._plan`). Les tours des monstres gardent leur
  rythme, pour rester lisibles.
- **Fenêtres :** inventaire avec poupée d'équipement et sac en trois onglets (Équipements,
  Consommables, Ressources, objets de quête compris), fiche de caractéristiques, grimoire de sorts,
  journal de quêtes, fenêtre de métier, carte du monde (touche M).
- **Infobulles d'objets** (sac, coffre, marchand) : l'objet, puis sa comparaison avec l'objet porté
  qu'il remplacerait (le premier emplacement libre, sinon le premier : anneau de gauche), stat par
  stat, gains en vert et pertes en rouge ; plages pour un article de marchand, dégâts moyens pour une
  arme ; « Emplacement libre » si rien n'est porté.
- **Aucune interface sur la zone de jeu**, comme Dofus 2 (`client/world/screen_layout.gd`) : la
  carte tient entre trois bordures, deux **bandes latérales** (150 px au moins) et la barre du bas ;
  pas de bandeau en haut, la carte monte jusqu'au bord de l'écran. Une carte standard (1216 × 544) est plus
  large qu'un écran 16:9 : elle est dessinée à l'échelle qui la fait tenir entre les bandes
  (≈ 81 % en 1280 × 720). Sur un écran plus large, la carte grandit jusqu'à toucher le haut de
  l'écran (≈ 99 % en 1600 × 720), puis le surplus élargit les bandes ; sur un écran plus haut, la
  carte se pose sur la barre et le surplus reste en haut, où débordent arbres et toits ; un
  intérieur garde la même échelle, centré. Les bandes sont opaques et cachent le décor qui déborde de la carte.
- **Bande gauche** : le **nom de la carte** en haut, puis la **minicarte**, carrée (la carte du monde en réduit, 5 × 5 cartes
  autour de la carte actuelle ; un clic dessus ouvre la carte du monde, hors combat), puis le
  **suivi de la quête** : son nom et cinq objectifs à faire au plus (« (+n) » s'il en reste
  d'autres), repliable ; un clic ouvre le journal (hors combat). Les deux restent en combat.
- **Bande droite** : en haut, les **messages** (« À vous de jouer », repère posé, objectif
  rempli…), qui s'effacent seuls ; dessous, en combat, l'**ordre de jeu** en colonne ; hors combat, un résumé du
  personnage (nom, niveau, race et Voie, expérience, brumes).
- **Repères de quête** : dans la proposition d'une quête et le journal, les noms des PNJ, des
  cartes et des zones sont des liens (en bleu). Un clic pose un repère, une épingle sur la carte
  du monde (ouverte sur sa zone) et la minicarte (une flèche au bord s'il est plus loin dans la
  zone) : là où est le PNJ (devant la porte s'il est dans une maison), la carte, ou la Pierre de
  Passage de la zone. Un seul repère à la fois ; le même nom recliqué, le bouton « Retirer le
  repère » de la carte du monde ou l'arrivée sur sa carte le retirent.
- **Objectif de la quête suivie** : une épingle jaune, posée et déplacée toute seule, sur la carte
  du monde et la minicarte, à l'endroit du premier objectif à faire : la carte à atteindre, le PNJ
  à qui parler, la carte la plus proche (dans la zone du joueur) où vit le monstre à vaincre ou
  pousse la ressource, celle des monstres qui lâchent l'objet à apporter tant qu'il en manque, puis
  le PNJ. Rien pour fabriquer ou équiper (`QuestLinks.objective_pin`).
- **En combat :** ordre de jeu dans la bande droite (une ligne par combattant vivant : son
  portrait dans un petit cadre à la couleur de son camp, sa barre de PV en bas, cadre doré pour
  celui qui joue ; son nom, doré à son tour, et ses PV), prévisualisation de portée et de zone, **dégâts et soins
  estimés** au-dessus de chaque combattant que toucherait le sort visé (fourchette sans coup
  critique, à la couleur de l'élément ; soins limités aux PV qui manquent), **clic droit sur un
  sort** pour le lancer sur soi, bouton « fin de tour ». Au survol d'un combattant, ses informations (nom, niveau, PV, PA, PM,
  résistances aux 6 éléments) remplacent la barre de sorts, comme dans Dofus Rétro. Au survol d'un
  **ennemi**, les cases qu'il peut atteindre s'affichent en vert cerné (avec ses PM restants pendant son
  tour, sinon ceux de son prochain tour, `Combat.movement_zone`), comme la portée de déplacement du
  joueur ; elles s'effacent quand la souris le quitte. Quand un sort est choisi, aucune portée de
  déplacement ne s'affiche (ni celle du joueur ni celle d'un ennemi) : seulement la portée du sort.
  **Historique du combat** (canal Combat de l'historique commun, ci-dessous) : début de chaque tour, sorts lancés
  (coups critiques), dégâts, soins et boucliers à la couleur de leur élément, bonus, malus, poisons
  et PM retirés (avec le sort qui les a posés), glyphes et pièges posés ou déclenchés, poussées,
  changements de phase, combattants vaincus. Un piège ennemi reste secret, dans l'historique comme
  sur la carte. Les **chiffres flottants** (dégâts, soins, boucliers, poisons) prennent aussi la
  couleur de leur élément (un choc, sans élément, reste rouge), comme les **glyphes** au sol
  (celle de leur premier effet chiffré ; sans élément, la couleur du camp). Au **survol d'une glyphe** (des deux camps) ou d'un piège allié : nom du sort, qui
  l'a lancé, camp, et pour une glyphe les tours restants.
- **Historique commun** (`client/ui/message_log.gd`), à gauche de la barre du bas, en
  combat comme en exploration (repliable, touche H, état gardé pendant la partie). Chaque message
  est rangé dans un **canal** : *Combat* (rien ne s'efface entre deux combats, un séparateur
  « Nouveau combat » marque le début de chacun) et *Commerce* (achats et ventes : objet, quantité,
  marchand, brumes dépensées ou gagnées). Des onglets filtrent un canal, « Tout » les mêle ; chaque
  canal garde ses 300 dernières lignes, si bien qu'un long combat ne chasse pas le commerce.
  **Prévu pour le chat** (phase multijoueur) : un message a déjà un canal, un auteur facultatif
  (affiché « Auteur : texte ») et une heure ; les canaux *Groupe*, *Équipe* et *Guilde* (puis
  privé) s'ajouteront comme onglets, avec une ligne de saisie sous le texte et une couleur par
  canal ; les messages viendront du serveur (commande « parler » vers un canal, événement relayé
  aux membres), le client ne faisant que les ranger. Il est à la place du chat de Dofus.
- **Boutique** : barre de recherche au-dessus de la liste (achat et vente) ; chaque mot doit
  apparaître dans le nom ou le type de l'objet, sans tenir compte des majuscules ni des accents.
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

- **Trophées de chasse** (décision de l'auteur, 23/10/2026 ; argumentaire dans l'avis de designer
  `avis/bestiaire_bonus_avis_designer.md` des fichiers du projet) : à côté de la connaissance, qui
  ne donne que de l'information, un second compteur par **famille** compte les **monstres vaincus**
  (l'élite compte pour 5). Paliers indicatifs, à ajuster selon la fréquence et la durée des combats
  contre la famille :

  | Palier | Monstres vaincus | Récompense |
  |---|---|---|
  | Bronze | 25 | +10 prospection contre la famille |
  | Argent | 75 | +20 prospection contre la famille (au total), objet d'apparence à l'effigie de la famille |
  | Or | 150, dont l'élite au moins une fois | familier à l'effigie de la famille, titre, trophée |

  - **La prospection contre la famille est la seule récompense de statistique** : elle ne s'applique
    qu'au butin des monstres de cette famille (élite comprise). Pas de dégâts ni de résistances
    contre la famille, pas de bonus global : le bestiaire ne rend personne plus fort en combat et
    n'est jamais obligatoire ; il fait du chasseur un fournisseur des artisans.
  - **Le reste est cosmétique, pour les collectionneurs** : équipements d'apparence (tenue affichée
    par-dessus l'équipement porté, sans statistique) et familiers décoratifs à l'effigie de la
    famille (chapeau d'épouvantail, bonnet en peau de loup, petite morille boudeuse qui suit le
    joueur…), titres parodiques sous le nom (« Ami des champignons, pas réciproque », « Ne passe
    plus sous les ponts »), trophées pour la future maison ou le comptoir de guilde.
  - En groupe, **tous les joueurs du combat** comptent chaque monstre vaincu. Les monstres trop bas
    pour le joueur (plus de 10 niveaux en dessous, à régler) ne comptent pas.
  - Mini-boss : pas de compteur, une entrée « vaincu une fois / dix fois » avec titre et trophée.
    Variantes cendrées : entrée à part. Archimonstres (long terme) : collection à la quête de
    l'Ocre de Dofus.
  - Demande deux systèmes nouveaux : un **emplacement d'apparence** et des **familiers décoratifs**.

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

### 16.5 Plan d'architecture multijoueur

> **Statut : plan validé par l'auteur le 26/10/2026** (les sept décisions de fin de section, et
> un hébergement gratuit pour les tests). Rien n'est encore commencé : M0 puis le prototype M1.

#### Quand

Le plus tôt possible une fois la boucle solo stable, et **avant d'ajouter beaucoup de contenu**
(Phase 3 : six races, cinq classes, donjons) : chaque système écrit pour un seul joueur devra être
repris pour le serveur. Calendrier proposé :

1. **Pendant l'alpha test 1** : jalon M0 (préparer le noyau), sans rien changer pour les testeurs.
2. **Juste après** : jalon M1 (prototype minimal), en parallèle de l'alpha test 2 (progression,
   art et son), qui touche surtout au contenu et à l'affichage.
3. **Phase 3 après M2** (combat de groupe) : le nouveau contenu s'écrit alors directement pour le
   multi. Les phases 3 et 4 du § 17 s'inversent donc en partie.

#### L'existant

Ce qui aide (le § 16.1 a été suivi depuis le début) :

- le noyau `game/core/` ne dépend pas de l'affichage ; le client envoie des commandes
  (`World.execute`) et reçoit des événements, des `Dictionary` décrits dans `Protocol` ;
- la partie entière se sauvegarde en un dictionnaire (`World.save_data`, `World.from_save`,
  `Character.to_dict`), ce qui donne déjà le format stocké côté serveur ;
- le butin est déjà tiré entre plusieurs joueurs (`Loot.roll` : limite par monstre, ordre de
  prospection) ;
- l'historique a déjà des canaux, un auteur et une commande « parler » prévus pour le chat (§ 14.3) ;
- le contenu est en JSON, lu de la même façon par le client et par le serveur ;
- les combats ont leur propre générateur aléatoire (`Combat.rng`) : avec une graine notée, un combat
  se rejoue à l'identique pour déboguer (§ 16.4).

Ce qu'il faut reprendre :

- **`World` ne connaît qu'un joueur** (`World.PLAYER_ID`, un seul `character`). Il mélange l'état
  d'une carte, partagé par tous ceux qui s'y trouvent (groupes de monstres et leur errance,
  réapparitions, mini-boss, ressources épuisées), et l'état d'un personnage (position, quêtes,
  cartes visitées, assis). Il faut les séparer.
- **Le client lit l'état du monde directement** (environ 150 accès à `world.character`,
  `world.map`, `world.combat`, `world.data`…, dont 50 dans `MapView`). En ligne, le client n'a plus
  le `World` : il tient une **copie locale** (instantané à l'entrée d'une carte, puis mise à jour par
  les événements) qui offre les mêmes lectures.
- **Les événements contiennent des `Vector2i`**, que le JSON ne sait pas écrire : il faut une
  conversion dans les deux sens (une case devient `[x, y]`).
- **Le combat n'a qu'un joueur** : placement, fin de combat, récompenses et retour sur la carte sont
  écrits pour `PLAYER_ID`. Le tour n'a pas de limite de temps.
- **La sauvegarde vit dans le navigateur** (`SaveGame`, `user://sauvegarde.json`) : en ligne, elle
  passe sur le serveur, et le client ne garde que ses options.

#### Principe : le serveur fait autorité

Le serveur calcule **tout ce qui a de la valeur** : déplacements, combats, butin, XP, inventaire,
brumes, récoltes, fabrication, quêtes, échanges. Le client n'envoie que des intentions (les
commandes actuelles) et affiche ce qu'on lui répond. Conséquences :

- le champ `entite` d'une commande est rempli par le serveur d'après la session, jamais lu du
  client ;
- les refus actuels du noyau (case hors de portée, pas assez de PA, objet absent…) deviennent la
  défense contre la triche, sans code en plus ;
- le client peut **anticiper** l'affichage d'un déplacement (le trajet est déterministe) mais se
  recale sur la réponse du serveur ;
- aucune donnée sensible n'est envoyée au client : pas de graine aléatoire, pas de butin avant sa
  révélation, pas de pièges invisibles des adversaires.

#### Découpage du noyau

| Aujourd'hui | Demain | Rôle |
|---|---|---|
| `World` (tout) | **`MapInstance`** | Une carte vivante : joueurs présents, groupes, errance, réapparitions, mini-boss, ressources épuisées |
| `World` (partie joueur) | **`PlayerState`** | Un personnage connecté : `Character`, position, quêtes, cartes visitées, assis, combat en cours |
| `Combat` à un joueur | `Combat` à N joueurs | Fighters de plusieurs joueurs, placement par camp, limite de temps par tour |
| `World` | `World` (façade solo) | Garde son interface actuelle : une `MapInstance` + un `PlayerState`, en local, pour que le solo et les tests ne changent pas |

- Les identifiants d'entité deviennent ceux des personnages (`"joueur"` n'existe plus qu'en solo).
- Chaque événement a une **portée** : personnel (inventaire, quêtes, brumes), carte (déplacements,
  groupes qui apparaissent ou partent) ou combat (tous ses participants et spectateurs). Le serveur
  s'en sert pour savoir à qui l'envoyer.
- Le **temps** reste piloté par `update(delta)` : le serveur fait avancer chaque carte occupée
  (une carte vide se met en veille et rattrape son retard quand quelqu'un y entre).

#### Client : une seule interface pour le solo et le multi

Le client parle à une **connexion** (`GameConnection`), avec deux versions :

- **locale** : le `World` tourne dans le même processus, comme aujourd'hui (jeu hors ligne, tests,
  captures, simulation) ;
- **distante** : les commandes partent par le réseau, les événements arrivent du serveur.

Le reste du client (carte, fenêtres, HUD) ne sait pas laquelle il utilise. C'est le plus gros du
travail côté client : remplacer les lectures directes de `world` par la copie locale.

#### Serveur

- **Godot 4.5 sans affichage** (export Linux « serveur dédié »), qui exécute **le même code
  `core/`** que le client : aucune règle n'est écrite deux fois. La piste Node/Colyseus (§ 16.2)
  est écartée pour cette raison.
- Un seul processus pour le prototype : une passerelle (connexions, authentification, sessions),
  un gestionnaire de cartes (une `MapInstance` par carte occupée, plus tard plusieurs instances par
  carte, § 13.2) et les combats. On découpera en plusieurs processus quand un seul ne suffira plus
  (tests de charge, Phase 4).
- **Pas l'API multijoueur de haut niveau de Godot** (RPC, synchronisation de nœuds) : elle est
  pensée pour des scènes partagées et fait confiance aux pairs. On garde nos commandes et
  événements, envoyés comme messages.

#### Protocole réseau

- **WebSocket** (chiffré, `wss://`) pour tous les clients, web et natif : un seul chemin à écrire
  et à tester. La page GitHub Pages est servie en HTTPS, donc le navigateur exige `wss`.
- Messages **JSON** : `{ "v": version, "n": numéro, "type": …, … }`, avec les commandes et
  événements actuels de `Protocol`. Lisible et facile à déboguer ; le volume d'un jeu au tour par
  tour est faible (quelques messages par seconde et par joueur). Jamais `bytes_to_var` sur ce qui
  vient du réseau (il peut créer des objets).
- **Version du protocole** vérifiée à la connexion : un client trop ancien reçoit « mettez le jeu à
  jour » (la version web se met à jour toute seule, le client natif doit être retéléchargé).
- **Reconnexion** : le client renvoie son jeton ; le serveur renvoie un instantané complet (carte,
  personnage, combat en cours) puis reprend le flux d'événements.
- **ENet (UDP)** n'est pas retenu : il n'existe pas dans le navigateur et son avantage (latence des
  jeux d'action) ne sert pas un jeu au tour par tour. **WebRTC** non plus : il sert au pair à pair,
  or le serveur fait autorité. On pourra ajouter ENet au client natif plus tard si un besoin
  apparaît, sans toucher aux messages.

#### Comptes et authentification

- Un **compte** (adresse et mot de passe, puis éventuellement Discord ou Google) porte plusieurs
  personnages ; le **pseudo est unique** sur le serveur (aujourd'hui il est libre).
- Les comptes sont confiés à un service géré (**Supabase Auth** proposé : inscription,
  confirmation par courriel, mot de passe oublié, connexion Discord, offre gratuite suffisante pour
  les tests) plutôt que de les écrire soi-même. Le hachage des mots de passe, les courriels et la
  réinitialisation sont la partie la plus risquée d'un système de comptes.
- Le client obtient un **jeton** du service de comptes et le présente au serveur de jeu à
  l'ouverture du WebSocket ; le serveur vérifie la signature du jeton et en tire l'identifiant du
  compte. Le mot de passe ne passe jamais par le serveur de jeu.
- Limitation de débit des connexions et des commandes (par compte et par adresse), dès le prototype.

#### Sauvegarde côté serveur

- **PostgreSQL** (fourni par Supabase dans la proposition ci-dessus, ou installé à côté du serveur).
- Tables du prototype : `comptes`, `personnages` (compte, pseudo unique, race, voie, niveau, carte,
  et l'état complet en **JSONB**, c'est-à-dire le `Character.to_dict` actuel avec quêtes et
  métiers). On sortira des colonnes ou des tables quand une recherche en aura besoin (hôtel des
  ventes, classements).
- Écriture à la fin de chaque combat, à chaque changement de carte, à la déconnexion et toutes les
  60 s ; les opérations entre joueurs (échange, hôtel des ventes) se feront en **une transaction**
  avec un **journal** (anti-duplication, § 13.5).
- Les états de carte (groupes, réapparitions) ne sont pas sauvegardés : un redémarrage du serveur
  repart des cartes d'origine. Les mini-boss réapparaissent comme aujourd'hui.
- **Pas de migration** des sauvegardes solo du navigateur (on ne peut pas savoir si
  elles ont été modifiées) ; tout le monde repart du niveau 1 en ligne, sauf peut-être pendant les
  tests fermés.

#### Client web et client natif

| | Navigateur (GitHub Pages) | Client natif (Windows, Linux, macOS) |
|---|---|---|
| Installation | Aucune, un lien suffit | Téléchargement (GitHub Releases, puis itch.io) |
| Mises à jour | Automatiques | À retélécharger (l'application itch.io peut le faire) |
| Performances | WebAssembly, pas de fils d'exécution (`thread_support=false`), WebGL 2, chargement plus long | Natif et multithread, Vulkan ou OpenGL, chargement rapide |
| Onglet en arrière-plan | Ralenti par le navigateur | Pas de ralentissement |
| Réseau | WebSocket | WebSocket (ENet possible plus tard) |
| Inconvénients | Plus lent sur les petites machines | Avertissements Windows et macOS sans certificat de signature (payant) |

- Le même projet Godot s'exporte vers les deux ; il suffit d'ajouter des préréglages d'export et
  une étape à la CI. **Proposé** : client natif Windows et Linux en archive sur GitHub Releases dès
  le prototype, macOS plus tard (signature Apple).
- Pour RV, l'écart de performances reste modéré (tour par tour, 2D) : le navigateur reste la porte
  d'entrée principale, le natif sert le confort des joueurs réguliers.

#### Hébergement

- **Client web** : GitHub Pages, comme aujourd'hui.
- **Serveur de jeu** : un petit serveur privé (VPS, de l'ordre de 5 € par mois chez Hetzner ou OVH)
  avec le serveur Godot dans un conteneur Docker et **Caddy** devant (certificat HTTPS automatique,
  donc `wss://`).
- **Gratuit pendant les tests, payant pour la bêta** (choix de l'auteur) : tout est en conteneur
  Docker, donc changer d'hébergeur revient à relancer le même conteneur ailleurs et à recopier la
  base. Pour le prototype (M1) et les premiers tests : le **PC de l'auteur** derrière un **tunnel
  Cloudflare** (gratuit, adresse `wss://` publique, aucun port à ouvrir ; le serveur ne tourne que
  quand le PC est allumé), ou une **machine virtuelle « Always Free » d'Oracle Cloud** (gratuite et
  allumée en permanence, mais inscription parfois refusée et machine reprise si elle reste inactive).
  Les hébergeurs gratuits qui mettent le service en veille (Render, Koyeb…) coupent les WebSocket
  et font attendre le premier joueur : à éviter pour un serveur de jeu. Supabase gratuit met en
  pause un projet inactif depuis une semaine (un clic pour le relancer). Passage sur un VPS payant
  au plus tard pour la bêta fermée (M5). Tarifs et offres à revérifier au moment du choix. Un serveur de jeu garde des connexions ouvertes longtemps : les
  hébergeurs de fonctions sans serveur (Vercel, Netlify…) ne conviennent pas.
- **Base et comptes** : Supabase (offre gratuite pour les tests) ou PostgreSQL sur le même VPS.
- **Deux environnements** : `staging` (test, mis à jour par la CI à chaque push sur `main`) et
  `production` (mis à jour à la main), chacun avec sa base. Sauvegardes automatiques de la base.
- **Jeu hors ligne** : la version solo (connexion locale) reste disponible pour les alpha tests et
  le développement, au moins jusqu'à la bêta.

#### Jalons

| Jalon | Contenu | Critère de sortie |
|---|---|---|
| **M0. Préparer le noyau** (pendant l'alpha 1) | Séparer `MapInstance` et `PlayerState`, `World` en façade solo ; ids de personnages ; portée des événements ; sérialisation JSON des commandes et événements (cases) et version du protocole ; `GameConnection` locale et copie locale de l'état côté client | Le solo marche comme avant, tous les tests passent, et un test fait tourner deux joueurs sur une même `MapInstance` sans réseau |
| **M1. Prototype minimal** | Serveur Godot sans affichage + WebSocket ; compte (inscription, connexion) ; création, chargement et sauvegarde du personnage sur le serveur ; deux joueurs sur la même carte se voient bouger, entrer et sortir ; combats encore en solo mais **calculés par le serveur** (le groupe attaqué disparaît pour les autres) ; client web et natif ; serveur de staging | Deux comptes sur deux machines se voient sur la même carte ; un combat gagné donne XP et butin enregistrés en base ; après déconnexion et reconnexion, on retrouve son personnage là où on l'a laissé |
| **M2. Combat de groupe** | Groupe (invitation, chef) ; rejoindre le combat d'un membre pendant le placement ; placement à plusieurs ; tour de 30 s (§ 7.2) ; déconnexion en combat (tours passés automatiquement, reprise à la reconnexion) ; butin entre joueurs par `Loot.roll` ; partage de l'XP et des brumes ; inventaire consultable mais non modifiable en combat (TODO, Phase 5) ; objectifs de quête « vaincre X » comptés pour le groupe | Trois joueurs finissent un combat ensemble, chacun reçoit sa part, et un joueur déconnecté peut revenir dans le combat |
| **M3. Social** | Chat par canaux (local, groupe, commerce, privé) branché sur l'historique ; amis, ignorés, statut en ligne ; signalement | Deux joueurs sur des cartes différentes discutent en privé et en groupe |
| **M4. Commerce** | Échange sécurisé entre joueurs ; hôtel des ventes ; journal des transactions | Aucun objet ni aucune brume ne peut être dupliqué (tests de déconnexion en plein échange) |
| **M5. Monde partagé** | Plusieurs instances par carte (§ 13.2) et deux mondes selon l'acte ; donjons et maisons instanciés ; guildes et métiers de guilde (§ 13.7) | Bêta fermée possible |
| **M6. Exploitation** | Supervision, sauvegardes, modération, déploiement sans perte, tests de charge | Bêta fermée ouverte |

M0 à M2 forment la Phase 4 (fondations réseau) et M3 à M6 la Phase 5 (multi) du § 17.

#### Décisions (validées par l'auteur le 26/10/2026)

1. **Calendrier** : M0 pendant l'alpha test 1, M1 juste après, Phase 3 après M2.
2. **Serveur** : Godot 4.5 sans affichage, même code `core/` (Node/Colyseus écarté).
3. **Transport** : WebSocket seul, web et natif, messages JSON (pas d'ENet ni de WebRTC pour
   l'instant).
4. **Comptes et base** : Supabase (comptes + PostgreSQL) pour commencer, ou tout héberger soi-même.
5. **Hébergement** : un VPS avec Docker et Caddy, un staging et une production.
6. **Client natif** : Windows et Linux sur GitHub Releases dès le prototype, macOS plus tard.
7. **Sauvegardes solo** : pas de migration vers le serveur ; le solo hors ligne reste jouable
   jusqu'à la bêta.

---

## 17. Périmètre par phase

| Phase | Contenu | Critère de sortie |
|---|---|---|
| **0. Pré-production** | Choix techniques, GDD validé, prototypes papier | Moteur choisi, structure du dépôt en place |
| **1. Prototype** | Une carte, déplacement, un combat 1 contre 1 | Un combat jouable de bout en bout |
| **2. Alpha solo** (court terme) | 3 races (une par camp), 4 classes (avec le Théologue), combat + butin, quêtes simples, 3 métiers, équipement, 3 zones de départ + Hautepierre | **Alpha test 1** (mécaniques) : tout le contenu, l'interface et les quêtes, XP ×3,5, 4 à 5 h pour tout finir. **Alpha test 2** (progression) : leveling réel (~15 h pour les niveaux 1 à 30), sorts par Voie et rang, art et son |
| **3. Solo étendu** (long terme) | 6 races de plus (Nains, Orcs, Semi-hommes, Géants, Squelettes, Lutins ; 9 au total), 5 classes de plus (Paladin, Myrmidon, Ombre, Chronomancien, Démoniste ; 9 au total), Voies, donjons, quêtes complexes, légendaires, scénario complet | Quête des Reliques jouable jusqu'au boss final |
| **4. Fondations réseau** | Serveur autoritaire, comptes, une instance, synchronisation | Deux joueurs se voient et combattent ensemble |
| **5. Multi** | Instances, groupe, amis, chat, échanges, hôtel des ventes, guildes | Bêta fermée |

> Les phases 3 et 4 peuvent se chevaucher : la phase 4 peut démarrer dès que l'alpha solo est stable.
> Plan validé (§ 16.5) : préparer le noyau pendant l'alpha test 1, prototype juste après,
> et Phase 3 après le combat de groupe (jalon M2), pour écrire le nouveau contenu directement pour le multi.
> Détail des tâches : voir [TODO.md](TODO.md).

---

## 18. Risques

| Risque | Impact | Parade |
|---|---|---|
| Périmètre trop large (MMO) | Projet jamais terminé | Phases strictes, chaque phase doit être jouable et livrable |
| Charge graphique (races × équipements × animations) | Élevé | Personnages modulaires, recolorisation, nombre de races limité tant que le pipeline n'est pas rodé |
| Équilibrage des Voies | Sorts ou rangs abusifs | Simulateur de combat ; une classe par personnage (§ 5), pas de combos entre classes |
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
