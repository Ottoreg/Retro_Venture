# Classes et races : toutes les variables

Généré par `game/tools/equilibrage.py` à partir du code (`core/character/`, `core/combat/`) et
de `game/data/` (`voies/`, `races/`, `sorts/`) : ne pas modifier à la main. Vue d'ensemble pour
l'équilibrage ; règles dans le GDD (§ 4), métiers dans [METIERS.md](METIERS.md), monstres dans
[CATALOGUE.md](CATALOGUE.md).

## Principe

Pas de niveau (GDD § 4.5) : une classe (Voie) active à la fois, changée hors combat. Chaque classe
a sa réputation et ses points de maîtrise ; les caractéristiques se gagnent par la pratique et
suivent le personnage d'une classe à l'autre. Pas de bonus de caractéristiques de race ni
d'équipement de départ : une race donne un passif et un sort.

## Caractéristiques

- Gagnées par la pratique : Vitalité, Force, Intelligence, Perception, Agilité ; plafond **300** par caractéristique (Vitalité 300), le reste vient
  de l'équipement et des panoplies.
- Élément → caractéristique : Acier → Force, Flamme → Intelligence, Givre → Perception, Tempête → Agilité ; Sacré = Acier + Flamme, Impie = Tempête + Givre.
- Puissance d'un élément = sa caractéristique (somme des deux pour un élément composé) + 4 par
  état élémentaire de cet élément (Arcaniste, 3 états au plus).
- **Dégâts** (`Combat.damage_value`) : jet × (100 + puissance) / 100 × (1 + % dégâts infligés)
  × (100 − résistance de la cible) / 100 + Dommages. Soins, boucliers, poisons : jet × (100 + puissance) / 100.
