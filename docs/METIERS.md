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
× (100 + bonus de race) / 100. Base : le champ `xp` du nœud pour une récolte, **5 × palier de
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
| **Lin** (J) | 3 | Lin | 1–2 | 8 | 8 | 60–120 | 2,25 / 1,12 | Lin des fées | tissu | hautepierre_0_1 ×5 |
| **Avoine** (K) | 8 | Avoine | 1–2 | 12 | 12 | 90–150 | 3,5 / 1,75 | Avoine du Champion | — | hautepierre_0_1 ×4, hautepierre_1_4 ×2 |
| **Seigle** (S) | 15 | Seigle | 1–2 | 18 | 18 | 90–150 | 5,25 / 2,62 | Seigle ergoté | — | hautepierre_0_1 ×3, hautepierre_1_4 ×3 |
| **Chanvre** (V) | 22 | Chanvre | 1–2 | 25 | 25 | 120–180 | 7 / 3,5 | Chanvre d'acier | tissu | hautepierre_0_1 ×2, hautepierre_1_4 ×3 |

### Bûcheron

*Abat les arbres pour en tirer du bois.*

| Nœud | Palier | Objet | Qté | Rép. base | Rép. à sa mesure | Repousse (s) | Temps (s) | Rare | Forge | Cartes |
|---|---|---|---|---|---|---|---|---|---|---|
| **Frêne** (F) | 1 | Bois de frêne | 1–3 | 5 | 5 | 60–120 | 1,75 / 1 | Cœur de frêne | bois | brumerive_0_0 ×5, brumerive_0_1 ×3, brumerive_1_1 ×2, brumerive_1_2 ×2, brumerive_2_0 ×3, crasse_roc_0_0 ×2, crasse_roc_0_1 ×1, crasse_roc_1_0 ×1, hautepierre_2_0 ×2, sylvebrume_0_0 ×4, sylvebrume_0_1 ×3, sylvebrume_1_0 ×5, sylvebrume_2_0 ×2, sylvebrume_2_1 ×1 |
| **Chêne** (C) | 3 | Bois de chêne | 1–2 | 8 | 8 | 60–120 | 2,25 / 1,12 | Chêne des Anciens | bois | brumerive_1_0 ×5, brumerive_1_1 ×2, brumerive_2_0 ×2, brumerive_2_1 ×2, crasse_roc_0_0 ×1, crasse_roc_0_2 ×1, crasse_roc_1_0 ×2, crasse_roc_1_1 ×1, hautepierre_0_2 ×2, hautepierre_2_0 ×2, hautepierre_4_2 ×1, sylvebrume_0_0 ×3, sylvebrume_1_0 ×3, sylvebrume_1_1 ×2, sylvebrume_1_2 ×1, sylvebrume_2_0 ×2 |
| **If** (Y) | 8 | Bois d'if | 1–2 | 12 | 12 | 90–150 | 3,5 / 1,75 | If funèbre | bois | brumerive_1_2 ×2, brumerive_2_0 ×1, brumerive_2_1 ×2, brumerive_3_1 ×2, crasse_roc_0_2 ×1, crasse_roc_1_1 ×1, crasse_roc_2_1 ×1, hautepierre_0_2 ×2, hautepierre_1_0 ×2, hautepierre_1_3 ×1, hautepierre_2_0 ×1, sylvebrume_1_1 ×2, sylvebrume_1_2 ×2, sylvebrume_2_0 ×1, sylvebrume_2_1 ×2, sylvebrume_2_2 ×1 |
| **Hêtre** (H) | 15 | Bois de hêtre | 1–2 | 18 | 18 | 90–150 | 5,25 / 2,62 | Hêtre centenaire | bois | hautepierre_1_0 ×2, hautepierre_1_1 ×1, hautepierre_1_3 ×2, hautepierre_2_3 ×2, hautepierre_2_4 ×1, hautepierre_3_0 ×1 |
| **Malorme** (L) | 22 | Bois de malorme | 1–2 | 25 | 25 | 120–180 | 7 / 3,5 | Malorme ensorcelée | bois | hautepierre_3_0 ×1, hautepierre_3_1 ×1, hautepierre_3_3 ×1, hautepierre_3_4 ×2, hautepierre_4_1 ×1, hautepierre_4_3 ×2 |

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
| **Cuivre** (U) | 1 | Minerai de cuivre | 1–3 | 5 | 5 | 60–120 | 1,75 / 1 | Cuivre vert-de-gris | minerai | brumerive_0_0 ×3, brumerive_0_1 ×2, brumerive_1_0 ×1, crasse_roc_0_0 ×3, crasse_roc_0_1 ×3, crasse_roc_1_0 ×3, crasse_roc_1_1 ×1, crasse_roc_2_0 ×2, sylvebrume_0_0 ×2, sylvebrume_0_1 ×2, sylvebrume_1_0 ×1 |
| **Fer** (I) | 3 | Minerai de fer | 1–2 | 8 | 8 | 60–120 | 2,25 / 1,12 | Fer météorique | minerai | brumerive_1_0 ×3, brumerive_1_1 ×1, brumerive_2_1 ×2, brumerive_2_2 ×2, brumerive_3_1 ×1, crasse_roc_0_0 ×4, crasse_roc_0_2 ×1, crasse_roc_1_0 ×3, crasse_roc_1_1 ×2, crasse_roc_1_2 ×2, crasse_roc_2_0 ×2, crasse_roc_2_1 ×2, crasse_roc_2_2 ×2, hautepierre_4_2 ×2, sylvebrume_1_0 ×1, sylvebrume_1_1 ×2, sylvebrume_2_0 ×1, sylvebrume_2_1 ×1 |
| **Étain** (T) | 8 | Minerai d'étain | 1–2 | 12 | 12 | 90–150 | 3,5 / 1,75 | Étain chantant | minerai | brumerive_1_2 ×2, brumerive_2_1 ×1, brumerive_2_2 ×2, brumerive_3_1 ×1, brumerive_3_2 ×1, crasse_roc_0_2 ×2, crasse_roc_1_1 ×1, crasse_roc_1_2 ×2, crasse_roc_2_1 ×2, crasse_roc_2_2 ×3, hautepierre_0_2 ×1, hautepierre_2_4 ×1, hautepierre_4_2 ×2, sylvebrume_1_2 ×1, sylvebrume_2_1 ×1, sylvebrume_2_2 ×2 |
| **Argent** (G) | 15 | Minerai d'argent | 1–2 | 18 | 18 | 90–150 | 5,25 / 2,62 | Argent lunaire | minerai | hautepierre_1_1 ×2, hautepierre_1_3 ×1, hautepierre_2_3 ×2, hautepierre_2_4 ×2, hautepierre_3_0 ×1, hautepierre_3_1 ×2, hautepierre_4_1 ×1, hautepierre_4_3 ×1 |
| **Obsidienne** (D) | 22 | Obsidienne | 1–2 | 25 | 25 | 120–180 | 7 / 3,5 | Obsidienne sanglante | minerai | hautepierre_3_1 ×1, hautepierre_3_3 ×2, hautepierre_3_4 ×2, hautepierre_4_1 ×1, hautepierre_4_3 ×1, hautepierre_4_4 ×1 |

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
selon son palier. Une ligne vaut au plus **100 points de score** (en points de Force, `Forge.line_cap`)
et un objet a au plus **8 lignes**. Le palier de l'objet est la moyenne des paliers (pondérée
par les quantités) ; les jets sont tirés entre 75 % et 100 % du total (plus avec Précision).
PA, PM, Portée : 1 par ressource quel que soit le palier, 1 au plus par objet. La caractéristique d'une ressource
n'est lisible qu'après un premier objet forgé, et seulement si le niveau équivalent de la réputation
de forgeron atteint son palier (`Forge.reveals`). Réputation : 5 × palier de l'objet en base.

