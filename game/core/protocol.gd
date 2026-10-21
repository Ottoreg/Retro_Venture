class_name Protocol
extends RefCounted
## Vocabulaire échangé entre le client et le noyau.
##
## Le client envoie des **commandes** (intentions du joueur) à `World.execute()`, qui renvoie des
## **événements** (ce qui s'est réellement passé). Les deux sont des `Dictionary` avec un champ
## `"type"`, sérialisables tels quels le jour où ils passeront par le réseau.

# --- Commandes (client → noyau) ---

## Exploration et combat : { type, entite: String, cible: Vector2i }
## En exploration, `sortie` (optionnel, « haut », « bas », « gauche » ou « droite ») : passer sur la
## carte voisine une fois arrivé sur la case du bord.
## En exploration, `porte` (optionnel, booléen) : franchir la porte de la case `cible` (voir
## `GameMap.doors`) une fois arrivé dessus.
## En exploration aussi (et pour « parler » et « engager ») : `interrompre_a` (optionnel, Vector2i),
## case du trajet en cours où le joueur s'arrête pour repartir vers la nouvelle cible.
const CMD_MOVE := "deplacer"
## Exploration : aller parler à un PNJ. { type, entite: String, pnj: String }
const CMD_TALK := "parler"
## Exploration : répartir des points de caractéristique. { type, entite: String, carac: String, points: int }
const CMD_SPEND_POINTS := "investir"
## Exploration : rendre tous les points investis, à répartir de nouveau (gratuit pendant l'alpha).
## { type, entite: String }
const CMD_RESET_POINTS := "reinitialiser_points"
## Exploration : s'asseoir (`assis` vrai) ou se relever (faux). Assis, les PV remontent plus vite
## (World.SIT_REGEN_FACTOR) ; on se relève tout seul en marchant ou en entrant en combat.
## { type, entite: String, assis: bool }
const CMD_SIT := "s_asseoir"
## Exploration : équiper un objet. { type, entite: String, objet: String (uid), emplacement: String (optionnel) }
const CMD_EQUIP := "equiper"
## Exploration : retirer l'objet d'un emplacement. { type, entite: String, emplacement: String }
const CMD_UNEQUIP := "desequiper"
## Exploration : jeter un objet. { type, entite: String, objet: String (uid), quantite: int }
const CMD_DROP := "jeter"
## Exploration, à côté d'un marchand : acheter un objet. Les équipements achetés ont des jets tirés
## au hasard. { type, entite: String, pnj: String, objet: String (id du modèle), quantite: int (optionnel) }
const CMD_BUY := "acheter"
## Exploration, à côté d'un marchand : vendre un objet (non porté) à prix réduit.
## { type, entite: String, pnj: String, objet: String (uid), quantite: int (optionnel) }
const CMD_SELL := "vendre"
## Exploration, à côté d'une ressource (arbre, minerai) : la récolter. { type, entite: String, case: Vector2i }
const CMD_HARVEST := "recolter"
## Exploration, à côté d'un atelier (PNJ avec « atelier ») : fabriquer un objet d'après sa recette.
## { type, entite: String, pnj: String, recette: String (id de l'objet fabriqué), quantite: int (optionnel) }
const CMD_CRAFT := "fabriquer"
## Exploration, à côté d'un meuble (coffre, lit) : l'utiliser. { type, entite: String, case: Vector2i }
const CMD_USE := "utiliser"
## Exploration, à côté du coffre : y déposer un objet non porté.
## { type, entite: String, case: Vector2i (coffre), objet: String (uid dans l'inventaire), quantite: int (optionnel) }
const CMD_DEPOSIT := "deposer"
## Exploration, à côté du coffre : reprendre un objet.
## { type, entite: String, case: Vector2i (coffre), objet: String (uid dans le coffre), quantite: int (optionnel) }
const CMD_WITHDRAW := "reprendre"
## Exploration, à côté d'une Pierre de Passage : voyager jusqu'à une autre, déjà découverte (ou
## « toujours_connue »), en payant son prix en écus. Arriver par un voyage ne découvre pas la pierre.
## { type, entite: String, case: Vector2i (la pierre), destination: String (id de la pierre d'arrivée) }
const CMD_TRAVEL := "voyager"
## Exploration, à côté du PNJ qui la propose : accepter une quête. { type, entite: String, quete: String }
const CMD_QUEST_ACCEPT := "accepter_quete"
## Remettre une quête proposée à plus tard (le marchand ou l'artisan ouvre alors sa boutique ou son
## atelier au prochain dialogue). { type, entite: String, quete: String }
const CMD_QUEST_DECLINE := "refuser_quete"
## Suivre une quête en cours (sous la minicarte), ou aucune avec "". { type, entite: String, quete: String }
const CMD_QUEST_TRACK := "suivre_quete"
## Exploration : attaquer un groupe de monstres. { type, entite: String, groupe: String }
const CMD_ENGAGE := "engager"
## Combat, phase de placement : { type, entite: String, cible: Vector2i }
const CMD_PLACE := "placer"
## Combat, fin du placement : { type, entite: String }
const CMD_READY := "pret"
## Combat : { type, entite: String, sort: String, cible: Vector2i }
const CMD_CAST := "lancer_sort"
## Combat : { type, entite: String }
const CMD_END_TURN := "fin_tour"