- Critique : 5 % par défaut (+ « critique » du sort et de l'équipement), × 1,5 sur la valeur tirée.
- PV = PV de la Voie + Vitalité ; initiative = celle de la Voie + Force + Intelligence + Perception
  + Agilité + équipement ; prospection = 100 + équipement + passif de race.

## Réputation et maîtrise

Même modèle pour chaque classe (`core/character/character.gd`) : la réputation est un total cumulé
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

Une nouvelle classe s'ouvre quand une classe a **5000** de réputation (`NEW_CLASS_REPUTATION`) ;
elle part de zéro. Maîtrise d'un sort : chaque rang ajoute **10 %** aux valeurs de base de ses
effets élémentaires (dégâts, soins, boucliers, poisons), plus les changements de son champ
`maitrise` aux rangs indiqués (colonne Maîtrise ci-dessous).

### Gains d'un combat (`core/character/progression.gd`)

| Variable | Valeur | Rôle |
|---|---|---|
| REPUTATION_PER_PA | 2 | réputation par PA d'un sort à effet réel (dégâts, soin de PV perdus, bouclier qui absorbe) |
| UTILITY_SHARE | 0,5 | part pour un sort utilitaire qui touche quelqu'un |
| KILL_SHARE | 0,25 | part de l'XP d'un monstre vaincu en réputation, partagée entre les joueurs |
| STAT_PER_PA | 0,03 | points de la caractéristique de l'élément par PA à effet réel |
| VITALITY_PER_HP | 0,02 | Vitalité par PV réellement perdu |
| MAX_PA_PER_COMBAT | 60 | PA comptés au plus par combat |
| MAX_HP_PER_COMBAT | 200 | PV perdus comptés au plus par combat |
| MIN_STAT_PACE | 0,2 | rythme minimal près du plafond : × max(0,2, 1 − points / plafond) |

Tout est multiplié par le facteur de difficulté (somme des niveaux des monstres / somme des
niveaux équivalents des joueurs). Exemple : 60 PA à effet réel à facteur 1 = 120 de réputation et 1,8
point(s) de caractéristique (avant ralentissement).

## Races

| Race | Camp | Départ | Passif | Effets du passif | Sort de race |
|---|---|---|---|---|---|
| **Elfe** | neutre | sylvebrume_0_0 | Œil perçant | portee +1 | Pas léger |
| **Gobelin** | ennemi | crasse_roc_0_0 | Chapardeur | prospection +20, ecus +20 | Coup bas |
| **Humain** | allie | brumerive_0_0 | Polyvalence | reputation_metier +10 | Ralliement |

| Sort de race | Caractéristiques | Effets | Maîtrise |
|---|---|---|---|
| **Pas léger** | 2 PA, portée 1–3, sans ligne de vue, 1/tour, relance 3 t. | téléportation sur la case | — |
| **Coup bas** | 3 PA, portée 1, 1/tour | 4–7 Tempête ; −1 PM au prochain tour | — |
| **Ralliement** | 1 PA, portée soi, sans ligne de vue, 1/tour, relance 4 t. | +2 PA tout de suite | — |

## Voies

| Voie | PV | PA | PM | Initiative | Sorts de rang I | Sorts de rang II |
|---|---|---|---|---|---|---|
| **Arcaniste** | 46 | 6 | 3 | 90 | 2 | 0 |
| **Chronomancien** | 50 | 6 | 3 | 95 | 6 | 0 |
| **Guerrier** | 60 | 6 | 3 | 100 | 5 | 2 |
| **Rôdeur** | 52 | 6 | 3 | 120 | 5 | 0 |
| **Théologue** | 48 | 6 | 3 | 85 | 5 | 0 |

Colonnes des sorts : *Moy.* = valeurs moyennes de base des dégâts, soins et boucliers directs (hors
horloge, glyphe et piège) ; *Moy./PA* ; *Rang 5* = moyenne avec +50 % de maîtrise. À multiplier par
(100 + puissance) / 100 en combat.

### Arcaniste

*Maître du feu et du givre. Lit beaucoup, court peu, explose parfois des choses par accident.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Composition** | I | 1 PA, portée soi, sans ligne de vue, critique 0 % | choisit d'un coup ses 3 états élémentaires parmi Flamme et Givre (permanents) ; +1 PA tout de suite | — | — | — | — |
| **Fusion arcanique** | I | 2 PA, portée soi, sans ligne de vue, 1/tour, critique 0 % | crée le sort de la combinaison des 3 états : Flamme + Flamme + Flamme → Fournaise ; Flamme + Flamme + Givre → Choc thermique ; Flamme + Givre + Givre → Armure de givre ; Givre + Givre + Givre → Blizzard | — | — | — | — |
| **Fournaise** | créé (Flamme+Flamme+Flamme) | 4 PA, portée 2–6, cercle de rayon 1, 1/tour | 9–13 Flamme aux ennemis ; glyphe (2 t.) : [3–5 Flamme aux ennemis] | 11 dégâts | 2,75 dégâts | 16,5 dégâts | — |
| **Choc thermique** | créé (Flamme+Flamme+Givre) | 4 PA, portée 1–5, 1/tour | 7–10 Flamme ; 4–6 Givre ; −10 Résistance Flamme (2 t.) | 13,5 dégâts | 3,38 dégâts | 20,25 dégâts | — |
| **Armure de givre** | créé (Flamme+Givre+Givre) | 4 PA, portée 0–3, 1/tour, relance 1 t. | bouclier 14–20 (Givre) aux alliés ; +20 Intelligence (2 t.) aux alliés | 17 bouclier | 4,25 bouclier | 25,5 bouclier | — |
| **Blizzard** | créé (Givre+Givre+Givre) | 4 PA, portée 1–5, cercle de rayon 1, 1/tour | 6–9 Givre aux ennemis ; −2 PM au prochain tour aux ennemis | 7,5 dégâts | 1,88 dégâts | 11,25 dégâts | — |

### Chronomancien

*Dérègle le temps avec des pouvoirs impies. Toujours en avance, ou en retard, mais jamais à l'heure.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Horloge** | I | 3 PA, portée 3, en ligne, portée non modifiable, 1/tour | 3–5 Impie aux ennemis ; horloge (3 t.) : [1 h : 10 Givre ; 2 h : poison 5 Givre par tour (2 t.) ; 3 h : −10 Retrait PA (2 t.) ; 4 h : inblocable (1 t.) ; 5 h : −10 Résistance Impie (1 t.) ; 6 h : −1 PM (1 t.) ; 7 h : 10 Tempête ; 8 h : poison 5 Tempête par tour (2 t.) ; 9 h : −10 Retrait PM (2 t.) ; 10 h : insoignable (1 t.) ; 11 h : −10 % dégâts infligés (1 t.) ; 12 h : −1 PA (1 t.)] aux ennemis | 4 dégâts | 1,33 dégâts | 6 dégâts | rang 3 : +5 % critique<br>rang 5 : +5 % critique |
| **Tic** | I | 2 PA, portée 1–6, 2/tour | 4–6 Impie ; +1 h sur l'horloge | 5 dégâts | 2,5 dégâts | 7,5 dégâts | rang 3 : +5 % critique<br>rang 5 : +5 % critique |
| **Tac** | I | 2 PA, portée 1–6, 2/tour | 4–6 Impie ; -1 h sur l'horloge | 5 dégâts | 2,5 dégâts | 7,5 dégâts | rang 3 : +5 % critique<br>rang 5 : +5 % critique |
| **Avance rapide** | I | 4 PA, portée 1–6, 1/tour | 9–12 Impie ; +3 h sur l'horloge | 10,5 dégâts | 2,62 dégâts | 15,75 dégâts | rang 3 : +5 % critique<br>rang 5 : coût 3 PA |
| **Retour en arrière** | I | 4 PA, portée 1–6, 1/tour | 9–12 Impie ; -3 h sur l'horloge | 10,5 dégâts | 2,62 dégâts | 15,75 dégâts | rang 3 : +5 % critique<br>rang 5 : coût 3 PA |
| **Contretemps** | I | 3 PA, portée 1–6, 1/tour, relance 2 t. | 6–8 Impie ; +6 h sur l'horloge | 7 dégâts | 2,33 dégâts | 10,5 dégâts | rang 3 : +5 % critique<br>rang 5 : relance 1 t. |

### Guerrier

*Au contact, il encaisse et rend les coups. Réfléchit après, de préférence.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Frappe** | I | 3 PA, portée 1, 2/tour | 8–12 Acier | 10 dégâts | 3,33 dégâts | 15 dégâts | rang 3 : +5 % critique<br>rang 5 : ajoute −1 PM au prochain tour aux ennemis |
| **Lancer de hache** | I | 4 PA, portée 2–5, 1/tour | 6–9 Acier | 7,5 dégâts | 1,88 dégâts | 11,25 dégâts | rang 3 : +1 portée<br>rang 5 : coût 3 PA |
| **Tourbillon** | I | 4 PA, portée soi, cercle de rayon 1 (sans le lanceur), sans ligne de vue, 1/tour | 7–10 Acier | 8,5 dégâts | 2,12 dégâts | 12,75 dégâts | rang 3 : ajoute poussée de 1 case(s)<br>rang 5 : zone de taille 2 |
| **Second souffle** | I | 2 PA, portée soi, sans ligne de vue, 1/tour, relance 3 t. | soin 12–18 (Acier) | 15 soin | 7,5 soin | 22,5 soin | rang 3 : relance 2 t.<br>rang 5 : ajoute bouclier 9–14 (Acier) |
| **Charge** | I | 3 PA, portée 2–4, en ligne, 1/tour, relance 2 t. | charge en ligne jusqu'au contact (effets suivants au contact seulement) ; 6–9 Acier | 7,5 dégâts | 2,5 dégâts | 11,25 dégâts | rang 3 : +1 portée<br>rang 5 : relance 1 t. |
| **Cri de guerre** | II (5000 rép.) | 3 PA, portée soi, cercle de rayon 2, sans ligne de vue, 1/tour, relance 4 t. | +4–6 Dommages (2 t.) aux alliés | — | — | — | rang 3 : relance 3 t.<br>rang 5 : zone de taille 3 |
| **Fendoir** | II (15000 rép.) | 5 PA, portée 1, 1/tour | 16–22 Acier | 19 dégâts | 3,8 dégâts | 28,5 dégâts | rang 3 : +5 % critique<br>rang 5 : coût 4 PA |

### Rôdeur

*Tire de loin, file entre les arbres et prétend toujours connaître un raccourci.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Flèche** | I | 3 PA, portée 2–6, 2/tour | 5–8 Tempête | 6,5 dégâts | 2,17 dégâts | 9,75 dégâts | — |
| **Tir perçant** | I | 4 PA, portée 3–7, 1/tour | 8–11 Acier | 9,5 dégâts | 2,38 dégâts | 14,25 dégâts | — |
| **Coup de dague** | I | 2 PA, portée 1, 2/tour | 3–5 Acier | 4 dégâts | 2 dégâts | 6 dégâts | — |
| **Roulade** | I | 2 PA, portée 1–2, sans ligne de vue, 1/tour, relance 2 t. | téléportation sur la case | — | — | — | — |
| **Collet** | I | 3 PA, portée 1–4, sans ligne de vue, 1/tour, relance 2 t. | piège invisible : [7–10 Acier aux ennemis ; −2 PM au prochain tour aux ennemis] | — | — | — | — |

### Théologue

*Soigneur sacré. Bénit les alliés, sermonne les ennemis, et cite des textes que personne n'a lus.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Châtiment** | I | 4 PA, portée 2–5, 2/tour | 8–12 Sacré | 10 dégâts | 2,5 dégâts | 15 dégâts | — |
| **Imposition des mains** | I | 3 PA, portée 0–3, 1/tour | soin 12–18 (Sacré) | 15 soin | 5 soin | 22,5 soin | — |
| **Rempart de foi** | I | 2 PA, portée 0–3, 1/tour, relance 2 t. | bouclier 12–16 (Sacré) | 14 bouclier | 7 bouclier | 21 bouclier | — |
| **Sermon** | I | 4 PA, portée 1–5, croix latine, en ligne, 1/tour | 4–7 Sacré aux ennemis ; soin 4–7 (Sacré) aux alliés | 5,5 dégâts, 5,5 soin | 1,38 dégâts, 1,38 soin | 8,25 dégâts, 8,25 soin | — |
| **Absolution** | I | 3 PA, portée 0–5, 1/tour, relance 2 t., critique 0 % | retire les bonus aux ennemis ; retire les malus et les poisons aux alliés | — | — | — | — |
