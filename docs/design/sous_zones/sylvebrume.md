# Sylvebrume agrandie : sous-zones des Mycéliens et des Arkhés

Proposition détaillée du 23/11/2026, **à valider par l'auteur** (GDD § 3.5). Rien n'est produit. Même gabarit et
mêmes règles que [Crasse-Roc](crasse_roc.md) : 6 cartes, paliers 1 et 2, 3 familles, une élite, un mini-boss à
3 phases (jamais de soin), 3 quêtes de race (condition `race`) dont la dernière mène à la chaîne commune du camp
neutre (Clairière de la Lisière, `sylvebrume_0_0`) ; carte de départ avec Pierre de Passage (10 brumes), maison et
enclume ; une ressource de monstre par famille (même procédé, équilibre général gardé) ; calque `placement`, bois
et minerai. Échelle actuelle de Sylvebrume : palier 1 de 14 à 68 PV (arbres), palier 2 de 54 à 59 PV, mini-boss 300 PV.
Givre puis Acier dominants dans la zone.

## 1. Le Bois-Farceur (Mycéliens, à l'est ; nom à revoir)

**Produit le 24/11/2026** (`sz_bois_farceur.py`, à valider) : `bois_farceur_x_y` = `sylvebrume_(x+3)_y`. La race n'existe
pas encore : seule la secondaire *Démenti* est dans le jeu ; les 3 quêtes de race sont écrites (`QUETES_RACE`). Élites :
Limace reine, Pied-de-Mouton ancestral, Grand Réseau errant. Phase 2 de la Rumeur sans échos (téléportation et Ragot).
Apparences provisoires (limaces en grouilleurs, vesses et Rumeur en morilles, mycéliums en arbres vivants pâles).

```
y=0  ⇠ Bosquet des Cerfs (sylvebrume_2_0)   [Rond des Rumeurs 1 *] ── [Sous-bois des Spores 1]
                                                   │                         │
y=1  ⇠ Scierie de Brumerive (sylvebrume_2_1) [Souche-Relais 1-2] ─── [Humus profond 2]
                                                   │                         │
y=2                                          [Cave à champignons 2] ─ [Cœur du Réseau ☠ 2]
```

Ambiance : sous-bois de ronds de champignons et de mycélium. Par leurs racines, les Mycéliens entendent tout ce
qui se dit partout et n'en font rien ; ils colportent les ragots d'un camp à l'autre et renient les morilles
grincheuses, cousines mal élevées. Identifiants `bois_farceur_x_y` (provisoires, comme le nom).

| Carte | Palier | Groupes | Récolte | PNJ |
|---|---|---|---|---|
| `bois_farceur_0_0` Rond des Rumeurs (départ) | 1 | limaces seules ou par 2 | bois | Pierre, maison (dans une souche), enclume ; Doyenne Lamelle, maîtresse de la Voie |
| `bois_farceur_1_0` Sous-bois des Spores | 1 | limaces, vesses | bois | Tante Volve, qui sait déjà ce que tu vas dire (et le répète) |
| `bois_farceur_0_1` Souche-Relais | 1-2 | vesses, un mycélium | — | Facteur Hyphe, « relais officiel des ragots » |
| `bois_farceur_1_1` Humus profond | 2 | mycéliums, vesses | minerai | — |
| `bois_farceur_0_2` Cave à champignons | 2 | mycéliums par 2-3, l'élite | minerai | — |
| `bois_farceur_1_2` Cœur du Réseau | 2 (boss) | la Rumeur ; 2 mycéliums | — | — |

| Monstre | Palier | PV / PA / PM | Élément | Rôle et sorts |
|---|---|---|---|---|
| **Limace gourmande** | 1 (faible) | 16 / 5 / 3 | Givre | Elle mange les Mycéliens, qui en font tout un drame. *Bave froide* (portée 4 : menace 7, −1 PM), *Suçon* (mêlée). |
| **Vesse-de-loup bavarde** | 1 (fort) | 24 / 6 / 2 | Givre | Champignon sauvage qui crache des spores en racontant sa vie. *Nuage de spores* (zone, portée 5 : menace 7, poison 2 tours), *Bavardage* (−1 PA, portée 3). IA distance. |
| **Mycélium errant** | 2 | 55 / 6 / 3 | Acier | Réseau de filaments qui s'est perdu. *Filaments* (attirance 2, portée 4), *Étreinte racinaire* (mêlée, état enraciné 1 tour). |
| **Pied-de-Mouton ancestral** (élite des vesses) | 2 | 80 / 7 / 2 | Givre | *Nuage de spores* renforcé, *Ragot* (−10 % de dégâts aux ennemis à 3 cases). IA soutien. |
| **La Rumeur** (mini-boss) | 2 | 300 / 7 / 3 | Givre et Acier | Un ragot devenu si gros qu'il a pris corps dans le réseau. Réapparition 45-60 s. |

**Phases de la Rumeur** : 1. *On dit que…* (100-70 %) : distance, *Bavardage*, *Nuage de spores*. 2. *Il paraît que…*
(70-30 %) : elle se démultiplie en 2 « échos » (invocations à 1 PV qui répètent ses sorts) et se téléporte de champignon
en champignon. 3. *Tout le monde le sait !* (sous 30 %) : plus d'échos ; mêlée Acier, *Étreinte racinaire* sur 2 cases,
+20 % de résistances.