# --- Événements (noyau → client) ---

## { type, entite: String, depuis: Vector2i, chemin: Array[Vector2i] } — chemin sans la case de
## départ. En combat, aussi `pm` : PM restants.
const EVT_MOVED := "deplace"
## { type, commande: String, raison: String }
const EVT_REFUSED := "refuse"
## { type, pnj: String, nom: String, case: Vector2i, repliques: Array[String] }, et `quete` (id, ou "")
## quand le texte vient d'une quête.
const EVT_DIALOGUE := "dialogue"
## Un PNJ propose une quête, à la place de son dialogue. { type, pnj, nom, case, quete: String,
## titre: String, niveau: int, repliques: Array[String], objectifs: Array[{ texte, fait, carte }],
## recompenses: { xp, ecus, objets: Array[{ objet, nom, rarete, quantite }] } }
const EVT_QUEST_OFFER := "quete_proposee"
## Une quête avance (objectif compté ou rempli, étape suivante, quête acceptée). { type, quete, texte }
const EVT_QUEST_PROGRESS := "quete_avance"
## Une quête est terminée et ses récompenses données. { type, quete, nom, xp, ecus, objets }
const EVT_QUEST_DONE := "quete_terminee"
## Journal des quêtes, après chaque changement. { type, journal: { en_cours, terminees, suivie } }
const EVT_QUESTS := "quetes"
## Boutique d'un marchand, à la place du dialogue quand on lui parle. { type, pnj: String, nom: String,
## case: Vector2i, repliques: Array[String], articles: Array[{ objet, nom, type, rarete, niveau,
## description, bonus, conditions, prix }], taux_revente: float }
const EVT_SHOP := "boutique"
## Achat ou vente effectué. { type, operation: « achat » ou « vente », objet: String (id du modèle),
## nom: String, quantite: int, prix: int (total), ecus: int (écus restants) }
const EVT_TRADE := "commerce"
## Atelier d'un artisan, à la place du dialogue quand on lui parle. { type, pnj: String, nom: String,
## case: Vector2i, repliques: Array[String], metier: String, nom_metier: String,
## recettes: Array[{ objet, nom, type, rarete, niveau (du métier), niveau_objet, description, bonus,
## conditions, ingredients: Array[{ objet, nom, quantite }], xp }] }
const EVT_WORKSHOP := "atelier"
## Ressource récoltée. { type, entite: String, case: Vector2i, ressource: String (nom), objet: String,
## nom: String, quantite: int, metier: String }
## `rare` : vrai si c'est la ressource rare du nœud (1 exemplaire, voir `Profession.RARE_CHANCE`).
const EVT_HARVESTED := "recolte"
## Une ressource récoltée de la carte actuelle a repoussé (renvoyé par `World.update`).
## { type, carte: String, case: Vector2i }
const EVT_RESOURCE_RESPAWNED := "repousse"
## Un groupe de monstres vaincu de la carte actuelle est réapparu (renvoyé par `World.update`).
## { type, carte: String, groupe: { id, case, monstres, niveaux } } — `niveaux` : le niveau tiré de
## chaque monstre, dans l'ordre de `monstres`.
const EVT_GROUP_RESPAWNED := "reapparition"
## Un groupe de monstres de la carte actuelle se promène (renvoyé par `World.update`).
## { type, groupe: String, chemin: Array[Vector2i] (sans la case de départ), case: Vector2i }
const EVT_GROUP_MOVED := "promenade"
## Coffre ouvert ou modifié. { type, case: Vector2i, coffre: { objets: Array, places: int } }
const EVT_CHEST := "coffre"
## Le joueur s'assoit ou se relève (aussi tout seul, avant une marche ou un combat).
## { type, entite: String, assis: bool }
const EVT_SAT := "assis"
## Le joueur a dormi : PV au maximum. { type, gain: int, pv: int, pv_max: int }
const EVT_RESTED := "repos"
## Pierre de Passage utilisée : destinations proposées. { type, case: Vector2i, ici: String (id de
## cette pierre), destinations: Array[{ id, nom, carte, prix: int (écus), connue: bool }], ecus: int
## (écus du joueur), resurrection: String (id de la pierre de son point de résurrection, ou "") }
const EVT_TRAVEL_MENU := "pierre_de_passage"
## Pierre de Passage découverte en l'utilisant : on pourra y revenir en voyage.
## { type, passage: String (id), nom: String }
const EVT_PASSAGE_DISCOVERED := "pierre_decouverte"
## Nouveau point de résurrection (la dernière Pierre de Passage utilisée), seulement s'il change.
## { type, passage: String (id), nom: String }
const EVT_RESPAWN_POINT := "point_de_resurrection"
## Objet fabriqué. { type, objet: String, nom: String, quantite: int, metier: String }
const EVT_CRAFTED := "fabrication"
## XP de métier gagnée. { type, metier: String, nom: String, gain: int, niveau: int, xp: int,
## xp_niveau: int, xp_suivant: int, niveaux: Array[int] (niveaux de métier atteints) }
const EVT_JOB := "metier"
## Arrivée sur une autre carte. { type, carte: String, nom: String, position: Vector2i } ; après un
## voyage par une Pierre de Passage, aussi `prix` : écus payés.
const EVT_MAP_CHANGED := "changement_carte"
## { type, groupe: String, combattants: Array[Dictionary], placement: Array[Vector2i] } — chaque
## combattant comme `Fighter.to_dict` (avec son `niveau` : celui tiré à l'apparition d'un monstre).
const EVT_COMBAT_STARTED := "combat_debut"
## { type, entite: String, case: Vector2i }
const EVT_PLACED := "place"
## { type, ordre: Array[String] } — ordre de jeu, par initiative.
const EVT_FIGHT_BEGINS := "combat_commence"
## { type, entite: String, tour: int, pa: int, pm: int }
const EVT_TURN_STARTED := "tour_debut"
## { type, entite: String }
const EVT_TURN_ENDED := "tour_fin"
## { type, entite: String, sort: String, cible: Vector2i, pa: int, critique: bool } — pa : PA
## restants ; `cache` : la cible ne doit pas être montrée à l'autre équipe (pose d'un piège).
const EVT_SPELL_CAST := "sort_lance"
## { type, entite: String, valeur: int, element: String, pv: int }
const EVT_DAMAGE := "degats"
## { type, entite: String, valeur: int, element: String, pv: int }
const EVT_HEAL := "soin"
## { type, entite: String }
const EVT_DIED := "mort"
## { type, entite: String, depuis: Vector2i, case: Vector2i }
const EVT_TELEPORTED := "teleporte"
## Effet sans dégâts. { type, entite: String, effet: String, valeur: int, pa: int, pm: int } ; un
## bouclier ajoute `element` et `bouclier` (total porté).
const EVT_STATUS := "effet"
## États d'un combattant après un changement (bonus, malus ou poison posé ou tombé). { type,
## entite: String, etats: Array[{ type, carac, element, valeur, min, max, tours, sort }], pa: int,
## pm: int } ; `nouveau` : l'état qui vient d'être posé (absent quand un état tombe) ; `retires` :
## nombre d'états qu'un sort vient de retirer.
const EVT_STATES := "etats"
## États élémentaires d'un combattant après un changement. { type, entite: String, etats: Array[String],
## element: String (celui qui vient d'être pris, absent pour une composition), composition: bool (les 3
## états choisis d'un coup, absent sinon) }
const EVT_ELEMENT_STATES := "etats_elementaires"
## Sort créé (« creer_sort ») : il prend une des 2 places de la barre, et chasse le plus ancien
## quand elles sont prises. { type, entite: String, sort: String (id), ancien: String (id du sort
## chassé, ou "") }
const EVT_SPELL_CREATED := "sort_cree"
## Charge : le combattant fonce en ligne droite. { type, entite: String, depuis: Vector2i,
## chemin: Array[Vector2i], case: Vector2i, contact: bool (arrivé au contact de la cible) }
const EVT_CHARGED := "charge"
## Combattant poussé ou attiré. { type, entite: String, depuis: Vector2i, case: Vector2i }
const EVT_PUSHED := "pousse"
## Glyphe posée au sol. { type, id: int, lanceur: String, equipe: int, cases: Array[Vector2i],
## tours: int, sort: String (nom) }
const EVT_GLYPH := "glyphe"
## Glyphe disparue (durée écoulée ou lanceur vaincu). { type, id: int }
const EVT_GLYPH_ENDED := "glyphe_fin"
## Piège posé. Invisible pour l'autre équipe : le client ne le montre qu'à l'équipe `equipe`.
## { type, id: int, lanceur: String, equipe: int, case: Vector2i, cases: Array[Vector2i] (zone),
## sort: String (nom) }
const EVT_TRAP := "piege"
## Piège déclenché par un ennemi. { type, id: int, entite: String (qui l'a déclenché), case:
## Vector2i, cases: Array[Vector2i], sort: String (nom) } ; ses effets suivent.
const EVT_TRAP_TRIGGERED := "piege_declenche"
## Piège retiré sans être déclenché (lanceur vaincu). { type, id: int }
const EVT_TRAP_ENDED := "piege_fin"
## Un monstre change de phase : ses PV sont passés sous un seuil de ses « phases » (une seule fois
## par phase). { type, entite: String, message: String } ; ses nouveaux sorts sont déjà appris, les
## effets de la phase (sur lui-même) suivent.
const EVT_PHASE := "phase"
## Gain d'expérience après un combat. { type, gain: int, xp: int, niveau: int }
const EVT_XP := "experience"
## { type, niveau: int, points: int (points de caractéristique à répartir) }
const EVT_LEVEL_UP := "niveau"
## Fiche du personnage mise à jour. { type, personnage: Dictionary }
const EVT_CHARACTER := "personnage"
## Inventaire mis à jour. { type, inventaire: Dictionary (voir Character.inventory_sheet) }
const EVT_INVENTORY := "inventaire"
## { type, vainqueur: int (équipe, -1 si aucune), xp: int } ; après le passage du monde, aussi
## `butin`: Array[{ objet, nom, rarete, quantite }], `ecus`: int, `niveaux`: Array[int],
## `surcharge`: bool (le sac déborde : faire de la place avant le prochain combat) ; après une
## défaite, `reveil`: { passage: String (id de la pierre, "" sans point de résurrection), nom: String
## (nom de la pierre, ou de la carte), carte: String } (où le personnage se réveille).
const EVT_COMBAT_ENDED := "combat_fin"
## Retour en exploration après un combat. { type, position: Vector2i, groupe_vaincu: String } ; après
## une défaite, aussi `reveil` (comme dans EVT_COMBAT_ENDED), suivi d'un EVT_MAP_CHANGED si le point
## de résurrection est sur une autre carte.
const EVT_EXPLORATION := "exploration"

