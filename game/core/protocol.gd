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
## Exploration, à côté d'une Pierre de Passage : voyager jusqu'à une autre.
## { type, entite: String, case: Vector2i (la pierre), destination: String (id de la pierre d'arrivée) }
const CMD_TRAVEL := "voyager"
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
## { type, pnj: String, nom: String, case: Vector2i, repliques: Array[String] }
const EVT_DIALOGUE := "dialogue"
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
const EVT_HARVESTED := "recolte"
## Une ressource récoltée de la carte actuelle a repoussé (renvoyé par `World.update`).
## { type, carte: String, case: Vector2i }
const EVT_RESOURCE_RESPAWNED := "repousse"
## Un groupe de monstres vaincu de la carte actuelle est réapparu (renvoyé par `World.update`).
## { type, carte: String, groupe: { id, case, monstres } }
const EVT_GROUP_RESPAWNED := "reapparition"
## Coffre ouvert ou modifié. { type, case: Vector2i, coffre: { objets: Array, places: int } }
const EVT_CHEST := "coffre"
## Le joueur a dormi : PV au maximum. { type, gain: int, pv: int, pv_max: int }
const EVT_RESTED := "repos"
## Pierre de Passage utilisée : destinations proposées. { type, case: Vector2i, ici: String (id de
## cette pierre), destinations: Array[{ id, nom, carte }] }
const EVT_TRAVEL_MENU := "pierre_de_passage"
## Objet fabriqué. { type, objet: String, nom: String, quantite: int, metier: String }
const EVT_CRAFTED := "fabrication"
## XP de métier gagnée. { type, metier: String, nom: String, gain: int, niveau: int, xp: int,
## xp_niveau: int, xp_suivant: int, niveaux: Array[int] (niveaux de métier atteints) }
const EVT_JOB := "metier"
## Arrivée sur une autre carte. { type, carte: String, nom: String, position: Vector2i }
const EVT_MAP_CHANGED := "changement_carte"
## { type, groupe: String, combattants: Array[Dictionary], placement: Array[Vector2i] }
const EVT_COMBAT_STARTED := "combat_debut"
## { type, entite: String, case: Vector2i }
const EVT_PLACED := "place"
## { type, ordre: Array[String] } — ordre de jeu, par initiative.
const EVT_FIGHT_BEGINS := "combat_commence"
## { type, entite: String, tour: int, pa: int, pm: int }
const EVT_TURN_STARTED := "tour_debut"
## { type, entite: String }
const EVT_TURN_ENDED := "tour_fin"
## { type, entite: String, sort: String, cible: Vector2i, pa: int } — pa : PA restants.
const EVT_SPELL_CAST := "sort_lance"
## { type, entite: String, valeur: int, element: String, pv: int }
const EVT_DAMAGE := "degats"
## { type, entite: String, valeur: int, pv: int }
const EVT_HEAL := "soin"
## { type, entite: String }
const EVT_DIED := "mort"
## { type, entite: String, depuis: Vector2i, case: Vector2i }
const EVT_TELEPORTED := "teleporte"
## Effet sans dégâts. { type, entite: String, effet: String, valeur: int, pa: int, pm: int }
const EVT_STATUS := "effet"
## Gain d'expérience après un combat. { type, gain: int, xp: int, niveau: int }
const EVT_XP := "experience"
## { type, niveau: int, points: int (points de caractéristique à répartir) }
const EVT_LEVEL_UP := "niveau"
## Fiche du personnage mise à jour. { type, personnage: Dictionary }
const EVT_CHARACTER := "personnage"
## Inventaire mis à jour. { type, inventaire: Dictionary (voir Character.inventory_sheet) }
const EVT_INVENTORY := "inventaire"
## { type, vainqueur: int (équipe, -1 si aucune), xp: int } ; après le passage du monde, aussi
## `butin`: Array[{ objet, nom, rarete, quantite, perdu: bool }], `ecus`: int, `niveaux`: Array[int].
const EVT_COMBAT_ENDED := "combat_fin"
## Retour en exploration après un combat. { type, position: Vector2i, groupe_vaincu: String }
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
const REASON_UNKNOWN_ITEM := "objet_inconnu"
const REASON_NOT_EQUIPPABLE := "objet_non_equipable"
const REASON_REQUIREMENTS := "conditions_non_remplies"
const REASON_ALREADY_WORN := "objet_deja_porte"
const REASON_EMPTY_SLOT := "emplacement_vide"
const REASON_ITEM_WORN := "objet_porte"
const REASON_NOT_ENOUGH_ECUS := "ecus_insuffisants"
const REASON_INVENTORY_FULL := "inventaire_plein"
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
const REASON_OUT_OF_RANGE := "hors_portee"
const REASON_NO_LINE_OF_SIGHT := "pas_de_ligne_de_vue"