### Valeur d'une ressource

`Forge.value` : max(1, arrondi((1 + palier / 8) × poids)) ; poids = points de la caractéristique
pour un point de Force.

| Caractéristique | Poids | Plafond d'une ligne | P1 | P4 | P7 | P10 | P12 | P13 | P16 | P19 | P22 | P25 | P28 | P50 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Force | 1 | 100 | 1 | 2 | 2 | 2 | 3 | 3 | 3 | 3 | 4 | 4 | 5 | 7 |
| Intelligence | 1 | 100 | 1 | 2 | 2 | 2 | 3 | 3 | 3 | 3 | 4 | 4 | 5 | 7 |
| Perception | 1 | 100 | 1 | 2 | 2 | 2 | 3 | 3 | 3 | 3 | 4 | 4 | 5 | 7 |
| Agilité | 1 | 100 | 1 | 2 | 2 | 2 | 3 | 3 | 3 | 3 | 4 | 4 | 5 | 7 |
| Vitalité | 4 | 400 | 5 | 6 | 8 | 9 | 10 | 11 | 12 | 14 | 15 | 17 | 18 | 29 |
| Initiative | 10 | 1000 | 11 | 15 | 19 | 23 | 25 | 26 | 30 | 34 | 38 | 41 | 45 | 73 |
| Prospection | 0,34 | 34 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 | 2 |
| Dommages | 0,34 | 34 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 | 2 |
| % Critique | 0,1 | 10 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| PA | fixe | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| PM | fixe | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| Portée | fixe | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

