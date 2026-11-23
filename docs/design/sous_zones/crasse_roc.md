# Crasse-Roc agrandie : sous-zones des Orcs et des Squelettes

Proposition détaillée du 23/11/2026, **à valider par l'auteur** (GDD § 3.5 « Une zone de départ par camp »).
Rien n'est produit. Gabarit de chaque sous-zone : 6 cartes, paliers 1 et 2, 3 familles, une élite, un mini-boss,
3 quêtes de race. Valeurs provisoires, à l'échelle des monstres actuels de Crasse-Roc (palier 1 : 14 à 26 PV,
palier 2 : environ 50 PV, mini-boss : 300 PV).

## Règles communes

- **Identifiants** : `braillards_x_y` et `ossuaire_x_y` (préfixe propre, comme une zone ; la région affichée,
  la carte du monde et la zone de forge restent Crasse-Roc).
- **Pierre de Passage** : une seule, celle de l'Entrée des galeries (`crasse_roc_0_0`). La sous-zone est à une
  ou deux cartes de la Pierre à pied.
- **Départ** : `carte_depart` des orcs = `braillards_0_0`, des squelettes (petit et grand) = `ossuaire_0_0`.
  Les gobelins ne changent pas.
- **Quêtes** : les trois quêtes de race portent la condition `race` (déjà gérée par `core/quests/`) ;
  la dernière envoie le joueur à l'Entrée des galeries, où commence la chaîne commune du camp ennemi.
- **Éléments** : Flamme dominante chez les orcs (comme le reste de Crasse-Roc), Impie et Givre chez les
  squelettes (exception assumée, à vérifier avec l'alerte des 60 % du catalogue sur toute la zone).
- Calque `placement` sur chaque carte à groupes, récolte (bois, minerai) sur au moins deux cartes par sous-zone.

## 1. La Fosse aux Braillards (Orcs, à l'est)

```
              x=0                          x=1
y=0  [Porte des Hurleurs 1 *] ──── [Fours à ferraille 1]
  ⇠ Puits des Vampipistrelles (crasse_roc_2_0)     │
y=1  [Arène des Gueulards 1-2] ── [Coulée de scories 2]
  ⇠ Poste avancé de la Milice (crasse_roc_2_1)     │
y=2  [Camp des Grognards 2] ──── [Tribune du Chef ☠ 2]
```

Ambiance : un camp de guerre sur des coulées de scories, où tout se règle à qui crie le plus fort. Les orcs
servent le Souverain Cendré « pour le bruit », sans trop savoir ce qu'on leur demande (ils n'écoutent pas).

### Cartes

| Carte | Palier | Groupes | Récolte | PNJ |
|---|---|---|---|---|
| `braillards_0_0` Porte des Hurleurs (départ) | 1 | gorets seuls ou par 2 | bois | Instructeur Krouk, maître de la Voie (comme les autres villages), maison et enclume |
| `braillards_1_0` Fours à ferraille | 1 | gorets, apprentis | minerai | Mâchefer, forgeronne qui « répare » en tapant plus fort |
| `braillards_0_1` Arène des Gueulards | 1-2 | apprentis par 2-3, un ferrailleur | — | Arbitre Gnarl (« le gagnant, c'est celui que j'entends ») |
| `braillards_1_1` Coulée de scories | 2 | ferrailleurs, apprentis | minerai | — |
| `braillards_0_2` Camp des Grognards | 2 | ferrailleurs par 2-3, l'élite | bois | Vieux Ronchon, orc à la retraite qui ne crie plus (scandale) |
| `braillards_1_2` Tribune du Chef | 2 (boss) | Gorgrak seul ; 2 ferrailleurs près de l'entrée | — | — |

### Monstres

