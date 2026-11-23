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
qui débloque et donne des **points de maîtrise** à répartir : **20** par palier (`CLASS_POINTS_PER_TIER`), puis au rythme du dernier palier, sans plafond.
Monter au rang *n* coûte *n* points : rang 5 = **15 points** par sort ou compétence.

| Palier | Réputation | Points de maîtrise gagnés | Niveau équivalent |
|---|---|---|---|
| Inconnu | 0 | 0 | 1 |
| Apprenti | 1000 | 20 | 7 |
| Compagnon | 5000 | 40 | 12 |
| Vétéran | 13000 | 60 | 18 |
| Maître | 29000 | 80 | 23 |
| Légende | 61000 | 100 | 30 |

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
| KILL_REPUTATION_PER_TIER | 10 | réputation par palier d'un monstre vaincu, au facteur de difficulté, partagée entre les joueurs |
| STAT_PER_PA | 0,03 | points de la caractéristique de l'élément par PA à effet réel |
| VITALITY_PER_HP | 0,02 | Vitalité par PV réellement perdu |
| MAX_PA_PER_COMBAT | 60 | PA comptés au plus par combat |
| MAX_HP_PER_COMBAT | 200 | PV perdus comptés au plus par combat |
| MIN_STAT_PACE | 0,2 | rythme minimal près du plafond : × max(0,2, 1 − points / plafond) |

Tout est multiplié par le facteur de difficulté (somme des paliers des monstres / somme des
paliers de réputation des joueurs, Inconnu compté 1). Exemple : 60 PA à effet réel à facteur 1 = 120 de réputation et 1,8
point(s) de caractéristique (avant ralentissement).

## Races

| Race | Camp | Départ | Passif | Effets du passif | Sort de race |
|---|---|---|---|---|---|
| **Arkhé** | neutre | sylvebrume_0_0 | Cœur élémentaire | coeur_elementaire +5 | Éruption |
| **Arkhé** | neutre | sylvebrume_0_0 | Cœur élémentaire | coeur_elementaire +5 | Éruption |
| **Arkhé** | neutre | sylvebrume_0_0 | Cœur élémentaire | coeur_elementaire +5 | Éruption |
| **Arkhé** | neutre | sylvebrume_0_0 | Cœur élémentaire | coeur_elementaire +5 | Éruption |
| **Elfe** | neutre | sylvebrume_0_0 | Œil perçant | portee +1 | Pas léger |
| **Géant** | allie | brumerive_0_0 | Carrure | pv_max +10 | Coup de semelle |
| **Gobelin** | ennemi | crasse_roc_0_0 | Chapardeur | prospection +20, ecus +20 | Coup bas |
| **Humain** | allie | brumerive_0_0 | Polyvalence | reputation_metier +10 | Ralliement |
| **Nain** | allie | brumerive_0_0 | Peau de pierre |  | — |
| **Orc** | ennemi | crasse_roc_0_0 | Peau épaisse | reduction_melee +10 | Cri de guerre |
| **Squelette** | ennemi | crasse_roc_0_0 | Déjà mort | deja_mort +1 | Remonter les os |

| Sort de race | Caractéristiques | Effets | Maîtrise |
|---|---|---|---|
| **Éruption** | 3 PA, portée soi, cercle de rayon 1, sans ligne de vue, 1/tour, relance 3 t. | 4–7 Flamme aux ennemis | — |
| **Éruption** | 3 PA, portée soi, cercle de rayon 1, sans ligne de vue, 1/tour, relance 3 t. | 4–7 Acier aux ennemis | — |
| **Éruption** | 3 PA, portée soi, cercle de rayon 1, sans ligne de vue, 1/tour, relance 3 t. | 4–7 Givre aux ennemis | — |
| **Éruption** | 3 PA, portée soi, cercle de rayon 1, sans ligne de vue, 1/tour, relance 3 t. | 4–7 Tempête aux ennemis | — |
| **Pas léger** | 2 PA, portée 1–3, sans ligne de vue, 1/tour, relance 3 t. | téléportation sur la case | — |
| **Coup de semelle** | 3 PA, portée 1, 1/tour, relance 2 t. | 5–8 Acier ; poussée de 2 case(s) | — |
| **Coup bas** | 3 PA, portée 1, 1/tour | 4–7 Tempête ; −1 PM au prochain tour | — |
| **Ralliement** | 1 PA, portée soi, sans ligne de vue, 1/tour, relance 4 t. | +2 PA tout de suite | — |
| **Cri de guerre** | 3 PA, portée soi, cercle de rayon 2, sans ligne de vue, 1/tour, relance 4 t. | +10 % dégâts infligés (2 t.) aux alliés | — |
| **Remonter les os** | 2 PA, portée soi, sans ligne de vue, 1/tour, relance 3 t. | soin 15 (Impie) | — |

## Voies

