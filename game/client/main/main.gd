extends Control
## Écran d'accueil provisoire, en attendant le menu principal (Phase 2).

const WORLD_SCENE := "res://client/world/world.tscn"


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "?")
	%Version.text = "Version %s — Phase 1 (prototype de combat)" % version
	%Play.pressed.connect(_on_play_pressed)
	%Play.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)
