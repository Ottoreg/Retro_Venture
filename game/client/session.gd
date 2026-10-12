class_name Session
extends RefCounted
## Informations passées d'un écran à l'autre (menu → création → monde).

## Personnage tout juste créé, ou `null`.
static var new_character: Character = null
## Vrai pour reprendre la partie sauvegardée.
static var continue_game := false
## Carte de départ imposée (outils de capture d'écran), ou "" pour celle de la race.
static var start_map := ""
