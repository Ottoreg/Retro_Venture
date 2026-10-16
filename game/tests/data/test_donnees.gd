extends "res://tests/test_case.gd"
## Vérifie tous les fichiers de contenu de `res://data/`.

const DATA_ROOT := "res://data"


func test_fichiers_json_valides() -> void:
	var files := _find_json(DATA_ROOT)
	assert_true(files.size() > 0, "au moins un fichier de données")
	for path in files:
		var json := JSON.new()
		var error := json.parse(FileAccess.get_file_as_string(path))
		assert_eq(error, OK, "%s ligne %d : %s" % [path, json.get_error_line(), json.get_error_message()])


func test_cartes_valides() -> void:
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) != TYPE_DICTIONARY:
			assert_true(false, "%s : objet JSON attendu" % path)
			continue
		var errors := GameMap.validate(data)
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		assert_eq(str(data.get("id")), path.get_file().get_basename(), "%s : l'id doit correspondre au nom du fichier" % path)


func test_toutes_les_cases_praticables_sont_accessibles() -> void:
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue  # Déjà signalé par test_cartes_valides.
		for cell: Vector2i in map.cells():
			if map.is_walkable(cell) and cell != map.spawn:
				assert_true(map.find_path(map.spawn, cell).size() > 0, "%s : case %s inaccessible depuis le départ" % [path, cell])


func test_carte_de_depart_chargeable() -> void:
	var map := DataLoader.load_map("res://data/cartes/brumerive_0_0.json")
	assert_true(map != null, "carte de départ")


func test_sorts_monstres_et_voies_valides() -> void:
	var spells := {}
	for path in DataLoader.list_json(DATA_ROOT.path_join("sorts")):
		var data: Variant = DataLoader.load_json(path)
		var errors := Spell.validate(data) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
		if errors.is_empty():
			spells[data["id"]] = Spell.from_dict(data)
	var items := {}
	for path in DataLoader.list_json(DATA_ROOT.path_join("objets")):
		var data: Variant = DataLoader.load_json(path)
		var errors := Item.validate(data) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
		if errors.is_empty():
			items[data["id"]] = data
	for path in DataLoader.list_json(DATA_ROOT.path_join("monstres")):
		var data: Variant = DataLoader.load_json(path)
		var errors := GameData.validate_monster(data, spells, items) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
	for path in DataLoader.list_json(DATA_ROOT.path_join("races")):
		var data: Variant = DataLoader.load_json(path)
		var errors := GameData.validate_race(data, spells) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
	for path in DataLoader.list_json(DATA_ROOT.path_join("voies")):
		var data: Variant = DataLoader.load_json(path)
		var errors := GameData.validate_voie(data, spells, items) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)


func test_monstres_des_cartes_existants() -> void:
	var game_data := GameData.load_all()
	assert_true(game_data.voies.has(World.DEFAULT_VOIE), "Voie de départ « %s »" % World.DEFAULT_VOIE)
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		for group in map.groups:
			for monster_id: String in GameMap.possible_monsters(group):
				assert_true(game_data.monsters.has(monster_id), "%s : monstre inconnu « %s »" % [path, monster_id])
			if group.has("apres_boss"):
				var boss: Dictionary = game_data.monsters.get(group["apres_boss"], {})
				assert_true(boss.get("boss", false), "%s : « apres_boss » %s n'est pas un boss" % [path, group["apres_boss"]])


func test_metiers_valides() -> void:
	var items := {}
	for path in DataLoader.list_json(DATA_ROOT.path_join("objets")):
		var data: Variant = DataLoader.load_json(path)
		if typeof(data) == TYPE_DICTIONARY:
			items[data.get("id")] = data
	var paths := DataLoader.list_json(DATA_ROOT.path_join("metiers"))
	assert_true(paths.size() >= 3, "bûcheron, mineur, forgeron")
	for path in paths:
		var data: Variant = DataLoader.load_json(path)
		var errors := Profession.validate(data, items) if typeof(data) == TYPE_DICTIONARY else PackedStringArray(["objet JSON attendu"])
		assert_eq(errors.size(), 0, "%s : %s" % [path, "; ".join(errors)])
		_assert_id_matches_file(data, path)
	var game_data := GameData.load_all()
	assert_eq(game_data.jobs.size(), paths.size(), "tous les métiers sont chargés")