| Voie | PV | PA | PM | Initiative | Sorts de rang I | Sorts de rang II |
|---|---|---|---|---|---|---|
| **Arcaniste** | 50 | 6 | 3 | 100 | 2 | 0 |
| **Chronomancien** | 50 | 6 | 3 | 100 | 20 | 0 |
| **Démoniste** | 50 | 6 | 3 | 100 | 20 | 0 |
| **Guerrier** | 50 | 6 | 3 | 100 | 5 | 2 |
| **Myrmidon** | 50 | 6 | 3 | 100 | 20 | 0 |
| **Ombre** | 50 | 6 | 3 | 100 | 20 | 0 |
| **Paladin** | 50 | 6 | 3 | 100 | 20 | 0 |
| **Rôdeur** | 50 | 6 | 3 | 100 | 5 | 0 |
| **Théologue** | 50 | 6 | 3 | 100 | 5 | 0 |

Colonnes des sorts : *Moy.* = valeurs moyennes de base des dégâts, soins et boucliers directs (hors
horloge, glyphe et piège) ; *Moy./PA* ; *Rang 5* = moyenne avec +50 % de maîtrise. À multiplier par
(100 + puissance) / 100 en combat.

### Arcaniste

*Maître du feu, du givre et de la foudre. Lit beaucoup, court peu, explose parfois des choses par accident.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Composition** | I | 1 PA, portée soi, sans ligne de vue, critique 0 % | choisit d'un coup ses 3 états élémentaires parmi Flamme et Givre et Tempête (permanents) ; +1 PA tout de suite | — | — | — | rang 1 : +1 % par état élémentaire<br>rang 2 : +1 % par état élémentaire<br>rang 3 : +1 % par état élémentaire, ajoute +1 PA tout de suite (premier lancer du tour)<br>rang 4 : +1 % par état élémentaire<br>rang 5 : +1 % par état élémentaire, ajoute +1 PA tout de suite (premier lancer du tour) |
| **Fusion arcanique** | I | 2 PA, portée soi, sans ligne de vue, 1/tour, critique 0 % | crée le sort de la combinaison des 3 états : Flamme + Flamme + Flamme → Fournaise ; Flamme + Flamme + Givre → Choc thermique ; Flamme + Givre + Givre → Armure de givre ; Givre + Givre + Givre → Blizzard ; Tempête + Tempête + Tempête → Foudre en chaîne ; Flamme + Tempête + Tempête → Fulgurance ; Givre + Tempête + Tempête → Vent arrière ; Flamme + Flamme + Tempête → Feu de brousse ; Givre + Givre + Tempête → Bourrasque glacée ; Flamme + Givre + Tempête → Cataclysme | — | — | — | rang 3 : coût 1 PA<br>rang 5 : +1 place de sort créé |
| **Fournaise** | créé (Flamme+Flamme+Flamme) | 4 PA, portée 2–6, cercle de rayon 1, 1/tour | 9–13 Flamme aux ennemis ; glyphe (2 t.) : [3–5 Flamme aux ennemis] | 11 dégâts | 2,75 dégâts | 16,5 dégâts | — |
| **Choc thermique** | créé (Flamme+Flamme+Givre) | 4 PA, portée 1–5, 1/tour | 7–10 Flamme ; 4–6 Givre ; −10 Résistance Flamme (2 t.) | 13,5 dégâts | 3,38 dégâts | 20,25 dégâts | — |
| **Armure de givre** | créé (Flamme+Givre+Givre) | 4 PA, portée 0–3, 1/tour, relance 1 t. | bouclier 14–20 (Givre) aux alliés ; +20 Intelligence (2 t.) aux alliés | 17 bouclier | 4,25 bouclier | 25,5 bouclier | — |
| **Blizzard** | créé (Givre+Givre+Givre) | 4 PA, portée 1–5, cercle de rayon 1, 1/tour | 6–9 Givre aux ennemis ; −2 PM au prochain tour aux ennemis | 7,5 dégâts | 1,88 dégâts | 11,25 dégâts | — |
| **Foudre en chaîne** | créé (Tempête+Tempête+Tempête) | 4 PA, portée 1–6, 1/tour | 9–12 Tempête ; rebond 6–8 Tempête sur l'ennemi le plus proche (2 case(s) au plus) ; rebond 3–5 Tempête sur l'ennemi le plus proche (2 case(s) au plus) | 10,5 dégâts | 2,62 dégâts | 15,75 dégâts | — |
| **Fulgurance** | créé (Flamme+Tempête+Tempête) | 4 PA, portée 2–4, cercle de rayon 1, 1/tour, relance 1 t. | téléportation sur la case ; 7–10 Tempête aux ennemis ; 3–5 Flamme aux ennemis | 12,5 dégâts | 3,12 dégâts | 18,75 dégâts | — |
| **Vent arrière** | créé (Givre+Tempête+Tempête) | 4 PA, portée 0–4, 1/tour, relance 1 t. | +2 PM (1 t.) aux alliés ; +20 Agilité (2 t.) aux alliés ; inblocable (1 t.) aux alliés | — | — | — | — |
| **Feu de brousse** | créé (Flamme+Flamme+Tempête) | 4 PA, portée 2–6, cercle de rayon 1, 1/tour | 7–10 Flamme aux ennemis ; 3–4 Tempête aux ennemis ; poison 3–4 Flamme par tour (2 t.) aux ennemis | 12 dégâts | 3 dégâts | 18 dégâts | — |
| **Bourrasque glacée** | créé (Givre+Givre+Tempête) | 4 PA, portée 1–5, en ligne, 1/tour | 6–9 Givre ; 2–3 Tempête ; poussée de 3 case(s) ; −1 PM au prochain tour | 10 dégâts | 2,5 dégâts | 15 dégâts | — |
| **Cataclysme** | créé (Flamme+Givre+Tempête) | 4 PA, portée 2–5, cercle de rayon 1, 1/tour, relance 2 t. | 5–7 Flamme aux ennemis ; 5–7 Givre aux ennemis ; 5–7 Tempête aux ennemis ; −1 PM au prochain tour aux ennemis ; poussée de 1 case(s) aux ennemis | 18 dégâts | 4,5 dégâts | 27 dégâts | — |

