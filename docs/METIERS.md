# Métiers et forge : toutes les variables

Généré par `game/tools/equilibrage.py` à partir du code (`core/jobs/profession.gd`,
`core/items/forge.gd`, `core/character/`) et de `game/data/` : ne pas modifier à la main.
Vue d'ensemble pour l'équilibrage ; les règles sont dans le GDD (§ 10.2 à 10.4), le détail des
objets et des monstres dans [CATALOGUE.md](CATALOGUE.md), les classes dans [CLASSES.md](CLASSES.md).

## Principe

Tous les métiers sont ouverts dès le début, sans niveau : on gagne de la **réputation de métier** à
chaque récolte ou objet forgé, selon la difficulté (palier de ce qu'on fait contre niveau
équivalent de sa réputation), et des **points de maîtrise** à placer dans des compétences qui
améliorent la qualité, sans jamais faire échouer. Métiers codés : Agriculteur (recolte), Bûcheron (recolte), Forgeron (artisanat), Herboriste (recolte), Mineur (recolte), Pêcheur (recolte).

## Réputation et maîtrise

Même modèle pour chaque métier (`core/character/character.gd`) : la réputation est un total cumulé
qui débloque ; chaque tranche de **500** de réputation donne **1 point de maîtrise** à répartir. Monter
au rang *n* coûte *n* points : rang 5 = **15 points** (7500 de réputation) par sort ou compétence.

| Palier | Réputation | Points de maîtrise gagnés | Niveau équivalent |
|---|---|---|---|
| Inconnu | 0 | 0 | 1 |
| Apprenti | 1000 | 2 | 7 |
| Compagnon | 5000 | 10 | 12 |
| Vétéran | 15000 | 30 | 19 |
| Maître | 40000 | 80 | 26 |
| Légende | 100000 | 200 | 36 |

**Niveau équivalent** (`Progression.equivalent_level`, jamais affiché) : la force tirée de la
réputation, l'ancienne courbe d'XP divisée par 3,5 (passer de *n* à *n*+1 coûte (60·*n* + 20·*n*²) / 3,5).
Il sert au **facteur de difficulté** : rapport niveau (monstre ou palier) / niveau équivalent,
interpolé entre les points 0,4 → 0,1, 1 → 0,5, 2 → 1, 3 → 1,5 (rapport → facteur), borné aux extrémités.

| Niveau équivalent | 1 | 2 | 3 | 5 | 8 | 10 | 12 | 15 | 20 | 25 | 30 | 40 | 50 | 60 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Réputation | 0 | 23 | 80 | 343 | 1280 | 2400 | 4023 | 7600 | 17371 | 33143 | 56343 | 130743 | 252000 | 431543 |

### Réputation gagnée

`Profession.reputation_gain` : base × 2 × facteur de difficulté (palier contre niveau équivalent)
× (100 + bonus de race) / 100. Base : le champ `xp` du nœud pour une récolte, **25 × palier de
l'objet** pour une forge. Passif humain : +10 % (« reputation_metier »). Pour une base de 10 :

| Palier \ niveau équivalent | 1 | 3 | 5 | 10 | 15 | 20 |
|---|---|---|---|---|---|---|
| 1 | 10 | 2 | 2 | 2 | 2 | 2 |
| 3 | 30 | 10 | 5 | 2 | 2 | 2 |
| 5 | 30 | 17 | 10 | 3 | 2 | 2 |
| 10 | 30 | 30 | 20 | 10 | 6 | 3 |
| 15 | 30 | 30 | 30 | 15 | 10 | 7 |
| 20 | 30 | 30 | 30 | 20 | 13 | 10 |

## Compétences

| Type | Compétence | Effet | Rang 1 | Rang 2 | Rang 3 | Rang 4 | Rang 5 |
|---|---|---|---|---|---|---|---|
| recolte | Abondance | +x % de chances d'une ressource de plus | 20 | 40 | 60 | 80 | 100 |
| recolte | Œil exercé | +x % de chances de ressource rare | 0,5 | 1 | 1,5 | 2 | 2,5 |
| recolte | Célérité | -x % de temps de récolte (1 s au moins) | 10 | 20 | 30 | 40 | 50 |
| artisanat | Précision | +x % au plancher des jets (75 % du maximum au départ) | 5 | 10 | 15 | 20 | 25 |

- Récolte : quantité tirée dans [min, max], **+1** si le jet d'Abondance passe. Ressource rare :
  chance de base **1 %** + Œil exercé, un seul exemplaire à la place de la récolte.
- Temps de récolte (`Profession.harvest_time`) : (1,5 + 0,25 × palier) s × (1 − Célérité), 1 s au moins ;
  le personnage récolte sans bouger, la ressource lui est réservée.
- Forge : chaque ligne de total *T* se tire entre *T* × (0,75 + Précision) et *T*.

## Métiers de récolte

Colonnes : palier (`niveau` du nœud) ; quantité par récolte ; réputation de base (`xp`) et
réputation gagnée à niveau équivalent = palier (facteur 0,5) ; repousse en secondes ; temps de
récolte sans Célérité / au rang 5 ; ressource rare ; forge (caractéristique et matière de la
ressource récoltée) ; nombre de nœuds par carte.

### Agriculteur

*Fauche les champs sauvages : céréales et fibres.*

| Nœud | Palier | Objet | Qté | Rép. base | Rép. à sa mesure | Repousse (s) | Temps (s) | Rare | Forge | Cartes |
|---|---|---|---|---|---|---|---|---|---|---|
| **Blé** (B) | 1 | Blé | 1–3 | 5 | 5 | 60–120 | 1,75 / 1 | Épi doré | — | hautepierre_0_1 ×6 |
| **Lin** (J) | 3 | Lin | 1–2 | 8 | 8 | 60–120 | 2,25 / 1,12 | Lin des fées | Prospection, tissu | hautepierre_0_1 ×5 |
| **Avoine** (K) | 8 | Avoine | 1–2 | 12 | 12 | 90–150 | 3,5 / 1,75 | Avoine du Champion | — | hautepierre_0_1 ×4, hautepierre_1_4 ×2 |
| **Seigle** (S) | 15 | Seigle | 1–2 | 18 | 18 | 90–150 | 5,25 / 2,62 | Seigle ergoté | — | hautepierre_0_1 ×3, hautepierre_1_4 ×3 |
| **Chanvre** (V) | 22 | Chanvre | 1–2 | 25 | 25 | 120–180 | 7 / 3,5 | Chanvre d'acier | Initiative, tissu | hautepierre_0_1 ×2, hautepierre_1_4 ×3 |

