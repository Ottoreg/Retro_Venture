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
const CMD_MOVE := "deplacer"
## Exploration : aller parler à un PNJ. { type, entite: String, pnj: String }
const CMD_TALK := "parler"
## Exploration : répartir des points de caractéristique. { type, entite: String, carac: String, points: int }
const CMD_SPEND_POINTS := "investir"
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
## { type, vainqueur: int (équipe, -1 si aucune), xp: int }
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
