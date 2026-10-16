# Chantier 6 — Quêtes : conception (à valider)

Conception pour l'alpha test 1, **validée par l'auteur** (questions ouvertes du § 9 tranchées
par défaut : journal sur Q, objets de quête pour les messages, récompenses en équipements,
secondaires de Hautepierre plus tard). **Lots 1 à 4 produits** (`docs/design/chantier6/`).
Écart avec ce document : le tutoriel donne le bonnet de berger (objet existant) à équiper. Il couvre le système (moteur, données, interface) puis le contenu : trois
tutoriels, la quête principale (acte I par camp, acte II par camp, début de l'acte III commun) et
les quêtes secondaires. Références : GDD § 3.3–3.4 (Reliques, camps, actes), § 11 (quêtes),
§ 14.3 (interface).

## 0. En bref

| Bloc | Quêtes | Niveaux | Où |
|---|---|---|---|
| Tutoriels (un par camp) | 3 | 1–2 | Première carte de chaque zone |
| Acte I — Chacun pour soi (une chaîne par camp) | 3 × 4 = 12 | 3–12 | Zone de départ |
| Secondaires des zones de départ (ouvertes à tous) | 3 × 5 = 15 | 2–11 | Zones de départ |
| Acte II — La révélation (une chaîne par camp) | 3 × 3 = 9 | 13–25 | Hautepierre |
| Acte III — L'alliance (début, commun) | 2 | 25–30 | Hautepierre, la Brèche |
| *Option : secondaires de Hautepierre* | *3* | *14–26* | *Hautepierre* |
| **Total** | **41** (+3) | | |

Un testeur joue **un** camp : tutoriel, 4 + 3 quêtes de sa chaîne, les 2 de l'alliance, les 5
secondaires de sa zone (et celles des autres zones s'il voyage) : **une vingtaine de quêtes** en
4 à 5 h. Seulement **2 nouveaux PNJ**, **7 objets de récompense** à dessiner, des objets de quête
sur **3 icônes génériques**.

### Décisions à valider

1. **Objectifs** : parler, vaincre (une espèce ou une famille), vaincre un groupe précis (boss),
   récolter, fabriquer, apporter, équiper, aller (sur une carte). Pas d'escorte ni de minuterie.
2. **Butin de quête** : certains objets n'apparaissent dans le butin d'un monstre **que** pendant
   la quête qui les demande (comme dans Dofus), sans compter dans sa limite de butin.
3. **Objets de quête** : type `quete`, ni vendables, ni jetables, ni équipables ; ils disparaissent
   à la fin de la quête (sauf souvenirs). Une case « Quête » dans l'inventaire.
4. **Conditions de camp** : tutoriel et quête principale réservés au camp de la race ; **les
   secondaires sont ouvertes à tous** (un humain peut aider un gobelin déserteur : c'est drôle et
   ça laisse les testeurs tout voir). L'acte III demande d'avoir fini l'acte II de son camp.
5. **Pas de blocage d'accès** pendant l'alpha : le laissez-passer de la fin de l'acte I est un
   souvenir (les Pierres de Passage restent toutes connues, `World.ALL_PASSAGES_KNOWN`).
6. **XP des quêtes en « combats de référence »** (CR = l'XP d'un combat contre 2 monstres du niveau
   de la quête, voir `balance.py`, × `Character.XP_RATE` comme le combat) : 1 CR par étape de
   tutoriel, 3 CR par secondaire, 5 CR par quête principale, 8 CR pour les boss de fin d'acte. Les
   quêtes donnent ainsi **15 à 20 %** de l'XP du jeu (le reste vient des combats, y compris ceux
   des objectifs). Écus : la fourchette du monstre du palier × 5 (secondaire) à × 10 (principale).
7. **Une seule quête proposée à la fois par PNJ**, la suivante apparaît quand la précédente est
   rendue. Une quête refusée reste proposée (`!`).
8. **Dialogues simples** : chaque quête a 3 textes par PNJ concerné (proposition avec
   « Accepter / Plus tard », en cours, fin) ; pas d'arbre ramifié pour l'alpha 1 (GDD § 11.2).
9. **Journal** (touche **Q**, bouton du bandeau) et **suivi** de la quête choisie sous la minicarte
   (objectif courant et compteur, par exemple « Loups des collines : 3 / 5 »).

## 1. Le système

### 1.1 Données : `game/data/quetes/<id>.json`

```json
{
  "id": "brumerive_verger",
  "nom": "Le verger de Mère Pomponne",
  "categorie": "principale",
  "acte": 1,
  "niveau": 6,
  "pnj": "mere_pomponne",
  "conditions": {"camp": "allie", "niveau_min": 5, "quetes_terminees": ["brumerive_aux_armes"]},
  "etapes": [
    {"objectifs": [
      {"type": "vaincre", "monstre": "gobelin_pillard", "nombre": 4},
      {"type": "apporter", "objet": "panier_de_pommes", "nombre": 5, "pnj": "mere_pomponne",
       "butin": {"monstres": ["gobelin_pillard"], "taux": 0.4}}
    ]},
    {"objectifs": [{"type": "parler", "pnj": "pere_pomponne"}]},
    {"objectifs": [{"type": "parler", "pnj": "mere_pomponne"}]}
  ],
  "dialogues": {
    "mere_pomponne": {"proposition": ["…"], "en_cours": ["…"], "fin": ["…"]},
    "pere_pomponne": {"fin": ["…"]}
  },
  "recompenses": {"xp_cr": 5, "ecus": 60, "objets": [{"objet": "bottes_de_rapine", "nombre": 1}]}
}
```

- `categorie` : `tutoriel`, `principale`, `secondaire` ; `acte` pour la principale.
- `niveau` : niveau de la quête (affiché, et base de l'XP) ; `niveau_min` dans les conditions.
- Conditions : `camp`, `race`, `voie` (optionnels), `niveau_min`, `quetes_terminees`.
- Objectifs (tous ceux d'une étape se font dans n'importe quel ordre) :

| Type | Champs | Compte… |
|---|---|---|
| `parler` | `pnj` | un clic sur le PNJ (son texte d'étape s'affiche) |
| `vaincre` | `monstre` ou `famille`, `nombre`, `carte` (option) | chaque monstre vaincu en combat gagné (l'élite compte pour sa famille) |
| `vaincre_groupe` | `monstre` (le boss) | la victoire contre son groupe |
| `recolter` | `objet`, `nombre` | les récoltes faites pendant l'étape |
| `fabriquer` | `objet` (ou `metier`), `nombre` | les fabrications faites pendant l'étape |
| `apporter` | `objet`, `nombre`, `pnj`, `butin` (option) | rendu en parlant au PNJ, les objets sont pris |
| `equiper` | `objet` ou `emplacement` | l'objet porté (vrai tout de suite s'il l'est déjà) |
| `aller` | `carte` | l'arrivée sur la carte |

- `recolter` ne demande que des ressources de niveau 1 de métier dans les zones de départ (on ne
  peut pas compter sur un métier monté) ; le contrôle des données le vérifie.
- `butin` d'un objectif `apporter` : l'objet de quête tombe de ces monstres au taux indiqué, et
  seulement pendant l'étape (pas de prospection, pas de limite de butin).
- Récompenses : `xp_cr` (converti en XP au niveau de la quête), `ecus`, `objets` (jets tirés comme
  un butin), et `donne` à l'acceptation (objet de départ du tutoriel, lettre à porter…).

### 1.2 Noyau (`game/core/quests/`)

- `Quest` (validation du JSON, comme `Item` ou `Spell`) et `QuestLog` dans `Character` : pour chaque
  quête, son état (`disponible`, `en_cours`, `terminee`), l'étape et les compteurs. Sauvegardé avec
  le personnage (`to_dict`), sans changer de version de sauvegarde (absent = vide).
- Le monde émet les événements qui font avancer les objectifs (combat gagné, récolte, fabrication,
  changement de carte, équipement, clic sur un PNJ) ; `QuestLog` les écoute.
- Commandes : `CMD_TALK` (déjà là pour les PNJ) renvoie le dialogue de quête s'il y en a un ;
  `CMD_QUEST_ACCEPT`, `CMD_QUEST_TURN_IN` (rendre : objets pris, récompenses données). Événements :
  `EVT_QUEST_UPDATED` (compteur), `EVT_QUEST_STEP`, `EVT_QUEST_DONE` (récompenses).
- `GameData.quests` charge le dossier ; validation : PNJ, monstres, familles, objets et quêtes
  cités existent, pas de cycle dans `quetes_terminees`, un PNJ donneur sur une carte.
- Tests : chaque type d'objectif, conditions (camp, niveau, quête précédente), butin de quête,
  récompenses, sauvegarde, et un test de données « chaque chaîne est faisable » (les monstres et
  ressources demandés existent sur des cartes de la bonne zone).

### 1.3 Interface

- **PNJ** : `!` jaune (quête à prendre), `?` jaune (à rendre), `?` gris (en cours) au-dessus de
  la tête, à la place de la bulle « … ».
- **Dialogue de quête** dans la bulle existante, avec deux boutons « Accepter » / « Plus tard »,
  puis « Terminer » au rendu (récompenses affichées comme le butin d'un combat).
- **Journal** (Q) : quêtes en cours et terminées, par catégorie ; pour chacune son texte, ses
  objectifs cochés, ses récompenses, et « Suivre ».
- **Suivi** sous la minicarte (repliable comme elle) ; message flottant à chaque objectif avancé
  (« Loups des collines : 3 / 5 »).
- Carte du monde : marqueur sur la carte du PNJ à qui rendre la quête suivie.

## 2. Tutoriels (un par camp, niveaux 1–2)

Même déroulé partout : **équipement, combat, métier (récolte puis forge), retour**. Le PNJ donne à
l'acceptation un objet à équiper (objet existant de niveau 1, à choisir à la production). XP :
1 CR par étape.

| Quête | PNJ (carte) | Étapes |
|---|---|---|
| **Bienvenue à Brumerive** (`brumerive_tutoriel`) | Alric le berger (0_0) | 1. Équiper le chapeau de feutre qu'il vous prête (« il était à mon père, qui ne l'a jamais porté »). 2. Vaincre 2 loups des collines. 3. Récolter 4 minerais de cuivre. 4. Fabriquer un objet chez Célébrimbert. 5. Revenir voir Alric. |
| **Fiche d'embauche** (`crasse_roc_tutoriel`) | Grumm, contremaître (0_0) | 1. Équiper le casque réglementaire (« casque non fourni, à rendre en fin de contrat »). 2. Vaincre 2 rats des galeries (« dératisation : c'est dans ta fiche de poste »). 3. Miner 4 minerais de cuivre. 4. Fabriquer un objet chez Krogma. 5. Pointer chez Grumm. |
| **Les premiers pas de la jeune pousse** (`sylvebrume_tutoriel`) | Elwyn, gardienne (0_0) | 1. Équiper la cape de feuilles (« elle a trois siècles, elle est neuve »). 2. Vaincre 2 morilles grincheuses (« avec respect »). 3. Récolter 5 bois de frêne (« du bois mort, évidemment ») ; Elwyn fournit le cuivre de la recette. 4. Fabriquer un objet chez Aelthar. 5. Revenir voir Elwyn. |

Le tutoriel terminé débloque l'acte I de son camp et les secondaires de sa zone.

## 3. Acte I — Chacun pour soi (zones de départ, 3–12)

Une chaîne de 4 quêtes par camp, une par palier, qui finit sur le mini-boss de la zone. Les trois
chaînes **se croisent** : les humains repoussent le raid gobelin, les gobelins affrontent la milice
de Hautepierre, les elfes chassent les bûcherons humains (et les gobelins, par principe). Chacune
laisse entrevoir un **Héraut Cendré** derrière les ordres (graine de l'acte II).

### 3.1 Humains — « Le raid gobelin » (camp allié, Brumerive)

Nouveau PNJ : **le bourgmestre Fortunat Pansu** (place du village, 0_0), persuadé d'être le héros de
l'histoire et de vous faire une faveur en vous laissant l'aider.

| # | Quête | Niv. | PNJ | Objectifs | Récompense |
|---|---|---|---|---|---|
| 1 | **Aux armes, citoyens (surtout vous)** | 3 | Pansu | Vaincre 4 frondeurs gobelins ; apporter 3 fiches de paie gobelines. *« Ils sont PAYÉS ?! »* | 5 CR, écus, bottes de marche |
| 2 | **Le verger de Mère Pomponne** | 6 | Mère Pomponne (2_0) | Vaincre 4 pillards ; apporter 5 paniers de pommes (butin de quête des pillards, 40 %) ; retrouver le Père Pomponne au camp du raid (nouveau PNJ, 2_2), qui ne veut pas rentrer : les gobelins ont des congés payés. | 5 CR, écus, objet existant du palier |
| 3 | **Les ordres du raid** | 9 | Hubert, sentinelle (3_1) | Apporter 3 ordres de raid (butin des briseurs et pillards) ; les faire lire à Grizzik le déserteur (1_0) : signés d'un « Héraut », avec un post-scriptum « les gobelins ne reviendront pas ». | 5 CR, écus |
| 4 | **La palissade de Krasbouk** | 12 | Pansu | Vaincre Krasbouk (3_2). Pansu s'attribue la victoire et vous remet un laissez-passer pour Hautepierre « dont vous n'aurez pas besoin, vous êtes avec moi ». | 8 CR, écus, **Écharpe du Héros de Brumerive** (nouvelle, « héros autoproclamé ») |

### 3.2 Gobelins — « Le grand raid » (camp ennemi, Crasse-Roc)

PNJ principal : **Grumm**, contremaître des galeries (0_0), qui transmet les ordres d'en haut sans
les lire.

| # | Quête | Niv. | PNJ | Objectifs | Récompense |
|---|---|---|---|---|---|
| 1 | **Objectifs de productivité** | 3 | Grumm | Vaincre 6 rats des galeries ; apporter 5 queues de rat (« le quota »). | 5 CR, écus, objet existant |
| 2 | **Heures supplémentaires (non payées)** | 6 | Grumm | Vaincre 4 vampipistrelles dans le puits (2_0) ; apporter 3 guanos luisants à Gnark (2_0), qui les vend pour Grumm. | 5 CR, écus |
| 3 | **Inspection surprise** | 9 | Grumm | Vaincre 4 miliciens de Hautepierre (2_1, 2_2) ; apporter 3 écussons de milice ; parler à Grizzlok le pacifiste (2_2), qui a lu l'ordre de mission en entier : les gobelins du raid servent de **diversion**, et personne n'a prévu de retour. | 5 CR, écus |
| 4 | **Le Balourd des Abîmes** | 12 | Grumm | Vaincre le Balourd (1_3), qui bloque la grande galerie. Grumm vous nomme « délégué provisoire » et vous envoie à Hautepierre porter un préavis de grève « en main propre au Souverain, ou à quelqu'un de proche ». | 8 CR, écus, **Carte du syndicat** (nouvelle, amulette) |

### 3.3 Elfes — « Ce n'est pas notre guerre » (camp neutre, Sylvebrume)

PNJ principaux : **Elwyn**, gardienne (0_0), et **Feuillemorte**, druide (1_1).

| # | Quête | Niv. | PNJ | Objectifs | Récompense |
|---|---|---|---|---|---|
| 1 | **Observer sans intervenir** | 3 | Elwyn | Aller à la Futaie ancienne (1_0) et à la Coupe rase (1_1) ; parler à Feuillemorte. *« Observer, c'est déjà agir. Lentement. »* | 5 CR, écus |
| 2 | **Les arbres sont nerveux** | 6 | Feuillemorte | Vaincre 4 arbres vivants (« pour les calmer ») ; apporter 3 sèves anciennes (un baume pour Vieux-Branchu, qu'on a coupé). | 5 CR, écus, cape d'écorce |
| 3 | **Coupe rase** | 9 | Feuillemorte | Vaincre 5 bûcherons de Brumerive ; apporter 3 bons de coupe : signés de Hautepierre, pour des palissades contre les gobelins, eux-mêmes poussés par un « Héraut ». *« Tout le monde a une bonne raison. C'est bien le problème. »* | 5 CR, écus |
| 4 | **La Mère-Toile** | 12 | Elwyn | Vaincre la Mère-Toile (0_2), dont la toile est devenue grise. Le conseil elfe décide, après trois siècles de délibération, d'envoyer une observatrice à Hautepierre : vous. | 8 CR, écus, **Broche de la Lisière** (nouvelle) |

Fin de l'acte I : la victoire contre le mini-boss débloque aussi ses variantes corrompues (déjà en
jeu) et l'acte II de son camp.

## 4. Quêtes secondaires des zones de départ (ouvertes à tous, 3 CR)

Elles reprennent les PNJ d'ambiance déjà placés (et leurs répliques). Condition : le tutoriel de
**n'importe quel** camp terminé, et le niveau.

### Brumerive

| Quête | Niv. | PNJ | Objectifs |
|---|---|---|---|
| **Les moutons d'Alric** | 2 | Alric (0_0) | Vaincre 5 loups des collines ; apporter 3 peaux de loup. |
| **Le prêt du berger** | 3 | Gobillon l'ermite (0_1) | Réclamer ses trois pièces : parler à Alric, qui renvoie au meunier, qui renvoie à Gobillon (qui les avait dans sa poche). Quête de déplacement, pour la blague. |
| **Le moulin de Tournevent** | 5 | Bernardin le meunier (1_1) | Vaincre 4 frondeurs qui visent les ailes ; récolter 4 bois de frêne pour les réparer. |
| **Fausse fiche de présence** | 6 | Grizzik le déserteur (1_0) | Apporter 3 fiches de paie gobelines : il s'en fait une fausse, « présent au raid ». |
| **La grève des épouvantails** | 8 | Gaudin le fermier (1_2) | Vaincre 4 épouvantails démotivés ; apporter 3 pailles ensorcelées ; parler à Grizzik, qui leur conseille un syndicat. |

### Crasse-Roc

| Quête | Niv. | PNJ | Objectifs |
|---|---|---|---|
| **Le dentier de Mamie Ratine** | 2 | Mamie Ratine (0_1) | Vaincre 6 rats ; apporter 4 dents de rat. |
| **Guano-culture** | 5 | Gnark (2_0) | Vaincre 5 vampipistrelles ; apporter 5 guanos luisants. |
| **La galerie effondrée** | 5 | Zogrub Troc-Tout (0_0) | Aller à la galerie effondrée (1_1) ; vaincre 3 grouilleurs ; miner 4 minerais de cuivre pour étayer. |
| **Le préavis de Grizzlok** | 8 | Grizzlok (2_2) | Porter son préavis à Grumm (parler), rapporter la réponse (un préavis de licenciement) ; vaincre 3 miliciens sur le chemin du retour. |
| **Le péage de Zibeline** | 11 | Zibeline la péagère (0_2) | Vaincre 4 contremaîtres zélés qui taxent son péage ; apporter 3 sifflets de contremaître. |

### Sylvebrume

| Quête | Niv. | PNJ | Objectifs |
|---|---|---|---|
| **Des champignons qui insultent** | 2 | Tantine Champignolle (0_1) | Vaincre 5 morilles grincheuses ; apporter 3 chapeaux de morille. |
| **L'ode au Grand Cerf** | 5 | Lyriandel le poète (2_0) | Apporter 3 poils scintillants (l'inspiration) ; faire lire l'ode à Elwyn (critique sévère) ; revenir. |
| **La dette de Vieux-Branchu** | 8 | Feuillemorte (1_1) | Apporter 5 copeaux de bois (butin des bûcherons) pour une stèle à Vieux-Branchu, « qui me devait de l'argent ». |
| **Rapport d'éclaireuse** | 10 | Sylphine l'éclaireuse (2_2) | Aller à la Scierie (2_1), aux Toiles grises (1_2) et à l'Orée du Sud (2_2) ; vaincre 3 tisseuses de brume. |
| **Du fil de brume** | 11 | Lindorë, marchande (0_0) | Apporter 4 fils de brume (pour une robe « de saison », la saison durant un siècle). |

## 5. Acte II — La révélation (Hautepierre, 13–25)

Chaque camp arrive par sa route et découvre, par son propre chemin, le vrai plan du Souverain :
reprendre les Reliques et asservir tout le monde, ses propres troupes comprises (GDD § 3.4).

### 5.1 Humains — « Le bureau des laissez-passer »

| # | Quête | Niv. | PNJ | Objectifs | Récompense |
|---|---|---|---|---|---|
| 1 | **Le tampon officiel** | 14 | Gaspard le Sobre, Intendant (2_1) | Parler au Sergent Mordicus (1_2) ; vaincre 5 détrousseurs ; apporter le tampon officiel (butin de quête, 30 %), sans lequel aucun laissez-passer n'est valable, même le vôtre. | 5 CR, écus |
| 2 | **Messages interceptés** | 20 | Capitaine Aldebert (2_1) | Vaincre 5 corbacs espions ; apporter 4 messages interceptés ; les faire lire à Pétronille l'archiviste : les raids gobelins n'étaient qu'une **diversion**, le Héraut cherche la Chevalière Sans-Rouille. | 5 CR, écus |
| 3 | **La vieille garde** | 23 | Pétronille (2_1) | Aller aux ruines de la Vieille Garde (3_1) ; vaincre 4 gargouilles ; parler au Capitaine Pérenne (fantôme), qui a vu le Héraut passer : « il cherchait la Chevalière, et il a dit "après, les humains" ». | 8 CR, écus, **Insigne de la Vieille Garde** (nouveau) |

### 5.2 Gobelins — « Le préavis »

| # | Quête | Niv. | PNJ | Objectifs | Récompense |
|---|---|---|---|---|---|
| 1 | **Le convoi de Brokk** | 14 | Brokk, caravanier (4_2) | Vaincre 3 loups cendreux et 3 détrousseurs qui pillent le convoi ; apporter 3 caisses de minerai (butin de quête) : du minerai pour forger… des colliers à gobelins. | 5 CR, écus |
| 2 | **Droit de passage** | 17 | Snagrod, délégué (2_1) | Vaincre 4 trolls des ponts (« ils ont un péage, nous on n'a même pas de chaise ») ; apporter 2 recettes de troll ; parler à l'Intendant, qui refuse de recevoir Snagrod (mais garde les recettes). | 5 CR, écus |
| 3 | **Le registre des sacrifiés** | 23 | Snagrod | Vaincre 4 gargouilles au Cimetière (4_1) ; apporter la liste du Héraut (butin de quête) : les gobelins y sont inscrits **en premier**, rubrique « consommables ». Snagrod dépose un préavis contre le Souverain lui-même. | 8 CR, écus, **Brassard du délégué** (nouveau) |

### 5.3 Elfes — « Ce n'est (finalement) pas pas notre guerre »

| # | Quête | Niv. | PNJ | Objectifs | Récompense |
|---|---|---|---|---|---|
| 1 | **Notes d'observatrice** | 14 | Ilyndra Tel'Hautaine, ambassadrice (2_1) | Parler à Clairon et Maître Ripaille (Grand-Place) et à Frère Bénitier (Porte de l'Ouest) pour son rapport sur « les us humains » ; vaincre 4 détrousseurs ; rapporter sa malle volée (butin de quête). | 5 CR, écus |
| 2 | **Les arbres qui brûlent** | 20 | Ilyndra | Vaincre 4 arbres calcinés (Bois-Corbeau, Colline Pelée) ; apporter 3 cendres tièdes : la cendre gagne les arbres, la forêt ne sera pas épargnée. | 5 CR, écus |
| 3 | **Le bal des Cendrillons** | 25 | Ilyndra | Vaincre 3 Cendrillons (camp, 3_3) ; apporter 3 invitations au bal : au programme du bal, « embrasement de Sylvebrume ». Ilyndra demande un siège au Conseil (« pour observer de plus près »). | 8 CR, écus, **Feuille d'argent de l'ambassade** (nouvelle) |

## 6. Acte III — L'alliance (début, commun, 25–30)

Condition : l'acte II de son camp terminé. Les trois chaînes convergent dans la Citadelle.

| # | Quête | Niv. | PNJ | Objectifs | Récompense |
|---|---|---|---|---|---|
| 1 | **Le Conseil des Peuples Libres** | 26 | Gaspard le Sobre (2_1) | Parler à Gaspard, Snagrod et Ilyndra (le Conseil naît, avec un siège pour les gobelins, qu'ils ont apporté eux-mêmes) ; vaincre 3 olifants de guerre aux Champs du Pèle-Ennemi (3_4), pour prouver que l'alliance tient au moins un combat. | 5 CR, écus |
| 2 | **La Brèche** | 30 | Capitaine Aldebert (2_1) | Vaincre Grondin, bélier de la Brèche (4_4). Au retour, Pétronille annonce que la Chevalière Sans-Rouille a disparu de la Citadelle : la quête des Reliques commence (suite à l'alpha 2 et en Phase 3). | 8 CR, écus, **Éclat de l'Aube** (nouveau, souvenir de fin d'alpha) |

## 7. Option : secondaires de Hautepierre (ouvertes à tous)

À produire seulement si le temps le permet (Hautepierre couvre les deux tiers du jeu, mais l'acte II
l'occupe déjà).

| Quête | Niv. | PNJ | Objectifs |
|---|---|---|---|
| **La relève** | 16 | Capitaine Pérenne, fantôme (3_1) | Lui trouver une relève : parler au Sergent Mordicus, à la Sergente Brisetout et à Clopin le vétéran (tous refusent, poliment ou non). |
| **La recette du troll** | 18 | Maître Ripaille (2_2) | Apporter 3 recettes de troll et 3 dents de troll (pour la soupe du jour). |
| **Authentiques fausses reliques** | 24 | Fulbert l'Authentique (1_2) | Apporter 5 cendres tièdes et 1 éclat de cendre, pour ses « Reliques garanties d'origine ». |

## 8. Production

### 8.1 Ce qu'il faut créer

- **Noyau** : `core/quests/` (quête, journal, objectifs, butin de quête), commandes et événements,
  validation dans `GameData`, sauvegarde ; tests.
- **Interface** : marques `!`/`?` des PNJ, dialogue avec boutons, journal (Q, bouton du bandeau),
  suivi sous la minicarte, marqueur sur la carte du monde ; tests client.
- **Données** : 41 fichiers de quêtes (44 avec l'option) et leurs dialogues.
- **PNJ** : 2 nouveaux (bourgmestre Pansu à Brumerive 0_0, Père Pomponne au camp du raid 2_2),
  posés avec `cartes.py`, apparence par le manifeste (rigs existants recolorés).
- **Objets** : ~8 objets de quête (paniers de pommes, tampon officiel, caisses de minerai, malle,
  liste du Héraut, laissez-passer, préavis, objet de départ des tutoriels si besoin) sur 3 icônes
  génériques (parchemin, caisse, sac) ; 7 objets de récompense nouveaux avec leur icône.

### 8.2 Lots proposés

1. **Système** : noyau, données, tests, interface (sans contenu réel, avec des quêtes de test).
2. **Tutoriels et acte I** (les 3 chaînes, 15 quêtes) : jouables de bout en bout dans chaque zone.
3. **Secondaires des zones de départ** (15 quêtes).
4. **Acte II et début de l'acte III** (11 quêtes).
5. *Option : secondaires de Hautepierre (3 quêtes).*

Chaque lot : contrôle mécanique des données (`src/controle.py` étendu aux quêtes : PNJ, monstres,
objets, cartes, niveaux cohérents avec les paliers), tests verts, GDD / TODO / guide des testeurs
à jour.

## 9. Questions ouvertes

1. Le journal sur **Q** te va-t-il (Dofus Rétro n'avait pas de raccourci fixe) ?
2. Faut-il un **objet de quête à porter** pour les quêtes « porter un message » (préavis de
   Grizzlok, laissez-passer), ou un simple dialogue suffit-il ? (Proposé : un objet, c'est plus
   lisible dans l'inventaire.)
3. Les 7 **récompenses uniques** : plutôt des équipements (comme proposé), ou des cosmétiques et
   titres plus tard ?
4. Les secondaires de Hautepierre (§ 7) : à faire pour l'alpha 1 ou plus tard ?