func test_ressources_et_ateliers_des_cartes() -> void:
	var game_data := GameData.load_all()
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		for cell: Vector2i in map.resource_nodes:
			var marker: String = map.resource_nodes[cell]
			assert_true(game_data.nodes.has(marker), "%s : aucune ressource de métier n'utilise « %s »" % [path, marker])
			var reachable := GameMap.is_adjacent(map.spawn, cell) or not map.approach_path(map.spawn, cell).is_empty()
			assert_true(reachable, "%s : ressource %s inaccessible" % [path, cell])
		for npc: Dictionary in map.npcs:
			var workshop: String = npc["atelier"]
			if not workshop.is_empty():
				assert_eq(str(game_data.jobs.get(workshop, {}).get("type")), Profession.TYPE_CRAFT, "%s : atelier « %s » inconnu" % [path, workshop])


func test_sorties_des_cartes_reciproques() -> void:
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		for direction: String in map.exits:
			var neighbor := DataLoader.load_map(DataLoader.map_path(map.exits[direction]))
			assert_true(neighbor != null, "%s : la sortie « %s » mène à une carte inexistante (%s)" % [path, direction, map.exits[direction]])
			if neighbor == null:
				continue
			var back: String = GameMap.OPPOSITE_DIRECTION[direction]
			assert_eq(neighbor.exits.get(back, ""), map.id, "%s : la carte %s doit avoir une sortie « %s » qui ramène ici" % [path, neighbor.id, back])
			var edge_cells := 0
			for cell: Vector2i in map.cells():
				if map.is_walkable(cell) and direction in map.exit_directions(cell):
					edge_cells += 1
			assert_true(edge_cells > 0, "%s : aucune case praticable sur le bord « %s »" % [path, direction])


func test_sorties_coherentes_avec_les_coordonnees() -> void:
	# La carte du monde place les cartes d'après leur id : une sortie mène à la carte voisine dans la
	# grille, dans la même zone (droite : x + 1, bas : y + 1).
	var offsets := {"droite": Vector2i(1, 0), "gauche": Vector2i(-1, 0), "bas": Vector2i(0, 1), "haut": Vector2i(0, -1)}
	var checked := 0
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		var here := WorldMapLayout.map_coordinates(map.id)
		if here.is_empty():
			continue
		for direction: String in map.exits:
			checked += 1
			var target: String = map.exits[direction]
			var there := WorldMapLayout.map_coordinates(target)
			assert_false(there.is_empty(), "%s : la sortie « %s » mène à %s, sans coordonnées" % [path, direction, target])
			if there.is_empty():
				continue
			assert_eq(there["zone"], here["zone"], "%s : la sortie « %s » change de zone (%s)" % [path, direction, target])
			assert_eq(there["position"], here["position"] + offsets[direction],
				"%s : la sortie « %s » doit mener à la carte voisine dans la grille, pas à %s" % [path, direction, target])
	assert_true(checked >= 6, "des sorties vérifiées")


func test_portes_reciproques() -> void:
	var door_count := 0
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		for cell: Vector2i in map.doors:
			door_count += 1
			var target := DataLoader.load_map(DataLoader.map_path(map.doors[cell]))
			assert_true(target != null, "%s : la porte %s mène à une carte inexistante (%s)" % [path, cell, map.doors[cell]])
			if target != null:
				assert_true(map.id in target.doors.values(), "%s : la carte %s doit avoir une porte qui ramène ici" % [path, target.id])
	assert_true(door_count >= 2, "au moins la porte de la maison et celle qui en sort")
	var house := DataLoader.load_map(DataLoader.map_path("maison_joueur"))
	assert_true(house != null and house.instance == "joueur", "maison du joueur, instanciée par joueur en multi")
	if house != null:
		assert_true("coffre" in house.obstacles.values() and "lit" in house.obstacles.values(), "un coffre et un lit")