### Bûcheron

*Abat les arbres pour en tirer du bois.*

| Nœud | Palier | Objet | Qté | Rép. base | Rép. à sa mesure | Repousse (s) | Temps (s) | Rare | Forge | Cartes |
|---|---|---|---|---|---|---|---|---|---|---|
| **Frêne** (F) | 1 | Bois de frêne | 1–3 | 5 | 5 | 60–120 | 1,75 / 1 | Cœur de frêne | Agilité, bois | brumerive_0_0 ×5, brumerive_0_1 ×3, brumerive_1_1 ×2, brumerive_1_2 ×2, brumerive_2_0 ×3, crasse_roc_0_0 ×2, crasse_roc_0_1 ×1, crasse_roc_1_0 ×1, hautepierre_2_0 ×2, sylvebrume_0_0 ×4, sylvebrume_0_1 ×3, sylvebrume_1_0 ×5, sylvebrume_2_0 ×2, sylvebrume_2_1 ×1 |
| **Chêne** (C) | 3 | Bois de chêne | 1–2 | 8 | 8 | 60–120 | 2,25 / 1,12 | Chêne des Anciens | Force, bois | brumerive_1_0 ×5, brumerive_1_1 ×2, brumerive_2_0 ×2, brumerive_2_1 ×2, crasse_roc_0_0 ×1, crasse_roc_0_2 ×1, crasse_roc_1_0 ×2, crasse_roc_1_1 ×1, hautepierre_0_2 ×2, hautepierre_2_0 ×2, hautepierre_4_2 ×1, sylvebrume_0_0 ×3, sylvebrume_1_0 ×3, sylvebrume_1_1 ×2, sylvebrume_1_2 ×1, sylvebrume_2_0 ×2 |
| **If** (Y) | 8 | Bois d'if | 1–2 | 12 | 12 | 90–150 | 3,5 / 1,75 | If funèbre | Perception, bois | brumerive_1_2 ×2, brumerive_2_0 ×1, brumerive_2_1 ×2, brumerive_3_1 ×2, crasse_roc_0_2 ×1, crasse_roc_1_1 ×1, crasse_roc_2_1 ×1, hautepierre_0_2 ×2, hautepierre_1_0 ×2, hautepierre_1_3 ×1, hautepierre_2_0 ×1, sylvebrume_1_1 ×2, sylvebrume_1_2 ×2, sylvebrume_2_0 ×1, sylvebrume_2_1 ×2, sylvebrume_2_2 ×1 |
| **Hêtre** (H) | 15 | Bois de hêtre | 1–2 | 18 | 18 | 90–150 | 5,25 / 2,62 | Hêtre centenaire | Force, bois | hautepierre_1_0 ×2, hautepierre_1_1 ×1, hautepierre_1_3 ×2, hautepierre_2_3 ×2, hautepierre_2_4 ×1, hautepierre_3_0 ×1 |
| **Malorme** (L) | 22 | Bois de malorme | 1–2 | 25 | 25 | 120–180 | 7 / 3,5 | Malorme ensorcelée | Intelligence, bois | hautepierre_3_0 ×1, hautepierre_3_1 ×1, hautepierre_3_3 ×1, hautepierre_3_4 ×2, hautepierre_4_1 ×1, hautepierre_4_3 ×2 |

### Herboriste

*Cueille les plantes des prés et des berges.*

| Nœud | Palier | Objet | Qté | Rép. base | Rép. à sa mesure | Repousse (s) | Temps (s) | Rare | Forge | Cartes |
|---|---|---|---|---|---|---|---|---|---|---|
| **Ortie** (O) | 1 | Ortie | 1–3 | 5 | 5 | 60–120 | 1,75 / 1 | Ortie royale | — | hautepierre_0_3 ×6 |
| **Trèfle** (Q) | 3 | Trèfle | 1–2 | 8 | 8 | 60–120 | 2,25 / 1,12 | Trèfle à quatre feuilles | — | hautepierre_0_3 ×5 |
| **Menthe** (P) | 8 | Menthe poivrée | 1–2 | 12 | 12 | 90–150 | 3,5 / 1,75 | Menthe glaciale | — | hautepierre_0_3 ×4 |
| **Sauge** (W) | 15 | Sauge | 1–2 | 18 | 18 | 90–150 | 5,25 / 2,62 | Sauge des Anciens | — | hautepierre_0_3 ×3, hautepierre_1_4 ×3 |
| **Piment** (Z) | 22 | Piment des forges | 1–2 | 25 | 25 | 120–180 | 7 / 3,5 | Piment du Dragon | — | hautepierre_0_3 ×2, hautepierre_1_4 ×3 |

### Mineur

*Extrait le minerai des rochers.*

| Nœud | Palier | Objet | Qté | Rép. base | Rép. à sa mesure | Repousse (s) | Temps (s) | Rare | Forge | Cartes |
|---|---|---|---|---|---|---|---|---|---|---|
| **Cuivre** (U) | 1 | Minerai de cuivre | 1–3 | 5 | 5 | 60–120 | 1,75 / 1 | Cuivre vert-de-gris | Intelligence, minerai | brumerive_0_0 ×3, brumerive_0_1 ×2, brumerive_1_0 ×1, crasse_roc_0_0 ×3, crasse_roc_0_1 ×3, crasse_roc_1_0 ×3, crasse_roc_1_1 ×1, crasse_roc_2_0 ×2, sylvebrume_0_0 ×2, sylvebrume_0_1 ×2, sylvebrume_1_0 ×1 |
| **Fer** (I) | 3 | Minerai de fer | 1–2 | 8 | 8 | 60–120 | 2,25 / 1,12 | Fer météorique | Force, minerai | brumerive_1_0 ×3, brumerive_1_1 ×1, brumerive_2_1 ×2, brumerive_2_2 ×2, brumerive_3_1 ×1, crasse_roc_0_0 ×4, crasse_roc_0_2 ×1, crasse_roc_1_0 ×3, crasse_roc_1_1 ×2, crasse_roc_1_2 ×2, crasse_roc_2_0 ×2, crasse_roc_2_1 ×2, crasse_roc_2_2 ×2, hautepierre_4_2 ×2, sylvebrume_1_0 ×1, sylvebrume_1_1 ×2, sylvebrume_2_0 ×1, sylvebrume_2_1 ×1 |
| **Étain** (T) | 8 | Minerai d'étain | 1–2 | 12 | 12 | 90–150 | 3,5 / 1,75 | Étain chantant | Agilité, minerai | brumerive_1_2 ×2, brumerive_2_1 ×1, brumerive_2_2 ×2, brumerive_3_1 ×1, brumerive_3_2 ×1, crasse_roc_0_2 ×2, crasse_roc_1_1 ×1, crasse_roc_1_2 ×2, crasse_roc_2_1 ×2, crasse_roc_2_2 ×3, hautepierre_0_2 ×1, hautepierre_2_4 ×1, hautepierre_4_2 ×2, sylvebrume_1_2 ×1, sylvebrume_2_1 ×1, sylvebrume_2_2 ×2 |
| **Argent** (G) | 15 | Minerai d'argent | 1–2 | 18 | 18 | 90–150 | 5,25 / 2,62 | Argent lunaire | Perception, minerai | hautepierre_1_1 ×2, hautepierre_1_3 ×1, hautepierre_2_3 ×2, hautepierre_2_4 ×2, hautepierre_3_0 ×1, hautepierre_3_1 ×2, hautepierre_4_1 ×1, hautepierre_4_3 ×1 |
| **Obsidienne** (D) | 22 | Obsidienne | 1–2 | 25 | 25 | 120–180 | 7 / 3,5 | Obsidienne sanglante | Force, minerai | hautepierre_3_1 ×1, hautepierre_3_3 ×2, hautepierre_3_4 ×2, hautepierre_4_1 ×1, hautepierre_4_3 ×1, hautepierre_4_4 ×1 |

