extends SceneTree
## Lanceur de tests minimal, sans dépendance externe.
##   godot --headless --path game -s res://tests/run_tests.gd
## Exécute toutes les méthodes `test_*` des fichiers `tests/**/test_*.gd`.
## Code de sortie : 0 si tout passe, 1 sinon.
##
## Limite : une erreur d'exécution GDScript interrompt le test sans le marquer en échec ;
## la CI échoue donc aussi si la sortie contient « SCRIPT ERROR ».

const TEST_ROOT := "res://tests"


var _started := false


## Les tests tournent à la première image : l'arbre de scène est alors prêt, et les scènes
## ajoutées par les tests reçoivent bien leur `_ready()`.
func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run_all()
	return false


func _run_all() -> void:
	var passed := 0
	var failed := 0
	for path in _find_test_files(TEST_ROOT):
		var script: GDScript = load(path)
		if script == null:
			printerr("ÉCHEC  %s : impossible de charger le script" % path)
			failed += 1
			continue
		for method in script.get_script_method_list():
			var test_name: String = method["name"]
			if not test_name.begins_with("test_"):
				continue
			var test = script.new()  # non typé : before_each() et failures viennent du script
			test.before_each()
			test.call(test_name)
			if test.failures.is_empty():
				passed += 1
				print("ok     %s::%s" % [path.get_file(), test_name])
			else:
				failed += 1
				for failure in test.failures:
					printerr("ÉCHEC  %s::%s : %s" % [path.get_file(), test_name, failure])
	print("\n%d test(s) réussi(s), %d échec(s)" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _find_test_files(dir_path: String) -> PackedStringArray:
	var files: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return files
	for sub in dir.get_directories():
		files.append_array(_find_test_files(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(dir_path.path_join(file))
	return files