### Chronomancien

*Dérègle le temps avec des pouvoirs impies. Toujours en avance, ou en retard, mais jamais à l'heure.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Horloge** | I | 3 PA, portée 3, en ligne, portée non modifiable, 1/tour | 3–5 Impie aux ennemis ; horloge (3 t.) : [1 h : 10 Givre ; 2 h : poison 5 Givre par tour (2 t.) ; 3 h : −10 Retrait PA (2 t.) ; 4 h : inblocable (1 t.) ; 5 h : −10 Résistance Impie (1 t.) ; 6 h : −1 PM (1 t.) ; 7 h : 10 Tempête ; 8 h : poison 5 Tempête par tour (2 t.) ; 9 h : −10 Retrait PM (2 t.) ; 10 h : insoignable (1 t.) ; 11 h : −10 % dégâts infligés (1 t.) ; 12 h : −1 PA (1 t.)] aux ennemis | 4 dégâts | 1,33 dégâts | 6 dégâts | rang 3 : +1 tour de cadran<br>rang 5 : +1 portée |
| **Tic** | I | 2 PA, portée 1–6, 2/tour | 4–6 Impie ; +1 h sur l'horloge | 5 dégâts | 2,5 dégâts | 7,5 dégâts | rang 3 : 3 fois par tour<br>rang 5 : ajoute +1 h sur l'horloge (en coup critique) |
| **Tac** | I | 2 PA, portée 1–6, 2/tour | 4–6 Impie ; -1 h sur l'horloge | 5 dégâts | 2,5 dégâts | 7,5 dégâts | rang 3 : 3 fois par tour<br>rang 5 : ajoute -1 h sur l'horloge (en coup critique) |
| **Avance rapide** | I | 4 PA, portée 1–6, 1/tour | 9–12 Impie ; +3 h sur l'horloge | 10,5 dégâts | 2,62 dégâts | 15,75 dégâts | rang 3 : +10 % critique<br>rang 5 : coût 3 PA |
| **Retour en arrière** | I | 4 PA, portée 1–6, 1/tour | 9–12 Impie ; -3 h sur l'horloge | 10,5 dégâts | 2,62 dégâts | 15,75 dégâts | rang 3 : +10 % critique<br>rang 5 : coût 3 PA |
| **Contretemps** | I | 3 PA, portée 1–6, 1/tour, relance 2 t. | 6–8 Impie ; +6 h sur l'horloge | 7 dégâts | 2,33 dégâts | 10,5 dégâts | rang 3 : relance 1 t.<br>rang 5 : coût 2 PA |
| **Arrêt sur image** | I | 2 PA, portée 1–6, 1/tour, relance 1 t. | l'heure atteinte rejoue son effet aux ennemis | — | — | — | rang 3 : coût 1 PA<br>rang 5 : relance 0 t. |
| **Rendez-vous** | I | 2 PA, portée 1–5, sans ligne de vue, 1/tour, relance 2 t. | échange de place | — | — | — | rang 3 : +1 portée<br>rang 5 : relance 1 t. |
| **Sursis** | I | 3 PA, portée soi, 1/tour, relance 3 t. | rend 50 % des PV perdus depuis son tour précédent | — | — | — | rang 3 : coût 2 PA<br>rang 5 : relance 2 t. |
| **Accélération** | I | 2 PA, portée 0–3, 1/tour, relance 3 t. | +1 PM (2 t.) aux alliés ; +20 Agilité (2 t.) aux alliés ; +20 Perception (2 t.) aux alliés | — | — | — | rang 3 : +1 portée<br>rang 5 : relance 2 t. |
| **Pulsion temporelle** | I | 3 PA, portée 1–6, 2/tour | pulsion 12–16 Givre au début du 2e tour de la cible aux ennemis | — | — | — | rang 3 : +10 % critique<br>rang 5 : coût 2 PA |
| **Seconde glacée** | I | 2 PA, portée 1–6, 3/tour | 4–6 Givre | 5 dégâts | 2,5 dégâts | 7,5 dégâts | rang 3 : +10 % critique<br>rang 5 : +1 portée |
| **Hiver éternel** | I | 4 PA, portée 2–6, cercle de rayon 1, 1/tour | 6–8 Givre aux ennemis | 7 dégâts | 1,75 dégâts | 10,5 dégâts | rang 3 : coût 3 PA<br>rang 5 : ajoute −1 PM (1 t.) aux ennemis |
| **Fin des temps** | I | 5 PA, portée 1–4, 1/tour | 18–24 Givre | 21 dégâts | 4,2 dégâts | 31,5 dégâts | rang 3 : +1 portée<br>rang 5 : coût 4 PA |
| **Écho du passé** | I | 3 PA, portée 1–6, 1/tour | 3–4 Givre par manipulation subie (6 au plus) | 3,5 dégâts | 1,17 dégâts | 5,25 dégâts | rang 3 : +10 % critique<br>rang 5 : coût 2 PA |
| **Déjà-vu** | I | 3 PA, portée 1–6, 1/tour, relance 2 t. | retour à sa case d'il y a 1 tour(s) aux ennemis ; −1 PM (1 t.) aux ennemis | — | — | — | rang 3 : relance 1 t.<br>rang 5 : ajoute −1 PA (1 t.) aux ennemis |
| **Saut dans le futur** | I | 3 PA, portée 1–5, 1/tour, relance 3 t. | envoi 2 tour(s) dans le futur aux ennemis | — | — | — | rang 3 : +1 portée<br>rang 5 : relance 2 t. |
| **Point de départ** | I | 1 PA, portée soi, 1/tour, relance 2 t. | retour à sa case d'il y a 1 tour(s) | — | — | — | rang 3 : relance 1 t.<br>rang 5 : ajoute +1 PM (1 t.) |
| **Cristal du temps** | I | 2 PA, portée soi, 1/tour, relance 2 t. | bouclier 12–16 (Givre) ; inamovible (1 t.) | 14 bouclier | 7 bouclier | 21 bouclier | rang 3 : coût 1 PA<br>rang 5 : ajoute +10 Résistance Givre (1 t.) |
| **Heure d'avance** | I | 2 PA, portée 0–4, 1/tour, relance 3 t. | envoi 1 tour(s) dans le futur aux alliés | — | — | — | rang 3 : +1 portée<br>rang 5 : relance 2 t. |