### Pêcheur

*Pêche depuis la berge, dans les remous des points d'eau.*

| Nœud | Palier | Objet | Qté | Rép. base | Rép. à sa mesure | Repousse (s) | Temps (s) | Rare | Forge | Cartes |
|---|---|---|---|---|---|---|---|---|---|---|
| **Remous (goujon)** (Â) | 1 | Goujon | 1–3 | 5 | 5 | 60–120 | 1,75 / 1 | Goujon doré | — | brumerive_0_0 ×1, brumerive_0_1 ×2, brumerive_1_0 ×1, brumerive_1_1 ×1, crasse_roc_0_0 ×1, crasse_roc_0_1 ×1, crasse_roc_1_0 ×2, sylvebrume_0_0 ×2, sylvebrume_0_1 ×2, sylvebrume_1_0 ×1, sylvebrume_2_0 ×2 |
| **Remous (perche)** (Ê) | 3 | Perche | 1–2 | 8 | 8 | 60–120 | 2,25 / 1,12 | Perche arc-en-ciel | — | brumerive_0_0 ×1, brumerive_0_1 ×4, brumerive_1_0 ×1, brumerive_1_1 ×1, brumerive_3_1 ×2, crasse_roc_0_0 ×1, crasse_roc_0_1 ×1, crasse_roc_1_0 ×2, crasse_roc_1_2 ×6, crasse_roc_1_3 ×1, hautepierre_0_1 ×1, hautepierre_0_3 ×2, hautepierre_1_4 ×2, sylvebrume_0_0 ×3, sylvebrume_0_1 ×2, sylvebrume_1_0 ×1, sylvebrume_2_0 ×4, sylvebrume_2_1 ×1 |
| **Remous (truite)** (Î) | 8 | Truite | 1–2 | 12 | 12 | 90–150 | 3,5 / 1,75 | Truite saumonée | — | brumerive_3_1 ×4, crasse_roc_1_2 ×8, crasse_roc_1_3 ×2, hautepierre_0_1 ×2, hautepierre_0_2 ×4, hautepierre_0_3 ×4, hautepierre_1_3 ×1, hautepierre_1_4 ×4, hautepierre_2_3 ×2, hautepierre_2_4 ×3, sylvebrume_2_1 ×2 |
| **Remous (brochet)** (Ô) | 15 | Brochet | 1–2 | 18 | 18 | 90–150 | 5,25 / 2,62 | Brochet centenaire | — | cendre_0_0 ×4, hautepierre_0_2 ×4, hautepierre_1_3 ×2, hautepierre_2_3 ×4, hautepierre_2_4 ×3, hautepierre_3_4 ×2 |
| **Remous (anguille des galeries)** (Û) | 22 | Anguille des galeries | 1–2 | 25 | 25 | 120–180 | 7 / 3,5 | Anguille électrique | — | cendre_0_0 ×4, hautepierre_3_4 ×2 |

## Forge personnalisée

`core/items/forge.gd` (GDD § 10.4). À l'enclume de la maison, on choisit un type d'objet et on y
pose **8 ressources différentes au plus** (les cases de la recette, quantité libre), matières obligatoires comprises. Chaque ressource de monstre donne
une caractéristique (plusieurs pour certaines ressources de haut palier, chacune à sa valeur pleine)
selon son palier. Une ligne vaut au plus **20 points de score par palier de forge** (`Forge.line_cap`, palier de
réputation de forgeron : Apprenti 1 à Légende 5, Inconnu compté 1 ; PA 100 points de score, PM 80 points de score, Portée 60 points de score : perdus avant leur palier)
et un objet a au plus **8 lignes**. Le palier de l'objet est la moyenne des paliers (pondérée
par les quantités) ; les jets sont tirés entre 75 % et 100 % du total (plus avec Précision).
PA, PM, Portée : 1 par ressource quel que soit le palier, 1 au plus par objet. La caractéristique d'une ressource
n'est lisible qu'après un premier objet forgé, et seulement si le palier de réputation
de forgeron atteint son palier (`Forge.reveals`). Réputation : 25 × palier de l'objet en base.

### Valeur d'une ressource

