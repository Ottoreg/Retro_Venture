class_name Protocol
extends RefCounted
## Vocabulaire échangé entre le client et le noyau.
##
## Le client envoie des **commandes** (intentions du joueur) à `World.execute()`, qui renvoie des
## **événements** (ce qui s'est réellement passé). Les deux sont des `Dictionary` avec un champ
## `"type"`, sérialisables tels quels le jour où ils passeront par le réseau.

# --- Commandes (client → noyau) ---

## { type, entite: String, cible: Vector2i }
const CMD_MOVE := "deplacer"

# --- Événements (noyau → client) ---

## { type, entite: String, depuis: Vector2i, chemin: Array[Vector2i] } — chemin sans la case de départ.
const EVT_MOVED := "deplace"
## { type, commande: String, raison: String }
const EVT_REFUSED := "refuse"

# --- Raisons de refus ---

const REASON_UNKNOWN_COMMAND := "commande_inconnue"
const REASON_INVALID_COMMAND := "commande_invalide"
const REASON_UNKNOWN_ENTITY := "entite_inconnue"
const REASON_OUT_OF_MAP := "hors_carte"
const REASON_BLOCKED := "case_bloquee"
const REASON_NO_PATH := "aucun_chemin"
const REASON_ALREADY_THERE := "deja_sur_place"