### Démoniste

*Démoniste agréé, ancien sous-traitant du Mordor. Ses démons pointent à l'heure (pas une minute de plus, la convention collective des Enfers est formelle) ; lui brûle tout ce qui refuse de signer.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Appel du Diablotin** | I | 3 PA, portée 1–2, relance 1 t. | invocation | — | — | — | — |
| **Trait impie** | I | 3 PA, portée 1–6, 2/tour | 7–9 Impie aux ennemis | 8 dégâts | 2,67 dégâts | 12 dégâts | rang 3 : +1 portée<br>rang 5 : +10 % critique |
| **Nuée de chauves-souris** | I | 4 PA, portée 2–6, cercle de rayon 1, 1/tour | 6–8 Impie aux ennemis | 7 dégâts | 1,75 dégâts | 10,5 dégâts | rang 3 : coût 3 PA<br>rang 5 : ajoute −1 Portée (1 t.) aux ennemis |
| **Main du Malin** | I | 5 PA, portée 1–3, 1/tour | 14–18 Impie aux ennemis | 16 dégâts | 3,2 dégâts | 24 dégâts | rang 3 : +1 portée<br>rang 5 : +15 % critique |
| **Sacrifice** | I | 2 PA, portée 1–6, sans ligne de vue, 1/tour | sacrifice | — | — | — | rang 3 : coût 1 PA<br>rang 5 : ajoute soin 10 (Impie) |
| **Chaînes infernales** | I | 3 PA, portée 1–5 | −2 PM au prochain tour aux ennemis | — | — | — | rang 3 : +1 portée<br>rang 5 : ajoute −1 PA (1 t.) aux ennemis |
| **Effroi** | I | 3 PA, portée 1–4, 1/tour | poussée de 2 case(s) aux ennemis ; −1 PA (1 t.) aux ennemis | — | — | — | rang 3 : coût 2 PA<br>rang 5 : ajoute 5–7 Impie aux ennemis |
| **Permutation** | I | 1 PA, portée 1–8, sans ligne de vue, 1/tour | échange de place avec un serviteur | — | — | — | rang 3 : +2 portée<br>rang 5 : ajoute +1 PM (1 t.) |
| **Appel du Molosse** | I | 4 PA, portée 1–2, relance 2 t. | invocation | — | — | — | — |
| **Appel de la Succube** | I | 3 PA, portée 1–2, relance 2 t. | invocation | — | — | — | — |
| **Mise à feu** | I | 2 PA, portée 1–6, cercle de rayon 1, 1/tour | 3–4 Flamme aux ennemis | 3,5 dégâts | 1,75 dégâts | 5,25 dégâts | rang 3 : +1 portée<br>rang 5 : embrase 1 |
| **Escarbille** | I | 2 PA, portée 1–7, 3/tour | 5–6 Flamme aux ennemis | 5,5 dégâts | 2,75 dégâts | 8,25 dégâts | rang 3 : +10 % critique<br>rang 5 : +1 portée |
| **Pluie de soufre** | I | 4 PA, portée 3–8, cercle de rayon 1, 1/tour | 7–9 Flamme aux ennemis | 8 dégâts | 2 dégâts | 12 dégâts | rang 3 : coût 3 PA<br>rang 5 : +10 % critique |
| **Fournaise** | I | 5 PA, portée 1–4, cercle de rayon 1, 1/tour | 13–16 Flamme aux ennemis | 14,5 dégâts | 2,9 dégâts | 21,75 dégâts | rang 3 : +1 portée<br>rang 5 : embrase 1 |
| **Explosion de cendres** | I | 3 PA, portée 1–6, cercle de rayon 2, 1/tour | cendres aux ennemis | — | — | — | rang 3 : coût 2 PA<br>rang 5 : +10 % critique |
| **Mur de flammes** | I | 3 PA, portée 2–5, 1/tour | glyphe (1 t.) : [6–8 Flamme aux ennemis] | — | — | — | rang 3 : +1 portée<br>rang 5 : zone de taille 2 |
| **Fumées âcres** | I | 3 PA, portée 1–5, 1/tour | −2 PM au prochain tour aux ennemis | — | — | — | rang 3 : +1 portée<br>rang 5 : ajoute −1 PA (1 t.) aux ennemis |
| **Pas de braise** | I | 2 PA, portée 1–3, sans ligne de vue, 1/tour | téléportation sur la case | — | — | — | rang 3 : coût 1 PA<br>rang 5 : +1 portée |
| **Peau de cendre** | I | 2 PA, portée soi, 1/tour | bouclier 8–10 (Flamme) | 9 bouclier | 4,5 bouclier | 13,5 bouclier | rang 3 : coût 1 PA<br>rang 5 : ajoute +10 Résistance Flamme (1 t.) |
| **Feu de camp** | I | 3 PA, portée 0–4, cercle de rayon 1, 1/tour | soin 5–7 (Flamme) aux alliés | 6 soin | 2 soin | 9 soin | rang 3 : +1 portée<br>rang 5 : ajoute +5 Dommages (1 t.) aux alliés |

