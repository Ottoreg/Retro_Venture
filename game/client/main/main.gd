extends Control
## Écran d'accueil : nouvelle partie ou reprise de la partie sauvegardée.

const WORLD_SCENE := "res://client/world/world.tscn"
const CREATION_SCENE := "res://client/creation/creation.tscn"


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "?")
	%Version.text = "Version %s — Phase 2 (alpha en construction)" % version
	%NewGame.pressed.connect(_on_new_game_pressed)
	%Continue.pressed.connect(_on_continue_pressed)
	var summary := SaveGame.summary()
	%Continue.disabled = summary.is_empty()
	%SaveInfo.text = "Partie en cours : %s" % summary if not summary.is_empty() else ""
	if summary.is_empty():
		%NewGame.grab_focus()
	else:
		%Continue.grab_focus()


func _on_new_game_pressed() -> void:
	Session.continue_game = false
	Session.new_character = null
	get_tree().change_scene_to_file(CREATION_SCENE)


func _on_continue_pressed() -> void:
	Session.continue_game = true
	Session.new_character = null
	get_tree().change_scene_to_file(WORLD_SCENE)