`Forge.value` : max(1, arrondi(palier × poids)) (palier 1 à 5), **× 3 pour une ressource rare** ; poids = points de
la caractéristique pour un point de score (le tableau donne la valeur d'une ressource non rare).

| Caractéristique | Poids | Plafond d'une ligne (paliers de forge 1 à 5) | P1 | P2 | P3 | P4 | P5 |
|---|---|---|---|---|---|---|---|
| Force | 1 | 20 / 40 / 60 / 80 / 100 | 1 | 2 | 3 | 4 | 5 |
| Intelligence | 1 | 20 / 40 / 60 / 80 / 100 | 1 | 2 | 3 | 4 | 5 |
| Perception | 1 | 20 / 40 / 60 / 80 / 100 | 1 | 2 | 3 | 4 | 5 |
| Agilité | 1 | 20 / 40 / 60 / 80 / 100 | 1 | 2 | 3 | 4 | 5 |
| Vitalité | 4 | 80 / 160 / 240 / 320 / 400 | 4 | 8 | 12 | 16 | 20 |
| Initiative | 10 | 200 / 400 / 600 / 800 / 1000 | 10 | 20 | 30 | 40 | 50 |
| Prospection | 0,34 | 6 / 13 / 20 / 27 / 34 | 1 | 1 | 1 | 1 | 2 |
| Dommages | 0,34 | 6 / 13 / 20 / 27 / 34 | 1 | 1 | 1 | 1 | 2 |
| % Critique | 0,1 | 2 / 4 / 6 / 8 / 10 | 1 | 1 | 1 | 1 | 1 |
| Soins | 0,34 | 6 / 13 / 20 / 27 / 34 | 1 | 1 | 1 | 1 | 2 |
| % Dégâts dévastateurs | 0,1 | 2 / 4 / 6 / 8 / 10 | 1 | 1 | 1 | 1 | 1 |
| Dégâts dévastateurs | 0,05 | 1 / 2 / 3 / 4 / 5 | 1 | 1 | 1 | 1 | 1 |
| % Dégâts spectraux | 0,1 | 2 / 4 / 6 / 8 / 10 | 1 | 1 | 1 | 1 | 1 |
| Dégâts spectraux | 0,05 | 1 / 2 / 3 / 4 / 5 | 1 | 1 | 1 | 1 | 1 |
| Réduction de dégâts | 0,08 | 1 / 3 / 4 / 6 / 8 | 1 | 1 | 1 | 1 | 1 |
| % Dommages de mêlée | 0,03 | 0 / 1 / 1 / 2 / 3 | 1 | 1 | 1 | 1 | 1 |
| Tacle | 0,1 | 2 / 4 / 6 / 8 / 10 | 1 | 1 | 1 | 1 | 1 |
| Fuite | 0,1 | 2 / 4 / 6 / 8 / 10 | 1 | 1 | 1 | 1 | 1 |
| Retrait PA | 0,2 | 4 / 8 / 12 / 16 / 20 | 1 | 1 | 1 | 1 | 1 |
| Retrait PM | 0,2 | 4 / 8 / 12 / 16 / 20 | 1 | 1 | 1 | 1 | 1 |
| % Épines brutes | 0,05 | 1 / 2 / 3 / 4 / 5 | 1 | 1 | 1 | 1 | 1 |
| Épines brutes | 0,07 | 1 / 2 / 4 / 5 / 7 | 1 | 1 | 1 | 1 | 1 |
| % Épines Acier | 0,06 | 1 / 2 / 3 / 5 / 6 | 1 | 1 | 1 | 1 | 1 |
| % Épines Flamme | 0,06 | 1 / 2 / 3 / 5 / 6 | 1 | 1 | 1 | 1 | 1 |
| % Épines Givre | 0,06 | 1 / 2 / 3 / 5 / 6 | 1 | 1 | 1 | 1 | 1 |
| % Épines Tempête | 0,06 | 1 / 2 / 3 / 5 / 6 | 1 | 1 | 1 | 1 | 1 |
| % Épines Sacré | 0,06 | 1 / 2 / 3 / 5 / 6 | 1 | 1 | 1 | 1 | 1 |
| % Épines Impie | 0,06 | 1 / 2 / 3 / 5 / 6 | 1 | 1 | 1 | 1 | 1 |
| Épines Acier | 0,09 | 1 / 3 / 5 / 7 / 9 | 1 | 1 | 1 | 1 | 1 |
| Épines Flamme | 0,09 | 1 / 3 / 5 / 7 / 9 | 1 | 1 | 1 | 1 | 1 |
| Épines Givre | 0,09 | 1 / 3 / 5 / 7 / 9 | 1 | 1 | 1 | 1 | 1 |
| Épines Tempête | 0,09 | 1 / 3 / 5 / 7 / 9 | 1 | 1 | 1 | 1 | 1 |
| Épines Sacré | 0,09 | 1 / 3 / 5 / 7 / 9 | 1 | 1 | 1 | 1 | 1 |
| Épines Impie | 0,09 | 1 / 3 / 5 / 7 / 9 | 1 | 1 | 1 | 1 | 1 |
| Dommages Acier | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Dommages Flamme | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Dommages Givre | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Dommages Tempête | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Dommages Sacré | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Dommages Impie | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Soins Acier | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Soins Flamme | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Soins Givre | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Soins Tempête | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Soins Sacré | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| Soins Impie | 0,5 | 10 / 20 / 30 / 40 / 50 | 1 | 1 | 2 | 2 | 3 |
| % Résistance Acier | 0,12 | 2 / 5 / 7 / 10 / 12 | 1 | 1 | 1 | 1 | 1 |
| % Résistance Flamme | 0,12 | 2 / 5 / 7 / 10 / 12 | 1 | 1 | 1 | 1 | 1 |
| % Résistance Givre | 0,12 | 2 / 5 / 7 / 10 / 12 | 1 | 1 | 1 | 1 | 1 |
| % Résistance Tempête | 0,12 | 2 / 5 / 7 / 10 / 12 | 1 | 1 | 1 | 1 | 1 |
| % Résistance Sacré | 0,12 | 2 / 5 / 7 / 10 / 12 | 1 | 1 | 1 | 1 | 1 |
| % Résistance Impie | 0,12 | 2 / 5 / 7 / 10 / 12 | 1 | 1 | 1 | 1 | 1 |
| PA | fixe | 0 / 0 / 0 / 0 / 1 | 1 | 1 | 1 | 1 | 1 |
| PM | fixe | 0 / 0 / 0 / 1 / 1 | 1 | 1 | 1 | 1 | 1 |
| Portée | fixe | 0 / 0 / 1 / 1 / 1 | 1 | 1 | 1 | 1 | 1 |

### Types d'objets

| Type | Matières obligatoires | Noms proposés | Attaque (dégâts selon le palier : × (1 + (P − 1) / 20) ; élément de la carac. élémentaire la plus forte, Sacré / Impie si leurs deux caracs sont à 10 % près) |
|---|---|---|---|
| coiffe | tissu | Coiffe, Chapeau, Bonnet, Heaume | — |
| cape | tissu | Cape, Manteau, Pèlerine | — |
| amulette | minerai | Amulette, Médaillon, Pendentif | — |
| anneau | minerai | Anneau, Bague, Chevalière | — |
| ceinture | cuir | Ceinture, Ceinturon | — |
| bottes | cuir | Bottes, Souliers, Sandales | — |
| epee | minerai, bois | Épée, Lame, Glaive | 4 PA, portée 1, 1/tour ; P1 : 7–11 Acier / P5 : 8–13 Acier / P10 : 10–16 Acier / P20 : 14–21 Acier / P30 : 17–27 Acier |
| arc | minerai, bois | Arc, Fronde | 4 PA, portée 2–5, 1/tour ; P1 : 5–8 Tempête / P5 : 6–10 Tempête / P10 : 7–12 Tempête / P20 : 10–16 Tempête / P30 : 12–20 Tempête |
| baton | minerai, bois | Bâton, Canne | 3 PA, portée 1–2, 1/tour ; P1 : 4–7 Givre / P5 : 5–8 Givre / P10 : 6–10 Givre / P20 : 8–14 Givre / P30 : 10–17 Givre |
| dague | minerai, bois | Dague, Couteau, Surin | 3 PA, portée 1, 2/tour ; P1 : 5–8 Impie / P5 : 6–10 Impie / P10 : 7–12 Impie / P20 : 10–16 Impie / P30 : 12–20 Impie |
| masse | minerai, bois | Masse, Marteau, Gourdin | 4 PA, portée 1, 1/tour ; P1 : 7–11 Sacré / P5 : 8–13 Sacré / P10 : 10–16 Sacré / P20 : 14–21 Sacré / P30 : 17–27 Sacré |
| sceptre | minerai, bois | Sceptre, Baguette | 4 PA, portée 2–5, 1/tour ; P1 : 5–8 Flamme / P5 : 6–10 Flamme / P10 : 7–12 Flamme / P20 : 10–16 Flamme / P30 : 12–20 Flamme |

### Ressources

Toutes les ressources qui servent à la forge (caractéristique ou matière), par palier.

| Ressource | Palier | Rareté | Caractéristique | Valeur | Matière | Obtention |
|---|---|---|---|---|---|---|
| **Aile de vampipistrelle** | 1 | commun | Force | +1 | cuir | Vampipistrelle comtesse (élite), palier 2 88 % ×2–4<br>Vampipistrelle, palier 1 55 % ×1–2 |
| **Bec de colombe** | 1 | rare | Dommages Sacré | +3 | — | Colombe baptiste, palier 1 10 % |
| **Bois de cerf enchanté** | 1 | peu_commun | Intelligence | +1 | — | Grand cerf de la Lisière (élite), palier 2 60 % ×1–2<br>Cerf enchanté, palier 1 20 % |
| **Bois de chêne** | 1 | peu_commun | Force | +1 | bois | Bûcheron (Chêne) |
| **Bois de frêne** | 1 | commun | Agilité | +1 | bois | Bûcheron (Frêne) |
| **Caillou de fronde** | 1 | commun | Perception | +1 | — | Frondeur vétéran (élite), palier 2 90 % ×2–5<br>Gobelin frondeur, palier 1 60 % ×1–3 |
| **Carapace de grouilleur** | 1 | commun | Force | +1 | — | Grouilleur ancestral (élite), palier 2 90 % ×2–4<br>Grouilleur, palier 1 50 % ×1–2<br>Grouilleur de braise, palier 3 50 % ×1–2 |
| **Chapeau de morille** | 1 | commun | Intelligence | +1 | — | Vieille Morille rancunière (élite), palier 1 90 % ×2–4<br>Morille grincheuse, palier 1 60 % ×1–2 |
| **Chêne des Anciens** | 1 | rare | % Résistance Acier | +3 | bois | Bûcheron (Chêne, rare) |
| **Croc de loup** | 1 | commun | Perception | +1 | — | Loup alpha (élite), palier 2 90 % ×2–4<br>Loup cendreux, palier 3 50 % ×1–2<br>Loup des collines, palier 1 50 % ×1–2 |
| **Cuivre vert-de-gris** | 1 | rare | Dommages Flamme | +3 | minerai | Mineur (Cuivre, rare) |
| **Cœur de frêne** | 1 | rare | % Résistance Tempête | +3 | bois | Bûcheron (Frêne, rare) |
| **Dent de rat** | 1 | commun | Agilité | +1 | — | Rat-roi (élite), palier 1 70 % ×1–2<br>Rat des galeries, palier 1 30 % |
| **Fer météorique** | 1 | rare | Dommages Acier | +3 | minerai | Mineur (Fer, rare) |
| **Fiche de paie gobeline** | 1 | peu_commun | Vitalité | +4 | — | Frondeur vétéran (élite), palier 2 50 %<br>Gobelin frondeur, palier 1 15 % |
| **Glande acide** | 1 | peu_commun | Vitalité | +4 | — | Grouilleur ancestral (élite), palier 2 50 % ×1–2<br>Grouilleur, palier 1 15 % |
| **Guano luisant** | 1 | peu_commun | % Critique | +1 | — | Vampipistrelle comtesse (élite), palier 2 48 %<br>Vampipistrelle, palier 1 12 % |
| **Lin** | 1 | commun | Prospection | +1 | tissu | Agriculteur (Lin) |
| **Lin des fées** | 1 | rare | Portée | +1 | tissu | Agriculteur (Lin, rare) |
| **Minerai de cuivre** | 1 | commun | Intelligence | +1 | minerai | Mineur (Cuivre) |
| **Minerai de fer** | 1 | peu_commun | Force | +1 | minerai | Mineur (Fer) |
| **Peau de loup** | 1 | commun | Initiative | +10 | cuir | Loup alpha (élite), palier 2 70 % ×1–2<br>Loup des collines, palier 1 30 % |
| **Plume de colombe** | 1 | commun | Force, Intelligence | +1, +1 | — | Colombe baptiste, palier 1 50 % |
| **Poil scintillant** | 1 | commun | Force | +1 | — | Grand cerf de la Lisière (élite), palier 2 90 % ×2–4<br>Cerf enchanté, palier 1 50 % ×1–2 |
| **Queue de rat** | 1 | commun | Prospection | +1 | cuir | Rat-roi (élite), palier 1 90 % ×2–4<br>Rat des galeries, palier 1 60 % ×1–2 |
| **Spores grincheuses** | 1 | peu_commun | Dommages | +1 | — | Vieille Morille rancunière (élite), palier 1 48 %<br>Morille grincheuse, palier 1 12 % |
| **Squelette de colombe** | 1 | legendaire | PM | +1 | — | Colombe baptiste, palier 1 0 % |
| **Sève ancienne** | 1 | rare | Intelligence | +3 | — | Arbre millénaire (élite), palier 2 40 % ×1–2<br>Arbre vivant, palier 1 10 % |
| **Écorce vivante** | 1 | commun | Agilité | +1 | — | Arbre millénaire (élite), palier 2 90 % ×2–5<br>Arbre vivant, palier 1 60 % ×1–3<br>Arbre calciné, palier 3 50 % ×1–2 |
| **Bois d'if** | 2 | peu_commun | Perception | +2 | bois | Bûcheron (If) |
| **Bon de coupe** | 2 | peu_commun | Perception | +2 | — | Abatteur en chef (élite), palier 2 48 %<br>Bûcheron de Brumerive, palier 2 12 % |
| **Citrouille grimaçante** | 2 | peu_commun | Agilité | +2 | — | Grand Épouvantail (élite), palier 2 48 %<br>Épouvantail démotivé, palier 2 12 % |
| **Copeaux de bois** | 2 | commun | Initiative | +20 | — | Abatteur en chef (élite), palier 2 88 % ×2–5<br>Bûcheron de Brumerive, palier 2 55 % ×1–3 |
| **Corne du Balourd** | 2 | rare | PA | +1 | — | Le Balourd des Abîmes (mini-boss), palier 2 100 % |
| **Crochet d'araignée** | 2 | peu_commun | Prospection | +1 | — | Grande Tisseuse (élite), palier 3 48 %<br>Tisseuse de brume, palier 2 12 % |
| **Fil de brume** | 2 | commun | Perception | +2 | — | La Mère-Toile (mini-boss), palier 2 90 % ×2–4<br>Grande Tisseuse (élite), palier 3 88 % ×2–5<br>Tisseuse de brume, palier 2 55 % ×1–3 |
| **Glaive brisé d'ange** | 2 | rare | Dommages Acier | +3 | — | Ange, palier 2 12 % |
| **Gnôle de raid** | 2 | commun | Force | +2 | — | Défonceur de portes (élite), palier 3 88 % ×2–4<br>Gobelin briseur, palier 2 55 % ×1–2 |
| **If funèbre** | 2 | rare | % Résistance Givre | +3 | bois | Bûcheron (If, rare) |
| **Maillon de cotte** | 2 | commun | Intelligence | +2 | — | Sergent de la milice (élite), palier 2 80 % ×2–5<br>Milicien de Hautepierre, palier 2 50 % ×1–3 |
| **Minerai d'étain** | 2 | commun | Agilité | +2 | minerai | Mineur (Étain) |
| **Médaille en chocolat** | 2 | peu_commun | Intelligence | +2 | — | Défonceur de portes (élite), palier 3 48 %<br>Gobelin briseur, palier 2 12 % |
| **Ordre de raid** | 2 | peu_commun | Perception | +2 | — | Krasbouk, Chef de Raid (syndiqué) (mini-boss), palier 2 100 %<br>Pillard émérite (élite), palier 2 48 %<br>Défonceur de portes (élite), palier 3 32 %<br>Gobelin pillard, palier 2 12 %<br>Gobelin briseur, palier 2 8 % |
| **Paille ensorcelée** | 2 | commun | Agilité | +2 | — | Grand Épouvantail (élite), palier 2 90 % ×2–5<br>Épouvantail démotivé, palier 2 60 % ×1–3 |
| **Plume d'ange** | 2 | commun | Force, Intelligence | +2, +2 | — | Ange, palier 2 35 % |
| **Registre des heures** | 2 | peu_commun | Dommages | +1 | — | Le Balourd des Abîmes (mini-boss), palier 2 50 % ×1–2<br>Contremaître en chef (élite), palier 3 48 %<br>Contremaître zélé, palier 2 12 % |
| **Sac de rapine** | 2 | commun | Vitalité | +8 | — | Krasbouk, Chef de Raid (syndiqué) (mini-boss), palier 2 90 % ×2–4<br>Pillard émérite (élite), palier 2 88 % ×2–4<br>Gobelin pillard, palier 2 55 % ×1–2 |
| **Sacré cœur** | 2 | legendaire | Force, Intelligence | +2, +2 | — | Ange, palier 2 0 % |
| **Sifflet de contremaître** | 2 | commun | Agilité | +2 | — | Contremaître en chef (élite), palier 3 80 % ×2–4<br>Contremaître zélé, palier 2 50 % ×1–2 |
| **Soie de la Mère-Toile** | 2 | rare | PM | +1 | — | La Mère-Toile (mini-boss), palier 2 100 % |
| **Écusson de milice** | 2 | peu_commun | Force | +2 | — | Sergent de la milice (élite), palier 2 48 %<br>Milicien de Hautepierre, palier 2 12 % |
| **Étain chantant** | 2 | rare | Dommages Tempête | +3 | minerai | Mineur (Étain, rare) |
| **Aile de Raphaël** | 3 | rare | Soins Sacré | +6 | — | Archange Raphaël (mini-boss), palier 3 10 % |
| **Argent lunaire** | 3 | rare | Dommages Givre | +6 | minerai | Mineur (Argent, rare) |
| **Bois de hêtre** | 3 | peu_commun | Force | +3 | bois | Bûcheron (Hêtre) |
| **Bourse vide** | 3 | commun | Initiative | +30 | — | Chef de bande (élite), palier 3 88 % ×2–4<br>Détrousseur des grands chemins, palier 3 55 % ×1–2 |
| **Carte au trésor douteuse** | 3 | peu_commun | Vitalité | +12 | — | Chef de bande (élite), palier 3 48 %<br>Détrousseur des grands chemins, palier 3 12 % |
| **Cendre tiède** | 3 | commun | Force | +3 | — | Marraine Cendrée (élite), palier 4 88 % ×2–5<br>Cendrillon, palier 4 55 % ×1–3<br>Arbre calciné, palier 3 50 % ×1–2<br>Grouilleur de braise, palier 3 50 % ×1–2<br>Loup cendreux, palier 3 50 % ×1–2 |
| **Cortex féral** | 3 | legendaire | % Dégâts dévastateurs | +1 | — | Lion de Juda, palier 3 0 % |
| **Croc de lion féroce** | 3 | rare | Dommages Sacré | +6 | — | Lion de Juda, palier 3 5 % |
| **Dent de troll** | 3 | commun | Intelligence | +3 | — | Troll gastronome (élite), palier 4 88 % ×2–4<br>Troll des ponts, palier 3 55 % ×1–2 |
| **Hêtre centenaire** | 3 | rare | % Résistance Acier | +3 | bois | Bûcheron (Hêtre, rare) |
| **Message intercepté** | 3 | peu_commun | Agilité | +3 | — | Corbac chef espion (élite), palier 4 48 %<br>Corbac espion, palier 3 12 % |
| **Minerai d'argent** | 3 | peu_commun | Perception | +3 | minerai | Mineur (Argent) |
| **Plume de corbac** | 3 | commun | Force | +3 | — | Corbac chef espion (élite), palier 4 88 % ×2–5<br>Corbac espion, palier 3 55 % ×1–3 |
| **Poil de crinière léonin** | 3 | commun | Dommages Sacré | +2 | — | Lion de Juda, palier 3 25 % |
| **Recette de troll** | 3 | peu_commun | Perception | +3 | — | Troll gastronome (élite), palier 4 48 %<br>Troll des ponts, palier 3 12 % |
| **Sacré cœur de Raphaël** | 3 | legendaire | Soins | +1 | — | Archange Raphaël (mini-boss), palier 3 0 % |
| **Tunique déchirée de Raphaël** | 3 | commun | % Résistance Impie | +1 | — | Archange Raphaël (mini-boss), palier 3 55 % |
| **Éclat de cendre** | 3 | rare | Portée | +1 | — | Grondin, Bélier de la Brèche (mini-boss), palier 4 100 % ×1–2<br>Arbre calciné, palier 3 3 %<br>Grouilleur de braise, palier 3 3 %<br>Loup cendreux, palier 3 3 % |
| **Bois de malorme** | 4 | rare | Intelligence | +12 | bois | Bûcheron (Malorme) |
| **Chanvre** | 4 | commun | Initiative | +40 | tissu | Agriculteur (Chanvre) |
| **Chanvre d'acier** | 4 | rare | Portée | +1 | tissu | Agriculteur (Chanvre, rare) |
| **Cuir d'olifant** | 4 | commun | Vitalité | +16 | cuir | Olifant-tour (élite), palier 5 88 % ×2–4<br>Olifant de guerre, palier 4 55 % ×1–2 |
| **Cœur de pierre** | 4 | peu_commun | Intelligence | +4 | — | Gargouille de la Grande Porte (élite), palier 4 48 %<br>Gargouille, palier 4 12 % |
| **Invitation au bal** | 4 | peu_commun | Agilité | +4 | — | Marraine Cendrée (élite), palier 4 48 %<br>Cendrillon, palier 4 12 % |
| **Ivoire d'olifant** | 4 | peu_commun | Initiative | +40 | — | Olifant-tour (élite), palier 5 48 %<br>Olifant de guerre, palier 4 12 % |
| **Malorme ensorcelée** | 4 | rare | % Résistance Flamme | +3 | bois | Bûcheron (Malorme, rare) |
| **Obsidienne** | 4 | rare | Force | +12 | minerai | Mineur (Obsidienne) |
| **Obsidienne sanglante** | 4 | rare | Dommages Acier | +6 | minerai | Mineur (Obsidienne, rare) |
| **Éclat de gargouille** | 4 | commun | Perception | +4 | — | Gargouille de la Grande Porte (élite), palier 4 88 % ×2–5<br>Gargouille, palier 4 55 % ×1–3 |
| **Fragment de cendre** | 5 | legendaire | PA | +1 | — | Le Souverain Cendré (mini-boss), palier 5 100 % |

Ressources par caractéristique : Force 14, Intelligence 12, Agilité 9, Perception 9, Vitalité 5, Initiative 5, Dommages Sacré 3, Dommages Acier 3, Prospection 3, Portée 3, % Résistance Acier 2, Dommages 2, PM 2, PA 2, Dommages Flamme 1, % Résistance Tempête 1, % Critique 1, % Résistance Givre 1, Dommages Tempête 1, Soins Sacré 1, Dommages Givre 1, % Dégâts dévastateurs 1, Soins 1, % Résistance Impie 1, % Résistance Flamme 1.

### Plans

Un plan (objet de type « recette ») donne d'avance le type, les ressources et le nom ; l'aperçu
montre tout. Bonus calculés comme `Forge.preview` sans Précision (plage du jet), au palier de forge 5.

| Plan | Type | Palier | Ressources | Jets | Obtention |
|---|---|---|---|---|---|
| **Anneau de cuivre** | anneau | 1 | 1 Minerai de cuivre, 3 Chapeau de morille, 2 Croc de loup | Intelligence 3–4, Perception 2 | boutique |
| **Arc de frêne** | arc | 1 | 1 Minerai de cuivre, 1 Bois de frêne, 4 Dent de rat | Intelligence 1, Agilité 4–5 | boutique |
| **Bâton de novice** | baton | 1 | 1 Minerai de cuivre, 1 Bois de frêne, 4 Chapeau de morille | Intelligence 4–5, Agilité 1 | boutique |
| **Ceinture de corde** | ceinture | 1 | 1 Peau de loup, 5 Glande acide | Initiative 8–10, Vitalité 15–20 | boutique |
| **Sceptre de novice** | sceptre | 1 | 1 Minerai de cuivre, 1 Bois de frêne, 2 Chapeau de morille, 2 Carapace de grouilleur | Intelligence 2–3, Agilité 1, Force 2 | boutique |
| **Épée de fer** | epee | 1 | 1 Minerai de cuivre, 1 Bois de frêne, 4 Carapace de grouilleur | Intelligence 1, Agilité 1, Force 3–4 | boutique |
| **Amulette-croc** | amulette | 1 | 1 Minerai de cuivre, 3 Carapace de grouilleur, 2 Croc de loup | Intelligence 1, Force 2–3, Perception 2 | boutique |
| **Bottes de marche** | bottes | 1 | 3 Peau de loup, 3 Dent de rat | Initiative 23–30, Agilité 2–3 | « Aux armes, citoyens (surtout vous) » |
| **Bottes de mousse** | bottes | 1 | 1 Peau de loup, 3 Croc de loup, 2 Glande acide | Initiative 8–10, Perception 2–3, Vitalité 6–8 | « Observer sans intervenir » |
| **Bottes feutrées** | bottes | 1 | 1 Peau de loup, 3 Dent de rat, 2 Queue de rat | Initiative 8–10, Agilité 2–3, Prospection 2 | « Objectifs de productivité » |
| **Cape en peau de loup** | cape | 1 | 1 Poil scintillant, 2 Dent de rat, 2 Glande acide, 1 Peau de loup, 1 Lin | Force 1, Agilité 2, Vitalité 6–8, Initiative 8–10, Prospection 1 | boutique |
| **Ceinturon riveté** | ceinture | 1 | 1 Peau de loup, 3 Glande acide, 2 Carapace de grouilleur | Initiative 8–10, Vitalité 9–12, Force 2 | « Le verger de Mère Pomponne » |
| **Casque cabossé** | coiffe | 1 | 1 Poil scintillant, 3 Fiche de paie gobeline, 2 Aile de vampipistrelle, 1 Lin | Force 2–3, Vitalité 9–12, Prospection 1 | boutique, « Inspection surprise » |
| **Couronne de ramure** | coiffe | 1 | 1 Poil scintillant, 3 Queue de rat, 2 Bois de cerf enchanté, 1 Lin | Force 1, Prospection 3–4, Intelligence 2 | « Coupe rase » |
| **Dague du Mauvais Œil** | dague | 1 | 1 Minerai de fer, 1 Bois de chêne, 2 Écorce vivante, 2 Caillou de fronde | Force 2, Agilité 2, Perception 2 | boutique |
| **Masse cerclée** | masse | 1 | 1 Minerai de fer, 1 Bois de chêne, 2 Aile de vampipistrelle, 2 Fiche de paie gobeline | Force 3–4, Vitalité 6–8 | boutique |
| **Cape d'écorce** | cape | 1 | 1 Poil scintillant, 3 Fiche de paie gobeline, 2 Caillou de fronde, 1 Lin | Force 1, Vitalité 9–12, Perception 2, Prospection 1 | « Les arbres sont nerveux » |
| **Cape de vampipistrelle** | cape | 1 | 1 Poil scintillant, 2 Écorce vivante, 2 Caillou de fronde, 1 Peau de loup, 1 Lin | Force 1, Agilité 2, Perception 2, Initiative 8–10, Prospection 1 | « Heures supplémentaires (non payées) » |
| **Chevalière du Cogneur** | anneau | 1 | 1 Minerai de fer, 3 Spores grincheuses, 2 Aile de vampipistrelle | Force 2–3, Dommages 2–3 | « Les ordres du raid » |
| **Chapeau d'épouvantail** | coiffe | 2 | 1 Paille ensorcelée, 2 Citrouille grimaçante, 2 Sac de rapine, 1 Queue de rat, 1 Lin | Agilité 5–6, Vitalité 12–16, Prospection 2 | « La grève des épouvantails » |
| **Amulette-sifflet** | amulette | 2 | 1 Minerai d'étain, 2 Copeaux de bois, 2 Sifflet de contremaître, 1 Crochet d'araignée | Agilité 5–6, Initiative 30–40, Prospection 1 | « Le péage de Zibeline » |
| **Cape de soie grise** | cape | 2 | 1 Fil de brume, 2 Registre des heures, 2 Crochet d'araignée, 1 Sac de rapine, 1 Lin | Perception 2, Dommages 2, Prospection 2–3, Vitalité 6–8 | « Du fil de brume » |
| **Broche de la Lisière** | amulette | 2 | 1 Minerai d'étain, 2 Médaille en chocolat, 2 Sifflet de contremaître, 1 Crochet d'araignée | Agilité 5–6, Intelligence 3–4, Prospection 1 | « La Mère-Toile » |
| **Carte du syndicat** | amulette | 2 | 1 Minerai d'étain, 2 Sifflet de contremaître, 2 Registre des heures, 1 Crochet d'araignée | Agilité 5–6, Dommages 2, Prospection 1 | « Le Balourd des Abîmes » |
| **Écharpe du Héros de Brumerive** | cape | 2 | 1 Soie de la Mère-Toile, 2 Sac de rapine, 2 Gnôle de raid, 1 Médaille en chocolat, 1 Lin | PM 1, Vitalité 12–16, Force 3–4, Intelligence 2, Prospection 1 | « La palissade de Krasbouk » |
| **Amulette chantante** | amulette | 2 | 1 Minerai d'étain, 2 Médaille en chocolat, 2 Crochet d'araignée, 1 Carte au trésor douteuse | Agilité 2, Intelligence 3–4, Prospection 2, Vitalité 9–12 | « Notes d'observatrice » |
| **Bottes de grand chemin** | bottes | 2 | 1 Aile de vampipistrelle, 2 Sifflet de contremaître, 2 Carte au trésor douteuse, 1 Bourse vide | Force 1, Agilité 3–4, Vitalité 18–24, Initiative 23–30 | « Le tampon officiel » |
| **Cape de loup cendreux** | cape | 2 | 1 Soie de la Mère-Toile, 2 Sifflet de contremaître, 2 Carte au trésor douteuse, 1 Bourse vide, 1 Lin | PM 1, Agilité 3–4, Vitalité 18–24, Initiative 23–30, Prospection 1 | « Le convoi de Brokk » |
| **Ceinture de troll** | ceinture | 3 | 1 Aile de vampipistrelle, 3 Carte au trésor douteuse, 2 Cendre tiède | Force 5–7, Vitalité 27–36 | « Droit de passage » |
| **Heaume d'argent** | coiffe | 3 | 3 Plume de corbac, 2 Carte au trésor douteuse, 1 Crochet d'araignée, 1 Lin | Force 7–9, Vitalité 18–24, Prospection 2 | « Messages interceptés » |
| **Ceinture d'écorce calcinée** | ceinture | 3 | 1 Aile de vampipistrelle, 2 Carte au trésor douteuse, 2 Plume de corbac, 1 Dent de troll | Force 5–7, Vitalité 18–24, Intelligence 2–3 | « Les arbres qui brûlent » |
| **Brassard du délégué** | amulette | 3 | 1 Obsidienne, 2 Message intercepté, 2 Éclat de gargouille, 1 Crochet d'araignée | Force 9–12, Agilité 5–6, Perception 6–8, Prospection 1 | « Le registre des sacrifiés » |
| **Insigne de la Vieille Garde** | amulette | 3 | 1 Obsidienne, 2 Plume de corbac, 2 Carte au trésor douteuse, 1 Crochet d'araignée | Force 14–18, Vitalité 18–24, Prospection 1 | « La vieille garde » |
| **Feuille d'argent de l'ambassade** | anneau | 4 | 1 Obsidienne, 2 Cœur de pierre, 2 Invitation au bal, 1 Crochet d'araignée | Force 9–12, Intelligence 6–8, Agilité 6–8, Prospection 1 | « Le bal des Cendrillons » |
| **Cape en cuir d'olifant** | cape | 3 | 3 Plume de corbac, 2 Cuir d'olifant, 1 Crochet d'araignée, 1 Chanvre | Force 7–9, Vitalité 24–32, Prospection 1, Initiative 30–40 | « Le Conseil des Peuples Libres » |
| **Éclat de l'Aube** | anneau | 4 | 1 Obsidienne, 1 Cuir d'olifant, 1 Plume de corbac, 1 Cœur de pierre, 1 Éclat de gargouille, 1 Invitation au bal | Force 11–15, Vitalité 12–16, Intelligence 3–4, Perception 3–4, Agilité 3–4 | « La Brèche » |
