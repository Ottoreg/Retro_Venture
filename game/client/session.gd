class_name Session
extends RefCounted
## Informations passées d'un écran à l'autre (menu → création → monde).

## Personnage tout juste créé, ou `null`.
static var new_character: Character = null
## Vrai pour reprendre la partie sauvegardée.
static var continue_game := false
## Carte de départ imposée (outils de capture d'écran), ou "" pour celle de la race.
static var start_map := ""
## Minicarte repliée par le joueur (gardé pendant la partie, pas dans la sauvegarde).
static var minimap_folded := false

## Questionnaire des testeurs (menu principal et menu pause : « Donner son avis »).
const FEEDBACK_URL := "https://docs.google.com/forms/d/e/1FAIpQLSfvVseTPS49X5ssBkdsdkNkJxVPzQwZ-EKNOKwkB1GjovaUDg/viewform"
