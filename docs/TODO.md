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
- [x] Ordre de jeu affiché (version texte ; frise illustrée plus tard)

### Contenu de test
- [x] 1 personnage Guerrier avec 4 sorts
- [x] 2 types de monstres (loup des collines, gobelin frondeur)
- [x] Assets temporaires (formes simples dessinées par le code)

---

## Phase 2 — Alpha solo (objectifs court terme)

Objectif : **10 à 15 h de jeu solo, niveaux 1 à 30 : 3 zones de départ (une par camp) + Hautepierre**.

### Personnage
- [x] **(MVP)** Écran de création : race, classe, nom, aperçu et récapitulatif (couleurs selon race et Voie)
- [x] **(MVP)** 3 races jouables, une par camp : Humain (allié), Gobelin (ennemi), Elfe (neutre) — bonus, passif, sort racial (passifs Polyvalence et Chapardeur actifs avec les métiers et le butin)
- [x] **(MVP)** Camp porté par la race dans les données ; carte de départ par race (`carte_depart`)
- [ ] Faire partir Gobelins et Elfes de leurs propres zones (à créer) — pour l'instant, tout le monde part de Brumerive
- [x] 3 classes jouables : Guerrier, Rôdeur, Arcaniste (4 sorts chacune)
- [ ] **(MVP)** Compléter jusqu'à environ 10 à 12 sorts par classe, débloqués par niveau (1 à 30)
- [x] **(MVP)** Caractéristiques, points à répartir (fiche, touche C), statistiques dérivées (PV, initiative, dégâts, soins, XP)
- [x] **(MVP)** XP, montée de niveau (courbe 60·n + 20·n²)
- [ ] Points de sort (avec le système des Voies)
- [ ] Rendement décroissant des caractéristiques
- [ ] **(MVP)** Modèle de sort avec `voie` et `rang` (préparation du système des Voies)
- [ ] Restat (objet ou PNJ)
- [ ] Décider s'il faut avancer le Théologue (soin) dans l'alpha pour l'équilibrage solo

### Combat
- [x] **(MVP)** Éléments composés **Sacré** (Acier + Flamme : moyenne Force / Intelligence, moyenne
  des résistances) et **Impie** (Tempête + Givre : moyenne Agilité / Chance), sorts et résistances ;
  premières armes : Masse bénite (Sacré), Dague du Mauvais Œil (Impie)
- [x] **(MVP)** Statistique **Dommages** : +X dégâts bruts à chaque ligne de dégâts de tout sort ou
  arme, sans élément ni résistance, pas sur les soins ; portée par les objets (Chevalière du
  Cogneur), affichée dans la fiche
