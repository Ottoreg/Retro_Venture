# Retro Venture — TODO list

> Liste de travail organisée par phase (voir [GDD § 17](GDD.md#17-périmètre-par-phase)).
> Cocher `[x]` quand une tâche est terminée. Les tâches marquées **(MVP)** sont indispensables à la
> sortie de la phase ; les autres peuvent glisser à la suivante.
> Conseil : transformer chaque section en *milestone* GitHub et chaque tâche en *issue*.

---

## Phase 0 — Pré-production

### Décisions
- [x] **(MVP)** Choisir le moteur : Godot 4 ([décision 0001](decisions/0001-moteur-godot-4.md))
- [x] **(MVP)** Choisir le langage : GDScript ([décision 0002](decisions/0002-langage-gdscript.md))
- [x] **(MVP)** Format des données de contenu : JSON ([décision 0003](decisions/0003-donnees-json.md))
- [x] Taille de tuile 64×32 et résolution 1280×720 ([décision 0004](decisions/0004-grille-isometrique.md))
- [ ] Choisir la licence du code et des assets
- [ ] Fixer le nom définitif du jeu et du monde (vérification de marques)

### Dépôt et outillage
- [x] Structure du dépôt, README, GDD, TODO
- [x] **(MVP)** Initialiser le projet Godot dans `game/` (rendu Compatibility, 1280×720, lanceur de tests)
- [ ] Activer Git LFS pour les assets binaires (`.gitattributes`)
- [x] Intégration continue (GitHub Actions) : tests Godot
- [x] Export web automatique publié sur GitHub Pages (jouable dans le navigateur)
- [x] Activer GitHub Pages (Settings → Pages → Source : GitHub Actions)
- [x] Intégration continue : validation des fichiers de données (syntaxe JSON + cartes)
- [x] Créer la branche `main`
- [x] Définir `main` comme branche par défaut
- [ ] Créer les labels et milestones GitHub (phase, domaine : combat, UI, contenu, art, réseau…)
- [ ] Rédiger `CONTRIBUTING.md` (conventions de nommage, de commits, de branches)
- [ ] Créer `game/assets/CREDITS.md` (registre des assets tiers et licences)

### Design
- [ ] **(MVP)** Valider le GDD v0.1 (relecture complète)
  - [x] Règles de combat de base (§ 7) et éléments (provisoires)
  - [x] Liste des 9 races (trois par camp) et ton parodique (§ 3.6, § 4.2)
  - [x] Races de l'alpha (Humain, Gobelin, Elfe) et structure en trois camps (§ 3.4)
  - [ ] Choisir les noms de peuple des 9 races (§ 4.2)
  - [x] Nom des spécialisations opposées : **Voie Miroir** (§ 5.3)
  - [ ] Revoir les noms du monde, des Reliques et du méchant dans le ton parodique (§ 3)
  - [x] Reliques : huit bagues tenues par les Hérauts Cendrés, une par peuple ou presque (§ 3.3)
  - [ ] Nommer les régions des Géants, des Lutins et des Fosses de Crasse-Roc (§ 3.3, § 3.5)
  - [ ] Écrire le synopsis des actes I à III pour chaque camp (`docs/lore/`)
- [ ] Tableur d'équilibrage : courbe d'XP, formules de dégâts, PV par niveau (`docs/design/`)
- [ ] Prototype « papier » du combat (grille + pions) pour tester PA/PM et 5 sorts par classe
- [ ] Document de lore court (1 à 2 pages) : histoire, Reliques, régions (`docs/lore/`)
- [ ] Planche de références visuelles (moodboard) par région

---

## Phase 1 — Prototype jouable

Objectif : **un combat jouable de bout en bout sur une carte**.

✅ **Terminée.** Reportés : sprites animés (Phase 2, graphismes), tacle / fuite (Phase 2, combat),
durée de tour limitée (Phase 4, combat multijoueur).

### Noyau (logique indépendante de l'affichage)
- [x] **(MVP)** Modèle de grille isométrique (coordonnées, conversion écran ↔ case, voisins)
- [x] **(MVP)** Recherche de chemin A* sur grille avec cases bloquantes (8 directions en exploration, 4 en combat)
- [x] **(MVP)** Architecture commandes → noyau → événements (base du futur réseau) — `World.execute()`, `Protocol`
- [x] **(MVP)** Générateur aléatoire à graine (combats rejouables) — une graine par combat
- [x] Chargement des données de contenu depuis `game/data/` + validation (cartes, sorts, monstres, Voies)
- [x] Tests unitaires du noyau (grille, carte, monde, combat, IA) + test de bout en bout de la scène

### Exploration
- [x] **(MVP)** Afficher une carte isométrique (sol, obstacles, décor, tri par profondeur) — formes provisoires, cadre entièrement couvert de cases
- [x] **(MVP)** Déplacement au clic, aperçu du chemin au survol ; un nouveau clic en chemin change de destination (même en marche vers un combat ou une sortie)
- [x] Animation de marche (formes provisoires : sauts, jambes, orientation gauche/droite)
- [x] Changement de carte par les bords (sorties réciproques, état des groupes mémorisé par carte) — pas de caméra : chaque carte tient dans l'écran, comme dans Dofus
- [x] Deuxième carte : Brumerive — Champs de l'est
- [x] PNJ cliquables avec bulle de dialogue (Alric le berger, Grizzik le gobelin « en pause »)

### Combat
- [x] **(MVP)** Lancer un combat en cliquant sur un monstre
- [x] **(MVP)** Phase de placement (cercles bleus)
- [x] **(MVP)** Tours par initiative, PA/PM, fin de tour
- [x] **(MVP)** Sorts : portée, ligne de vue, zone, dégâts élémentaires, résistances, soins, limites et délais de relance
- [x] **(MVP)** IA de monstre simple (mêlée et distance)
- [x] **(MVP)** Conditions de victoire / défaite, écran de fin
- [x] Prévisualisation de portée et de zone au survol
- [x] Ordre de jeu affiché : frise de portraits (retours de test, lot 3)

### Contenu de test
- [x] 1 personnage Guerrier avec 4 sorts
- [x] 2 types de monstres (loup des collines, gobelin frondeur)
- [x] Assets temporaires (formes simples dessinées par le code)

---

## Phase 2 — Alpha solo (objectifs court terme)

Objectif : **10 à 15 h de jeu solo, niveaux 1 à 30 : 3 zones de départ (une par camp) + Hautepierre**,
en deux tests (décision de l'auteur) :

- **Alpha test 1 — les mécaniques.** Tout le contenu du chantier 3, puis l'**interface** et les
  **quêtes** en derniers chantiers avant le lancement. XP de combat ×3,5 (`Character.XP_RATE`) :
  tout le contenu se finit en 4 à 5 h. Pas de test de la progression.
- **Alpha test 2 — la progression.** Leveling réel (XP ×1, ~15 h pour les niveaux 1 à 30), sorts
  par niveau et modèle voie/rang, équilibrage race × classe, **art et son**.

Les tâches marquées *(alpha 2)* sont reportées au second test.

### Lancement de l'alpha test 1

Tout le contenu et les systèmes MVP de l'alpha 1 sont faits (chantiers 1, 3, 4 et 6). Reste :

- [x] Version 0.6.0 « Alpha test 1 » sur l'écran d'accueil ; bouton « Donner son avis » (menu
  principal et menu pause) vers le questionnaire (`Session.FEEDBACK_URL`)
- [x] Distribution : GitHub Pages (https://ottoreg.github.io/Retro_Venture/, publié à chaque push
  sur `main`)
- [x] Guide des testeurs à jour ([GUIDE_TESTEURS.md](GUIDE_TESTEURS.md) : par où commencer,
  problèmes connus, questionnaire)
- [x] Questionnaire de référence ([FORMULAIRE_ALPHA1.md](FORMULAIRE_ALPHA1.md))
- [x] Questionnaire créé avec `docs/creer_formulaire.gs` (Apps Script) ; lien des testeurs dans
  `Session.FEEDBACK_URL` et le guide des testeurs
- [x] Lien vérifié depuis le jeu (« Donner son avis ») dans une fenêtre privée
- [ ] Passe de l'auteur dans chaque camp (tutoriel et début de l'acte I, une Voie différente à
  chaque fois) sur la version publiée
- [x] Retours de la passe de l'auteur : bulle de dialogue sous le bandeau du haut (placée sous le
  PNJ quand elle déborderait), suivi de quête plus petit et repliable, ligne de vue exigée pour 7
  sorts de monstres qui traversaient les obstacles (racines, ronces, spores, ultrason, « Ça
  tombe ! », nuée de corbeaux), garde-fou de la lecture des événements
- [x] Suite de la passe de l'auteur : catalogue des objets, monstres et sorts
  ([CATALOGUE.md](CATALOGUE.md), `game/tools/catalogue.py`) ; monstres à moins de 3 PM avec une
  menace d'au moins 7 ; éléments des dégâts rééquilibrés par zone (GDD § 8.1) ; historique du
  combat, couleurs des éléments, survol des glyphes et pièges (GDD § 14.3) ; aide des
  caractéristiques corrigée
- [x] Retours de tests, lot 1 : le jeu tourne sans le focus (temps réel rattrapé, `MapView._real_delta`),
  minicarte dans la barre du bas et suivi des quêtes dans le bandeau du haut (plus rien sur la
  zone de jeu ; minicarte 5 × 3, plus de bouton pour la replier), halo blanc sur les cases de sortie
  praticables et flèche alignée sur l'une d'elles (`GameMap.exit_cells`)
- [x] Retour de test : les états de l'Arcaniste étaient fastidieux (3 lancers de *Braise* ou
  *Frimas* par combinaison) ; un seul sort, *Composition*, ouvre une grille des 4 combinaisons
  (au-dessus du sort, ou de la souris par raccourci) et applique celle choisie (GDD § 4.3) ;
  *Créer un sort* renommé *Fusion arcanique* (choix de l'auteur ; l'id reste `arcaniste_creer_un_sort`)
