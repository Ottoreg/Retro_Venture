extends "res://tests/test_case.gd"
## Vérifications de base sur la configuration du projet.


func test_scene_principale_se_charge() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene")
	var scene: PackedScene = load(path)
	assert_true(scene != null, "scène principale %s" % path)
	if scene:
		var main := scene.instantiate()
		assert_true(main.get_node_or_null("Center/Box/Version") != null, "label de version présent")
		main.free()


func test_version_definie() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	assert_false(version.is_empty(), "application/config/version")


## Chaque caractère des textes du jeu (chaînes du code, données JSON) existe dans la police : sinon
## il s'affiche comme un carré, surtout dans la version web, qui n'a pas de police de secours.
func test_caracteres_presents_dans_la_police() -> void:
	var font := ThemeDB.fallback_font
	var literal := RegEx.create_from_string("\"(?:[^\"\\\\]|\\\\.)*\"")
	var missing := {}
	for path in _text_files("res://client") + _text_files("res://core") + _text_files("res://data"):
		var text := FileAccess.get_file_as_string(path)
		var parts: Array = [text] if path.ends_with(".json") else literal.search_all(text).map(func(m: RegExMatch) -> String: return m.get_string())
		for part: String in parts:
			for i in part.length():
				var code := part.unicode_at(i)
				if code > 127 and not font.has_char(code):
					missing["%s (U+%04X) dans %s" % [part[i], code, path.get_file()]] = true
	assert_eq(missing.keys(), [], "caractères absents de la police")


func _text_files(dir: String) -> Array:
	var files := []
	for sub in DirAccess.get_directories_at(dir):
		files += _text_files(dir.path_join(sub))
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd") or file.ends_with(".json"):
			files.append(dir.path_join(file))
	return files
