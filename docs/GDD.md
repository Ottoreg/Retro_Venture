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

Un continent ancien, marqué par une guerre oubliée. Les peuples libres (Humains, Elfes, Nains et
d'autres) vivent séparés, méfiants les uns envers les autres. À l'est, au-delà des montagnes, s'étendent
les **Marches Cendrées**, une terre morte où quelque chose se réveille.

### 3.2 Histoire

- **L'Âge de l'Aube.** Les premiers peuples forgent ensemble sept **Reliques de l'Aube**, chacune
  porteuse d'une part de la lumière originelle.
- **La Première Ombre.** Vorhak, un roi-sorcier, veut s'approprier la lumière des Reliques pour régner
  sur toute chose. Les peuples s'unissent, le vainquent au prix d'une guerre terrible, et l'enferment
  dans sa citadelle de **Nocthrône**.
- **La Dispersion.** Pour qu'aucun peuple ne puisse un jour devenir à son tour un tyran, les Reliques
  sont séparées et cachées aux quatre coins du monde. Leur emplacement se perd dans les légendes.
- **Aujourd'hui.** Les cendres recommencent à tomber sur les terres de l'est. Des créatures corrompues
  descendent des montagnes. Vorhak, devenu le **Souverain Cendré**, s'éveille et envoie ses servants
  traquer les Reliques avant les peuples libres.

### 3.3 Les Reliques de l'Aube (quête principale)

Chaque Relique est liée à une région, un peuple, une chaîne de quêtes et un donjon final. Le joueur les
récupère une à une ; chacune débloque un pouvoir unique (emplacement d'équipement « Relique », voir § 9).

| # | Relique | Région | Peuple gardien | Pouvoir envisagé |
|---|---|---|---|---|
| 1 | La Lanterne d'Aube | Collines de Brumerive | Semi-hommes | Révèle les invisibles, bonus de prospection |
| 2 | La Lame Sans-Rouille | Hautepierre | Humains | Dégâts de Lumière, brise les boucliers |
| 3 | Le Cor des Vents | Plaines d'Orvent | Humains (cavaliers) | Invoque une charge, +PM aux alliés |
| 4 | La Feuille d'Argent | Sylvebrume | Elfes | Soins de zone, résistance à l'Ombre |
| 5 | L'Enclume-Cœur | Forges de Durhal | Nains | Améliore les objets, armure |
| 6 | La Couronne Brisée | Marais Gris | (perdue) | Domine les morts-vivants |
| 7 | L'Étoile Première | Nocthrône | — | Requise pour l'affrontement final |

L'ordre d'obtention est libre pour les Reliques 1 à 5, puis imposé pour 6 et 7.

### 3.4 Antagoniste et factions

- **Le Souverain Cendré (Vorhak)** : boss final. Il n'apparaît que par ses lieutenants jusqu'à la fin.
- **Les Hérauts Cendrés** : lieutenants, un par région, chacun boss d'un donjon de Relique.
- **Les Corrompus** : monstres touchés par les cendres (versions plus fortes des monstres normaux).
- **Le Conseil des Peuples Libres** : faction alliée qui sert de « hub » de quête principale.

### 3.5 Régions (provisoires)

| Région | Ambiance | Niveaux | Phase |
|---|---|---|---|
| Collines de Brumerive | Campagne paisible, village de départ | 1–10 | Court terme |
| Hautepierre et ses environs | Cité humaine fortifiée, plaines, bois | 8–25 | Court terme |
| Sylvebrume | Forêt elfique ancienne et brumeuse | 20–40 | Long terme |
| Forges de Durhal | Montagnes et cités naines souterraines | 25–45 | Long terme |
| Plaines d'Orvent | Steppes de cavaliers | 35–55 | Long terme |
| Marais Gris | Marécages hantés, ruines | 50–70 | Long terme |
| Marches Cendrées / Nocthrône | Terre désolée, citadelle | 70–100 | Long terme |

### 3.6 Ton

**Parodique, mais un minimum sérieux.** Le jeu détourne les codes du *Seigneur des Anneaux*
(la quête interminable, les prophéties, les elfes hautains, les nains bourrus, les semi-hommes qui
pensent surtout à manger, les méchants très méchants), à la manière dont Dofus joue sur les mots et
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

**Les 6 races du jeu** (validées) : 3 jouables dès l'alpha, les 3 autres en Phase 3.

| Race | Bonus | Passif | Sort racial | Phase |
|---|---|---|---|---|
| **Humain** | +Vitalité, +Sagesse | *Polyvalence* : +10 % d'XP de métier | *Ralliement* : +1 PA à un allié pour 1 tour | Alpha |
| **Nain** | +Force, +Vitalité | *Peau de pierre* : +5 % de résistances | *Fureur des profondeurs* : bonus de dégâts quand PV < 50 % | Alpha |
| **Elfe** | +Agilité, +Intelligence | *Œil perçant* : +1 portée sur les sorts à distance | *Pas léger* : téléportation courte | Alpha |
| **Semi-homme** | +Chance, +Agilité | *Petit mais discret* : +prospection, esquive accrue | *Second petit-déjeuner* : se soigne, une fois par combat | Phase 3 |
| **Orc** | +Force, +Vitalité | *Peau épaisse* : réduction des dégâts de mêlée | *Cri de guerre* : bonus de dégâts aux alliés proches | Phase 3 |
| **Gobelin** | +Agilité, +Chance | *Chapardeur* : +monnaie et +prospection | *Coup bas* : dégâts accrus dans le dos de la cible | Phase 3 |

Les bonus, passifs et sorts sont des propositions, à équilibrer.

Orcs et gobelins jouables sont des **renégats** : ils ont déserté les armées du Souverain Cendré
(beaucoup de quêtes et de dialogues à écrire sur la méfiance des autres peuples).

**Noms de peuple** — à la manière des classes de Dofus (jeux de mots, verlan, détournements),
le nom de race générique sert dans les règles et le nom de peuple dans le jeu. Propositions, à choisir :

| Race | Pistes de noms de peuple |
|---|---|
| Humain | **Lambdas** (les « gens normaux »), **Moyen-Terriens**, **Bonhommes** |
| Nain | **Barbichus**, **Naindustriels**, **Trapus** |
| Semi-homme | **Grignotins**, **Bedonnets**, **Deux-Déjeuners** |
| Elfe | **Elfiers** (elfe + fier), **Éternelfes**, **Pointus** |
| Orc | **Grognards**, **Orcharnés** (orc + acharnés), **Bourrus** |
| Gobelin | **Gobe-Tout**, **Chapardins**, **Ricaneurs** |

Plus de races qu'aujourd'hui n'est pas exclu à très long terme, mais la charge graphique (races ×
sexes × équipements × animations) impose de s'en tenir à ces 6.

### 4.3 Classes (Voies)

**Court terme (3 classes) :**

| Classe | Rôle | Éléments principaux | Style |
|---|---|---|---|
| **Guerrier** | Mêlée, encaisse | Acier (Force) | Charges, coups de zone en mêlée, réduction de dégâts |
| **Rôdeur** | Distance, mobilité | Acier / Tempête (Force / Agilité) | Arc, pièges, poussée, gestion de distance |
| **Arcaniste** | Dégâts magiques, contrôle | Flamme / Givre (Intelligence / Chance) | Sorts de zone, ralentissements, un petit soin |

> Option si l'équilibrage en solo l'exige : ajouter un **Druide** (soin/nature) comme 4e classe dès
> l'alpha, ou donner au Rôdeur un soin léger.

**Long terme (environ 10 Voies)** : Guerrier, Rôdeur, Arcaniste, Gardien (tank, bouclier), Druide
(soin, nature), Ménestrel (soutien, bonus/malus), Ombrelame (assassin, invisibilité), Runelier (glyphes,
pièges), Chaman (invocations d'esprits), Paladin de l'Aube (hybride lumière), Dompteur (familiers).

### 4.4 Caractéristiques

| Carac. | Effet |
|---|---|
| **Vitalité** | Points de vie |
| **Sagesse** | Bonus d'XP, résistance au retrait de PA/PM |
| **Force** | Dégâts Acier (physique) |
| **Intelligence** | Dégâts Flamme, puissance des soins |
| **Chance** | Dégâts Givre, prospection |
| **Agilité** | Dégâts Tempête, esquive, initiative |

**Statistiques dérivées :** PV, PA (6 de base), PM (3 de base), Initiative, Portée (+0), Prospection
(100 de base), Coups critiques %, Résistances % par élément, Soins, Invocations max.

### 4.5 Progression

- **Niveau max :** 30 en alpha solo, 100 à terme.
- **Par niveau :** 5 points de caractéristique à répartir, 1 point de sort.
- **Rendement décroissant** sur les caractéristiques au-delà de certains paliers (à la Dofus) pour
  favoriser la diversité.
- **Courbe d'XP** à définir dans un tableur dédié (`docs/design/`), cible : niveau 10 en environ 2 h,
  niveau 30 en environ 15 h pour l'alpha.
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

### 5.3 Implication court terme

Les classes sont **fixes** dans l'alpha (pas d'apprentissage croisé), mais **le modèle de données
prévoit déjà `voie` et `rang` sur chaque sort** pour que le système s'ajoute plus tard sans refonte.

---

## 6. Exploration et monde

- Le monde est découpé en **cartes** (un écran chacune), reliées par leurs bords et par des portes ou
  escaliers. Chaque carte a des coordonnées `[x, y]` sur la carte du monde.
- **Déplacement au clic** sur une grille isométrique ; recherche de chemin (A*).
- Sur une carte : PNJ, groupes de monstres visibles qui errent, ressources récoltables, éléments
  interactifs (portes, coffres, panneaux).
- **Zaaps / points de voyage** (nom à définir : *Pierres de Passage*) à découvrir pour voyager
  rapidement contre de la monnaie.
- **Carte du monde** et **minicarte** consultables.
- **Point de résurrection** choisi au dernier temple / point de voyage activé.
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
- **Coups critiques :** chance de base + bonus ; effet critique défini par sort.
- **Éléments :** Acier, Flamme, Givre, Tempête (+ Lumière et Ombre réservées au légendaire et au
  scénario). Chaque combattant a des résistances en %.
- **Effets :** dégâts, soin, bouclier, bonus/malus (PA, PM, portée, résistances…), poussée/attirance,
  téléportation, invocation, pièges et glyphes, états (*Enraciné*, *Invisible*, *Porté*…).
- **Tacle / fuite** (quitter une case adjacente à un ennemi coûte des PM selon l'Agilité) : prévu,
  activable par réglage pour tester son intérêt.
- **Temps par tour :** illimité en solo (option), 30 s en multi.
- **Mort :** le personnage vaincu retourne à son point de résurrection avec 1 PV ; pas de perte
  d'objets (à rediscuter pour d'éventuelles zones dangereuses à terme).

### 7.3 IA des monstres

Comportements configurables par donnée, et non codés par monstre :

- `melee` : s'approche et frappe la cible la plus proche ou la plus faible.
- `ranged` : garde la distance, se replace hors de la ligne de vue après avoir tiré.
- `support` : soigne ou buffe les alliés en priorité.
- `summoner` : invoque puis se protège.
- `boss` : script dédié par phases (seuils de PV).

L'IA évalue les actions possibles avec un score simple (dégâts attendus, risque) ; pas besoin de
recherche profonde au départ.

---

## 8. Monstres, butin et raretés

### 8.1 Monstres

- Chaque monstre a : niveau (plage), caractéristiques, résistances, sorts, comportement IA, table de
  butin, XP et monnaie de base.
- **Groupes :** de 1 à 8 monstres, composition aléatoire dans une liste par zone.
- **Variantes Corrompues :** versions plus fortes avec un butin spécifique (cendres, fragments).
- **Archimonstres** (long terme) : variantes rares nommées, au butin amélioré.

### 8.2 Butin (drop)

- Chaque monstre a une **table de butin** : objet, taux de base, seuil de prospection éventuel.
- **Chance effective** ≈ `taux_base × (prospection_personnage / 100)`, plafonnée.
- **Seuil de prospection de groupe :** certains butins rares exigent que la somme des prospections du
  groupe dépasse un seuil (incitation à jouer en groupe en multi).
- **Répartition en groupe :** chaque objet tiré est attribué individuellement, pondéré par la
  prospection de chacun.
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
| Relique | — | ✅ (une seule Relique équipée à la fois) |

### 9.2 Règles

- Chaque objet a un **niveau requis**, éventuellement des **conditions** (caractéristique minimale,
  Voie, quête accomplie).
- **Jets aléatoires :** les objets fabriqués ou ramassés ont des statistiques tirées dans une plage
  (par ex. Force 10–15).
- **Armes :** une arme est un « sort » particulier (coût en PA, portée, zone, dégâts par élément).
- **Panoplies :** bonus cumulatif selon le nombre de pièces du même ensemble équipées.
- **Apparence :** coiffe, cape et arme sont visibles sur le personnage.
- **Long terme :** forgemagie (modification des jets avec des runes), objets légendaires à effets
  uniques liés au butin rare et aux quêtes, objets liés au compte.

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
- Contenu cible de l'alpha : un tutoriel, environ 15 quêtes secondaires, un premier chapitre de la quête
  principale (piste de la Lanterne d'Aube).

### 11.2 Long terme : quêtes complexes

- **Embranchements et choix** avec conséquences (drapeaux de monde persistants par personnage).
- **Chaînes multi-régions** (une chaîne par Relique, plus une chaîne finale).
- **Dialogues ramifiés** avec conditions (caractéristiques, réputation, objets).
- **Réputation** auprès des peuples et factions.
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

### 13.3 Fonctionnalités multi

| Domaine | Fonctionnalités |
|---|---|
| **Social** | Chat (local, groupe, commerce, recrutement, privé), liste d'amis, ignorés, émotes |
| **Groupe** | Jusqu'à 8 joueurs, partage d'XP, suivi du chef, marqueurs de quête partagés |
| **Combat** | Rejoindre le combat d'un ami, combats de groupe, mode spectateur, verrouillage du combat |
| **Quêtes** | Objectifs partagés en groupe (« vaincre X » compte pour tous), événements de monde |
| **Métiers** | Échange sécurisé entre joueurs, artisanat assisté, commandes, hôtel des ventes |
| **Guildes** | Création, rangs, banque, niveau de guilde (long terme) |
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
- **Personnages :** sprites animés en 8 directions (4 dessinées + symétrie), animations : repos,
  marche, course, attaque, sort, dégât, mort, récolte.
- **Personnalisation :** couleurs du personnage par zones de teinte ; équipements visibles.
- **Pipeline :** outils à valider (Aseprite, Krita, Inkscape, Spine/DragonBones pour l'animation
  squelettale éventuelle).

### 14.2 Audio

- Musique orchestrale et folk (cordes, flûtes, cornemuses, chœurs pour les moments épiques), un thème
  par région, un thème de combat, un thème de boss.
- Bruitages courts et lisibles pour chaque type de sort et d'impact.

### 14.3 Interface (inspirée de Dofus Rétro)

- **Bandeau bas :** chat à gauche, PV / PA / PM au centre, barre de sorts et d'objets, boutons de
  menus (inventaire, caractéristiques, sorts, quêtes, métiers, carte, amis, guilde).
- **Fenêtres :** inventaire avec poupée d'équipement, fiche de caractéristiques, grimoire de sorts,
  journal de quêtes, fenêtre de métier.
- **En combat :** frise d'initiative, prévisualisation de portée et de zone, dégâts estimés au survol,
  bouton « fin de tour ».
- Interface redimensionnable, lisible en 1280×720 minimum.

---

## 15. Propriété intellectuelle

Le jeu est **inspiré** de Dofus et du Seigneur des Anneaux, il ne doit **rien en reprendre
directement** :

- **Pas de noms, lieux ou personnages de Tolkien** (Hobbit, Mordor, Sauron, Gondor, Anneau unique,
  etc.). Certains termes sont des marques déposées (par ex. « Hobbit », « Ent ») ; les termes
  génériques (Elfe, Nain, Orque) peuvent être utilisés.
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
| **2. Alpha solo** (court terme) | 3 races, 3 classes, combat + butin, quêtes simples, 3 métiers, équipement, 2 régions | Environ 10 à 15 h de jeu solo de niveau 1 à 30 |
| **3. Solo étendu** (long terme) | 3 races de plus (6 au total), ~10 classes, Voies, donjons, quêtes complexes, légendaires, scénario complet | Quête des Reliques jouable jusqu'au boss final |
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
    { "objet": "equipement.cape_du_loup", "taux": 0.01, "seuil_prospection": 200 }
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
