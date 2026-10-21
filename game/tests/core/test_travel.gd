extends "res://tests/test_case.gd"
## Pierres de Passage : on voyage de l'une à l'autre, entre des cartes qui ne sont pas reliées. Il
## faut d'abord découvrir une pierre (la toucher) pour y voyager, et le voyage se paie ; la dernière
## pierre touchée est le point de résurrection, où l'on se réveille après une défaite.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _world: World
var _stone := Fixtures.center()
## Groupe de loups de la carte « b », pour perdre un combat loin de chez soi.
var _wolves := GameMap.plan_cell(2, 2)
## Porte de la carte « test » vers la maison, et celle de la maison.
var _door := GameMap.plan_cell(8, 4)
var _house_door := GameMap.plan_cell(4, 2)


func before_each() -> void:
	_maps = {
		"test": Fixtures.map({_stone: "*", _door: "+"}, [], {"id": "test", "sorties": {"droite": "voisine"}, "portes": ["maison"]}),
		"b": Fixtures.map({_stone: "*", _wolves: "1"}, [{"monstres": ["loup"]}], {"id": "b"}),
		"c": Fixtures.map({_stone: "*"}, [], {"id": "c"}),
		"d": Fixtures.map({_stone: "*"}, [], {"id": "d"}),
		"voisine": Fixtures.map({}, [], {"id": "voisine", "sorties": {"gauche": "test"}}),
		"maison": GameMap.from_dict({"id": "maison", "nom": "Maison", "portes": ["test"],
			"plan": [".....", " ....", ".....", " ....", "@.+.."]}),
	}
	_world = _new_world("test")


## Pierres de test : « depart » sur la carte de départ du testeur, « pierre_b » et « pierre_c » à
## découvrir, « elite » toujours connue, « perdue » sur une carte introuvable.
func _data() -> GameData:
	return Fixtures.data([
		{"id": "depart", "nom": "Départ", "carte": "test", "prix": 10},
		{"id": "pierre_b", "nom": "B", "carte": "b", "prix": 15},
		{"id": "pierre_c", "nom": "C", "carte": "c"},
		{"id": "elite", "nom": "Élite", "carte": "d", "toujours_connue": true},
		{"id": "perdue", "nom": "Perdue", "carte": "introuvable"},
	])


## Nouveau personnage de test qui commence la partie sur cette carte ; pierres à découvrir, comme
## hors de la phase de test (voir `test_phase_de_test_toutes_les_pierres_connues`).
func _new_world(map_id: String) -> World:
	var world := World.new(_maps[map_id], _data(), _loader, Fixtures.character())
	world.all_passages_known = false
	return world


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _command(type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra, true)
	return _world.execute(command)


func _go_next_to_stone() -> void:
	var path := _world.map.approach_path(_world.position_of(World.PLAYER_ID), _stone)
	if not path.is_empty():
		_command(Protocol.CMD_MOVE, {"cible": path[-1]})


func _assert_refused(events: Array[Dictionary], reason: String, message := "") -> void:
	assert_eq(events.size(), 1, message)
	assert_eq(events[0]["type"], Protocol.EVT_REFUSED, message)
	assert_eq(events[0].get("raison"), reason, message)