**Quêtes de race (`race: mycelien`, cèpe, girolle et amanite)** : 1. **Premier ragot** (Lamelle) : vaincre 3 limaces et
rapporter « ce qu'elles disaient » (tutoriel). 2. **Le relais est en panne** (Hyphe) : vaincre 3 vesses qui brouillent le
réseau, rapporter 5 bois pour la Souche-Relais. 3. **Correspondant à la Lisière** (Lamelle) : on t'envoie écouter les elfes
de près : parler au chef de la Clairière de la Lisière, première quête de la chaîne du camp. Secondaire : **Démenti**
(Tante Volve), vaincre la Rumeur.

## 2. Les Sources primordiales (Arkhés, au nord)

**Produites le 24/11/2026** (`sz_sources.py`, à valider) : `sources_x_y` = `sylvebrume_x_(y-1)`, départ de l'Arkhé et de
ses 3 variantes. Simplifications : un seul Gardien de source (Acier et Givre), mal-éclos à jets de Flamme et de Givre,
Crise d'identité = −10 % de résistance Flamme et Givre aux ennemis proches. Élites : Grande Étincelle, Grand Mal-Éclos,
Gardien du Puits. Le débat des Sages : parler aux 3 autres Sages puis revenir à Ferrugine. Apparences reprises des Arkhés.

```
y=-2 [Glacier source 2] ──────────── [Puits des Origines ☠ 2]
          │                                  │
y=-1 [Brasier source 1-2] ────────── [Orage source 2]
          │                                  │
y=0  [Bassin des Éclosions 1 *] ── [Forge source 1]
  ⇡ Clairière de la Lisière (sylvebrume_0_0)  ⇡ Futaie ancienne (sylvebrume_1_0)
```

Ambiance : une clairière où jaillissent les quatre éléments, une source par variante (forge, brasier, orage,
glacier). Les Arkhés y naissent ; les élémentaires « mal éclos » se disputent pour savoir quel élément est le meilleur.
Éléments mélangés (exception à la dominante de la zone). Identifiants `sources_x_y`.

| Carte | Palier | Groupes | Récolte | PNJ |
|---|---|---|---|---|
| `sources_0_0` Bassin des Éclosions (départ, toutes variantes) | 1 | étincelles seules ou par 2 | bois | Pierre, maison, enclume ; Ancienne Prima, maîtresse de la Voie |
| `sources_1_0` Forge source | 1 | étincelles, mal-éclos | minerai | Sage Ferrugine (Acier), persuadé que l'Acier est le meilleur élément |
| `sources_0_1` Brasier source | 1-2 | mal-éclos, un gardien | bois | Sage Cendrine (Flamme), persuadée du contraire |
| `sources_1_1` Orage source | 2 | gardiens, mal-éclos | minerai | Sage Fulgur (Tempête), qui coupe la parole à tout le monde |
| `sources_0_2` Glacier source | 2 | gardiens par 2-3, l'élite | minerai | Sage Frimaire (Givre), qui ne s'énerve jamais, c'est pire |
| `sources_1_2` Puits des Origines | 2 (boss) | l'Indécis ; 2 gardiens | — | — |

| Monstre | Palier | PV / PA / PM | Élément | Rôle et sorts |
|---|---|---|---|---|
| **Étincelle folle** | 1 (faible) | 14 / 5 / 4 | Flamme ou Tempête (au hasard) | *Crépitement* (mêlée), *Saut* (téléportation de 2 cases). |
| **Élémentaire mal éclos** | 1 (fort) | 26 / 6 / 3 | celui de sa source | Arkhé raté qui hésite encore. *Jet élémentaire* (portée 4 : menace 7), *Crise d'identité* (change d'élément chaque tour). |
| **Gardien de source** | 2 | 55 / 6 / 3 | celui de sa source (Acier, Flamme, Tempête, Givre) | *Coup de source* (mêlée), *Jaillissement* (zone en ligne, portée 5), résistance à son élément. Quatre variantes de couleur, une par source. |
| **Grand Mal-Éclos** (élite des mal-éclos) | 2 | 85 / 7 / 3 | les quatre | *Crise d'identité* qui touche aussi les ennemis à 2 cases (leurs résistances tournent). |
| **L'Indécis** (mini-boss) | 2 | 300 / 7 / 3 | les quatre | Le premier Arkhé, qui n'a jamais choisi son élément. Réapparition 45-60 s. |

**Phases de l'Indécis** (une par tranche, jamais de soin) : 1. *Acier* (100-70 %) : mêlée lourde, résistances hautes.
2. *Tempête puis Givre* (70-30 %) : tireur, *Jaillissement* et ralentissements, change d'élément tous les 2 tours.
3. *Flamme* (sous 30 %) : « Finalement, le feu ! » +2 PM, mêlée Flamme +20 %, brûlure.

**Quêtes de race (`race: arkhe` et variantes)** : 1. **Éclosion** (Prima) : vaincre 3 étincelles folles (tutoriel).
2. **Le débat des Sages** (les quatre Sages) : visiter les quatre sources, vaincre 2 mal-éclos et rapporter 5 minerais
pour « départager » les Sages (qui restent en désaccord). 3. **Ouverture au monde** (Prima) : aller voir comment vivent
les autres peuples : parler au chef de la Clairière de la Lisière, première quête de la chaîne du camp. Secondaire :
**Choisis-toi** (Sage Frimaire), vaincre l'Indécis.