- [ ] Sorts de Voie sacrés et impies (avec les nouvelles Voies)
- [ ] **(MVP)** Tous les types d'effets : soin, bouclier, bonus/malus, poussée, téléportation, états
- [ ] **(MVP)** Coups critiques
- [x] **(MVP)** Groupes de 1 à 3 monstres (limite de l'alpha), d'espèces mélangées, tous visibles sur
  la carte ; composition fixe ou tirée au sort à chaque apparition
- [ ] Groupes plus grands (jusqu'à 8) une fois l'équilibrage fait
- [ ] **(MVP)** IA : `ranged`, `support`
- [ ] Tacle / fuite (activable pour tester)
- [ ] Monstres agressifs (engagent le combat à proximité)
- [ ] Mini-boss de fin de région avec script par phases

### Monstres et butin
- [ ] **(MVP)** Environ 15 à 20 monstres répartis sur les 4 zones (dont des PNJ combattants de chaque camp)
  (7 aujourd'hui : loup et frondeur gobelin à Brumerive, rat des galeries et grouilleur à Crasse-Roc,
  cerf enchanté et arbre vivant à Sylvebrume, et le Souverain Cendré)
- [x] Deux types de monstres par zone de départ, avec deux attaques et un butin propre chacun
- [x] **(MVP)** Tables de butin, prospection (sans seuil), raretés (couleurs), écus
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
- [ ] Variantes Corrompues (2 ou 3 pour tester le concept)

### Équipement et inventaire
- [x] **(MVP)** Inventaire (ressources empilées, équipements) limité à 60 places ; fenêtre (touche I)
- [x] Sac plein : le butin de combat entre quand même, en surplus ; plus de combat tant qu'on n'a pas
  fait de la place (message à la fin du combat, dans l'inventaire et au clic sur un groupe)
- [ ] Objets de quête dans l'inventaire (avec les quêtes)
- [x] **(MVP)** Équipement : arme, coiffe, cape, amulette, 2 anneaux, ceinture, bottes ; équipement de départ par Voie
- [x] **(MVP)** Conditions d'équipement (niveau, caractéristiques ; pas deux objets identiques)
- [x] **(MVP)** Armes utilisables en combat (attaque de l'arme dans la barre de sorts)
- [x] Jets aléatoires de statistiques
- [ ] Plus d'objets (22 équipements aujourd'hui) pour couvrir les niveaux 1 à 30
- [ ] **(MVP alpha test)** Système de panoplies : bonus de panoplie qui grandit avec le nombre de
  pièces équipées, affiché dans l'inventaire (pièces portées / bonus actifs)
- [ ] **(MVP alpha test)** Six panoplies élémentaires de 6 pièces (coiffe, cape, amulette, anneau,
  ceinture, bottes) : Acier, Flamme, Givre, Tempête, Sacré, Impie (GDD § 9.3)
- [ ] **(MVP alpha test)** Panoplie Initiative et Dommages (3 pièces) et panoplie Prospection
  (3 pièces), à mélanger avec une panoplie élémentaire incomplète
- [ ] Recettes de forgeron et/ou butin pour obtenir ces panoplies
- [ ] Équipement visible sur le personnage (coiffe, cape, arme)
- [x] Marchands PNJ (achat / vente) : Barlimon (Brumerive), Zogrub (Crasse-Roc) et Lindorë (Sylvebrume) vendent tous les objets, prix selon la rareté, revente à 25 %
- [x] Coffre personnel dans la maison du joueur (100 places, sauvegardé)
- [ ] Banque

### Métiers
- [x] **(MVP)** Système de métier générique (niveau 1 à 100, XP, recettes) ; métiers sur la fiche du personnage
- [x] **(MVP)** Bûcheron : frêne et chêne, repousse en 1 à 2 minutes
- [ ] Bûcheron : 2 ou 3 essences de plus (if…)
- [x] **(MVP)** Mineur : cuivre et fer, repousse en 1 à 2 minutes
- [ ] Mineur : 2 ou 3 minerais de plus (argent…)
- [x] **(MVP)** Forgeron : atelier (Célébrimbert à Brumerive, Krogma à Crasse-Roc, Aelthar à Sylvebrume), interface de fabrication, 10 recettes
- [ ] Forgeron : environ 20 recettes
- [x] Ressources de monstres utilisées dans les recettes (peau et croc de loup)
- [x] Passif humain : +10 % d'XP de métier
- [ ] Animation de récolte (durée fixe, outil en main)

### Quêtes
- [ ] **(MVP)** Moteur de quêtes : étapes, objectifs (parler, vaincre, récolter, apporter, aller à), récompenses
- [ ] **(MVP)** Journal de quêtes et suivi de l'objectif courant
- [ ] **(MVP)** Icônes `!` / `?` sur les PNJ
- [ ] **(MVP)** Système de dialogues (arbre simple)
- [ ] **(MVP)** Tutoriel par camp (déplacement, combat, équipement, métier)
- [ ] **(MVP)** Conditions de quête par camp et par acte de la quête principale
- [ ] Environ 15 quêtes secondaires
- [ ] Quête principale : actes I et II (une chaîne par camp), début de l'acte III à Hautepierre
- [ ] Réputation simple par camp (si les quêtes de l'acte I le demandent)

### Monde
- [ ] **(MVP)** Zone de départ humaine : Collines de Brumerive (environ 8 à 10 cartes) — 2 cartes + la maison
- [ ] **(MVP)** Zone de départ gobeline : Galeries de Crasse-Roc (environ 8 à 10 cartes) — 2 cartes (entrée des galeries, le Crassier)
- [ ] **(MVP)** Zone de départ elfe : Lisière de Sylvebrume (environ 8 à 10 cartes) — 2 cartes (clairière de la Lisière, Futaie ancienne)
- [x] Carte d'élite de test : Trône de Cendre (Marches Cendrées), le Souverain Cendré, accessible par la Pierre de Passage
- [x] Chaque race démarre dans sa zone (humains à Brumerive, gobelins à Crasse-Roc, elfes à Sylvebrume)
- [ ] **(MVP)** Zone commune : Hautepierre et environs (ville + environ 15 cartes)
- [ ] Villes hostiles aux autres camps avant l'acte III (gardes PNJ agressifs)
- [x] **(MVP)** Sauvegarde / chargement automatique (personnage, carte, position, groupes restants avec
  leur composition et leur place, groupes vaincus) dans `user://`
- [x] Pierres de Passage : une sur la 1re carte de chaque zone, voyage gratuit de l'une à l'autre
  (les zones ne sont pas reliées autrement pour l'instant)
- [ ] Pierres de Passage à découvrir, voyage payant, pierres dans d'autres zones
- [ ] Carte du monde et minicarte
- [ ] Point de résurrection
- [x] Portes entre cartes (`+` dans le plan) et cartes en intérieur (sol en parquet)
- [x] Maison du joueur dans chaque zone de départ (Brumerive, Crasse-Roc, Sylvebrume) : coffre partagé et lit (tous les PV) ; cartes personnelles (`"instance": "joueur"`)
- [x] PV gardés d'un combat à l'autre, régénération lente hors combat (1 PV / 2 s), 1 PV après une défaite

### Interface
- [x] **(MVP)** Bandeau bas façon Dofus Rétro, en exploration comme en combat : PV dans un cœur rouge
  qui se vide, PA dans une étoile bleue, PM dans une case verte, sorts en icônes (raccourci et coût
  en PA), bouton de fin de tour, boutons de menus (personnage, inventaire, sorts, métiers)
- [ ] **(MVP)** Fenêtres : inventaire + poupée, caractéristiques, sorts, quêtes, métiers
  (faits : inventaire, caractéristiques, sorts avec un onglet par famille (Voie, race, arme),
  métiers avec un onglet par métier, boutique, atelier, coffre ; reste : quêtes)
- [ ] **(MVP)** Menu principal, options (volume, résolution), pause
- [ ] Infobulles d'objets et de sorts (comparaison avec l'équipement porté)
- [x] Inventaire : 8 cases « Reliques » visibles dès le début (vides tant que la Relique n'est pas
  reprise), en plus des 2 anneaux
- [ ] Raccourcis clavier

### Art et audio
- [x] Test de direction artistique sur la place de Brumerive : sol sans quadrillage, chemins, eau,
  arbres, rochers, minerais, maison et auberge, personnages articulés (humain, gobelin), loup, PNJ
- [x] Outils : capture d'écran du jeu (`tools/screenshot.gd`) et planche des images (`tools/art_sheet.gd`)
- [x] Style étendu à tout le jeu : champs, intérieur de la maison (murs, plancher, coffre, lit),
  menu illustré, aperçu du personnage à la création, thème de l'interface (bois et or)
- [x] Palettes de zone (Crasse-Roc plus sombre et terne, Sylvebrume plus fraîche) ; cabane gobeline,
  entrée des galeries, pavillon elfe, Pierre de Passage, fougères et champignons
- [x] Personnages réduits à 80 % (taille validée)
- [ ] **(MVP)** Tileset Brumerive et Hautepierre (reste : intérieurs, clôtures, ponts, murets, Hautepierre)
- [ ] **(MVP)** Sprites des 3 races × 2 sexes (repos, marche, attaque, sort, dégât, mort, récolte)
  (fait : humain, elfe, gobelin, repos / marche / attaque ; reste : femmes, dégât, mort, récolte)
- [ ] **(MVP)** Sprites des monstres de l'alpha (faits : loup, frondeur gobelin, rat, grouilleur,
  cerf enchanté, arbre vivant, Souverain Cendré)
- [ ] **(MVP)** Effets visuels des sorts
- [x] **(MVP)** Icônes d'objets, de ressources et de sorts : sorts des Voies et des races, attaques
  des armes, jauges du bandeau, les 36 objets (inventaire en grille d'icônes, boutique, coffre,
  atelier, métiers, butin)
- [x] Système de recoloration des personnages (modèles SVG à couleurs remplaçables)
- [ ] Musiques : 2 thèmes de région, 1 thème de combat, 1 thème de boss, menu
- [ ] Bruitages : interface, pas, impacts, sorts

### Qualité
- [ ] Équilibrage des 9 combinaisons race × classe sur les niveaux 1 à 30
- [ ] Session de test externe (5 joueurs minimum) + formulaire de retours
- [ ] Build distribuable (itch.io en accès privé, par exemple)

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
- [ ] Voies mixtes : **Ombre** (assassin invisible) et **Venomancien** (maître des poisons)
- [ ] Voies à distance : **Théologue** (soigneur sacré) et **Démoniste** (dégâts impies)
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
- [ ] **Simulateur de combat** automatisé pour détecter les combinaisons abusives
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
- [ ] Répartition du butin en groupe (pondérée par la prospection de chacun ; pas de seuil)
- [ ] Objectifs de quêtes partagés en groupe
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

- Version navigateur
- PvP (duels, arènes)
- Maisons de joueurs : achat, décoration, plusieurs maisons par ville
- Succès / hauts faits
- Bestiaire et encyclopédie du monde en jeu
- Éditeur de cartes et de quêtes intégré pour accélérer la production de contenu