### Guerrier

*Au contact, il encaisse et rend les coups. Réfléchit après, de préférence.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Frappe** | I | 3 PA, portée 1, 2/tour | 8–12 Acier | 10 dégâts | 3,33 dégâts | 15 dégâts | rang 3 : +5 % critique<br>rang 5 : ajoute −1 PM au prochain tour aux ennemis |
| **Lancer de hache** | I | 4 PA, portée 2–5, 1/tour | 6–9 Acier | 7,5 dégâts | 1,88 dégâts | 11,25 dégâts | rang 3 : +1 portée<br>rang 5 : coût 3 PA |
| **Tourbillon** | I | 4 PA, portée soi, cercle de rayon 1 (sans le lanceur), sans ligne de vue, 1/tour | 7–10 Acier | 8,5 dégâts | 2,12 dégâts | 12,75 dégâts | rang 3 : ajoute poussée de 1 case(s)<br>rang 5 : zone de taille 2 |
| **Second souffle** | I | 2 PA, portée soi, sans ligne de vue, 1/tour, relance 3 t. | soin 12–18 (Acier) | 15 soin | 7,5 soin | 22,5 soin | rang 3 : relance 2 t.<br>rang 5 : ajoute bouclier 9–14 (Acier) |
| **Charge** | I | 3 PA, portée 2–4, en ligne, 1/tour, relance 2 t. | charge en ligne jusqu'au contact (effets suivants au contact seulement) ; 6–9 Acier | 7,5 dégâts | 2,5 dégâts | 11,25 dégâts | rang 3 : +1 portée<br>rang 5 : relance 1 t. |
| **Cri de guerre** | II (0 rép.) | 3 PA, portée soi, cercle de rayon 2, sans ligne de vue, 1/tour, relance 4 t. | +4–6 Dommages (2 t.) aux alliés | — | — | — | rang 3 : relance 3 t.<br>rang 5 : zone de taille 3 |
| **Fendoir** | II (0 rép.) | 5 PA, portée 1, 1/tour | 16–22 Acier | 19 dégâts | 3,8 dégâts | 28,5 dégâts | rang 3 : +5 % critique<br>rang 5 : coût 4 PA |

### Myrmidon