- [ ] Gel vu contre Grondin (une fois, non reproduit en 20 combats simulés jusqu'aux 3 phases) :
  attendre un retour avec la console du navigateur
- [ ] Inviter les testeurs (5 au moins), avec le lien du jeu et le guide
- [ ] Après le test : dépouiller les réponses, décider des ajustements d'équilibrage (ci-dessous,
  Monde) et des corrections, puis préparer l'alpha test 2

### Personnage
- [x] **(MVP)** Écran de création : race, classe, nom, aperçu et récapitulatif (couleurs selon race et Voie)
- [x] **(MVP)** 3 races jouables, une par camp : Humain (allié), Gobelin (ennemi), Elfe (neutre) — bonus, passif, sort racial (passifs : Polyvalence +10 % d'XP de métier, Œil perçant +1 portée, Chapardeur +20 prospection et +20 % d'écus)
- [x] **(MVP)** Camp porté par la race dans les données ; carte de départ par race (`carte_depart`)
- [x] Faire partir Gobelins et Elfes de leurs propres zones (Crasse-Roc et Sylvebrume)
- [x] 3 classes jouables : Guerrier, Rôdeur, Arcaniste (4 sorts chacune)
- [x] **(MVP)** 4e classe : **Théologue** (soigneur sacré), 4 sorts de départ (Châtiment, Imposition
  des mains, Rempart de foi, Sermon), tenue, icônes de sorts, équipement de départ (GDD § 4.3)
