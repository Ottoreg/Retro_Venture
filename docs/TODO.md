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
- [ ] **(MVP)** Choisir le format des données de contenu (JSON, YAML ou ressources du moteur)
- [ ] Choisir la taille de tuile (86×43 ou 64×32) et la résolution de référence
- [ ] Choisir la licence du code et des assets
- [ ] Fixer le nom définitif du jeu et du monde (vérification de marques)

### Dépôt et outillage
- [x] Structure du dépôt, README, GDD, TODO
- [x] **(MVP)** Initialiser le projet Godot dans `game/` (rendu Compatibility, 1280×720, lanceur de tests)
- [ ] Ouvrir le projet dans l'éditeur Godot et commiter les fichiers générés (`*.uid`, `*.import`)
- [ ] Activer Git LFS pour les assets binaires (`.gitattributes`)
- [x] Intégration continue (GitHub Actions) : tests Godot
- [x] Export web automatique publié sur GitHub Pages (jouable dans le navigateur)
- [ ] Activer GitHub Pages (Settings → Pages → Source : GitHub Actions)
- [ ] Intégration continue : validation des fichiers de données
- [ ] Créer les labels et milestones GitHub (phase, domaine : combat, UI, contenu, art, réseau…)
- [ ] Rédiger `CONTRIBUTING.md` (conventions de nommage, de commits, de branches)
- [ ] Créer `game/assets/CREDITS.md` (registre des assets tiers et licences)

### Design
- [ ] **(MVP)** Valider le GDD v0.1 (relecture complète)
- [ ] Tableur d'équilibrage : courbe d'XP, formules de dégâts, PV par niveau (`docs/design/`)
- [ ] Prototype « papier » du combat (grille + pions) pour tester PA/PM et 5 sorts par classe
- [ ] Document de lore court (1 à 2 pages) : histoire, Reliques, régions (`docs/lore/`)
- [ ] Planche de références visuelles (moodboard) par région

---

## Phase 1 — Prototype jouable

Objectif : **un combat jouable de bout en bout sur une carte**.

### Noyau (logique indépendante de l'affichage)
- [ ] **(MVP)** Modèle de grille isométrique (coordonnées, conversion écran ↔ case, voisins)
- [ ] **(MVP)** Recherche de chemin A* sur grille avec cases bloquantes
- [ ] **(MVP)** Architecture commandes → noyau → événements (base du futur réseau)
- [ ] **(MVP)** Générateur aléatoire à graine (combats rejouables)
- [ ] Chargement des données de contenu depuis `game/data/` + validation par schéma
- [ ] Tests unitaires du noyau

### Exploration
- [ ] **(MVP)** Afficher une carte isométrique (sol, obstacles, décor, tri par profondeur)
- [ ] **(MVP)** Déplacement au clic avec animation de marche
- [ ] Caméra et changement de carte par les bords
- [ ] Un PNJ cliquable avec une bulle de dialogue

### Combat
- [ ] **(MVP)** Lancer un combat en cliquant sur un monstre
- [ ] **(MVP)** Phase de placement
- [ ] **(MVP)** Tours par initiative, PA/PM, fin de tour
- [ ] **(MVP)** Sorts : portée, ligne de vue, zone, dégâts élémentaires, résistances
- [ ] **(MVP)** IA de monstre `melee` simple
- [ ] **(MVP)** Conditions de victoire / défaite, écran de fin
- [ ] Prévisualisation de portée et de zone au survol
- [ ] Frise d'initiative

### Contenu de test
- [ ] 1 personnage Guerrier avec 4 sorts
- [ ] 2 types de monstres
- [ ] Assets temporaires (formes simples ou assets libres de droits, crédités)

---

## Phase 2 — Alpha solo (objectifs court terme)

Objectif : **10 à 15 h de jeu solo, niveaux 1 à 30, sur 2 régions**.

### Personnage
- [ ] **(MVP)** Écran de création : race, classe, couleurs, nom
- [ ] **(MVP)** 3 races jouables : Humain, Elfe, Nain (bonus, passif, sort racial)
- [ ] **(MVP)** 3 classes jouables : Guerrier, Rôdeur, Arcaniste (environ 10 à 12 sorts chacune, niveaux 1 à 30)
- [ ] **(MVP)** Caractéristiques, points à répartir, statistiques dérivées
- [ ] **(MVP)** XP, montée de niveau, points de sort
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
- [ ] **(MVP)** Environ 15 à 20 monstres répartis sur 2 régions
- [ ] **(MVP)** Tables de butin, prospection, raretés (couleurs)
- [ ] **(MVP)** Écran de butin en fin de combat
- [ ] Seuils de prospection pour les objets rares
- [ ] Variantes Corrompues (2 ou 3 pour tester le concept)

### Équipement et inventaire
- [ ] **(MVP)** Inventaire (objets, ressources, quêtes) avec poids ou nombre de cases limité
- [ ] **(MVP)** Équipement : arme, coiffe, cape, amulette, 2 anneaux, ceinture, bottes
- [ ] **(MVP)** Conditions d'équipement (niveau, caractéristiques)
- [ ] **(MVP)** Armes utilisables en combat
- [ ] Jets aléatoires de statistiques
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
- [ ] **(MVP)** Tutoriel (déplacement, combat, équipement, métier)
- [ ] Environ 15 quêtes secondaires
- [ ] Premier chapitre de la quête principale (piste de la Lanterne d'Aube)

### Monde
- [ ] **(MVP)** Région 1 : Collines de Brumerive (village de départ, environ 15 à 20 cartes)
- [ ] **(MVP)** Région 2 : Hautepierre et environs (ville + environ 20 cartes)
- [ ] **(MVP)** Sauvegarde / chargement (format compatible avec la future base serveur)
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
- [ ] Ajouter progressivement environ 7 races (Petites-gens, Cavaliers d'Orvent, Sylvanides, Orques renégats…)
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
- [ ] Seuil de prospection de groupe et répartition du butin
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
