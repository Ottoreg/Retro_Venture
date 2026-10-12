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
  - [x] Liste des 6 races et ton parodique (§ 3.6, § 4.2)
  - [x] Races de l'alpha (Humain, Gobelin, Elfe) et structure en trois camps (§ 3.4)
  - [ ] Choisir les noms de peuple des 6 races (§ 4.2)
  - [ ] Revoir les noms du monde, des Reliques et du méchant dans le ton parodique (§ 3)
  - [ ] Revoir la répartition des Reliques entre régions et camps (§ 3.3), par ex. une Relique liée aux gobelins
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
- [ ] Décider s'il faut une 4e classe de soin (Druide) pour l'équilibrage solo

### Combat
- [ ] **(MVP)** Tous les types d'effets : soin, bouclier, bonus/malus, poussée, téléportation, états
- [ ] **(MVP)** Coups critiques
- [ ] **(MVP)** Combats contre des groupes de 1 à 8 monstres
- [ ] **(MVP)** IA : `ranged`, `support`
- [ ] Tacle / fuite (activable pour tester)
- [ ] Monstres agressifs (engagent le combat à proximité)
- [ ] Mini-boss de fin de région avec script par phases

### Monstres et butin
- [ ] **(MVP)** Environ 15 à 20 monstres répartis sur les 4 zones (dont des PNJ combattants de chaque camp)
- [x] **(MVP)** Tables de butin, prospection (sans seuil), raretés (couleurs), écus
- [x] **(MVP)** Écran de butin en fin de combat
- [ ] Variantes Corrompues (2 ou 3 pour tester le concept)

### Équipement et inventaire
- [x] **(MVP)** Inventaire (ressources empilées, équipements) limité à 60 places ; fenêtre (touche I)
- [ ] Objets de quête dans l'inventaire (avec les quêtes)
- [x] **(MVP)** Équipement : arme, coiffe, cape, amulette, 2 anneaux, ceinture, bottes ; équipement de départ par Voie
- [x] **(MVP)** Conditions d'équipement (niveau, caractéristiques ; pas deux objets identiques)
- [x] **(MVP)** Armes utilisables en combat (attaque de l'arme dans la barre de sorts)
- [x] Jets aléatoires de statistiques
- [ ] Plus d'objets (16 aujourd'hui) pour couvrir les niveaux 1 à 30
- [ ] 3 ou 4 panoplies avec bonus d'ensemble
- [ ] Équipement visible sur le personnage (coiffe, cape, arme)
- [ ] Marchands PNJ (achat / vente)
- [ ] Banque / coffre personnel

### Métiers
- [ ] **(MVP)** Système de métier générique (niveau, XP, recettes)
- [ ] **(MVP)** Bûcheron : 4 ou 5 essences d'arbres, réapparition des ressources
- [ ] **(MVP)** Mineur : 4 ou 5 minerais
- [ ] **(MVP)** Forgeron : atelier, interface de fabrication, environ 20 recettes
- [ ] Ressources de monstres utilisées dans les recettes

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
- [ ] **(MVP)** Zone de départ humaine : Collines de Brumerive (environ 8 à 10 cartes)
- [ ] **(MVP)** Zone de départ gobeline : Galeries de Crasse-Roc (environ 8 à 10 cartes)
- [ ] **(MVP)** Zone de départ elfe : Lisière de Sylvebrume (environ 8 à 10 cartes)
- [ ] **(MVP)** Zone commune : Hautepierre et environs (ville + environ 15 cartes)
- [ ] Villes hostiles aux autres camps avant l'acte III (gardes PNJ agressifs)
- [x] **(MVP)** Sauvegarde / chargement automatique (personnage, carte, position, groupes vaincus) dans `user://`
- [ ] Points de voyage (Pierres de Passage)
- [ ] Carte du monde et minicarte
- [ ] Point de résurrection

### Interface
- [ ] **(MVP)** Bandeau bas : PV / PA / PM, barre de sorts, boutons de menus
- [ ] **(MVP)** Fenêtres : inventaire + poupée, caractéristiques, sorts, quêtes, métiers
- [ ] **(MVP)** Menu principal, options (volume, résolution), pause
- [ ] Infobulles d'objets et de sorts (comparaison avec l'équipement porté)
- [ ] Raccourcis clavier

### Art et audio
- [ ] **(MVP)** Tileset Brumerive et Hautepierre
- [ ] **(MVP)** Sprites des 3 races × 2 sexes (repos, marche, attaque, sort, dégât, mort, récolte)
- [ ] **(MVP)** Sprites des monstres de l'alpha
- [ ] **(MVP)** Effets visuels des sorts
- [ ] **(MVP)** Icônes d'objets, de ressources et de sorts
- [ ] Système de recoloration des personnages
- [ ] Musiques : 2 thèmes de région, 1 thème de combat, 1 thème de boss, menu
- [ ] Bruitages : interface, pas, impacts, sorts

### Qualité
- [ ] Équilibrage des 9 combinaisons race × classe sur les niveaux 1 à 30
- [ ] Session de test externe (5 joueurs minimum) + formulaire de retours
- [ ] Build distribuable (itch.io en accès privé, par exemple)

---

## Phase 3 — Solo étendu (objectifs long terme)

### Races et classes
- [ ] Ajouter les 3 autres races : Nain (allié), Orc (ennemi), Semi-homme (neutre), avec leurs zones de départ et chaînes d'acte I
- [ ] Ajouter progressivement environ 7 Voies (Gardien, Druide, Ménestrel, Ombrelame, Runelier, Chaman, Paladin de l'Aube…)
- [ ] Étendre la progression jusqu'au niveau 100

### Système des Voies (classes mixtes)
- [ ] Maîtres de Voie (PNJ) et quêtes d'apprentissage des Fondamentaux
- [ ] Rangs I / II / III et règles de spécialisation
- [ ] Changement de spécialisation (quête + coût)
- [ ] Barre de sorts limitée et préréglages de barres
- [ ] Passif de Maîtrise de Voie
- [ ] Quêtes de Voie (déblocage du rang III)
- [ ] **Simulateur de combat** automatisé pour détecter les combinaisons abusives

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
- [ ] Chaînes de quêtes des 7 Reliques
- [ ] Chaîne finale et combat contre le Souverain Cendré
- [ ] Mise en scène dans le moteur (déplacements scriptés, caméra, bulles)
- [ ] Événements de monde (invasions cendrées)

### Objets légendaires
- [ ] Emplacement Relique et pouvoirs des 7 Reliques
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
- Maisons de joueurs
- Succès / hauts faits
- Bestiaire et encyclopédie du monde en jeu
- Éditeur de cartes et de quêtes intégré pour accélérer la production de contenu