- [x] **(MVP)** Effet « bouclier » (absorbe des dégâts jusqu'au prochain tour) pour le Rempart de foi
- [x] Soins et boucliers ont un élément et grandissent avec sa caractéristique (plus avec
  l'Intelligence seule) ; même règle pour tous les effets chiffrés à venir (poisons, pièges…)
- [ ] **(MVP)** *(alpha 2)* Compléter jusqu'à environ 10 à 12 sorts par classe, débloqués par niveau (1 à 30)
- [x] **(MVP)** Caractéristiques, points à répartir (fiche, touche C), statistiques dérivées (PV, initiative, dégâts, soins, XP)
- [x] **(MVP)** XP, montée de niveau (courbe 60·n + 20·n²)
- [ ] Points de sort (avec le système des Voies)
- [x] Vitesse d'XP de l'alpha 1 : XP de combat ×3,5 (`Character.XP_RATE`), tout le contenu en 4 à 5 h ;
  à remettre à 1.0 pour l'alpha 2
- [ ] *(alpha 2)* Rendement décroissant des caractéristiques
- [ ] **(MVP)** *(alpha 2)* Modèle de sort avec `voie` et `rang` (préparation du système des Voies) :
  sorti de l'alpha 1, qui teste les mécaniques et pas la progression
- [ ] Restat (objet ou PNJ)

### Combat
- [x] **(MVP)** Éléments composés **Sacré** (Force + Intelligence ; résistance (Acier + Flamme) / 2 + Sacré)
  et **Impie** (Agilité + Chance ; résistance (Tempête + Givre) / 2 + Impie), sorts et résistances ;
  premières armes : Masse bénite (Sacré), Dague du Mauvais Œil (Impie)
- [x] **(MVP)** Statistique **Dommages** : +X dégâts bruts à chaque ligne de dégâts de tout sort ou
  arme, sans élément ni résistance, pas sur les soins ; portée par les objets (Chevalière du
  Cogneur), affichée dans la fiche
- [ ] Sorts de Voie sacrés et impies (avec les nouvelles Voies)
- [x] **(MVP)** Effets : soin, bouclier, téléportation, bonus/malus temporaires (caractéristiques, PA,
  PM, portée, Dommages, % Critique, résistances), poisons, poussée (avec dégâts de choc) et attirance
  (GDD § 7.4)
- [x] **(MVP)** Glyphes (effets au début du tour de qui est dessus) et pièges invisibles pour
  l'adversaire (déclenchés en entrant sur la case) ; Cercle de sève de l'Arbre millénaire,
  Chausse-trape du Frondeur vétéran
- [ ] États spéciaux (*Enraciné*, *Invisible*, *Porté*…) et invocations
- [x] **(MVP)** Cases de placement **prédéfinies par carte**, façon Dofus (GDD § 7.1) : calque
  `placement` (`j` joueurs, `m` monstres), obligatoire sur les cartes à groupes ; le combat démarre
  sur ces cases quel que soit l'endroit où le groupe est engagé (l'ancien placement près du groupe
  est supprimé) ; calques des 7 cartes existantes, outil `tools/placement.py` pour les proposer
- [ ] Afficher aussi les cases de départ des monstres (en rouge) pendant le placement, comme Dofus
- [x] **(MVP)** Coups critiques (5 % par défaut par sort, bonus « % Critique » d'équipement, × 1,5)
- [x] **(MVP)** Groupes de 1 à 3 monstres (limite de l'alpha), d'espèces mélangées, tous visibles sur
  la carte ; composition fixe ou tirée au sort à chaque apparition
- [ ] Groupes plus grands (jusqu'à 8) une fois l'équilibrage fait
- [x] **(MVP)** IA : sorts notés sur chaque cible (dégâts, soins, bonus/malus, glyphes, pièges) ;
  comportements `distance` (frondeurs) et `soutien`
- [ ] Tacle / fuite (activable pour tester)
- [ ] Monstres agressifs (engagent le combat à proximité)
- [x] Mini-boss de fin de région avec script par phases (`boss` et `phases` dans les données ; soin
  interdit au changement de phase) : Krasbouk, Balourd des Abîmes, Mère-Toile et Grondin
  (réapparition en 60 s au plus pendant l'alpha)

### Monstres et butin
- [x] **(MVP)** Monstres répartis sur les 4 zones, dont des PNJ combattants de chaque camp (miliciens
  de Hautepierre, bûcherons de Brumerive, gobelins) : 50 monstres (familles, élites, mini-boss,
  variantes, Grondin, Souverain Cendré)
- [x] **(MVP)** Paliers de niveau dans chaque zone de départ : 1–3, 4–6, 7–9 et 10–12 dans chacune,
  asymétriques entre zones (GDD § 3.5)
- [x] **(MVP)** Niveau variable dans une famille : tiré à l'apparition dans la tranche du palier, avec
  des poids par famille (rat des galeries surtout 1, un peu 2, parfois 3 ; grouilleur l'inverse) ;
  élites à niveau fixe ; niveau sauvegardé avec le groupe et affiché dans la bulle (GDD § 3.5, § 8.1)
- [x] **(MVP)** Caractéristiques selon le niveau (PV, Force, Intelligence, Chance, Agilité,
  résistances, XP) ; butin indépendant du niveau ; PA et PM fixes pour toute la famille, sauf
  exception déclarée dans ses données
- [x] Niveaux variables pour les familles de toutes les zones (avec leurs paliers)
- [x] Deux types de monstres par zone de départ, avec deux attaques et un butin propre chacun
- [x] **(MVP)** Tables de butin, prospection (sans seuil), raretés (couleurs), écus
- [x] Limite de butin par monstre partagée entre les joueurs (quantité max de la ligne), tirage du
  plus prospecteur au moins prospecteur (prêt pour le groupe)
- [x] **(MVP)** Écran de butin en fin de combat
- [x] **(MVP)** Réapparition des groupes vaincus (2 à 3 minutes, réglable par groupe ; sauvegardée)
- [x] Groupes qui se promènent sur la carte (quelques pas toutes les 8 à 20 s, à 3 cases au plus de
  leur origine, jamais sur le joueur, une porte, un bord de sortie ou derrière un bâtiment)
- [x] Un monstre élite par famille (Loup alpha, Frondeur vétéran, Rat-roi, Grouilleur ancestral,
  Grand cerf de la Lisière, Arbre millénaire) : plus grand, plus fort, butin rare plus fréquent
- [x] Apparition des élites : tentative toutes les 5 à 6 min de jeu (temps global), sur une carte au
  hasard de leur famille, nouveau groupe ou remplacement d'un monstre s'il y a 3 groupes ; une seule
  en vie par espèce ; ancienneté (losanges puis couronne, +10 % de butin par rang, 10 rangs) ;
  sauvegardées
- [ ] Ancienneté des élites : passer d'un rang par minute (tests) à un rang par heure
- [x] Variantes Corrompues : loup cendreux, grouilleur de braise, arbre calciné (Hautepierre, et
  dans le repaire de chaque mini-boss une fois vaincu)

### Équipement et inventaire
- [x] **(MVP)** Inventaire (ressources empilées, équipements) limité à 60 places ; fenêtre (touche I)
- [x] Sac plein : le butin de combat entre quand même, en surplus ; plus de combat tant qu'on n'a pas
  fait de la place (message à la fin du combat, dans l'inventaire et au clic sur un groupe)
- [x] Objets de quête dans l'inventaire (type `quete`, ni vendus ni jetables)
- [x] **(MVP)** Équipement : arme, coiffe, cape, amulette, 2 anneaux, ceinture, bottes ; équipement de départ par Voie
- [x] **(MVP)** Conditions d'équipement (niveau, caractéristiques ; pas deux objets identiques)
- [x] **(MVP)** Armes utilisables en combat (attaque de l'arme dans la barre de sorts)
- [x] Jets aléatoires de statistiques
- [x] Plus d'objets pour couvrir les niveaux 1 à 30 (133 équipements, 66 ressources, 6 objets de
  quête)
- [x] **(MVP alpha test)** Système de panoplies : bonus de panoplie qui grandit avec le nombre de
  pièces équipées, affiché dans l'inventaire et chez le marchand (pièces portées / palier actif)
- [x] **(MVP alpha test)** Six panoplies élémentaires de 6 pièces (coiffe, cape, amulette, anneau,
  ceinture, bottes) : Acier, Flamme, Givre, Tempête, Sacré, Impie (GDD § 9.3)
- [x] **(MVP alpha test)** Panoplie Initiative et Dommages (3 pièces) et panoplie Prospection
  (3 pièces), à mélanger avec une panoplie élémentaire incomplète
- [ ] Équilibrer les panoplies après les retours de test (prix, niveau, paliers)
- [ ] Recettes de forgeron et/ou butin pour obtenir ces panoplies
- [ ] Équipement visible sur le personnage (coiffe, cape, arme)
- [ ] Objet parodique : **Cape en peau d'ananas** (« la peau d'ananas résiste à une bille d'acier
  chauffée à 1000 °C » : l'armure anti-dragon). Pas terrible en caractéristiques, mais **beaucoup de
  résistance Flamme** : l'objet à sortir contre la Cendre, le Souverain Cendré et les variantes
  corrompues. Demande des bonus de résistance sur l'équipement (aujourd'hui seulement les
  caractéristiques) ; recette ou butin à définir (GDD § 9.2)
- [x] Marchands PNJ (achat / vente) : Barlimon (Brumerive), Zogrub (Crasse-Roc) et Lindorë (Sylvebrume) vendent tous les objets, prix selon la rareté, revente à 25 %
- [x] Coffre personnel dans la maison du joueur (100 places, sauvegardé)
- [ ] Banque

### Métiers
- [x] **(MVP)** Système de métier générique (niveau 1 à 100, XP, recettes) ; métiers sur la fiche du personnage
- [x] **(MVP)** Bûcheron : frêne et chêne, repousse en 1 à 2 minutes
- [x] Bûcheron : if (niv. 8), hêtre (niv. 15), malorme (niv. 22) — lot Métiers
- [x] **(MVP)** Mineur : cuivre et fer, repousse en 1 à 2 minutes
- [x] Mineur : étain (niv. 8), argent (niv. 15), obsidienne (niv. 22) — lot Métiers
- [x] **(MVP)** Forgeron : atelier (Célébrimbert à Brumerive, Krogma à Crasse-Roc, Aelthar à Sylvebrume), interface de fabrication, 10 recettes
- [x] Forgeron : 23 recettes (13 de plus avec le lot Métiers, qui demandent des butins de
  plusieurs zones)
- [x] Ressources de monstres utilisées dans les recettes (peau et croc de loup)
- [x] Passif humain : +10 % d'XP de métier
- [x] Ressources rares de récolte : 1 % par récolte, un exemplaire à la place de la récolte normale
  (`rare` dans les données, `Profession.RARE_CHANCE`) ; 10 ressources rares et 6 recettes améliorées
  (`docs/design/chantier3_brouillon/src/ressources_rares.py`)
- [ ] Futurs métiers de récolte (herboriste, pêcheur…) : une ressource rare par ressource, même règle
- [ ] Animation de récolte (durée fixe, outil en main)

### Quêtes
- [x] **(MVP)** Conception du chantier 6 ([docs/design/chantier6_quetes.md](design/chantier6_quetes.md)) :
  système, 3 tutoriels, actes I et II par camp, début de l'acte III, 15 secondaires ; production
  en 4 lots (`docs/design/chantier6/produire_lot<n>.py`)
  - [x] Lot 1, **système** : `core/quests/` (`Quest`, `QuestLog`, `QuestBook`), 8 types
    d'objectifs, butin et objets de quête, conditions de camp, XP en combats de référence,
    sauvegarde ; marques `!`/`?` des PNJ, proposition (Accepter / Plus tard), journal (Q), suivi
    sous la minicarte
  - [x] Lot 2, **tutoriels et acte I** : 15 quêtes, 2 PNJ (bourgmestre Pansu, Père Pomponne),
    5 objets et leurs icônes
  - [x] Lot 3, **secondaires des zones de départ** (15 quêtes, 5 par zone, ouvertes à tous les
    camps après n'importe quel tutoriel)
  - [x] Lot 4, **acte II et début de l'acte III** (11 quêtes : 3 par camp à Hautepierre, puis le
    Conseil des Peuples Libres et la Brèche, communs), 8 objets et leurs icônes
  - [ ] Option : secondaires de Hautepierre (3 quêtes), marqueur de quête sur la carte du monde
- [x] **(MVP)** Moteur de quêtes : étapes, objectifs (parler, vaincre, récolter, apporter, aller à), récompenses
- [x] **(MVP)** Journal de quêtes et suivi de l'objectif courant
- [x] **(MVP)** Icônes `!` / `?` sur les PNJ
- [x] **(MVP)** Système de dialogues (simple : proposition, en cours, objectif, fin ; l'arbre ramifié
  attendra le § 11.2 du GDD)
- [x] **(MVP)** Tutoriel par camp (déplacement, combat, équipement, métier)
- [x] **(MVP)** Conditions de quête par camp et par acte de la quête principale
- [x] Environ 15 quêtes secondaires (15, lot 3 du chantier 6)
- [x] Quête principale : actes I et II (une chaîne par camp), début de l'acte III à Hautepierre
- [ ] Réputation simple par camp (si les quêtes de l'acte I le demandent)

### Monde
- [x] **(MVP)** Conception du contenu du chantier 3 ([docs/design/chantier3_brouillon](design/chantier3_brouillon/)) :
  **entièrement validée par l'auteur** (mini-boss révisés compris : réapparition en 60 s au plus,
  phases de profils différents selon le thème, plus de soin en phase). Durée réglée par l'XP ×3,5
  de l'alpha 1 (tout le contenu en 4 à 5 h)
- [x] **(MVP)** Production du chantier 3 par lots (4 zones, puis variantes et métiers) : chaque
  nouvelle carte à groupes reçoit son calque de placement. Outils : `src/produire.py <lot>`
  (monstres, sorts, objets, fragment de manifeste), `src/cartes.py` et `src/plans_<lot>.py` (plans)
  - [x] Lot **Brumerive** : 8 nouvelles cartes (et retouches des 2 existantes), 11 monstres dont
    Krasbouk, 14 sorts, 13 objets et leurs icônes, fourche, hache, casque ; objets hors boutique
    (`"boutique": false`)
  - [x] Lot **Crasse-Roc** : 8 nouvelles cartes (et retouches des 2 existantes), 11 monstres dont
    le Balourd des Abîmes, 14 sorts, 13 objets et leurs icônes, dessins de la vampipistrelle et du
    Balourd, palette « forges » (lave)
  - [x] Lot **Sylvebrume** : 7 nouvelles cartes (et retouches des 2 existantes), 11 monstres dont
    la Mère-Toile, 11 sorts, 13 objets et leurs icônes, dessins de la morille et de l'araignée
  - [x] Lot **Hautepierre, première moitié** : les 19 cartes (ville, routes, cartes cendrées, la
    Brèche) avec leur calque de placement, la Pierre de Passage de la Grand-Place (20 écus), les 3
    portes vers les zones de départ, palettes « hautepierre » et « cendree »
  - [x] Lot **Hautepierre, seconde moitié** : groupes et PNJ des 19 cartes (marchande, forgeron,
    personnages de la Citadelle…), 13 monstres (6 familles, leurs élites, Grondin), 23 sorts, 35
    objets et leurs icônes ; dessins du corbac, de la gargouille, de l'olifant, de Grondin, du troll
    (tête, assemblage), de la massue et de la capuche
  - [x] Lot **Variantes** (avancé pour Hautepierre) : loup cendreux, grouilleur de braise, arbre
    calciné (`"corrompu": true`, `"base"`, sans élite), 3 sorts, 4 objets et leurs icônes
  - [x] Dessins des décors de la ville : Tour Blanche, temple, tours de garde (portes, Vigie,
    horloge), fontaine et étals de la Grand-Place, Arbre Blanc, poteaux indicateurs aux 6 portes
    entre la ville et les zones de départ (`src/decors_ville.py`)
  - [x] Apparition des variantes corrompues après le mini-boss de leur zone : groupes
    `"apres_boss"` (un par repaire de mini-boss, la variante avec sa base), débloqués pour de bon
    à la première victoire contre le boss (`World.defeated_bosses`, sauvegardé)
  - [x] Intégration : combats simulés sur chaque groupe de chaque carte, pour les 4 Voies
    (`game/tools/simulation.gd`, rapport `docs/design/simulation_combats.md`). Le joueur est joué
    par l'IA des monstres, à leur niveau, équipement modélisé comme dans `balance.py`
  - [ ] **Ajustements d'équilibrage, après l'alpha test 1** (décision de l'auteur : attendre les
    retours des vrais joueurs ; constats de la simulation, IA contre IA, à confirmer en jeu) :
    - mini-boss au niveau 12 en solo : Krasbouk battu par l'arcaniste et le théologue seulement
      (guerrier 30 %, rôdeur 0 %), Mère-Toile par le théologue seulement, Balourd jamais par le
      rôdeur (et il retire ~50 % des PV aux autres) ;
    - Cendrillons (soutien qui fuit et se soigne) : combats de 30 à 80 tours ;
    - rôdeur le plus faible (20 à 70 % de victoires contre les arbres, bûcherons, briseurs) ;
      théologue très lent (2 à 3 fois plus de tours) mais presque intouchable, et sans sort de
      2 PA il ne vient pas à bout d'un milicien qui lève son bouclier (le gobelin, grâce à Coup
      bas, y arrive) ;
    - [x] monstres à moins de 3 PM : menace (PM + portée) portée à 7 au moins (GDD § 8.1) :
      Racines, Pluie de cendres, Ronces à 6 cases ; Spores, Nuage de rancune à 5 ;
    - [x] éléments des dégâts rééquilibrés (l'Acier faisait 74 % des monstres, 87 % de Brumerive) :
      un élément dominant par zone (GDD § 8.1), Acier 33 % du jeu, relevé dans le catalogue ;
    - monstres trop doux pour leur palier (moins d'un quart des PV de référence perdus) : rats,
      morilles, détrousseurs, gargouilles, olifants (mêlée seule, repoussés par leur propre charge) ;
    - durée : les combats durent 2 à 4 fois les tours du modèle (approche depuis les cases de
      placement comprise) ; à reporter dans `balance.py` (minutes par combat) pour garder 4 à 5 h
  - [x] Lot **Métiers** : 6 ressources de récolte (nœuds recolorés, sans nouveau dessin), posées sur
    31 cartes sans couper de chemin, 13 recettes de forgeron, 16 objets et leurs icônes
- [x] **(MVP)** Zone de départ humaine : Collines de Brumerive — 10 cartes + la maison (lot Brumerive)
- [x] **(MVP)** Zone de départ gobeline : Galeries de Crasse-Roc — 10 cartes + la maison (lot Crasse-Roc)
- [x] **(MVP)** Zone de départ elfe : Lisière de Sylvebrume — 9 cartes + la maison (lot Sylvebrume)
- [x] Carte d'élite de test : Trône de Cendre (Marches Cendrées), le Souverain Cendré, accessible par la Pierre de Passage
- [x] Chaque race démarre dans sa zone (humains à Brumerive, gobelins à Crasse-Roc, elfes à Sylvebrume)
- [x] **(MVP)** Zone commune : Hautepierre et environs — 19 cartes, ville, monstres, Grondin
- [ ] Villes hostiles aux autres camps avant l'acte III (gardes PNJ agressifs)
- [x] **(MVP)** Sauvegarde / chargement automatique (personnage, carte, position, groupes restants avec
  leur composition et leur place, groupes vaincus) dans `user://`
- [x] Pierres de Passage : une sur la 1re carte de chaque zone, voyage de l'une à l'autre
  (les zones ne sont pas reliées autrement pour l'instant)
- [x] Pierres de Passage à découvrir (en touchant la pierre), voyage payant (10 écus vers une zone de
  départ ; `prix` et `toujours_connue` dans les données), prix et pierres inconnues dans la fenêtre
- [x] Phase de test : toutes les Pierres de Passage connues dès le début (`World.ALL_PASSAGES_KNOWN`),
  tant que les zones ne sont pas reliées à pied
- [ ] Remettre la découverte des pierres (`ALL_PASSAGES_KNOWN` à false) quand les zones seront reliées
- [ ] Pierres de Passage dans d'autres zones (Hautepierre…), prix selon la distance
- [x] Carte du monde et minicarte : touche M (ou bouton du bandeau, ou clic sur la minicarte), un
  onglet par zone, cartes en grille d'après leurs coordonnées (`<zone>_<x>_<y>`), **tout le monde
  montré dès le début** comme dans Dofus (nombre de cartes visitées par zone), Pierres de Passage ;
  minicarte façon Dofus Rétro : la carte du monde en réduit, 5 × 5 cartes autour de la carte
  actuelle (nom au survol, repliable)
- [x] Point de résurrection : la dernière Pierre de Passage touchée (au départ, celle de la zone de
  départ) ; après une défaite, réveil à côté d'elle avec 1 PV, même sur une autre carte
- [ ] Point de résurrection aux temples
- [x] Portes entre cartes (`+` dans le plan) et cartes en intérieur (sol en parquet)
- [x] Maison du joueur dans chaque zone de départ (Brumerive, Crasse-Roc, Sylvebrume) : coffre partagé et lit (tous les PV) ; cartes personnelles (`"instance": "joueur"`)
- [x] PV gardés d'un combat à l'autre, régénération lente hors combat (1 PV / 2 s), 1 PV après une défaite

### Interface
- [x] **(MVP)** Bandeau bas façon Dofus Rétro, en exploration comme en combat : PV dans un cœur rouge
  qui se vide, PA dans une étoile bleue, PM dans une case verte, sorts en icônes (raccourci et coût
  en PA), bouton de fin de tour, boutons de menus (personnage, inventaire, sorts, métiers, carte,
  quêtes)
- [x] Marque au sol (losange doré) devant les portes où l'on peut entrer
- [x] **(MVP)** Fenêtres : inventaire + poupée, caractéristiques, sorts, quêtes, métiers
  (inventaire, caractéristiques, sorts avec un onglet par famille (Voie, race, arme), métiers avec
  un onglet par métier, boutique, atelier, coffre, journal des quêtes)
- [x] **(MVP)** Menu principal, options (volume, plein écran, taille de la fenêtre, mode tactique ;
  `user://options.cfg`, hors sauvegarde), pause (Échap : le jeu s'arrête ; reprendre, options,
  menu principal, quitter)
- [ ] Infobulles d'objets et de sorts (comparaison avec l'équipement porté)
- [x] En combat, au survol d'un combattant : nom, niveau, PV, PA, PM et résistances à la place de la
  barre de sorts
- [x] Inventaire : 8 cases « Reliques » visibles dès le début (vides tant que la Relique n'est pas
  reprise), en plus des 2 anneaux
- [ ] Raccourcis clavier
- [x] Retour de test « combats lents » : un sort ne fait plus attendre ses animations, actions
  gardées pendant une marche et envoyées dans l'ordre (5 au plus), raccourcis de sorts AZERTY
  (& é " ' ( - è _ ç à) en plus de 1 à 0
- [x] **(MVP)** Mode tactique en combat, façon Dofus (GDD § 14.3) : bouton « Tactique » ou touche T,
  cases à plat en damier, eau en trous (retours de test, lot 3), obstacles qui bloquent la vue en blocs, décor masqué,
  combattants en pions (couleur du camp, initiale, PV), retenu d'un combat à l'autre (`Options`)
- [x] Historique du combat (GDD § 14.3) : sorts lancés et leurs effets, couleurs des éléments,
  repliable (touche H) ; survol des glyphes et pièges alliés : sort, lanceur, tours restants
- [x] Chiffres flottants du combat à la couleur de l'élément (dégâts, soins, boucliers, poisons)
- [x] Fiche du personnage : l'aide de chaque caractéristique cite dégâts, soins et boucliers de ses
  éléments (l'Intelligence n'était plus seule à « augmenter les soins »)
- [x] Retours de test, lot 2 : équiper par double-clic ou glisser-déposer (sac ↔ emplacements, refus
  expliqués), bouton « Réinitialiser » (restat gratuit pendant l'alpha, commande
  `reinitialiser_points`), provenance des valeurs de la fiche au survol (points, race, chaque objet,
  panoplie ; `Character.stat_sources`)
- [x] Retours de test, lot 4 : course au-delà de 3 cases (× 1,5, `MapView.walk_speed`),
  bouton « S'asseoir » et touche A (régénération × 3, `World.sitting`, commande `s_asseoir`,
  pose assise du `Rig`, relevé en marchant ou en combat), barre d'objets hors combat à la place
  des sorts (`CombatHud.ItemSlot`, 8 emplacements, seulement montrée : pas de raccourcis
  d'équipement, choix de l'auteur)
- [x] Retours de test, lot 3 : frise de tour en portraits (`CombatHud.TurnPortrait` : le
  combattant dessiné dans un cadre à la couleur de son camp, PV en bas, doré à son tour, nom en
  infobulle), clic droit sur un sort pour le lancer sur soi (`MapView.cast_on_self`), dégâts et
  soins prévus au-dessus des combattants touchés quand on vise (`Combat.spell_preview`, sans
  hasard ni critique), glyphes à la couleur de leur élément (champ `element` de l'événement
  `glyphe`), eau en trous dans le mode tactique
- [ ] Barre d'objets : la rendre utilisable (glisser un consommable, clic ou touche pour l'utiliser,
  emplacements sauvegardés) quand les premiers consommables arriveront (Alchimiste, nourriture)

### Art et audio

*(alpha 2)* Reporté au second test, sauf les dessins demandés par le contenu du chantier 3.

- [x] Test de direction artistique sur la place de Brumerive : sol sans quadrillage, chemins, eau,
  arbres, rochers, minerais, maison et auberge, personnages articulés (humain, gobelin), loup, PNJ
- [x] Outils : capture d'écran du jeu (`tools/screenshot.gd`) et planche des images (`tools/art_sheet.gd`)
- [x] Style étendu à tout le jeu : champs, intérieur de la maison (murs, plancher, coffre, lit),
  menu illustré, aperçu du personnage à la création, thème de l'interface (bois et or)
- [x] Palettes de zone (Crasse-Roc plus sombre et terne, Sylvebrume plus fraîche) ; cabane gobeline,
  entrée des galeries, pavillon elfe, Pierre de Passage, fougères et champignons
- [x] Personnages réduits à 80 % (taille validée)
- [ ] **(MVP)** *(alpha 2)* Tileset : intérieurs, clôtures, ponts, murets (Brumerive et Hautepierre
  sont dessinées, avec les décors de la ville)
- [ ] **(MVP)** *(alpha 2)* Sprites des 3 races × 2 sexes (repos, marche, attaque, sort, dégât, mort,
  récolte) (fait : humain, elfe, gobelin, repos / marche / attaque ; reste : femmes, dégât, mort,
  récolte)
- [x] **(MVP)** Dessins des monstres de l'alpha (toutes les familles, élites, mini-boss et Grondin)
- [ ] **(MVP)** *(alpha 2)* Effets visuels des sorts
- [x] **(MVP)** Icônes d'objets, de ressources et de sorts : sorts des Voies et des races, attaques
  des armes, jauges du bandeau, tous les objets (inventaire en grille d'icônes, boutique, coffre,
  atelier, métiers, butin)
- [x] Système de recoloration des personnages (modèles SVG à couleurs remplaçables)
- [ ] *(alpha 2)* Musiques : 2 thèmes de région, 1 thème de combat, 1 thème de boss, menu
- [ ] *(alpha 2)* Bruitages : interface, pas, impacts, sorts

### Qualité
- [ ] *(alpha 2)* Équilibrage des 9 combinaisons race × classe sur les niveaux 1 à 30
- [ ] Session de test externe (5 joueurs minimum) + formulaire de retours (voir « Lancement de
  l'alpha test 1 »)
- [x] Build distribuable : GitHub Pages (itch.io en accès privé plus tard, si besoin)

---

## Phase 3 — Solo étendu (objectifs long terme)

### Races et classes
- [ ] Race **Nain** (allié) : passif *Peau de pierre*, sort *Fureur des profondeurs*, zone de départ et chaîne d'acte I
- [ ] Race **Orc** (ennemi) : passif *Peau épaisse*, sort *Cri de guerre*, zone de départ et chaîne d'acte I
- [ ] Race **Semi-homme** (neutre) : passif *Petit mais discret*, sort *Second petit-déjeuner*, zone de départ et chaîne d'acte I
- [ ] Race **Géant** (allié) : bonus, passif *Carrure*, sort *Coup de semelle*, assemblage agrandi (≈ 1,25×), zone de départ et chaîne d'acte I
- [ ] Race **Squelette** (ennemi, mort-vivant) : passif *Déjà mort*, sort *Remonter les os*, assemblage squelette, zone de départ et chaîne d'acte I
- [ ] Race **Lutin** (neutre) : passif *Farceur*, sort *Tour de passe-passe*, assemblage réduit (≈ 0,8×), zone de départ et chaîne d'acte I
- [ ] Différencier les races proches (Nain / Orc, Semi-homme / Lutin) et valider leurs noms de peuple (GDD § 4.2)
- [ ] Voies de corps à corps : **Paladin** (guerrier sacré) et **Myrmidon** (guerrier tank)
- [ ] Voies mixtes : **Ombre** (assassin invisible) et **Chronomancien** (maître du temps, remplace le Venomancien)
- [ ] Voie à distance : **Démoniste** (dégâts impies) ; le Théologue est avancé dans l'alpha
- [ ] Mécaniques de ces Voies : invisibilité, poisons et dégâts sur la durée, provocation, auras,
  invocations, sacrifice de PV, résurrection (multi)
- [ ] Étendre la progression jusqu'au niveau 100

### Système des Voies (classes mixtes)
- [ ] Maîtres de Voie (PNJ) et quêtes d'apprentissage des Fondamentaux
- [ ] Rangs I / II / III et règles de spécialisation
- [ ] Changement de spécialisation (quête + coût)
- [ ] Barre de sorts limitée et préréglages de barres
- [ ] Passif de Maîtrise de Voie
- [ ] Quêtes de Voie (déblocage du rang III)
- [ ] **Simulateur de combat** automatisé pour détecter les combinaisons abusives (base faite :
  `game/tools/simulation.gd` ; reste les Voies mixtes et le modèle voie/rang)
- [ ] **Voies Miroir** : spécialisation opposée qui retourne l'élément d'une Voie
  (sacré ↔ impie, givre ↔ flamme, acier ↔ tempête), débloquée par une quête de Voie (GDD § 5.3)

### Donjons
- [ ] Système de donjon : clé, suite de salles, sortie / abandon
- [ ] Scripts de boss (phases, invocations, zones dangereuses)
- [ ] Un donjon par région (panoplie et ressources exclusives)
- [ ] Donjons de Relique (boss = Héraut Cendré)
- [ ] Compagnons PNJ pour aider en solo

### Quêtes et scénario
- [ ] Dialogues ramifiés avec conditions
- [ ] Drapeaux de monde persistants (choix et conséquences)
- [ ] Réputation auprès des peuples et factions
- [ ] Chaînes de quêtes des 8 Reliques
- [ ] Chaîne finale et combat contre le Souverain Cendré
- [ ] Mise en scène dans le moteur (déplacements scriptés, caméra, bulles)
- [ ] Événements de monde (invasions cendrées)

### Encyclopédie
- [ ] Fenêtre d'encyclopédie avec recherche et liens entre fiches (GDD § 14.4)
- [ ] Fiches d'objets : jets possibles, conditions, panoplie, comment l'obtenir (butin, recette, marchand)
- [ ] Fiches de monstres : caractéristiques, résistances, sorts, butin et taux, zones, élite
- [ ] Fiches de classes et de races : rôle, éléments, sorts, passif et sort racial
- [ ] Bestiaire : fiches de monstres qui se remplissent à chaque combat gagné, complètes en 10 combats
  (paliers : 1 nom et niveau, 2 PV/PA/PM, 3 résistances, 5 sorts, 7 butin, 10 taux, zones, élite) ;
  compteur de victoires par monstre sauvegardé

### Objets légendaires
- [ ] Les 8 Reliques (bagues) : 8 emplacements équipables en même temps en plus des 2 anneaux,
  pouvoirs uniques, une par Héraut Cendré (GDD § 3.3, § 9.1)
- [ ] Objets légendaires à effets uniques (butin très rare et quêtes)
- [ ] Archimonstres (variantes rares nommées)
- [ ] Forgemagie (modification des jets avec des runes)

### Métiers
- [ ] Herboriste et Alchimiste (potions)
- [ ] Tailleur, Joaillier, Cordonnier
- [ ] Pêcheur et Cuisinier
- [ ] Éleveur et montures
- [ ] Objets personnalisés des artisans de haut niveau (GDD § 10.4) : choisir le nom de la
  compétence (Chef-d'œuvre, Pièce de maître, Façonnage libre) ; score par statistique ; limites par
  ligne, par objet, par statistique et nombre de lignes, selon le niveau de l'objet ; coût en
  ressources de l'élément de chaque statistique (lâchées par les monstres de cet élément) ;
  liste de patrons en plus des recettes classiques ; trancher les questions ouvertes (jets, armes,
  objets liés, forgemagie, niveau de métier requis)

### Monde
- [ ] Régions : Sylvebrume, Forges de Durhal, Plaines d'Orvent, Marais Gris, Marches Cendrées / Nocthrône
- [ ] Cycle jour/nuit (optionnel)
- [ ] Familiers

---

## Phase 4 — Fondations réseau

Peut démarrer dès que l'alpha solo est stable.

- [ ] Choisir la pile serveur (Godot sans affichage, Node/Colyseus…) et le transport (WebSocket, ENet)
- [ ] Définir le protocole (sérialisation des commandes / événements, versionnage)
- [ ] Faire tourner le noyau de jeu côté serveur (même code que le solo)
- [ ] Comptes : inscription, connexion, sessions (jetons), hachage des mots de passe
- [ ] Base de données : schéma (comptes, personnages, inventaires, quêtes, métiers) — PostgreSQL
- [ ] Synchronisation de l'exploration (positions, entrées et sorties de carte)
- [ ] Combat multijoueur : tours avec limite de temps, déconnexion / reconnexion en combat
- [ ] Tests de charge (combien de joueurs et de combats par processus)
- [ ] Environnement de test hébergé (staging)

---

## Phase 5 — Multijoueur

### Instances
- [ ] Gestionnaire d'instances : plafond par carte, création et fusion automatiques
- [ ] Attribution d'instance (priorité amis / groupe, puis remplissage)
- [ ] Deux mondes d'instances selon l'avancement : actes I et II (entre débutants, havres de paix des
  zones de départ) et à partir de l'acte III (instances communes) ; bascule définitive dès la première
  quête de l'alliance, annoncée au joueur (GDD § 13.2)
- [ ] Mode mentor : un joueur de l'acte III rejoint un ami débutant en groupe, sans récolte ni butin
- [ ] Passer les actes I et II pour commencer à l'acte III (choix définitif, confirmation qui
  rappelle la perte des récompenses de quêtes : XP, objets, écus) (GDD § 13.2)
- [ ] Rejoindre l'instance d'un ami
- [ ] Instances privées de donjon par groupe
- [ ] Maisons de joueurs instanciées : chaque joueur entre dans sa propre copie de `maison_joueur` (et des maisons de Crasse-Roc et Sylvebrume)
  (cartes marquées `"instance": "joueur"`), avec son coffre

### Social
- [ ] Chat : local, groupe, commerce, recrutement, privé ; filtres
- [ ] Liste d'amis et d'ignorés, statut en ligne
- [ ] Groupe (jusqu'à 8) : invitation, chef, partage d'XP, suivi
- [ ] Guildes : création, rangs, banque (puis niveau de guilde)
- [ ] Émotes

### Gameplay multi
- [ ] Rejoindre le combat d'un ami, verrouiller un combat, mode spectateur
- [ ] Décider et appliquer la règle de groupe entre camps opposés avant l'acte III (GDD § 13.3)
- [ ] Répartition du butin en groupe : brancher les joueurs du combat sur `Loot.roll` (limite par
  monstre et tirage par ordre de prospection déjà faits) ; répartition des écus à décider
- [ ] Objectifs de quêtes partagés en groupe
- [ ] Ouvrir l'inventaire, la fiche et les autres fenêtres pendant un combat (consultation pendant
  le tour des autres joueurs) : consultation seulement, ni changement d'équipement ni objet
  consommable utilisé en combat. Aujourd'hui fermées en combat
- [ ] Échange sécurisé entre joueurs
- [ ] Artisanat assisté et commandes
- [ ] Hôtel des ventes
- [ ] Événements de monde collectifs

### Exploitation
- [ ] Anti-triche : validation serveur, limitation de débit, journal des transactions
- [ ] Outils de modération (signalement, sanctions, journal de chat)
- [ ] Supervision (métriques, journaux, alertes) et sauvegardes de la base
- [ ] Déploiement (conteneurs, mise à jour sans perte de données)
- [ ] Décider de la migration des personnages solo vers le serveur
- [ ] Bêta fermée

---

## Idées en attente (backlog)

- PvP (duels, arènes)
- Maisons de joueurs : achat, décoration, plusieurs maisons par ville
- Succès / hauts faits
- Bestiaire et encyclopédie du monde en jeu
- Éditeur de cartes et de quêtes intégré pour accélérer la production de contenu

### Identité des classes (à décider après les premiers retours de l'alpha 1)

**Choix de l'auteur pour l'alpha 1 (fait)** : Arcaniste Flamme / Givre (états élémentaires choisis
par *Composition* dans une grille, *Créer
un sort* à 2 PA, 4 sorts créés à 4 PA, 2 places dans la barre (vides : « ? ») et 3 orbes d'états ; anciens sorts retirés ; la Tempête
annoncée pour la suite), *Charge* du Guerrier, *Collet* du
Rôdeur, *Absolution* du Théologue (GDD § 4.3). Les idées ci-dessous restent pour la suite.
- [ ] IA qui compose les états de l'Arcaniste (simulation des combats, futurs monstres mages)
- [ ] Arcaniste : états et combinaisons de Tempête (6 sorts créés de plus), après l'alpha 1

Rien à produire avant les premiers tests. But : que chaque classe se joue différemment (comme
dans Dofus), au lieu de 4 sorts de dégâts. Trois idées par classe, à choisir (une, deux au
plus) ; toutes doivent marcher en solo, sans allié.

- **Guerrier**
  - *Rancune* (jauge) : chaque coup reçu donne de la Rancune (ex. 1 pour 5 PV perdus, 10 au
    plus) ; Frappe et Tourbillon la dépensent pour plus de dégâts, Second souffle la change en
    soin. Il cherche à être frappé. Coût moyen (compteur par combattant + affichage).
  - *Élan* (charge) : chaque case parcourue dans le tour donne +X % au prochain coup de mêlée ;
    il faut partir de loin. Coût faible (PM dépensés avant le sort).
  - *Défi* (provocation solo) : un ennemi Défié qui frappe le Guerrier prend un contrecoup ;
    s'il fuit ou frappe un autre, il prend un malus. Base de la future provocation du Myrmidon.
    Coût moyen (état qui réagit aux actions de la cible).
- **Rôdeur**
  - *Rabatteur* : Collets (pièges existants) + Tir perçant ou Flèche de rabat qui poussent ; un
    ennemi poussé dans un collet est immobilisé et prend des dégâts en plus (style Sram). Coût
    le plus faible (reste la règle « poussé dans un piège »).
  - *Pistage* : chaque Flèche pose une Trace (3 au plus) ; le Coup de dague les consomme pour un
    gros coup, la Roulade ramène à distance. Va-et-vient distance/contact. Coût moyen (état
    cumulable).
  - *Carquois compté* : 6 flèches par combat, chaque tir laisse une flèche au sol près de la
    cible, à ramasser en marchant dessus. Risque de frustration : tester sur un seul sort. Coût
    élevé (objets posés sur la grille).
- **Arcaniste** (refonte multi-élément prévue après l'alpha test, GDD § 4.3 : ces idées
  ne valent que d'ici là)
  - *Choc thermique* : la Flamme pose Brûlé (poison Flamme), le Givre pose Gelé ; frapper un
    Brûlé au Givre (ou l'inverse) déclenche un Choc (gros dégâts, l'état disparaît). Coût moyen.
  - *Thermostat* (jauge) : la Flamme fait monter la température, le Givre la fait baisser ;
    chaud, Flamme renforcée ; froid, Givre renforcé ; au maximum il **explose** (touche tout
    autour de lui, lui compris), au minimum il gèle (perd ses PM). Colle à sa description.
    Coût moyen (même jauge que la Rancune).
  - *Incantation différée* : un sort lourd marque une zone visible qui explose au début de son
    tour suivant ; l'Éclat de givre empêche d'en sortir (style Xélor/Féca). Coût moyen (glyphe
    à retardement, l'IA doit apprendre à fuir les zones marquées).
- **Théologue**
  - *Faire la quête* (jauge de Foi) : Châtiment et Sermon remplissent la Foi, les soins et le
    Rempart la consomment pour être plus forts : un soigneur qui frappe pour soigner. Coût moyen
    (même jauge).
  - *Commandements* : il impose une règle à un ennemi (« Tu ne bougeras point », « Tu ne
    frapperas point de loin », « Tu ne frapperas point le prêcheur ») ; une désobéissance coûte
    une Pénitence (dégâts Sacrés). Le plus original. Coût élevé (surveiller déplacements et
    sorts ; l'IA pourra apprendre à les respecter plus tard).
  - *Terre consacrée* : un sort pose une zone sacrée (glyphe) qui renforce les soins et brûle
    les ennemis à chaque tour ; le Sermon pousse vers l'autel ou en chasse. Coût faible.

Synthèse : une **jauge de classe** commune (Rancune, Thermostat, Faire la quête) et un **état
réactif sur la cible** (Pistage, Choc thermique, Défi) couvrent la plupart des idées. Proposition :
Guerrier Rancune (+ Élan), Rôdeur Rabatteur, Arcaniste Thermostat, Théologue Faire la quête
(Commandements plus tard, avec le Paladin ou en alpha 2). Toute adoption demande de relancer
`tools/simulation.gd` et de mettre à jour GDD § 4.3, le guide des testeurs et le catalogue.