## Perd un combat contre les loups de la carte « b » : le joueur, à 1 PV, passe son tour.
## Renvoie les événements de la fin du combat.
func _lose_fight() -> Array[Dictionary]:
	_command(Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	var monster := _world.combat.get_fighter("groupe_1_1")
	var player := _world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if _world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	player.hp = 1
	_command(Protocol.CMD_READY)
	var events := _command(Protocol.CMD_END_TURN)
	assert_false(_world.in_combat(), "combat perdu")
	return events


func test_la_pierre_sur_la_carte() -> void:
	var map: GameMap = _maps["c"]
	assert_eq(map.travel_stone(), _stone)
	assert_false(map.is_walkable(_stone), "la pierre bloque sa case")
	var beside := map.beside(_stone)
	assert_true(map.is_walkable(beside) and GameMap.is_adjacent(beside, _stone), "case d'arrivée à côté de la pierre")
	assert_eq(Fixtures.map().travel_stone(), Vector2i(-1, -1), "pas de pierre")


func test_pierre_de_la_zone_de_depart() -> void:
	var character := _world.character
	assert_eq(_world.data.start_passage("testeur"), "depart", "la pierre de la carte de départ de la race")
	assert_eq(_world.data.start_passage("inconnue"), "")
	assert_eq(character.known_passages, ["depart"] as Array[String], "connue dès la création")
	assert_eq(character.respawn_passage, "depart", "et point de résurrection")
	assert_true(_world.is_passage_known("elite"), "toujours connue")
	assert_false(_world.is_passage_known("pierre_b"), "à découvrir")
	# Sans pierre dans la zone de départ (données de test sans pierres) : rien de connu.
	var bare := World.new(_maps["test"], Fixtures.data(), _loader, Fixtures.character())
	assert_true(bare.character.known_passages.is_empty())
	assert_eq(bare.character.respawn_passage, "")


func test_phase_de_test_toutes_les_pierres_connues() -> void:
	# Tant que les zones ne sont pas reliées à pied, toutes les pierres sont connues dès le début.
	var world := World.new(_maps["test"], _data(), _loader, Fixtures.character())
	assert_eq(world.all_passages_known, World.ALL_PASSAGES_KNOWN)
	world.all_passages_known = true
	assert_true(world.is_passage_known("pierre_b"), "connue sans l'avoir touchée")
	assert_false(world.is_passage_known("inconnue"), "une pierre qui n'existe pas reste inconnue")
	assert_false(world.character.known_passages.has("pierre_b"), "rien d'ajouté à la sauvegarde")


func test_menu_de_la_pierre() -> void:
	_assert_refused(_command(Protocol.CMD_USE, {"case": _stone}), Protocol.REASON_TOO_FAR)
	_go_next_to_stone()
	_world.character.inventory.ecus = 12
	var events := _command(Protocol.CMD_USE, {"case": _stone})
	assert_eq(events.size(), 1, "pierre déjà connue et déjà point de résurrection : seulement le menu")
	assert_eq(events[0]["type"], Protocol.EVT_TRAVEL_MENU)
	assert_eq(events[0]["ici"], "depart")
	assert_eq(events[0]["ecus"], 12)
	assert_eq(events[0]["resurrection"], "depart")
	var destinations := {}
	for destination: Dictionary in events[0]["destinations"]:
		destinations[destination["id"]] = destination
	assert_eq(destinations.size(), 5)
	assert_eq(destinations["pierre_b"], {"id": "pierre_b", "nom": "B", "carte": "b", "prix": 15, "connue": false})
	assert_eq(destinations["pierre_c"]["prix"], 0, "gratuit par défaut")
	assert_true(destinations["depart"]["connue"])
	assert_true(destinations["elite"]["connue"], "toujours connue")


func test_decouverte_au_clic() -> void:
	_world = _new_world("b")
	_go_next_to_stone()
	var events := _command(Protocol.CMD_USE, {"case": _stone})
	assert_eq(events.size(), 3)
	assert_eq(events[0], {"type": Protocol.EVT_PASSAGE_DISCOVERED, "passage": "pierre_b", "nom": "B"})
	assert_eq(events[1], {"type": Protocol.EVT_RESPAWN_POINT, "passage": "pierre_b", "nom": "B"})
	assert_eq(events[2]["type"], Protocol.EVT_TRAVEL_MENU, "puis le menu de voyage")
	assert_eq(events[2]["resurrection"], "pierre_b")
	assert_true(_world.is_passage_known("pierre_b"))
	assert_eq(_world.character.known_passages, ["depart", "pierre_b"] as Array[String])
	assert_eq(_world.character.respawn_passage, "pierre_b")
	var again := _command(Protocol.CMD_USE, {"case": _stone})
	assert_eq(again.size(), 1, "déjà découverte, déjà point de résurrection")
	assert_eq(again[0]["type"], Protocol.EVT_TRAVEL_MENU)


func test_voyager() -> void:
	_world.character.discover_passage("pierre_c")
	_go_next_to_stone()
	var events := _command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_c"})
	assert_eq(events.size(), 1, "voyage gratuit : l'inventaire ne change pas")
	assert_eq(events[0]["type"], Protocol.EVT_MAP_CHANGED)
	assert_eq(events[0]["prix"], 0)
	assert_eq(_world.map.id, "c")
	var arrival := _world.position_of(World.PLAYER_ID)
	assert_true(GameMap.is_adjacent(arrival, _world.map.travel_stone()), "on arrive à côté de la pierre")
	assert_eq(_world.character.respawn_passage, "depart", "arriver par un voyage ne change pas le point de résurrection")
	# Et retour, contre 10 brumes.
	_world.character.inventory.ecus = 25
	events = _command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "depart"})
	assert_eq(events[0]["type"], Protocol.EVT_MAP_CHANGED)
	assert_eq(events[0]["prix"], 10)
	assert_eq(_world.map.id, "test")
	assert_eq(_world.character.inventory.ecus, 15, "brumes débitées")
	var inventory := Fixtures.of_type(events, Protocol.EVT_INVENTORY)
	assert_eq(inventory.size(), 1, "événement d'inventaire")
	assert_eq(inventory[0]["inventaire"]["ecus"], 15)


