# Brumerive agrandie : sous-zones des Nains et des Géants

Proposition détaillée du 23/11/2026, **à valider par l'auteur** (GDD § 3.5). Rien n'est produit. Même gabarit et
mêmes règles que [Crasse-Roc](crasse_roc.md) : 6 cartes, paliers 1 et 2, 3 familles, une élite, un mini-boss à
3 phases (jamais de soin), 3 quêtes de race (condition `race`) dont la dernière mène à la chaîne commune du camp
allié (Place du village, `brumerive_0_0`) ; carte de départ avec Pierre de Passage (10 brumes), maison et enclume ;
une ressource de monstre par famille (même procédé, équilibre général gardé) ; calque `placement`, bois et minerai.
Échelle actuelle de Brumerive : palier 1 environ 22 PV, palier 2 de 42 à 77 PV, mini-boss 300 PV.
Tempête dominante dans la zone.

## 1. Le Comptoir de Barbe-Fendue (Nains, au nord)

**Produit le 24/11/2026** (`sz_barbe_fendue.py`, à valider) : cartes `brumerive_1_-1` (Carreau) à `brumerive_2_-3`
(Salle des Comptes) ; `barbe_fendue_x_y` ci-dessous = `brumerive_(x+1)_(y-1)`. Élites ajoutées : Taupe contremaîtresse (taupes),
Golem de filon d'or (golems). PNJ : Durgrim explique la forge, Doyenne Brisepierre les Voies, Fendoir le Négociant marchand.
*Délocalisation* se termine chez le bourgmestre Pansu. « Vole 1 PA » = −1 PA pendant 1 tour. Apparences provisoires.

```
y=-2 [Front de taille 2] ──────── [Salle des Comptes ☠ 2]
          │                               │
y=-1 [Galerie des Péages 1-2] ── [Monte-charges 2]
          │                               │
y=0  [Carreau de la mine 1 *] ── [Terril aux Taupes 1]
  ⇡ Champs de l'est (brumerive_1_0)  ⇡ Verger des Pommeaux (brumerive_2_0)
```

Ambiance : une mine à ciel ouvert creusée dans les collines par une colonie naine venue « faire affaire » avec les
humains. La guilde des mineurs facture chaque coup de pioche, même ceux des autres. Identifiants `barbe_fendue_x_y`.

| Carte | Palier | Groupes | Récolte | PNJ |
|---|---|---|---|---|
| `barbe_fendue_0_0` Carreau de la mine (départ) | 1 | taupes seules ou par 2 | minerai | Pierre, maison, enclume ; Maître-Mineur Durgrim, maître de la Voie |
| `barbe_fendue_1_0` Terril aux Taupes | 1 | taupes, apprentis | minerai | Brunhild, comptable (« Chaque caillou a un prix. Celui-ci : trois brumes. ») |
| `barbe_fendue_0_1` Galerie des Péages | 1-2 | apprentis, un golem | bois (étais) | Péagiste Barbe-Grise |
| `barbe_fendue_1_1` Monte-charges | 2 | golems, apprentis | minerai | — |
| `barbe_fendue_0_2` Front de taille | 2 | golems par 2-3, l'élite | minerai | Vieux Tordbras, qui creuse « vers l'or » depuis 80 ans (en ligne droite) |
| `barbe_fendue_1_2` Salle des Comptes | 2 (boss) | le Grand Trésorier ; 2 golems à l'entrée | — | — |

