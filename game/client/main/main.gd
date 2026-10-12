extends Control
## Écran d'accueil provisoire, en attendant le menu principal (Phase 2).


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "?")
	%Version.text = "Version %s — Phase 0" % version