func test_pierres_de_passage_et_zones_de_depart() -> void:
	var game_data := GameData.load_all()
	assert_true(game_data.passages.size() >= 3, "une pierre par zone de départ")
	var with_stone := {}
	for passage_id: String in game_data.passages:
		var map := DataLoader.load_map(DataLoader.map_path(game_data.passages[passage_id]["carte"]))
		assert_true(map != null, "pierre « %s » : carte introuvable" % passage_id)
		if map != null:
			assert_ne(map.travel_stone(), Vector2i(-1, -1), "pierre « %s » : pas de « * » sur la carte %s" % [passage_id, map.id])
			with_stone[map.id] = true
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map != null and map.travel_stone() != Vector2i(-1, -1):
			assert_true(with_stone.has(map.id), "%s : une pierre sans entrée dans data/passages" % path)
	for race_id: String in game_data.races:
		var start := str(game_data.races[race_id]["carte_depart"])
		assert_true(DataLoader.load_map(DataLoader.map_path(start)) != null, "race « %s » : carte de départ %s" % [race_id, start])
		assert_true(with_stone.has(start), "race « %s » : sa première carte a une Pierre de Passage" % race_id)
		# Voyage vers une zone de départ : 10 écus, et il faut d'abord y être allé.
		var stone := game_data.start_passage(race_id)
		assert_eq(game_data.passages.get(stone, {}).get("carte"), start, "race « %s » : pierre de sa zone de départ" % race_id)
		assert_eq(game_data.passage_price(stone), 10, "pierre « %s » : 10 écus" % stone)
		assert_false(game_data.passage_always_known(stone), "pierre « %s » : à découvrir" % stone)
	# La carte d'élite de test : gratuite et connue de tous.
	assert_eq(game_data.passage_price("trone_de_cendre"), 0)
	assert_true(game_data.passage_always_known("trone_de_cendre"))
	assert_eq(str(game_data.races["gobelin"]["carte_depart"]), "crasse_roc_0_0")
	assert_eq(str(game_data.races["elfe"]["carte_depart"]), "sylvebrume_0_0")
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map != null and not map.palette.is_empty():
			assert_true(Art.manifest()["palettes"].has(map.palette), "%s : palette « %s » inconnue" % [path, map.palette])


func test_monstres_des_zones_et_carte_d_elite() -> void:
	var game_data := GameData.load_all()
	# Deux types de monstres par zone de départ.
	var zones := {"brumerive": ["brumerive_0_0", "brumerive_1_0"], "crasse_roc": ["crasse_roc_0_0", "crasse_roc_1_0"],
		"sylvebrume": ["sylvebrume_0_0", "sylvebrume_1_0"]}
	for zone: String in zones:
		var kinds := {}
		for map_id: String in zones[zone]:
			var map := DataLoader.load_map(DataLoader.map_path(map_id))
			assert_true(map != null, "carte %s" % map_id)
			if map == null:
				continue
			for group in map.groups:
				for monster_id: String in GameMap.possible_monsters(group):
					kinds[monster_id] = true
		assert_true(kinds.size() >= 2, "zone %s : au moins deux types de monstres (%s)" % [zone, str(kinds.keys())])
	# Le Souverain Cendré : le plus puissant, seul sur la carte d'élite, joignable par une Pierre de Passage.
	var boss: Dictionary = game_data.monsters["souverain_cendre"]
	assert_true(boss.get("boss", false), "le Cendré est un boss")
	for monster_id: String in game_data.monsters:
		if monster_id != "souverain_cendre":
			var strongest := game_data.create_monster(monster_id, "m", game_data.monster_level_range(monster_id).y)
			assert_true(strongest.max_hp < int(boss["caracteristiques"]["pv"]), "%s moins fort que le Cendré, même à son plus haut niveau" % monster_id)
	var elite := DataLoader.load_map(DataLoader.map_path("cendre_0_0"))
	assert_true(elite != null and elite.groups.size() == 1 and elite.groups[0]["monstres"] == ["souverain_cendre"], "le Cendré sur sa carte")
	var reachable := false
	for passage: Dictionary in game_data.passages.values():
		reachable = reachable or passage["carte"] == "cendre_0_0"
	assert_true(reachable, "carte d'élite accessible par une Pierre de Passage")


func _assert_id_matches_file(data: Variant, path: String) -> void:
	if typeof(data) == TYPE_DICTIONARY:
		assert_eq(str(data.get("id")), path.get_file().get_basename(), "%s : l'id doit correspondre au nom du fichier" % path)