*Myrmidon de la Légion des Boucliers Réglementaires. A juré de ne jamais reculer, surtout parce qu'on ne lui a jamais appris la marche arrière.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Serrer les rangs** | I | 1 PA, portée soi, 1/tour | blindage | — | — | — | rang 3 : ajoute blindage<br>rang 5 : ajoute +3 reduction_degats (2 t.) |
| **Coup de bouclier** | I | 3 PA, portée 1, 2/tour | 8–11 Acier aux ennemis ; blindage | 9,5 dégâts | 3,17 dégâts | 14,25 dégâts | rang 3 : +5 % critique<br>rang 5 : ajoute −1 PM (1 t.) aux ennemis |
| **Bouclier lancé** | I | 4 PA, portée 2–5, 1/tour | 6–9 Acier aux ennemis ; rebond 4–6 Acier sur l'ennemi le plus proche (2 case(s) au plus) ; blindage | 7,5 dégâts | 1,88 dégâts | 11,25 dégâts | rang 3 : +1 portée<br>rang 5 : coût 3 PA |
| **Écrasement** | I | 5 PA, portée 1, 1/tour | 16–21 Acier aux ennemis ; blindage | 18,5 dégâts | 3,7 dégâts | 27,75 dégâts | rang 3 : +5 % critique<br>rang 5 : coût 4 PA |
| **Retour à l'envoyeur** | I | 4 PA, portée 1, 1/tour | 10–13 Acier aux ennemis | 11,5 dégâts | 2,88 dégâts | 17,25 dégâts | rang 3 : +5 % critique<br>rang 5 : +1 portée |
| **Coup d'épaule** | I | 2 PA, portée 1, 1/tour | 3–5 Acier aux ennemis ; poussée de 2 case(s) aux ennemis ; blindage | 4 dégâts | 2 dégâts | 6 dégâts | rang 3 : ajoute −1 PM (1 t.) aux ennemis<br>rang 5 : coût 1 PA |
| **Démolition** | I | 3 PA, portée 1–2, cercle de rayon 1, 1/tour, relance 1 t. | demolition ; 7–9 Acier aux ennemis ; blindage | 8 dégâts | 2,67 dégâts | 12 dégâts | rang 3 : +1 portée<br>rang 5 : zone de taille 2 |
| **Bélier** | I | 3 PA, portée 2–5, sans ligne de vue, en ligne, 1/tour, relance 2 t. | charge en ligne jusqu'au contact (effets suivants au contact seulement) ; 5–7 Acier aux ennemis ; blindage | 6 dégâts | 2 dégâts | 9 dégâts | rang 3 : +1 portée<br>rang 5 : relance 1 t. |
| **Peau de fer** | I | 2 PA, portée soi, 1/tour, relance 3 t. | +5 reduction_degats (2 t.) | — | — | — | rang 3 : relance 2 t.<br>rang 5 : ajoute blindage |
| **Garde** | I | 2 PA, portée 1–3, sans ligne de vue, 1/tour, relance 2 t. | garde (2 t.) aux alliés | — | — | — | rang 3 : +1 portée<br>rang 5 : ajoute bouclier 6–8 (Acier) aux alliés |
| **Morsure du froid** | I | 2 PA, portée 1–2, 2/tour | 4–6 Givre aux ennemis ; gelure aux ennemis | 5 dégâts | 2,5 dégâts | 7,5 dégâts | rang 3 : +1 portée<br>rang 5 : ajoute gelure aux ennemis |
| **Coup glacé** | I | 3 PA, portée 1, 2/tour | 8–11 Givre aux ennemis ; gelure aux ennemis | 9,5 dégâts | 3,17 dégâts | 14,25 dégâts | rang 3 : +5 % critique<br>rang 5 : ajoute −1 PM au prochain tour aux ennemis |
| **Souffle hivernal** | I | 4 PA, portée 1–3, en ligne, 1/tour | 6–8 Givre aux ennemis ; gelure aux ennemis ; gel | 7 dégâts | 1,75 dégâts | 10,5 dégâts | rang 3 : +1 portée<br>rang 5 : coût 3 PA |
| **Avalanche** | I | 5 PA, portée 1, cercle de rayon 1, 1/tour | 13–17 Givre aux ennemis ; gelure aux ennemis | 15 dégâts | 3 dégâts | 22,5 dégâts | rang 3 : +5 % critique<br>rang 5 : coût 4 PA |
| **Bris de glace** | I | 4 PA, portée 1, 1/tour | 9–12 Givre aux ennemis | 10,5 dégâts | 2,62 dégâts | 15,75 dégâts | rang 3 : +5 % critique<br>rang 5 : +1 portée |
| **Entrave** | I | 2 PA, portée 1–4, 1/tour | −2 PM au prochain tour aux ennemis ; gelure aux ennemis | — | — | — | rang 3 : +1 portée<br>rang 5 : ajoute −1 PA (1 t.) aux ennemis |
| **Coup sur le casque** | I | 3 PA, portée 1, 1/tour, relance 5 t. | 3–5 Givre aux ennemis ; assomme (1 t.) aux ennemis | 4 dégâts | 1,33 dégâts | 6 dégâts | rang 3 : relance 4 t.<br>rang 5 : ajoute gelure aux ennemis |
| **Glissade** | I | 3 PA, portée 2–5, en ligne, 1/tour, relance 2 t. | charge en ligne jusqu'au contact (effets suivants au contact seulement) | — | — | — | rang 3 : +1 portée<br>rang 5 : relance 1 t. |
| **Carapace de glace** | I | 2 PA, portée soi, 1/tour, relance 1 t. | bouclier 8–10 (Givre) ; carapace_de_glace (2 t.) | 9 bouclier | 4,5 bouclier | 13,5 bouclier | rang 3 : coût 1 PA<br>rang 5 : ajoute +10 Résistance Givre (2 t.) |
| **Défi** | I | 2 PA, portée 1–5, 1/tour, relance 2 t. | attire de 2 case(s) aux ennemis ; provoque (2 t.) aux ennemis | — | — | — | rang 3 : +1 portée<br>rang 5 : relance 1 t. |

### Ombre

