extends "res://tests/test_case.gd"
## Élevage, lot 3 (GDD § 10.3, docs/design/elevage/etapes.md) : Apprivoiser, donné par le licol ; dernier ennemi
## apprivoisable sous 25 % de ses PV ; réussi, il quitte le combat sans son butin et devient une monture sauvage.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _world: World


## Monde réel, un groupe de `monsters` au centre, un guerrier avec ou sans licol, déjà en combat au contact du 1er monstre.
func _fight(monsters: Array, licol := true) -> World:
	var character := Character.create("Testeur", "humain", "guerrier")
	if licol:
		character.inventory.add(GameData.load_all().items[Combat.TAME_ITEM])
	_world = World.new(Fixtures.map({Fixtures.center(): "1"}, [{"monstres": monsters}]), GameData.load_all(), Callable(), character)
	_world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})
	var monster := _world.combat.get_fighter("groupe_1_1")
	var player := _world.combat.get_fighter(World.PLAYER_ID)
	for i in monsters.size():
		_world.combat.get_fighter("groupe_1_%d" % (i + 1)).initiative = 0  # le joueur commence
	player.initiative = 1000
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if _world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	_world.execute({"type": Protocol.CMD_READY, "entite": World.PLAYER_ID})
	return _world


func _tame() -> Array[Dictionary]:
	_world.combat.get_fighter(World.PLAYER_ID).pa = 30
	return _world.execute({"type": Protocol.CMD_CAST, "entite": World.PLAYER_ID, "sort": Combat.TAME_SPELL,
		"cible": _world.combat.get_fighter("groupe_1_1").cell})


func _reason(events: Array[Dictionary]) -> String:
	return str(events[0].get("raison", "")) if events[0]["type"] == Protocol.EVT_REFUSED else ""


func test_le_licol_donne_apprivoiser() -> void:
	assert_true(_fight(["ampa_brun"]).combat.get_fighter(World.PLAYER_ID).get_spell(Combat.TAME_SPELL) != null)
	assert_true(_fight(["ampa_brun"], false).combat.get_fighter(World.PLAYER_ID).get_spell(Combat.TAME_SPELL) == null, "sans licol, pas de sort")


func test_conditions() -> void:
	_fight(["ampa_brun"])
	assert_eq(_reason(_tame()), Protocol.REASON_TOO_HEALTHY, "à 25 % de ses PV ou plus")
	_fight(["ampa_brun", "ampa_brun"])
	_world.combat.get_fighter("groupe_1_1").hp = 1
	assert_eq(_reason(_tame()), Protocol.REASON_NOT_LAST, "un autre ennemi est debout")
	_fight(["grand_ampa_brun"])
	_world.combat.get_fighter("groupe_1_1").hp = 1
	assert_eq(_reason(_tame()), Protocol.REASON_NOT_TAMABLE, "une élite ne s'apprivoise pas")
	_fight(["loup_des_collines"])
	_world.combat.get_fighter("groupe_1_1").hp = 1
	assert_eq(_reason(_tame()), Protocol.REASON_NOT_TAMABLE, "pas d'espèce de monture")


func test_chance_selon_les_paliers() -> void:
	_fight(["ampa_brun"])
	var player := _world.combat.get_fighter(World.PLAYER_ID)
	var monster := _world.combat.get_fighter("groupe_1_1")
	assert_eq(player.tame_bonus, 0, "éleveur Inconnu, sans compétence")
	assert_eq(_world.combat.tame_chance(player, monster), 40, "50 % − 10 pour le palier 2")
	player.tame_bonus = 200
	assert_eq(_world.combat.tame_chance(player, monster), 95, "95 % au plus")


func test_reussite_monture_sauvage_sans_butin() -> void:
	_fight(["ampa_brun"])
	var character: Character = _world.players[World.PLAYER_ID].character
	_world.combat.get_fighter("groupe_1_1").hp = 1
	_world.combat.get_fighter(World.PLAYER_ID).tame_bonus = 100
	var tamed: Dictionary = {}
	var events: Array[Dictionary] = []
	for attempt in 20:
		events = _tame()
		var found := Fixtures.of_type(events, Protocol.EVT_TAMED)
		assert_eq(found.size(), 1, "une tentative par lancer")
		if found[0]["reussi"]:
			tamed = found[0]
			break
	assert_false(tamed.is_empty(), "réussi à 95 %")
	assert_eq(tamed["monture"]["espece"], "ampa")
	assert_eq(tamed["monture"]["robe"], "brun")
	assert_true(tamed["monture"]["sexe"] in ["male", "femelle"])
	assert_true(int(tamed["monture"]["docilite"]) >= 1 and int(tamed["monture"]["docilite"]) <= 100)
	assert_false(_world.in_combat(), "le dernier ennemi parti, le combat est gagné")
	var ended := Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)
	assert_eq(ended[0]["vainqueur"], Fighter.TEAM_PLAYERS)
	assert_eq(ended[0]["butin"], [], "sans son butin")
	assert_eq(character.inventory.quantity_of(Combat.TAME_ITEM), 0, "le licol est consommé")
	var mounts := character.inventory.entries.values().filter(func(e: Dictionary) -> bool: return e["objet"] == World.WILD_MOUNT)
	assert_eq(mounts.size(), 1)
	assert_eq(mounts[0]["monture"], tamed["monture"])
	assert_true(character.job_reputation(Combat.TAME_JOB) > 0, "réputation d'éleveur")
	var saved := Inventory.from_dict(character.inventory.to_dict(), GameData.load_all().items)
	assert_eq(saved.entries[mounts[0]["uid"]]["monture"], tamed["monture"], "gardée dans la sauvegarde")