### Types d'objets

| Type | Matières obligatoires | Noms proposés | Attaque (dégâts selon le palier : × (1 + (P − 1) / 20) ; élément de la carac. élémentaire la plus forte) |
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
| **Bois de frêne** | 1 | commun | — | — | bois | Bûcheron (Frêne) |
| **Carapace de grouilleur** | 1 | commun | Force | +1 | — | Grouilleur ancestral (élite) niv. 7 90 % ×2–4<br>Grouilleur niv. 1–3 50 % ×1–2<br>Grouilleur de braise niv. 16–18 50 % ×1–2 |
| **Chapeau de morille** | 1 | commun | Intelligence | +1 | — | Vieille Morille rancunière (élite) niv. 6 90 % ×2–4<br>Morille grincheuse niv. 1–3 60 % ×1–2 |
| **Croc de loup** | 1 | commun | Perception | +1 | — | Loup alpha (élite) niv. 7 90 % ×2–4<br>Loup cendreux niv. 13–15 50 % ×1–2<br>Loup des collines niv. 1–3 50 % ×1–2 |
| **Cuivre vert-de-gris** | 1 | rare | — | — | minerai | Mineur (Cuivre, rare) |
| **Cœur de frêne** | 1 | rare | — | — | bois | Bûcheron (Frêne, rare) |
| **Dent de rat** | 1 | commun | Agilité | +1 | — | Rat-roi (élite) niv. 5 70 % ×1–2<br>Rat des galeries niv. 1–3 30 % |
| **Glande acide** | 1 | peu_commun | Vitalité | +5 | — | Grouilleur ancestral (élite) niv. 7 50 % ×1–2<br>Grouilleur niv. 1–3 15 % |
| **Minerai de cuivre** | 1 | commun | — | — | minerai | Mineur (Cuivre) |
| **Peau de loup** | 1 | commun | Initiative | +11 | cuir | Loup alpha (élite) niv. 7 70 % ×1–2<br>Loup des collines niv. 1–3 30 % |
| **Queue de rat** | 1 | commun | Prospection | +1 | cuir | Rat-roi (élite) niv. 5 90 % ×2–4<br>Rat des galeries niv. 1–3 60 % ×1–2 |
| **Spores grincheuses** | 1 | peu_commun | Dommages | +1 | — | Vieille Morille rancunière (élite) niv. 6 48 %<br>Morille grincheuse niv. 1–3 12 % |
| **Bois de chêne** | 3 | peu_commun | — | — | bois | Bûcheron (Chêne) |
| **Chêne des Anciens** | 3 | rare | — | — | bois | Bûcheron (Chêne, rare) |
| **Fer météorique** | 3 | rare | — | — | minerai | Mineur (Fer, rare) |
| **Lin** | 3 | commun | — | — | tissu | Agriculteur (Lin) |
| **Lin des fées** | 3 | rare | — | — | tissu | Agriculteur (Lin, rare) |
| **Minerai de fer** | 3 | peu_commun | — | — | minerai | Mineur (Fer) |
| **Aile de vampipistrelle** | 4 | commun | Force | +2 | cuir | Vampipistrelle comtesse (élite) niv. 9 88 % ×2–4<br>Vampipistrelle niv. 4–6 55 % ×1–2 |
| **Bois de cerf enchanté** | 4 | peu_commun | Intelligence | +2 | — | Grand cerf de la Lisière (élite) niv. 9 60 % ×1–2<br>Cerf enchanté niv. 4–6 20 % |
| **Caillou de fronde** | 4 | commun | Perception | +2 | — | Frondeur vétéran (élite) niv. 9 90 % ×2–5<br>Gobelin frondeur niv. 4–6 60 % ×1–3 |
| **Fiche de paie gobeline** | 4 | peu_commun | Vitalité | +6 | — | Frondeur vétéran (élite) niv. 9 50 %<br>Gobelin frondeur niv. 4–6 15 % |
| **Guano luisant** | 4 | peu_commun | % Critique | +1 | — | Vampipistrelle comtesse (élite) niv. 9 48 %<br>Vampipistrelle niv. 4–6 12 % |
| **Poil scintillant** | 4 | commun | Force | +2 | tissu | Grand cerf de la Lisière (élite) niv. 9 90 % ×2–4<br>Cerf enchanté niv. 4–6 50 % ×1–2 |
| **Sève ancienne** | 4 | rare | Intelligence | +2 | — | Arbre millénaire (élite) niv. 10 40 % ×1–2<br>Arbre vivant niv. 4–6 10 % |
| **Écorce vivante** | 4 | commun | Agilité | +2 | — | Arbre millénaire (élite) niv. 10 90 % ×2–5<br>Arbre vivant niv. 4–6 60 % ×1–3<br>Arbre calciné niv. 19–21 50 % ×1–2 |
| **Bon de coupe** | 7 | peu_commun | Perception | +2 | — | Abatteur en chef (élite) niv. 12 48 %<br>Bûcheron de Brumerive niv. 7–9 12 % |
| **Citrouille grimaçante** | 7 | peu_commun | Agilité | +2 | — | Grand Épouvantail (élite) niv. 12 48 %<br>Épouvantail démotivé niv. 7–9 12 % |
| **Copeaux de bois** | 7 | commun | Initiative | +19 | — | Abatteur en chef (élite) niv. 12 88 % ×2–5<br>Bûcheron de Brumerive niv. 7–9 55 % ×1–3 |
| **Maillon de cotte** | 7 | commun | Intelligence | +2 | — | Sergent de la milice (élite) niv. 12 80 % ×2–5<br>Milicien de Hautepierre niv. 7–9 50 % ×1–3 |
| **Ordre de raid** | 7 | peu_commun | Perception | +2 | — | Krasbouk, Chef de Raid (syndiqué) (mini-boss) niv. 12 100 %<br>Pillard émérite (élite) niv. 12 48 %<br>Défonceur de portes (élite) niv. 15 32 %<br>Gobelin pillard niv. 7–9 12 %<br>Gobelin briseur niv. 10–12 8 % |
| **Paille ensorcelée** | 7 | commun | Agilité | +2 | tissu | Grand Épouvantail (élite) niv. 12 90 % ×2–5<br>Épouvantail démotivé niv. 7–9 60 % ×1–3 |
| **Sac de rapine** | 7 | commun | Vitalité | +8 | — | Krasbouk, Chef de Raid (syndiqué) (mini-boss) niv. 12 90 % ×2–4<br>Pillard émérite (élite) niv. 12 88 % ×2–4<br>Gobelin pillard niv. 7–9 55 % ×1–2 |
| **Écusson de milice** | 7 | peu_commun | Force | +2 | — | Sergent de la milice (élite) niv. 12 48 %<br>Milicien de Hautepierre niv. 7–9 12 % |
| **Bois d'if** | 8 | peu_commun | — | — | bois | Bûcheron (If) |
| **If funèbre** | 8 | rare | — | — | bois | Bûcheron (If, rare) |
| **Minerai d'étain** | 8 | commun | — | — | minerai | Mineur (Étain) |
| **Étain chantant** | 8 | rare | — | — | minerai | Mineur (Étain, rare) |
| **Crochet d'araignée** | 10 | peu_commun | Prospection | +1 | — | Grande Tisseuse (élite) niv. 15 48 %<br>Tisseuse de brume niv. 10–12 12 % |
| **Fil de brume** | 10 | commun | Dommages | +1 | tissu | La Mère-Toile (mini-boss) niv. 12 90 % ×2–4<br>Grande Tisseuse (élite) niv. 15 88 % ×2–5<br>Tisseuse de brume niv. 10–12 55 % ×1–3 |
| **Gnôle de raid** | 10 | commun | Force | +2 | — | Défonceur de portes (élite) niv. 15 88 % ×2–4<br>Gobelin briseur niv. 10–12 55 % ×1–2 |
| **Médaille en chocolat** | 10 | peu_commun | Intelligence | +2 | — | Défonceur de portes (élite) niv. 15 48 %<br>Gobelin briseur niv. 10–12 12 % |
| **Registre des heures** | 10 | peu_commun | Perception | +2 | — | Le Balourd des Abîmes (mini-boss) niv. 12 50 % ×1–2<br>Contremaître en chef (élite) niv. 15 48 %<br>Contremaître zélé niv. 10–12 12 % |
| **Sifflet de contremaître** | 10 | commun | Agilité | +2 | — | Contremaître en chef (élite) niv. 15 80 % ×2–4<br>Contremaître zélé niv. 10–12 50 % ×1–2 |
| **Corne du Balourd** | 12 | rare | PA | +1 | — | Le Balourd des Abîmes (mini-boss) niv. 12 100 % |
| **Soie de la Mère-Toile** | 12 | rare | PM | +1 | tissu | La Mère-Toile (mini-boss) niv. 12 100 % |
| **Bourse vide** | 13 | commun | Initiative | +26 | — | Chef de bande (élite) niv. 18 88 % ×2–4<br>Détrousseur des grands chemins niv. 13–15 55 % ×1–2 |
| **Carte au trésor douteuse** | 13 | peu_commun | Vitalité | +11 | — | Chef de bande (élite) niv. 18 48 %<br>Détrousseur des grands chemins niv. 13–15 12 % |
| **Cendre tiède** | 13 | commun | Force | +3 | — | Marraine Cendrée (élite) niv. 30 88 % ×2–5<br>Cendrillon niv. 25–27 55 % ×1–3<br>Arbre calciné niv. 19–21 50 % ×1–2<br>Grouilleur de braise niv. 16–18 50 % ×1–2<br>Loup cendreux niv. 13–15 50 % ×1–2 |
| **Éclat de cendre** | 13 | rare | Portée | +1 | — | Grondin, Bélier de la Brèche (mini-boss) niv. 30 100 % ×1–2<br>Arbre calciné niv. 19–21 3 %<br>Grouilleur de braise niv. 16–18 3 %<br>Loup cendreux niv. 13–15 3 % |
| **Argent lunaire** | 15 | rare | — | — | minerai | Mineur (Argent, rare) |
| **Bois de hêtre** | 15 | peu_commun | — | — | bois | Bûcheron (Hêtre) |
| **Hêtre centenaire** | 15 | rare | — | — | bois | Bûcheron (Hêtre, rare) |
| **Minerai d'argent** | 15 | peu_commun | — | — | minerai | Mineur (Argent) |
| **Dent de troll** | 16 | commun | Intelligence | +3 | — | Troll gastronome (élite) niv. 21 88 % ×2–4<br>Troll des ponts niv. 16–18 55 % ×1–2 |
| **Recette de troll** | 16 | peu_commun | Perception | +3 | — | Troll gastronome (élite) niv. 21 48 %<br>Troll des ponts niv. 16–18 12 % |
| **Message intercepté** | 19 | peu_commun | Agilité | +3 | — | Corbac chef espion (élite) niv. 24 48 %<br>Corbac espion niv. 19–21 12 % |
| **Plume de corbac** | 19 | commun | Force | +3 | tissu | Corbac chef espion (élite) niv. 24 88 % ×2–5<br>Corbac espion niv. 19–21 55 % ×1–3 |
| **Bois de malorme** | 22 | rare | — | — | bois | Bûcheron (Malorme) |
| **Chanvre** | 22 | commun | — | — | tissu | Agriculteur (Chanvre) |
| **Chanvre d'acier** | 22 | rare | — | — | tissu | Agriculteur (Chanvre, rare) |
| **Cœur de pierre** | 22 | peu_commun | Intelligence | +4 | — | Gargouille de la Grande Porte (élite) niv. 27 48 %<br>Gargouille niv. 22–24 12 % |
| **Malorme ensorcelée** | 22 | rare | — | — | bois | Bûcheron (Malorme, rare) |
| **Obsidienne** | 22 | rare | — | — | minerai | Mineur (Obsidienne) |
| **Obsidienne sanglante** | 22 | rare | — | — | minerai | Mineur (Obsidienne, rare) |
| **Éclat de gargouille** | 22 | commun | Perception | +4 | — | Gargouille de la Grande Porte (élite) niv. 27 88 % ×2–5<br>Gargouille niv. 22–24 55 % ×1–3 |
| **Invitation au bal** | 25 | peu_commun | Agilité | +4 | — | Marraine Cendrée (élite) niv. 30 48 %<br>Cendrillon niv. 25–27 12 % |
| **Cuir d'olifant** | 28 | commun | Vitalité | +18 | cuir | Olifant-tour (élite) niv. 33 88 % ×2–4<br>Olifant de guerre niv. 28–30 55 % ×1–2 |
| **Ivoire d'olifant** | 28 | peu_commun | Initiative | +45 | — | Olifant-tour (élite) niv. 33 48 %<br>Olifant de guerre niv. 28–30 12 % |
| **Fragment de cendre** | 50 | legendaire | PA | +1 | — | Le Souverain Cendré (mini-boss) niv. 50 100 % |