func _find_json(dir_path: String) -> PackedStringArray:
	return DataLoader.list_json(dir_path)


func test_maison_marchand_et_forgeron_dans_chaque_zone_de_depart() -> void:
	var game_data := GameData.load_all()
	for race_id: String in game_data.races:
		var map := DataLoader.load_map(DataLoader.map_path(str(game_data.races[race_id]["carte_depart"])))
		assert_true(map != null)
		if map == null:
			continue
		var merchant := false
		var smith := false
		for npc: Dictionary in map.npcs:
			merchant = merchant or npc.get("marchand", false)
			smith = smith or npc.get("atelier", "") == "forgeron"
		assert_true(merchant, "%s : un marchand" % map.id)
		assert_true(smith, "%s : un forgeron" % map.id)
		var house: GameMap = null
		for cell: Vector2i in map.doors:
			var target := DataLoader.load_map(DataLoader.map_path(map.doors[cell]))
			if target != null and target.instance == "joueur":
				house = target
		assert_true(house != null, "%s : une porte vers une maison du joueur" % map.id)
		if house != null:
			assert_true("coffre" in house.obstacles.values() and "lit" in house.obstacles.values(), "%s : coffre et lit" % house.id)
			assert_eq(house.door_to(map.id), house.doors.keys()[0], "la porte de la maison ramène à %s" % map.id)


func test_un_elite_par_famille_de_monstres() -> void:
	var game_data := GameData.load_all()
	var art: Dictionary = Art.manifest()["monstres"]
	var placed := {}
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map != null:
			for group in map.groups:
				for monster_id: String in GameMap.possible_monsters(group):
					placed[monster_id] = true
	var elite_of := {}
	for monster_id: String in game_data.monsters:
		var elite: Dictionary = game_data.monsters[monster_id]
		if not elite.get("elite", false):
			continue
		var family: String = elite["famille"]
		assert_true(game_data.monsters.has(family) and not game_data.monsters[family].get("elite", false), "%s : famille « %s » inconnue" % [monster_id, family])
		if not game_data.monsters.has(family):
			continue
		elite_of[family] = monster_id
		var base: Dictionary = game_data.monsters[family]
		assert_true(int(elite["niveau"]) > game_data.monster_level_range(family).y, "%s : niveau plus haut que toute la tranche de %s" % [monster_id, family])
		assert_false(elite.has("niveaux"), "%s : niveau fixe" % monster_id)
		assert_true(int(elite["caracteristiques"]["pv"]) >= 2 * int(base["caracteristiques"]["pv"]), "%s : au moins deux fois plus de PV" % monster_id)
		assert_true(float(art[monster_id].get("echelle", 1.0)) > float(art[family].get("echelle", 1.0)) or art[monster_id].has("rig"), "%s : plus grand" % monster_id)
		var rates := {}
		for drop: Dictionary in elite["butin"]:
			rates[drop["objet"]] = float(drop["taux"])
		for drop: Dictionary in base["butin"]:
			var rarity: String = game_data.items[drop["objet"]]["rarete"]
			if rarity != "commun":
				assert_true(rates.get(drop["objet"], 0.0) > float(drop["taux"]), "%s : « %s » plus fréquent que sur %s" % [monster_id, drop["objet"], family])
		assert_false(placed.has(monster_id), "%s : pas de groupe fixe, l'élite apparaît d'elle-même" % monster_id)
		assert_true(placed.has(family), "%s : sa famille vit sur une carte (où l'élite pourra apparaître)" % monster_id)
	for monster_id: String in game_data.monsters:
		var monster: Dictionary = game_data.monsters[monster_id]
		# Une variante corrompue n'est pas une famille : pas d'élite, mais une famille d'origine.
		if monster.get("corrompu", false):
			var origin: Dictionary = game_data.monsters.get(str(monster.get("base", "")), {})
			assert_true(not origin.is_empty() and not origin.get("elite", false) and not origin.get("corrompu", false),
				"%s : « base » doit être une famille existante" % monster_id)
			assert_false(elite_of.has(monster_id), "%s : pas d'élite pour une variante" % monster_id)
			continue
		# Un boss est unique : ni famille, ni élite.
		if not monster.get("elite", false) and not monster.get("boss", false):
			assert_true(elite_of.has(monster_id), "famille « %s » : il lui faut un élite" % monster_id)