*Assassin à la pige de la Confrérie des Ombres (cotisation non remboursable). Frappe dans le dos et repart avant l'addition.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Survoltage** | I | 2 PA, portée soi, 1/tour | image | — | — | — | rang 3 : coût 1 PA<br>rang 5 : ajoute +1 PM (1 t.) |
| **Lame-éclair** | I | 3 PA, portée 1, 2/tour | 9–12 Tempête | 10,5 dégâts | 3,5 dégâts | 15,75 dégâts | rang 3 : +5 % critique<br>rang 5 : ajoute poussée de 1 case(s) |
| **Shuriken d'orage** | I | 3 PA, portée 2–6, 2/tour | 7–9 Tempête ; rebond 7–9 Tempête sur l'ennemi le plus proche (2 case(s) au plus) | 8 dégâts | 2,67 dégâts | 12 dégâts | rang 3 : +1 portée<br>rang 5 : +10 % critique |
| **Coup de tonnerre** | I | 5 PA, portée 1, 1/tour | 18–24 Tempête | 21 dégâts | 4,2 dégâts | 31,5 dégâts | rang 3 : +5 % critique<br>rang 5 : ajoute −1 PM (1 t.) |
| **Court-circuit** | I | 2 PA, portée 1–8, sans ligne de vue, 2/tour | court_circuit | — | — | — | rang 3 : +2 portée<br>rang 5 : coût 1 PA |
| **Rafale** | I | 3 PA, portée 1–3, 1/tour | 5–7 Tempête ; poussée de 2 case(s) | 6 dégâts | 2 dégâts | 9 dégâts | rang 3 : +1 portée<br>rang 5 : ajoute −1 PM (1 t.) |
| **Foudroiement** | I | 3 PA, portée 2–5, en ligne, 1/tour, relance 1 t. | téléportation sur la case ; 6–8 Tempête aux ennemis ; image | 7 dégâts | 2,33 dégâts | 10,5 dégâts | rang 3 : relance 0 t.<br>rang 5 : +1 portée |
| **Pas de l'éclair** | I | 2 PA, portée 1–4, 1/tour, relance 1 t. | téléportation sur la case ; image | — | — | — | rang 3 : +1 portée<br>rang 5 : relance 0 t. |
| **Corps électrique** | I | 2 PA, portée soi, 1/tour, relance 2 t. | bouclier 10–14 (Tempête) | 12 bouclier | 6 bouclier | 18 bouclier | rang 3 : relance 1 t.<br>rang 5 : ajoute +20 Agilité (1 t.) |
| **Vent porteur** | I | 2 PA, portée 0–4, 1/tour, relance 3 t. | +1 PM (2 t.) ; +20 Agilité (2 t.) | — | — | — | rang 3 : relance 2 t.<br>rang 5 : ajoute +1 PM (2 t.) |
| **Fondu au noir** | I | 2 PA, portée soi, 1/tour, relance 2 t. | invisible (2 t.) | — | — | — | rang 3 : coût 1 PA<br>rang 5 : relance 1 t. |
| **Surin** | I | 3 PA, portée 1, 2/tour | 8–11 Acier | 9,5 dégâts | 3,17 dégâts | 14,25 dégâts | rang 3 : +5 % critique<br>rang 5 : ajoute poison 2–3 Acier par tour (2 t.) |
| **Lame de jet** | I | 3 PA, portée 2–5, 2/tour | 7–10 Acier | 8,5 dégâts | 2,83 dégâts | 12,75 dégâts | rang 3 : +1 portée<br>rang 5 : +10 % critique |
| **Exécution** | I | 5 PA, portée 1, 1/tour | 16–20 Acier | 18 dégâts | 3,6 dégâts | 27 dégâts | rang 3 : +5 % critique<br>rang 5 : coût 4 PA |
| **Arme d'obscurité** | I | 3 PA, portée 1–5, 1/tour | arme_ombre aux ennemis | — | — | — | rang 3 : +1 portée<br>rang 5 : coût 2 PA |
| **Coupe-jarret** | I | 2 PA, portée 1, 1/tour | −2 PM (1 t.) aux ennemis | — | — | — | rang 3 : ajoute −1 PA (1 t.) aux ennemis<br>rang 5 : coût 1 PA |
| **Entaille** | I | 3 PA, portée 1, 2/tour | 5–7 Acier ; −10 Résistance Acier (2 t.) | 6 dégâts | 2 dégâts | 9 dégâts | rang 3 : +5 % critique<br>rang 5 : ajoute −1 PM (1 t.) |
| **Dans le dos** | I | 2 PA, portée 1–4, 1/tour, relance 2 t. | dans_le_dos | — | — | — | rang 3 : relance 1 t.<br>rang 5 : coût 1 PA |
| **Monde des ombres** | I | 2 PA, portée 0–4, 1/tour | monde_des_ombres | — | — | — | rang 3 : +1 portée<br>rang 5 : coût 1 PA |
| **Affûtage** | I | 1 PA, portée soi, 1/tour | +20 Force (3 t.) | — | — | — | rang 3 : ajoute +3 % Critique (3 t.)<br>rang 5 : ajoute +3 Dommages (3 t.) |

### Paladin

*Paladin breveté de l'Ordre du Saint Paratonnerre. Béni par les dieux, foudroyé par eux aussi (souvent). Persuadé d'être l'Élu, comme les 214 autres Élus de sa promotion.*

