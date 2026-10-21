class_name Session
extends RefCounted
## Informations passées d'un écran à l'autre (menu → création → monde).

## Personnage tout juste créé, ou `null`.
static var new_character: Character = null
## Vrai pour reprendre la partie sauvegardée.
static var continue_game := false
## Carte de départ imposée (outils de capture d'écran), ou "" pour celle de la race.
static var start_map := ""
## Suivi de quête replié par le joueur (gardé pendant la partie, pas dans la sauvegarde).
static var tracker_folded := false
## Historique de combat replié (même règle).
static var combat_log_folded := false
## Repère posé depuis un texte de quête ({ carte, nom }, voir `QuestLinks`), ou {} : montré sur la
## minicarte et la carte du monde, retiré en arrivant sur sa carte (pas dans la sauvegarde).
static var quest_pin: Dictionary = {}

## Questionnaire des testeurs (menu principal et menu pause : « Donner son avis »).
const FEEDBACK_URL := "https://docs.google.com/forms/d/e/1FAIpQLSdwoJr5-OnRuVcVNbvRGnjtO4MqxJTUe7SIIbgfeKJlRuYcxQ/viewform"