func test_panoplies_de_l_alpha_test() -> void:
	var data := GameData.load_all()
	var elemental := ["forgeron_hargneux", "pyromane_repenti", "bonhomme_de_neige", "courant_d_air", "enfant_de_choeur", "mauvais_oeil"]
	for set_id in elemental + ["presse", "fouineur"]:
		assert_true(data.sets.has(set_id), "panoplie « %s »" % set_id)
	for set_id: String in data.sets:
		var panoply: Dictionary = data.sets[set_id]
		var expected := 6 if set_id in elemental else 3
		assert_eq(panoply["objets"].size(), expected, "%s : %d pièces" % [set_id, expected])
		var slots := {}
		for item_id: String in panoply["objets"]:
			slots[data.items[item_id]["type"]] = true
		assert_eq(slots.size(), expected, "%s : une pièce par emplacement" % set_id)
		# Le bonus grandit avec le nombre de pièces : chaque palier donne au moins autant que le précédent.
		var previous := {}
		for count in range(2, expected + 1):
			var tier := data.set_tier(set_id, count)
			assert_false(tier.is_empty(), "%s : bonus à %d pièces" % [set_id, count])
			for stat: String in previous:
				assert_true(int(tier.get(stat, 0)) >= int(previous[stat]), "%s : %s ne baisse pas à %d pièces" % [set_id, stat, count])
			previous = tier
	# Les panoplies de 3 pièces se mélangent : Pressé et Fouineur n'ont aucun emplacement en commun.
	var used := {}
	for set_id in ["presse", "fouineur"]:
		for item_id: String in data.sets[set_id]["objets"]:
			var slot: String = data.items[item_id]["type"]
			assert_false(used.has(slot), "emplacement « %s » partagé" % slot)
			used[slot] = true


func test_le_theologue() -> void:
	var data := GameData.load_all()
	assert_true(data.voies.has("theologue"), "Voie du Théologue")
	var character := Character.create("Frère Tuck-Tuck", "humain", "theologue")
	data.give_starting_kit(character)
	assert_eq(character.inventory.equipped_entry("arme")["objet"], "sceptre_de_novice", "sceptre de départ")
	var fighter := data.create_character_fighter(character, "joueur")
	var ids: Array[String] = []
	for spell in fighter.spells:
		ids.append(spell.id)
	for spell_id in ["theologue_chatiment", "theologue_imposition", "theologue_rempart", "theologue_sermon"]:
		assert_true(spell_id in ids, "sort %s" % spell_id)
	var kinds := {}
	for spell_id in ["theologue_chatiment", "theologue_imposition", "theologue_rempart", "theologue_sermon"]:
		for effect: Dictionary in data.spells[spell_id].effects:
			kinds[effect["type"] + "/" + str(effect.get("element", ""))] = true
	assert_true(kinds.has("degats/sacre"), "des dégâts Sacré")
	assert_true(kinds.has("soin/sacre"), "un soin Sacré")
	assert_true(kinds.has("bouclier/sacre"), "un bouclier Sacré")
	assert_true(Art.manifest()["tenues"].has("theologue"), "tenue du Théologue")


## Zone d'une carte : son id sans les coordonnées (« crasse_roc_1_3 » → « crasse_roc »).
static func _zone_of(map_id: String) -> String:
	var parts := map_id.split("_")
	return "_".join(parts.slice(0, parts.size() - 2)) if parts.size() > 2 else map_id


