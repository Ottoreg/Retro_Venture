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