| Monstre | Palier | PV / PA / PM | Élément | Rôle et sorts |
|---|---|---|---|---|
| **Taupe-pioche** | 1 (faible) | 18 / 5 / 4 | Acier | Taupe qui creuse plus vite que les nains (ils lui en veulent). *Griffe-pioche* (mêlée), *Galerie* (s'enterre : téléportation de 3 cases). |
| **Apprenti mineur** | 1 (fort) | 24 / 6 / 3 | Tempête | Nain en stage non payé. *Coup de pioche* (mêlée), *Lancer de lampe* (portée 4, Tempête : menace 7), *Facture* (−1 PA, portée 3). |
| **Golem de minerai** | 2 | 60 / 6 / 2 | Acier | Tas de minerai animé par contrat. *Poing de roche* (mêlée, poussée 1), *Éboulis* (zone en croix, portée 5 : menace 7). Résistance Acier. |
| **Contrôleur des Poids et Mesures** (élite des apprentis) | 2 | 80 / 7 / 3 | Tempête | *Facture* sur tout le groupe ennemi à 2 cases, *Lancer de lampe*, *Pesée* (+10 % de dégâts aux alliés). IA soutien. |
| **Grand Trésorier Orbaril** (mini-boss) | 2 | 300 / 7 / 3 | Acier et Tempête | Il compte tout, surtout ce qu'on lui doit. Réapparition 45-60 s. |

**Phases d'Orbaril** : 1. *Bilan* (100-70 %) : mêlée au marteau-tampon, *Facture*. 2. *Recouvrement* (70-30 %) :
« Vous me devez des PV. » Tireur, *Pluie de pièces* (zone, Tempête, portée 6), vole 1 PA par coup. 3. *Faillite*
(sous 30 %) : « Tout doit disparaître ! » +2 PM, mêlée Acier +20 %, plus de sort à distance.

**Quêtes de race (`race: nain`)** : 1. **Contrat d'embauche** (Durgrim) : vaincre 3 taupes-pioches, signer en bas
(tutoriel). 2. **Facture impayée** (Brunhild) : rapporter 5 minerais du Terril et vaincre 2 apprentis « qui ont
pioché sans payer ». 3. **Délocalisation** (Durgrim) : la guilde t'envoie « développer le marché humain » : parler au
chef du village sur la Place du village, première quête de la chaîne du camp. Secondaire : **Contrôle fiscal**
(Tordbras), vaincre Orbaril.

## 2. Les Hauts-Perchés (Géants, à l'ouest)

**Produits le 24/11/2026** (`sz_hauts_perches.py`, à valider) : cartes `brumerive_-1_0` (Seuil) à `brumerive_-2_2`
(Aire du Doyen) ; `hauts_perches_x_y` ci-dessous = `brumerive_(-1-x)_y`. Élites ajoutées : Agneau-Montagne (agneaux),
Grand Esprit des cimes (esprits). PNJ : Haute-Borne explique la forge, Grand-Toise Marbre les Voies, Troque-Montagne marchande.
*Ambassade* se termine chez le bourgmestre Pansu. Apparences et icônes provisoires reprises des dessins existants.

```
y=0  [Corniche aux Moutons 1] ── [Seuil des Géants 1 *] ⇢ Place du village (brumerive_0_0)
          │                              │
y=1  [Falaise du Vent 2] ────── [Bergerie trop basse 1-2] ⇢ Rives de la Brume (brumerive_0_1)
          │                              │
y=2  [Aire du Doyen ☠ 2] ────── [Col des Bourrasques 2]
```

Ambiance : corniches et falaises ventées au-dessus de la Brume. Les maisons humaines y sont trop basses (on s'y
plie en quatre), un vieux gardien met trois jours à finir sa phrase, et les moutons sont géants eux aussi.
Identifiants `hauts_perches_x_y`.

| Carte | Palier | Groupes | Récolte | PNJ |
|---|---|---|---|---|
| `hauts_perches_0_0` Seuil des Géants (départ) | 1 | agneaux seuls ou par 2 | bois | Pierre, maison (porte basse), enclume ; Gardienne Haute-Borne, maître de la Voie |
| `hauts_perches_1_0` Corniche aux Moutons | 1 | agneaux, béliers | bois | Berger Petit-Pas, humain minuscule à côté de ses moutons |
| `hauts_perches_0_1` Bergerie trop basse | 1-2 | béliers, un esprit | — | Charpentier Toisé, qui refait le toit « encore un peu plus haut » |
| `hauts_perches_1_1` Falaise du Vent | 2 | esprits, béliers | minerai | — |
| `hauts_perches_0_2` Col des Bourrasques | 2 | esprits par 2-3, l'élite | minerai | — |
| `hauts_perches_1_2` Aire du Doyen | 2 (boss) | le Doyen ; 2 esprits | — | — |

| Monstre | Palier | PV / PA / PM | Élément | Rôle et sorts |
|---|---|---|---|---|
| **Agneau géant** | 1 (faible) | 20 / 5 / 4 | Acier | « Agneau » de la taille d'un cheval. *Coup de tête* (mêlée, poussée 1), *Bêlement* (−1 PM, 2 cases). |
| **Bélier des cimes** | 1 (fort) | 30 / 6 / 3 | Tempête | *Charge laineuse* (charge de 3 cases, Tempête : menace 7), *Toison électrique* (épines 2 tours). |
| **Esprit des bourrasques** | 2 | 45 / 6 / 4 | Tempête | Vent qui a pris de mauvaises habitudes. *Rafale* (portée 6, poussée 2), *Tourbillon* (zone autour de lui). IA distance. |
| **Grand Bélier Corne-de-Brume** (élite des béliers) | 2 | 85 / 7 / 3 | Tempête | *Charge laineuse* renforcée, *Toison électrique* sur le groupe. |
| **Le Doyen Lentissime** (mini-boss) | 2 | 300 / 6 / 2 | Acier et Tempête | Ancien gardien géant, devenu fou d'impatience envers… lui-même. Réapparition 45-60 s. |

**Phases du Doyen** : 1. *Introduction* (100-70 %) : « Jeune… voyageur… je… » Mêlée lente et lourde, *Piétinement*
(zone autour de lui). 2. *Développement* (70-30 %) : il appelle le vent : *Souffle des cimes* (ligne de 6 cases,
poussée 3), *Grêle* (zone, portée 6). 3. *Conclusion* (sous 30 %) : « …et donc… DÉGAGE ! » Il finit enfin sa phrase :
+3 PM, mêlée Acier +25 %.

**Quêtes de race (`race: geant`)** : 1. **Le compte des moutons** (Haute-Borne) : vaincre 3 agneaux géants échappés
(tutoriel). 2. **Plafond trop bas** (Toisé) : rapporter 5 bois et vaincre 2 béliers qui ont défoncé la bergerie.
3. **Ambassade** (Haute-Borne) : aller rassurer les humains sur la Place du village (« Baisse-toi en entrant »),
première quête de la chaîne du camp. Secondaire : **Le mot de la fin** (Petit-Pas), vaincre le Doyen.