## Chaque quête est faisable : ses PNJ et ses cartes existent, ses monstres vivent sur des cartes de
## la zone de son donneur (les boss aussi), ses ressources se récoltent au niveau 1 de métier dans les
## zones de départ, et sa chaîne remonte à un tutoriel (ou n'a pas de condition de quête).
func test_quetes_faisables() -> void:
	var game_data := GameData.load_all()
	assert_eq(game_data.quests.size(), DataLoader.list_json(DATA_ROOT.path_join("quetes")).size(), "toutes les quêtes sont valides")
	var npc_maps := {}
	var monsters_by_zone := {}
	var maps := {}
	for path in _find_json(DATA_ROOT.path_join("cartes")):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		maps[map.id] = map
		for npc in map.npcs:
			npc_maps[npc["id"]] = map.id
		var zone := _zone_of(map.id)
		if not monsters_by_zone.has(zone):
			monsters_by_zone[zone] = {}
		for group in map.groups:
			for monster_id: String in GameMap.possible_monsters(group):
				monsters_by_zone[zone][monster_id] = true
				var family: String = game_data.monsters.get(monster_id, {}).get("famille", monster_id)
				monsters_by_zone[zone][family] = true
	var node_levels := {}
	for node: Dictionary in game_data.nodes.values():
		node_levels[node["objet"]] = mini(int(node_levels.get(node["objet"], 99)), int(node.get("niveau", 1)))
	for quest_id: String in game_data.quests:
		var quest: Dictionary = game_data.quests[quest_id]
		assert_true(npc_maps.has(quest["pnj"]), "%s : donneur %s sur une carte" % [quest_id, quest["pnj"]])
		var zone := _zone_of(npc_maps.get(quest["pnj"], ""))
		for npc_id: String in quest.get("dialogues", {}):
			assert_true(npc_maps.has(npc_id), "%s : PNJ des dialogues %s" % [quest_id, npc_id])
		for step: Dictionary in quest["etapes"]:
			for objective: Dictionary in step["objectifs"]:
				if objective.has("pnj"):
					assert_true(npc_maps.has(objective["pnj"]), "%s : PNJ %s" % [quest_id, objective["pnj"]])
				if objective.has("carte"):
					assert_true(maps.has(objective["carte"]), "%s : carte %s" % [quest_id, objective["carte"]])
				if objective.has("monstre"):
					assert_true(monsters_by_zone.get(zone, {}).has(objective["monstre"]),
						"%s : %s vit dans la zone %s" % [quest_id, objective["monstre"], zone])
				for monster_id: String in objective.get("butin", {}).get("monstres", []):
					assert_true(game_data.monsters.has(monster_id), "%s : butin de %s" % [quest_id, monster_id])
				if objective["type"] == Quest.OBJ_HARVEST and int(quest["niveau"]) <= 12:
					assert_eq(int(node_levels.get(objective["objet"], 99)), 1, "%s : %s se récolte au niveau 1" % [quest_id, objective["objet"]])
		# Remonter la chaîne jusqu'à une quête sans condition de quête.
		var current := quest_id
		for depth in 50:
			var required: Array = game_data.quests[current].get("conditions", {}).get("quetes_terminees", [])
			if required.is_empty():
				break
			current = required[0]
		assert_true(game_data.quests[current].get("conditions", {}).get("quetes_terminees", []).is_empty(), "%s : chaîne sans boucle" % quest_id)


func test_chaines_principales_par_camp() -> void:
	var game_data := GameData.load_all()
	for camp: String in GameData.CAMPS:
		var tutorials := 0
		var act_one := 0
		for quest: Dictionary in game_data.quests.values():
			if quest.get("conditions", {}).get("camp", "") != camp:
				continue
			if quest["categorie"] == "tutoriel":
				tutorials += 1
			elif quest["categorie"] == "principale" and int(quest.get("acte", 0)) == 1:
				act_one += 1
		assert_eq(tutorials, 1, "un tutoriel pour le camp %s" % camp)
		assert_eq(act_one, 4, "quatre quêtes d'acte I pour le camp %s" % camp)
		var act_two := game_data.quests.values().filter(func(q: Dictionary) -> bool:
			return int(q.get("acte", 0)) == 2 and q.get("conditions", {}).get("camp", "") == camp)
		assert_eq(act_two.size(), 3, "trois quêtes d'acte II pour le camp %s" % camp)
	# Acte III : commun, ouvert par la fin de l'acte II de n'importe quel camp.
	var act_three := game_data.quests.values().filter(func(q: Dictionary) -> bool: return int(q.get("acte", 0)) == 3)
	assert_eq(act_three.size(), 2, "le Conseil et la Brèche")
	for quest: Dictionary in act_three:
		assert_false(quest.get("conditions", {}).has("camp"), "%s : ouverte aux trois camps" % quest["id"])