| Monstre | Palier | PV / PA / PM | Élément | Rôle et sorts |
|---|---|---|---|---|
| **Goret de braise** | 1 (faible) | 16 / 5 / 4 | Flamme | Cochon de guerre qui se roule dans les braises. *Ruade* (mêlée), *Groin brûlant* (2 cases, brûlure 1 tour). |
| **Apprenti braillard** | 1 (fort) | 26 / 6 / 3 | Flamme | Jeune orc en formation au cri. *Coup de tête* (mêlée), *Caillou d'échauffement* (portée 4 : menace 7), *Cri d'encouragement* (+10 % de dégâts à un allié, 2 tours). IA soutien. |
| **Ferrailleur orc** | 2 | 50 / 6 / 3 | Acier et Flamme | Armure de récupération (résistance Acier). *Masse de ferraille* (mêlée, poussée 1), *Boulon chauffé à blanc* (portée 5, Flamme). |
| **Grand Gueulard** (élite des apprentis) | 2 | 80 / 7 / 3 | Flamme | *Cri d'encouragement* sur tout le groupe, *Hurlement* (−1 PM aux ennemis à 2 cases). |
| **Gorgrak la Grande Gueule** (mini-boss) | 2 | 300 / 7 / 3 | Flamme | Chef de guerre qui tient des réunions… de hurlements. Réapparition 45-60 s. |

**Phases de Gorgrak** (jamais de soin) :

1. *Ordre du jour* (100-70 %) : mêlée lourde (*Coup de poing de séance*), *Caillou d'échauffement*.
2. *Motion de hurlement* (70-30 %) : « Qui est pour ? Je n'entends rien ! » Il recule et devient tireur :
   *Marmite de braise* (zone en croix, portée 6), *Hurlement* ; +1 portée.
3. *Vote à main levée* (sous 30 %) : « Adopté à l'unanimité de moi ! » Frénésie : +2 PM, +20 % de dégâts en mêlée,
   plus aucun sort à distance.

### Quêtes de race (condition `race: orc`)

1. **Premier cri** (Krouk) : vaincre 3 gorets de braise, puis revenir crier devant Krouk. Tutoriel de combat.
2. **Réunion de hurlements** (Arbitre Gnarl) : gagner deux combats d'apprentis à l'Arène et rapporter 5 minerais
   des Fours pour la cloche de l'arène (fondue, elle ne sonnait pas assez fort).
3. **Mutation disciplinaire** (Krouk) : « Tu cries trop bien, le Chef se sent menacé. » Le joueur est envoyé aux
   galeries : parler au contremaître de l'Entrée des galeries, première quête de la chaîne du camp.

Secondaire : **La Grande Gueule** (Vieux Ronchon), vaincre Gorgrak pour « rétablir le silence ».

## 2. L'Ossuaire de la Première Ombre (Squelettes, à l'ouest)

```
               x=1                       x=0
y=0  [Champ des Croix 1] ──────── [Grille de l'Ossuaire 1 *] ⇢ Entrée des galeries (crasse_roc_0_0)
          │                               │
y=1  [Caisse de retraite 2] ──── [Catacombes de l'Appel 1-2] ⇢ La Rataillerie (crasse_roc_0_1)
          │                               │
y=2  [Crypte du Colonel ☠ 2] ─── [Charnier des Gradés 2]
```

Ambiance : un vieux champ de bataille et ses catacombes, où les soldats de la Première Ombre, relevés par le
Souverain Cendré, attendent une retraite qu'on ne leur versera jamais. Les gradés morts font encore l'appel.

### Cartes

| Carte | Palier | Groupes | Récolte | PNJ |
|---|---|---|---|---|
| `ossuaire_0_0` Grille de l'Ossuaire (départ) | 1 | os errants seuls ou par 2 | bois (arbres morts) | Sergent-Chef Clavicule, maître de la Voie, maison et enclume |
| `ossuaire_1_0` Champ des Croix | 1 | os errants, pleureuses | bois | Fossoyeur Pelle-à-Vide, vivant, très gêné |
| `ossuaire_0_1` Catacombes de l'Appel | 1-2 | pleureuses, un vétéran | minerai | — |
| `ossuaire_1_1` Caisse de retraite des Trépassés | 2 | vétérans par 2-3 | minerai | Guichetière Vertèbre (« Revenez demain. Depuis trois siècles. ») |
| `ossuaire_0_2` Charnier des Gradés | 2 | vétérans, l'élite | — | — |
| `ossuaire_1_2` Crypte du Colonel | 2 (boss) | le Colonel seul ; 2 vétérans au garde-à-vous | — | — |

