extends "res://tests/test_case.gd"
## Promenade des groupes de monstres autour de leur case d'origine, et sauvegarde de leur
## composition et de leur position.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _world: World
## Porte en haut à droite de la carte, groupe au centre.
var _door := GameMap.plan_cell(0, 8)


func before_each() -> void:
	_maps = {
		"test": Fixtures.map({Fixtures.center(): "1", _door: "+"}, [{"parmi": ["mannequin", "blinde", "loup"], "nombre": [3, 3]}],
			{"portes": ["test"]}),
	}
	_world = World.new(_maps["test"], Fixtures.data(), _loader, Fixtures.character())


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


## Avance le temps jusqu'à la prochaine promenade ; renvoie son événement ({} s'il n'y en a pas).
func _next_walk() -> Dictionary:
	for i in 60:
		for event in _world.update(1.0):
			if event["type"] == Protocol.EVT_GROUP_MOVED:
				return event
	return {}


func test_le_groupe_se_promene_pres_de_chez_lui() -> void:
	var home := Fixtures.center()
	var moves := 0
	for i in 20:
		var before := _world.position_of("groupe_1")
		var event := _next_walk()
		if event.is_empty():
			continue
		moves += 1
		assert_eq(event["groupe"], "groupe_1")
		var path: Array = event["chemin"]
		assert_true(path.size() >= 1 and path.size() <= World.GROUP_WANDER_STEPS, "1 à 3 pas (%d)" % path.size())
		var previous := before
		for cell: Vector2i in path:
			assert_eq(absi(cell.x - previous.x) + absi(cell.y - previous.y), 1, "des pas droits")
			assert_true(_world.map.is_walkable(cell))
			previous = cell
		var arrival: Vector2i = event["case"]
		assert_eq(arrival, path[-1])
		assert_eq(_world.position_of("groupe_1"), arrival, "position du groupe à jour")
		assert_eq(_world.group_at(arrival)["id"], "groupe_1")
		assert_true(maxi(absi(arrival.x - home.x), absi(arrival.y - home.y)) <= World.GROUP_WANDER_RANGE, "reste près de son origine")
		assert_ne(arrival, _world.position_of(World.PLAYER_ID))
		assert_false(_world.map.doors.has(arrival), "jamais sur une porte")
		assert_true(_world.map.exit_directions(arrival).is_empty(), "jamais sur un bord de sortie")
	assert_true(moves >= 15, "il bouge régulièrement (%d promenades)" % moves)


func test_pas_de_promenade_sur_le_joueur_ni_en_combat() -> void:
	# Le joueur se place juste à côté : le groupe ne marche jamais sur lui.
	var next_to := Fixtures.center() + Vector2i(1, 0)
	_world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": next_to})
	for i in 10:
		var event := _next_walk()
		for cell: Vector2i in event.get("chemin", []):
			assert_ne(cell, next_to, "le groupe contourne le joueur")
	_world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})
	assert_true(_world.in_combat())
	assert_true(_next_walk().is_empty(), "personne ne se promène pendant un combat")


func test_composition_et_position_sauvegardees() -> void:
	var group: Dictionary = _world.groups()[0]
	var monsters: Array = group["monstres"].duplicate()
	assert_false(_next_walk().is_empty())
	var cell := _world.position_of("groupe_1")
	assert_ne(cell, Fixtures.center(), "le groupe a bougé")
	var save: Variant = JSON.parse_string(JSON.stringify(_world.save_data()))
	for i in 10:
		var restored := World.from_save(save, Fixtures.data(), _loader)
		assert_true(restored != null)
		var back: Dictionary = restored.groups()[0]
		assert_eq(str(back["monstres"]), str(monsters), "même composition après la reprise")
		assert_eq(back["case"], cell, "même place")
		assert_eq(restored.position_of("groupe_1"), cell)
		assert_eq(back["foyer"], Fixtures.center(), "il se promène toujours autour de son origine")


func test_ancienne_sauvegarde_et_sauvegarde_incoherente() -> void:
	var save: Dictionary = JSON.parse_string(JSON.stringify(_world.save_data()))
	# Ancien format : seulement l'id des groupes restants.
	save["groupes_restants"] = {"test": ["groupe_1"]}
	var restored := World.from_save(save, Fixtures.data(), _loader)
	assert_eq(restored.groups().size(), 1)
	assert_eq(restored.groups()[0]["monstres"].size(), 3, "composé à nouveau")
	assert_eq(restored.position_of("groupe_1"), Fixtures.center())
	# Monstre inconnu, case hors de la carte : on reprend le groupe tel qu'il apparaît d'habitude.
	save["groupes_restants"] = {"test": [{"id": "groupe_1", "case": [99, 99], "monstres": ["dragon"]}]}
	restored = World.from_save(save, Fixtures.data(), _loader)
	var group: Dictionary = restored.groups()[0]
	assert_eq(group["case"], Fixtures.center())
	for monster_id: String in group["monstres"]:
		assert_true(monster_id in ["mannequin", "blinde", "loup"], monster_id)


func test_jamais_cache_derriere_un_batiment() -> void:
	# Un « bâtiment » de 2 × 2 cases juste devant le groupe (plus bas à l'écran).
	var center := Fixtures.center()
	var blocks := {}
	for cell: Vector2i in [center + Vector2i(1, 1), center + Vector2i(2, 1), center + Vector2i(1, 2), center + Vector2i(2, 2)]:
		blocks[cell] = "#"
	blocks[center] = "1"
	_maps["test"] = Fixtures.map(blocks, [{"monstres": ["mannequin"]}])
	_world = World.new(_maps["test"], Fixtures.data(), _loader, Fixtures.character())
	assert_true(_world.map.is_behind_building(center - Vector2i(1, 1)), "case derrière le bâtiment")
	assert_false(_world.map.is_behind_building(center + Vector2i(3, 3)), "case devant le bâtiment")
	for i in 15:
		for cell: Vector2i in _next_walk().get("chemin", []):
			assert_false(_world.map.is_behind_building(cell), "pas derrière le bâtiment (%s)" % str(cell))