# --- Raisons de refus ---

const REASON_UNKNOWN_COMMAND := "commande_inconnue"
const REASON_INVALID_COMMAND := "commande_invalide"
const REASON_UNKNOWN_ENTITY := "entite_inconnue"
const REASON_OUT_OF_MAP := "hors_carte"
const REASON_BLOCKED := "case_bloquee"
const REASON_NO_PATH := "aucun_chemin"
const REASON_ALREADY_THERE := "deja_sur_place"
const REASON_NO_EXIT := "pas_de_sortie"
const REASON_UNKNOWN_MAP := "carte_inconnue"
const REASON_NOT_ENOUGH_POINTS := "points_insuffisants"
const REASON_NOTHING_TO_RESET := "aucun_point_investi"
const REASON_UNKNOWN_ITEM := "objet_inconnu"
const REASON_NOT_EQUIPPABLE := "objet_non_equipable"
const REASON_REQUIREMENTS := "conditions_non_remplies"
const REASON_ALREADY_WORN := "objet_deja_porte"
const REASON_EMPTY_SLOT := "emplacement_vide"
const REASON_ITEM_WORN := "objet_porte"
const REASON_NOT_ENOUGH_ECUS := "ecus_insuffisants"
## Voyage vers une Pierre de Passage pas encore découverte.
const REASON_PASSAGE_UNKNOWN := "pierre_inconnue"
const REASON_INVENTORY_FULL := "inventaire_plein"
## Un objet de quête ne se jette ni ne se vend.
const REASON_QUEST_ITEM := "objet_de_quete"
## Le sac déborde (butin en surplus) : pas de nouveau combat avant d'avoir fait de la place.
const REASON_INVENTORY_OVERLOADED := "inventaire_surcharge"
const REASON_TOO_FAR := "trop_loin"
const REASON_DEPLETED := "ressource_epuisee"
const REASON_JOB_LEVEL := "niveau_de_metier_insuffisant"
const REASON_MISSING_INGREDIENTS := "ingredients_manquants"
const REASON_WRONG_PHASE := "mauvaise_phase"
const REASON_NOT_YOUR_TURN := "pas_votre_tour"
const REASON_OCCUPIED := "case_occupee"
const REASON_NOT_PLACEMENT_CELL := "case_de_placement_invalide"
const REASON_NOT_ENOUGH_PM := "pm_insuffisants"
const REASON_NOT_ENOUGH_PA := "pa_insuffisants"
const REASON_UNKNOWN_SPELL := "sort_inconnu"
const REASON_SPELL_LIMIT := "sort_deja_lance"
const REASON_SPELL_COOLDOWN := "sort_en_recharge"
## « Fusion arcanique » sans 3 états élémentaires, ou avec une combinaison qui n'a pas de sort.
const REASON_NO_COMBINATION := "combinaison_inconnue"
## Sort de composition des états sans combinaison (`etats`) qu'il propose.
const REASON_INVALID_COMPOSITION := "composition_invalide"
const REASON_OUT_OF_RANGE := "hors_portee"
const REASON_NO_LINE_OF_SIGHT := "pas_de_ligne_de_vue"
const REASON_NOT_IN_LINE := "pas_en_ligne"