Ressources par caractéristique : Force 7, Intelligence 7, Perception 7, Agilité 7, Vitalité 5, Initiative 4, Prospection 2, Dommages 2, PA 2, % Critique 1, PM 1, Portée 1.

### Plans

Un plan (objet de type « recette ») donne d'avance le type, les ressources et le nom ; l'aperçu
montre tout. Bonus calculés comme `Forge.preview` sans Précision (plage du jet).

| Plan | Type | Palier | Ressources | Jets | Obtention |
|---|---|---|---|---|---|
| **Anneau de cuivre** | anneau | 1 | 1 Minerai de cuivre, 3 Chapeau de morille, 2 Croc de loup | Intelligence 2–3, Perception 2 | boutique |
| **Arc de frêne** | arc | 1 | 1 Minerai de cuivre, 1 Bois de frêne, 4 Dent de rat | Agilité 3–4 | boutique |
| **Bâton de novice** | baton | 1 | 1 Minerai de cuivre, 1 Bois de frêne, 4 Chapeau de morille | Intelligence 3–4 | boutique |
| **Ceinture de corde** | ceinture | 1 | 1 Peau de loup, 5 Glande acide | Initiative 8–11, Vitalité 19–25 | boutique |
| **Sceptre de novice** | sceptre | 1 | 1 Minerai de cuivre, 1 Bois de frêne, 2 Chapeau de morille, 2 Carapace de grouilleur | Intelligence 2, Force 2 | boutique |
| **Épée de fer** | epee | 1 | 1 Minerai de cuivre, 1 Bois de frêne, 4 Carapace de grouilleur | Force 3–4 | boutique |
| **Amulette-croc** | amulette | 1 | 1 Minerai de cuivre, 3 Carapace de grouilleur, 2 Croc de loup | Force 2–3, Perception 2 | boutique |
| **Bottes de marche** | bottes | 1 | 3 Peau de loup, 3 Dent de rat | Initiative 25–33, Agilité 2–3 | « Aux armes, citoyens (surtout vous) » |
| **Bottes de mousse** | bottes | 1 | 1 Peau de loup, 3 Croc de loup, 2 Glande acide | Initiative 8–11, Perception 2–3, Vitalité 8–10 | « Observer sans intervenir » |
| **Bottes feutrées** | bottes | 1 | 1 Peau de loup, 3 Dent de rat, 2 Queue de rat | Initiative 8–11, Agilité 2–3, Prospection 2 | « Objectifs de productivité » |
| **Cape en peau de loup** | cape | 2 | 1 Poil scintillant, 2 Dent de rat, 2 Glande acide, 1 Peau de loup | Force 2, Agilité 2, Vitalité 8–10, Initiative 8–11 | boutique |
| **Ceinturon riveté** | ceinture | 1 | 1 Peau de loup, 3 Glande acide, 2 Carapace de grouilleur | Initiative 8–11, Vitalité 11–15, Force 2 | « Le verger de Mère Pomponne » |
| **Casque cabossé** | coiffe | 4 | 1 Poil scintillant, 3 Fiche de paie gobeline, 2 Aile de vampipistrelle | Force 5–6, Vitalité 14–18 | boutique, « Inspection surprise » |
| **Couronne de ramure** | coiffe | 3 | 1 Poil scintillant, 3 Queue de rat, 2 Bois de cerf enchanté | Force 2, Prospection 2–3, Intelligence 3–4 | « Coupe rase » |
| **Dague du Mauvais Œil** | dague | 4 | 1 Minerai de fer, 1 Bois de chêne, 2 Écorce vivante, 2 Caillou de fronde | Agilité 3–4, Perception 3–4 | boutique |
| **Masse cerclée** | masse | 4 | 1 Minerai de fer, 1 Bois de chêne, 2 Aile de vampipistrelle, 2 Fiche de paie gobeline | Force 3–4, Vitalité 9–12 | boutique |
| **Cape d'écorce** | cape | 4 | 1 Poil scintillant, 3 Fiche de paie gobeline, 2 Caillou de fronde | Force 2, Vitalité 14–18, Perception 3–4 | « Les arbres sont nerveux » |
| **Cape de vampipistrelle** | cape | 4 | 1 Poil scintillant, 2 Écorce vivante, 2 Caillou de fronde, 1 Peau de loup | Force 2, Agilité 3–4, Perception 3–4, Initiative 8–11 | « Heures supplémentaires (non payées) » |
| **Chevalière du Cogneur** | anneau | 2 | 1 Minerai de fer, 3 Spores grincheuses, 2 Aile de vampipistrelle | Dommages 2–3, Force 3–4 | « Les ordres du raid » |
| **Chapeau d'épouvantail** | coiffe | 6 | 1 Paille ensorcelée, 2 Citrouille grimaçante, 2 Sac de rapine, 1 Queue de rat | Agilité 5–6, Vitalité 12–16, Prospection 1 | « La grève des épouvantails » |
| **Amulette-sifflet** | amulette | 9 | 1 Minerai d'étain, 2 Copeaux de bois, 2 Sifflet de contremaître, 1 Crochet d'araignée | Initiative 29–38, Agilité 3–4, Prospection 1 | « Le péage de Zibeline » |
| **Cape de soie grise** | cape | 10 | 1 Fil de brume, 2 Registre des heures, 2 Crochet d'araignée, 1 Sac de rapine | Dommages 1, Perception 3–4, Prospection 2, Vitalité 6–8 | « Du fil de brume » |
| **Broche de la Lisière** | amulette | 10 | 1 Minerai d'étain, 2 Médaille en chocolat, 2 Sifflet de contremaître, 1 Crochet d'araignée | Intelligence 3–4, Agilité 3–4, Prospection 1 | « La Mère-Toile » |
| **Carte du syndicat** | amulette | 10 | 1 Minerai d'étain, 2 Sifflet de contremaître, 2 Registre des heures, 1 Crochet d'araignée | Agilité 3–4, Perception 3–4, Prospection 1 | « Le Balourd des Abîmes » |
| **Écharpe du Héros de Brumerive** | cape | 9 | 1 Soie de la Mère-Toile, 2 Sac de rapine, 2 Gnôle de raid, 1 Médaille en chocolat | PM 1, Vitalité 12–16, Force 3–4, Intelligence 2 | « La palissade de Krasbouk » |
| **Amulette chantante** | amulette | 10 | 1 Minerai d'étain, 2 Médaille en chocolat, 2 Crochet d'araignée, 1 Carte au trésor douteuse | Intelligence 3–4, Prospection 2, Vitalité 8–11 | « Notes d'observatrice » |
| **Bottes de grand chemin** | bottes | 11 | 1 Aile de vampipistrelle, 2 Sifflet de contremaître, 2 Carte au trésor douteuse, 1 Bourse vide | Force 2, Agilité 3–4, Vitalité 17–22, Initiative 20–26 | « Le tampon officiel » |
| **Cape de loup cendreux** | cape | 12 | 1 Soie de la Mère-Toile, 2 Sifflet de contremaître, 2 Carte au trésor douteuse, 1 Bourse vide | PM 1, Agilité 3–4, Vitalité 17–22, Initiative 20–26 | « Le convoi de Brokk » |
| **Ceinture de troll** | ceinture | 12 | 1 Aile de vampipistrelle, 3 Carte au trésor douteuse, 2 Cendre tiède | Force 6–8, Vitalité 25–33 | « Droit de passage » |
| **Heaume d'argent** | coiffe | 16 | 3 Plume de corbac, 2 Carte au trésor douteuse, 1 Crochet d'araignée | Force 7–9, Vitalité 17–22, Prospection 1 | « Messages interceptés » |
| **Ceinture d'écorce calcinée** | ceinture | 14 | 1 Aile de vampipistrelle, 2 Carte au trésor douteuse, 2 Plume de corbac, 1 Dent de troll | Force 6–8, Vitalité 17–22, Intelligence 2–3 | « Les arbres qui brûlent » |
| **Brassard du délégué** | amulette | 19 | 1 Obsidienne, 2 Message intercepté, 2 Éclat de gargouille, 1 Crochet d'araignée | Agilité 5–6, Perception 6–8, Prospection 1 | « Le registre des sacrifiés » |
| **Insigne de la Vieille Garde** | amulette | 16 | 1 Obsidienne, 2 Plume de corbac, 2 Carte au trésor douteuse, 1 Crochet d'araignée | Force 5–6, Vitalité 17–22, Prospection 1 | « La vieille garde » |
| **Feuille d'argent de l'ambassade** | anneau | 21 | 1 Obsidienne, 2 Cœur de pierre, 2 Invitation au bal, 1 Crochet d'araignée | Intelligence 6–8, Agilité 6–8, Prospection 1 | « Le bal des Cendrillons » |
| **Cape en cuir d'olifant** | cape | 21 | 3 Plume de corbac, 2 Cuir d'olifant, 1 Crochet d'araignée | Force 7–9, Vitalité 27–36, Prospection 1 | « Le Conseil des Peuples Libres » |
| **Éclat de l'Aube** | anneau | 23 | 1 Obsidienne, 1 Cuir d'olifant, 1 Plume de corbac, 1 Cœur de pierre, 1 Éclat de gargouille, 1 Invitation au bal | Vitalité 14–18, Force 2–3, Intelligence 3–4, Perception 3–4, Agilité 3–4 | « La Brèche » |