### Monstres

| Monstre | Palier | PV / PA / PM | Élément | Rôle et sorts |
|---|---|---|---|---|
| **Os errant** | 1 (faible) | 14 / 5 / 4 | Impie | Tibia ou fémur qui cherche son squelette. *Coup d'os* (mêlée), *Ricochet* (portée 3). |
| **Pleureuse de l'Ossuaire** | 1 (fort) | 24 / 6 / 3 | Givre | Veuve fantôme qui pleure tout le monde, même les vivants. *Larmes glacées* (portée 5 : menace 8, −1 PM), *Complainte* (zone, Givre). IA distance. |
| **Vétéran de la Première Ombre** | 2 | 50 / 6 / 3 | Acier et Impie | Soldat squelette qui demande sa retraite. *Lance rouillée* (2 cases en ligne), *Javelot de service* (portée 5, Impie), *Garde-à-vous* (+résistances 1 tour). |
| **Adjudant Rotule** (élite des vétérans) | 2 | 80 / 7 / 3 | Impie | Fait l'appel : *Appel* (+1 PA aux alliés), *Corvée* (−2 PA à une cible, portée 4). IA soutien. |
| **Le Colonel Ossature** (mini-boss) | 2 | 300 / 7 / 3 | Impie et Givre | Mort depuis trois siècles, refuse toute démobilisation. Réapparition 45-60 s. |

**Phases du Colonel** (jamais de soin) :

1. *Revue des troupes* (100-70 %) : soutien qui donne des ordres (*Appel*, *Corvée*) et frappe peu (*Sabre de parade*).
2. *Rompez les rangs !* (70-30 %) : il s'effondre en tas d'os et se reforme ailleurs à chaque tour (téléportation
   courte), lance ses propres os (*Pluie de phalanges*, Impie, zone, portée 6).
3. *Dernier carré* (sous 30 %) : « Personne ne quitte le front, même pas moi ! » Givre en mêlée : *Étreinte du
   permafrost* (−2 PM), +20 % de résistances, plus de téléportation.

### Quêtes de race (condition `race: squelette`, petit et grand)

1. **Appel du matin** (Sergent-Chef Clavicule) : « Il vous manque un os, soldat ! » Vaincre des os errants jusqu'à
   retrouver le sien (objet de quête). Tutoriel de combat.
2. **Dossier de retraite** (Guichetière Vertèbre) : remplir le formulaire, il faut le tampon des pleureuses
   (vaincre 3 pleureuses) puis 5 bois pour le cercueil réglementaire. Le dossier est refusé : « Vous n'êtes pas mort
   assez longtemps. »
3. **Réaffectation** (Clavicule) : les galeries manquent de bras (« même sans muscles »). Parler au contremaître de
   l'Entrée des galeries, première quête de la chaîne du camp.

Secondaire : **Démobilisation** (Pelle-à-Vide), vaincre le Colonel Ossature pour qu'il « prenne enfin sa retraite ».

## Questions ouvertes

1. Une maison et une enclume dans chaque sous-zone (proposé), ou seulement celles de l'Entrée des galeries ?
2. Les orcs et les squelettes passent-ils toujours par la Pierre de l'Entrée des galeries, ou faut-il une petite
   Pierre par sous-zone (le GDD dit une seule par zone) ?
3. Ressources de monstres (forge) : une par famille, produites avec `docs/design/forge/produire.py`, comme les autres.