| Sort | Rang | Caractéristiques | Effets | Moy. | Moy./PA | Rang 5 | Maîtrise |
|---|---|---|---|---|---|---|---|
| **Aura de bravoure** | I | 2 PA, portée soi | aura | — | — | — | rang 3 : coût 1 PA<br>rang 5 : +1 tour d'aura |
| **Coup béni** | I | 3 PA, portée 1, 2/tour | 9–12 Sacré aux ennemis | 10,5 dégâts | 3,5 dégâts | 15,75 dégâts | rang 3 : +10 % critique<br>rang 5 : ajoute +1 PM (1 t.) |
| **Marteau lancé** | I | 3 PA, portée 2–5, 2/tour | 7–10 Sacré aux ennemis | 8,5 dégâts | 2,83 dégâts | 12,75 dégâts | rang 3 : +1 portée<br>rang 5 : +10 % critique |
| **Jugement** | I | 5 PA, portée 1, 1/tour | 20–26 Sacré aux ennemis | 23 dégâts | 4,6 dégâts | 34,5 dégâts | rang 3 : +10 % critique<br>rang 5 : coût 4 PA |
| **Onde sacrée** | I | 4 PA, portée soi, 1/tour | 8–11 Sacré aux ennemis | 9,5 dégâts | 2,38 dégâts | 14,25 dégâts | rang 3 : coût 3 PA<br>rang 5 : +10 % critique |
| **Coup de bouclier** | I | 3 PA, portée 1, 1/tour | 5–7 Sacré aux ennemis ; poussée de 2 case(s) aux ennemis | 6 dégâts | 2 dégâts | 9 dégâts | rang 3 : coût 2 PA<br>rang 5 : ajoute −1 PM (1 t.) aux ennemis |
| **Sceau de pénitence** | I | 3 PA, portée 1–4, relance 2 t. | −2 PM au prochain tour aux ennemis | — | — | — | rang 3 : +1 portée<br>rang 5 : ajoute −1 PA (1 t.) aux ennemis |
| **Ruée sainte** | I | 2 PA, portée 2–5, en ligne, relance 2 t. | charge en ligne jusqu'au contact (effets suivants au contact seulement) | — | — | — | rang 3 : +1 portée<br>rang 5 : ajoute +1 PM (1 t.) |
| **Aura de protection** | I | 2 PA, portée soi | aura | — | — | — | rang 3 : coût 1 PA<br>rang 5 : +1 tour d'aura |
| **Bénédiction** | I | 2 PA, portée 0–3, relance 3 t. | +30 Force (2 t.) aux alliés ; +30 Intelligence (2 t.) aux alliés | — | — | — | rang 3 : +1 portée<br>rang 5 : relance 2 t. |
| **Balise** | I | 2 PA, portée 1–5 | balise | — | — | — | rang 3 : +1 portée<br>rang 5 : coût 1 PA |
| **Étincelle** | I | 3 PA, portée 2–6, 2/tour | 7–10 Tempête aux ennemis | 8,5 dégâts | 2,83 dégâts | 12,75 dégâts | rang 3 : +1 portée<br>rang 5 : +10 % critique |
| **Chaîne d'éclairs** | I | 4 PA, portée 2–5, 1/tour | 7–10 Tempête aux ennemis ; rebond 7–10 Tempête sur l'ennemi le plus proche (2 case(s) au plus) | 8,5 dégâts | 2,12 dégâts | 12,75 dégâts | rang 3 : coût 3 PA<br>rang 5 : +10 % critique |
| **Foudre céleste** | I | 5 PA, portée 3–6, 1/tour | 18–24 Tempête aux ennemis | 21 dégâts | 4,2 dégâts | 31,5 dégâts | rang 3 : +10 % critique<br>rang 5 : +1 portée |
| **Surtension** | I | 3 PA, portée 1–8, sans ligne de vue, 1/tour | surtension | — | — | — | rang 3 : coût 2 PA<br>rang 5 : +2 portée |
| **Aimantation** | I | 3 PA, portée 2–5, 1/tour | attire de 3 case(s) aux ennemis | — | — | — | rang 3 : +1 portée<br>rang 5 : ajoute −1 PM au prochain tour aux ennemis |
| **Électrocution** | I | 3 PA, portée 1–5, 1/tour | 4–6 Tempête aux ennemis ; −2 PM au prochain tour aux ennemis ; −1 PA (1 t.) aux ennemis | 5 dégâts | 1,67 dégâts | 7,5 dégâts | rang 3 : +1 portée<br>rang 5 : +10 % critique |
| **Saut d'éclair** | I | 2 PA, portée 1–8, sans ligne de vue, relance 2 t. | saut_balise | — | — | — | rang 3 : coût 1 PA<br>rang 5 : relance 1 t. |
| **Bouclier statique** | I | 2 PA, portée soi, 1/tour | bouclier 12–16 (Tempête) ; +3 epines_tempete_fixes (1 t.) | 14 bouclier | 7 bouclier | 21 bouclier | rang 3 : coût 1 PA<br>rang 5 : ajoute +10 Résistance Tempête (1 t.) |
| **Paratonnerre vivant** | I | 2 PA, portée 0–4, relance 3 t. | paratonnerre aux alliés ; +1 PM (1 t.) aux alliés | — | — | — | rang 3 : +1 portée<br>rang 5 : relance 2 t. |

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