func test_pierre_toujours_connue() -> void:
	_go_next_to_stone()
	var events := _command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "elite"})
	assert_eq(events[0]["type"], Protocol.EVT_MAP_CHANGED, "pas besoin de la découvrir")
	assert_eq(_world.map.id, "d")
	assert_false("elite" in _world.character.known_passages, "le voyage ne la découvre pas")
	assert_eq(_world.character.respawn_passage, "depart")
	# La toucher en fait le point de résurrection, sans « découverte ».
	events = _command(Protocol.CMD_USE, {"case": _stone})
	assert_eq(events.size(), 2)
	assert_eq(events[0], {"type": Protocol.EVT_RESPAWN_POINT, "passage": "elite", "nom": "Élite"})
	assert_eq(_world.character.respawn_passage, "elite")


func test_voyages_refuses() -> void:
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "elite"}), Protocol.REASON_TOO_FAR)
	_go_next_to_stone()
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "depart"}), Protocol.REASON_ALREADY_THERE)
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "nulle_part"}), Protocol.REASON_UNKNOWN_ENTITY)
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": 3}), Protocol.REASON_INVALID_COMMAND)
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": GameMap.plan_cell(1, 1), "destination": "elite"}), Protocol.REASON_UNKNOWN_ENTITY, "pas une pierre")
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_b"}), Protocol.REASON_PASSAGE_UNKNOWN, "pas encore découverte")
	_world.character.discover_passage("pierre_b")
	_world.character.inventory.ecus = 14
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_b"}), Protocol.REASON_NOT_ENOUGH_ECUS, "il en faut 15")
	assert_eq(_world.character.inventory.ecus, 14, "rien n'est débité")
	_world.character.discover_passage("perdue")
	_assert_refused(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "perdue"}), Protocol.REASON_UNKNOWN_MAP)
	assert_eq(_world.map.id, "test", "on n'a pas bougé")
	_world.character.inventory.ecus = 15
	assert_eq(_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_b"})[0]["type"], Protocol.EVT_MAP_CHANGED, "juste assez")
	assert_eq(_world.character.inventory.ecus, 0)


func test_validation_des_pierres() -> void:
	assert_false(GameData.validate_passage({"id": "x", "nom": "X"}).is_empty(), "il faut une carte")
	var stone := {"id": "x", "nom": "X", "carte": "a"}
	assert_true(GameData.validate_passage(stone).is_empty(), "prix et toujours_connue optionnels")
	for price: Variant in [-1, 2.5, "10"]:
		stone["prix"] = price
		assert_false(GameData.validate_passage(stone).is_empty(), "prix %s refusé" % str(price))
	stone["prix"] = 10.0  # Un nombre JSON entier se lit en flottant.
	assert_true(GameData.validate_passage(stone).is_empty())
	stone["toujours_connue"] = "oui"
	assert_false(GameData.validate_passage(stone).is_empty(), "toujours_connue : vrai ou faux")
	stone["toujours_connue"] = true
	assert_true(GameData.validate_passage(stone).is_empty())


# --- Point de résurrection ----------------------------------------------------------------------

func test_resurrection_apres_une_defaite() -> void:
	# Point de résurrection : la pierre de départ (carte « test ») ; le combat est perdu sur « b ».
	_world = _new_world("b")
	var events := _lose_fight()
	assert_eq(_world.map.id, "test", "réveil sur la carte du point de résurrection")
	assert_true(GameMap.is_adjacent(_world.position_of(World.PLAYER_ID), _stone), "à côté de la pierre")
	assert_eq(_world.character.hp(_world.data), 1, "avec 1 PV")
	var ended: Dictionary = Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]
	assert_eq(ended["reveil"], {"passage": "depart", "nom": "Départ", "carte": "test"})
	var back: Dictionary = Fixtures.of_type(events, Protocol.EVT_EXPLORATION)[0]
	assert_eq(back["reveil"], ended["reveil"])
	assert_eq(back["position"], _world.position_of(World.PLAYER_ID))
	var changed := Fixtures.of_type(events, Protocol.EVT_MAP_CHANGED)
	assert_eq(changed.size(), 1, "l'affichage change de carte")
	assert_eq(events[-1], changed[0], "juste après le retour en exploration")
	assert_eq(changed[0]["carte"], "test")
	assert_eq(_world.visited_maps(), ["b", "test"] as Array[String], "la carte du réveil est visitée")


