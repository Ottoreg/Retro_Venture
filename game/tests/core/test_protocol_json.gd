extends "res://tests/test_case.gd"
## Messages en JSON pour le réseau (GDD § 16.5) : version, numéro, cases en [x, y]. Les tests
## vérifient aussi l'aller-retour de chaque commande et de chaque événement du noyau
## (`Protocol.verify_json`, activé par `run_tests.gd`).


func test_enveloppe_version_et_numero() -> void:
	var text := Protocol.encode({"type": Protocol.CMD_MOVE, "entite": "p1", "cible": Vector2i(3, -2)}, 7)
	var raw: Dictionary = JSON.parse_string(text)
	assert_eq(int(raw["v"]), Protocol.VERSION)
	assert_eq(int(raw["n"]), 7)
	assert_eq(raw["cible"], [3.0, -2.0], "une case s'écrit [x, y]")
	var header := {}
	var back := Protocol.decode(text, header)
	assert_eq(back, {"type": Protocol.CMD_MOVE, "entite": "p1", "cible": Vector2i(3, -2)})
	assert_eq(int(header["n"]), 7)


func test_cases_et_listes_de_cases() -> void:
	var path: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	var event := {"type": Protocol.EVT_MOVED, "carte": "a", "entite": "p1", "depuis": Vector2i(0, 0), "chemin": path,
		"groupe": {"id": "g", "case": Vector2i(4, 4), "niveaux": [2, 3]}, "vide": [] as Array[Vector2i]}
	var back := Protocol.decode(Protocol.encode(event))
	assert_eq(typeof(back["depuis"]), TYPE_VECTOR2I)
	assert_eq(back["chemin"].get_typed_builtin(), TYPE_VECTOR2I, "liste de cases typée, comme dans le noyau")
	assert_eq(back["chemin"], path)
	assert_eq(back["groupe"]["case"], Vector2i(4, 4), "aussi dans un sous-dictionnaire")
	assert_eq(back["groupe"]["niveaux"], [2, 3], "deux nombres hors d'un champ de case restent une liste")
	assert_eq(typeof(back["groupe"]["niveaux"][0]), TYPE_INT, "les entiers redeviennent des int")


func test_messages_refuses() -> void:
	assert_eq(Protocol.decode("pas du json"), {})
	assert_eq(Protocol.decode("[1, 2]"), {}, "un message est un objet")
	assert_eq(Protocol.decode('{"v": %d, "n": 1}' % Protocol.VERSION), {}, "sans type")
	assert_eq(Protocol.decode('{"v": %d, "n": 1, "type": "deplacer"}' % (Protocol.VERSION + 1)), {}, "autre version")
	assert_eq(Protocol.decode('{"type": "deplacer"}'), {}, "sans version")


func test_cles_en_case() -> void:
	var wire: Dictionary = Protocol.to_wire({Vector2i(2, 5): "arbre"})
	assert_eq(wire, {"2,5": "arbre"})