func test_resurrection_sur_la_carte_du_combat() -> void:
	_world = _new_world("b")
	_go_next_to_stone()
	_command(Protocol.CMD_USE, {"case": _stone})
	assert_eq(_world.character.respawn_passage, "pierre_b")
	var events := _lose_fight()
	assert_eq(_world.map.id, "b")
	assert_true(GameMap.is_adjacent(_world.position_of(World.PLAYER_ID), _stone), "à côté de la pierre de « b »")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_MAP_CHANGED).size(), 0, "même carte")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_EXPLORATION)[0]["reveil"]["passage"], "pierre_b")
	assert_eq(_world.groups().size(), 1, "les loups sont toujours là")
	assert_eq(_world.position_of("groupe_1"), _wolves)


func test_resurrection_sans_carte() -> void:
	_world = _new_world("b")
	_world.character.respawn_passage = "perdue"
	var events := _lose_fight()
	assert_eq(_world.map.id, "b", "carte du point de résurrection introuvable : on reste ici")
	assert_eq(_world.position_of(World.PLAYER_ID), _world.map.spawn, "au départ de la carte, comme avant")
	assert_eq(_world.character.hp(_world.data), 1)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_EXPLORATION)[0]["reveil"]["passage"], "")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_MAP_CHANGED).size(), 0)


# --- Cartes visitées et sauvegarde ----------------------------------------------------------------

func test_cartes_visitees() -> void:
	assert_eq(_world.visited_maps(), ["test"] as Array[String], "la carte de départ")
	_command(Protocol.CMD_MOVE, {"cible": GameMap.plan_cell(4, 8), "sortie": "droite"})
	assert_eq(_world.map.id, "voisine")
	_command(Protocol.CMD_MOVE, {"cible": GameMap.plan_cell(4, 0), "sortie": "gauche"})
	assert_eq(_world.map.id, "test")
	_command(Protocol.CMD_MOVE, {"cible": _door, "porte": true})
	assert_eq(_world.map.id, "maison")
	_command(Protocol.CMD_MOVE, {"cible": _house_door, "porte": true})
	assert_eq(_world.map.id, "test")
	_world.character.discover_passage("pierre_c")
	_go_next_to_stone()
	_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_c"})
	assert_eq(_world.visited_maps(), ["test", "voisine", "maison", "c"] as Array[String], "bords, porte et voyage, sans doublon")
	_world.visited_maps().append("triche")
	assert_eq(_world.visited_maps().size(), 4, "une copie pour l'interface")


func test_sauvegarde_du_voyage() -> void:
	_world.character.discover_passage("pierre_c")
	_go_next_to_stone()
	_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_c"})
	_command(Protocol.CMD_USE, {"case": _stone})
	var restored := World.from_save(JSON.parse_string(JSON.stringify(_world.save_data())), _data(), _loader)
	assert_true(restored != null)
	assert_eq(restored.map.id, "c")
	assert_eq(restored.character.known_passages, ["depart", "pierre_c"] as Array[String])
	assert_eq(restored.character.respawn_passage, "pierre_c")
	assert_eq(restored.visited_maps(), ["test", "c"] as Array[String])


func test_vieille_sauvegarde() -> void:
	_world.character.discover_passage("pierre_c")
	_go_next_to_stone()
	_command(Protocol.CMD_TRAVEL, {"case": _stone, "destination": "pierre_c"})
	var save: Dictionary = JSON.parse_string(JSON.stringify(_world.save_data()))
	for key: String in ["pierres_connues", "point_de_resurrection", "cartes_visitees"]:
		save["personnage"].erase(key)
	var restored := World.from_save(save, _data(), _loader)
	assert_true(restored != null, "une sauvegarde d'avant les voyages se relit")
	assert_eq(restored.character.known_passages, ["depart"] as Array[String], "la pierre de la zone de départ")
	assert_eq(restored.character.respawn_passage, "depart", "sert de point de résurrection")
	assert_eq(restored.visited_maps(), ["c"] as Array[String], "au moins la carte actuelle")
	# Point de résurrection sur une pierre qui n'existe plus : retour à celle de la zone de départ.
	save["personnage"]["point_de_resurrection"] = "disparue"
	assert_eq(World.from_save(save, _data(), _loader).character.respawn_passage, "depart")
