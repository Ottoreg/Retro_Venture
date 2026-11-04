extends "res://tests/test_case.gd"
## Tour céleste réduite (demande de l'auteur, 04/11/2026) : parvis avec Cupidon et le portier, cinq
## étages enchaînés, vol de vie, Exorcisme, et IA des anges (corps à corps, chasseur, bond).

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var C := GameMap.plan_cell(15, 9)
var _data := GameData.load_all()
## Grande carte ouverte (19 × 31) : le Lion a la place de bondir.
var _open := GameMap.from_dict({"id": "ouverte", "plan": range(31).map(func(i: int) -> String:
	return ("@" if i == 0 else (" " if i % 2 == 1 else ".")) + ".".repeat(18))})


## Combat sur une carte ouverte : [[id de monstre ou « joueur », case], …] (le joueur : « p0 », « p1 »…).
func _fight(fighters_at: Array) -> Combat:
	var fighters: Array[Fighter] = []
	for i in fighters_at.size():
		var kind: String = fighters_at[i][0]
		var fighter := _data.create_player("guerrier", "p%d" % i, "Testeur") if kind == "joueur" else _data.create_monster(kind, "m%d" % i)
		fighter.cell = fighters_at[i][1]
		fighters.append(fighter)
	return Combat.new(_open, fighters, [] as Array[Vector2i], 1)


func _world(map_id: String) -> World:
	var loader := func(id: String) -> GameMap: return DataLoader.load_map(DataLoader.map_path(id))
	return World.new(loader.call(map_id), _data, loader)


func test_la_tour_et_ses_etages() -> void:
	assert_eq(_data.passages["tour_celeste"]["carte"], "celeste_0_0", "Pierre de Passage du parvis")
	assert_true(_data.passage_always_known("tour_celeste"))
	var parvis := DataLoader.load_map(DataLoader.map_path("celeste_0_0"))
	assert_eq(parvis.groups[0]["monstres"], ["cupidon"], "Cupidon seul sur le parvis")
	assert_eq(_data.monsters["cupidon"]["butin"], [{"objet": "cle_celeste", "taux": 1.0, "par_joueur": true}], "la clé à 100 %")
	assert_eq(parvis.npcs[0]["entree"], {"carte": "tour_celeste_1", "cle": "cle_celeste"})
	var rooms := [["ange", "colombe_baptiste", "colombe_baptiste", "colombe_baptiste"],
		["ange", "ange", "colombe_baptiste", "lion_de_juda"], ["colombe_baptiste", "lion_de_juda", "lion_de_juda", "lion_de_juda"],
		["ange", "ange", "ange", "lion_de_juda"], ["ange", "archange_raphael", "colombe_baptiste", "lion_de_juda"]]
	for n in 5:
		var room := DataLoader.load_map(DataLoader.map_path("tour_celeste_%d" % (n + 1)))
		var monsters: Array = room.groups[0]["monstres"].duplicate()
		monsters.sort()
		assert_eq(monsters, rooms[n], "étage %d" % (n + 1))
		assert_eq(room.next_floor, "tour_celeste_%d" % (n + 2) if n < 4 else "tour_celeste_sommet", "puis l'étage suivant, le chœur au sommet")
		assert_eq(room.get_npc("gardien_celeste")["entree"], {"carte": "celeste_0_0"}, "étage %d : un gardien fait sortir" % (n + 1))
	assert_true(_data.monsters["archange_raphael"].get("boss", false), "l'Archange est le mini-boss")


func test_portier_contre_une_cle() -> void:
	var world := _world("celeste_0_0")
	var talk := {"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": "saint_pierrot"}
	assert_eq(Fixtures.of_type(world.execute(talk), Protocol.EVT_DIALOGUE).size(), 1, "sans clé : il parle")
	assert_eq(world.map.id, "celeste_0_0")
	world.character.inventory.add(_data.items["cle_celeste"])
	var events := world.execute(talk)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_MAP_CHANGED)[0]["carte"], "tour_celeste_1", "avec : il fait entrer")
	assert_eq(world.position_of(World.PLAYER_ID), world.map.spawn)
	assert_eq(world.character.inventory.quantity_of("cle_celeste"), 0, "la clé est prise")


func test_une_victoire_fait_monter_d_un_etage() -> void:
	for floor_id: String in ["tour_celeste_4", "tour_celeste_5"]:
		var world := _world(floor_id)
		world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})
		var player := world.combat.get_fighter(World.PLAYER_ID)
		var last: Fighter = null
		for fighter in world.combat.fighters:
			if fighter.team != Fighter.TEAM_PLAYERS:
				fighter.hp = 0
				last = fighter
		last.hp = 1
		world.execute({"type": Protocol.CMD_READY, "entite": World.PLAYER_ID})
		player.cell = IsoGrid.neighbors_4(last.cell).filter(func(cell: Vector2i) -> bool: return world.combat.is_free(cell))[0]
		var events := world.execute({"type": Protocol.CMD_CAST, "entite": World.PLAYER_ID, "sort": "guerrier_frappe", "cible": last.cell})
		assert_false(world.in_combat())
		assert_eq(world.map.id, "tour_celeste_5" if floor_id == "tour_celeste_4" else "tour_celeste_sommet", "%s : on monte" % floor_id)
		assert_eq(Fixtures.of_type(events, Protocol.EVT_MAP_CHANGED).size(), 1)


func test_cupidon_donne_une_cle_a_chaque_joueur() -> void:
	var rng := RandomNumberGenerator.new()
	var loot := Loot.roll([_data.monsters["cupidon"]], {"a": 100, "b": 100, "c": 100}, rng)
	for player_id: String in loot:
		assert_eq(loot[player_id].filter(func(drop: Dictionary) -> bool: return drop["objet"] == "cle_celeste").size(), 1, player_id)


func test_le_gardien_fait_sortir_sans_cle() -> void:
	var world := _world("tour_celeste_3")
	var events := world.execute({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": "gardien_celeste"})
	assert_eq(Fixtures.of_type(events, Protocol.EVT_MAP_CHANGED)[0]["carte"], "celeste_0_0", "retour au parvis")


func test_raphael_donne_le_calice_une_fois_par_visite() -> void:
	var world := _world("tour_celeste_sommet")
	var talk := {"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": "raphael_sommet"}
	assert_eq(Fixtures.of_type(world.execute(talk), Protocol.EVT_DIALOGUE).size(), 1, "il parle aussi")
	world.execute(talk)
	assert_eq(world.character.inventory.quantity_of("calice_toujours_ruisselant"), 1, "un seul calice par visite")
	world.execute({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": "gardien_celeste"})
	world.character.inventory.add(_data.items["cle_celeste"])
	world.execute({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": "saint_pierrot"})
	assert_eq(world.map.id, "tour_celeste_1")
	assert_true(_data.items["calice_toujours_ruisselant"]["description"].contains("trente brumes"), "l'indice sur la suite")


func test_le_groupe_revient_pendant_le_combat() -> void:
	var world := _world("tour_celeste_1")
	world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})
	assert_true(world.in_combat())
	assert_true(world.group("groupe_1").is_empty(), "le groupe combattu a quitté la carte")
	world.update(4.0)
	assert_true(world.group("groupe_1").is_empty(), "pas avant 5 s")
	world.update(7.0)
	assert_false(world.group("groupe_1").is_empty(), "de retour 5 à 10 s après le début du combat")
	assert_true(world.in_combat(), "pendant le combat")


func test_vol_de_vie_et_exorcisme() -> void:
	var combat := _fight([["cupidon", C], ["joueur", C + Vector2i(3, 0)], ["archange_raphael", C + Vector2i(4, 0)]])
	var cupidon := combat.get_fighter("m0")
	var player := combat.get_fighter("p1")
	cupidon.hp = 10
	var events: Array[Dictionary] = []
	combat._apply_effect(cupidon, player, cupidon.get_spell("cupidon_fleche_cupide").effects[0], events)
	assert_eq(player.max_hp - player.hp, 10, "Flèche cupide : 10 dégâts")
	assert_eq(cupidon.hp, 20, "qu'il reprend")
	var archange := combat.get_fighter("m2")
	combat._apply_effect(archange, player, archange.get_spell("archange_exorcisme").effects[0], events)
	assert_true(player.has_state(Spell.STATE_EXORCISM))
	combat._hurt(player, 1, "acier", events)
	assert_true(player.is_alive(), "d'autres dégâts ne l'achèvent pas")
	combat._hurt(player, 1, "sacre", events)
	assert_false(player.is_alive(), "les premiers dégâts Sacré l'achèvent")


func test_l_ange_va_au_contact_pour_frapper_deux_fois() -> void:
	var combat := _fight([["ange", C], ["joueur", C + Vector2i(4, 0)]])
	var ange := combat.get_fighter("m0")
	var move := CombatAI.next_action(combat, ange, false)
	assert_eq(move["type"], Protocol.CMD_MOVE, "plutôt que tirer de loin")
	assert_eq(IsoGrid.distance(move["cible"], C + Vector2i(4, 0)), 1)
	ange.cell = move["cible"]
	for i in 2:
		var cast := CombatAI.next_action(combat, ange, true)
		assert_eq(cast["sort"], "ange_glaive", "coup %d au glaive" % (i + 1))
		combat._apply_action(ange, cast)
	assert_true(CombatAI.next_action(combat, ange, true).is_empty(), "6 PA : deux coups")


func test_cupidon_tire_de_loin_et_reste_sur_place() -> void:
	var combat := _fight([["cupidon", C], ["joueur", C + Vector2i(8, 0)]])
	var cupidon := combat.get_fighter("m0")
	var move := CombatAI.next_action(combat, cupidon, false)
	assert_eq(IsoGrid.distance(move["cible"], C + Vector2i(8, 0)), 5, "à sa portée maximale")
	cupidon.cell = move["cible"]
	combat._apply_action(cupidon, CombatAI.next_action(combat, cupidon, true))
	assert_true(CombatAI.next_action(combat, cupidon, true).is_empty(), "il a tiré : il ne fuit pas")


func test_le_lion_vise_le_plus_faible_et_bondit() -> void:
	var combat := _fight([["lion_de_juda", C], ["joueur", C + Vector2i(1, 0)], ["joueur", C + Vector2i(0, 3)]])
	combat.get_fighter("p2").hp = 10
	var move := CombatAI.next_action(combat, combat.get_fighter("m0"), false)
	assert_eq(move["type"], Protocol.CMD_MOVE, "il quitte le plus fort pour le plus faible")
	assert_eq(IsoGrid.distance(move["cible"], C + Vector2i(0, 3)), 1)
	combat = _fight([["lion_de_juda", C], ["joueur", C + Vector2i(6, 0)]])
	var lion := combat.get_fighter("m0")
	var leap := CombatAI.next_action(combat, lion, false)
	assert_eq(leap.get("sort"), "lion_bond", "trop loin : il bondit")
	combat._apply_action(lion, leap)
	assert_eq(lion.cell, C + Vector2i(3, 0))
	lion.start_turn()
	assert_false(lion.cast_blocker(lion.get_spell("lion_bond")).is_empty(), "pas au tour suivant")
	lion.start_turn()
	assert_true(lion.cast_blocker(lion.get_spell("lion_bond")).is_empty(), "un tour sur deux")


func test_l_archange_exorcise_d_abord_puis_soigne_ou_juge() -> void:
	var combat := _fight([["archange_raphael", C], ["ange", C + Vector2i(0, 3)], ["joueur", C + Vector2i(1, 0)]])
	var archange := combat.get_fighter("m0")
	var ange := combat.get_fighter("m1")
	ange.hp = 20
	var cast := CombatAI.best_cast(combat, archange, C)
	assert_eq(cast["sort"], "archange_exorcisme", "l'Exorcisme avant le soin")
	combat._apply_action(archange, cast)
	assert_eq(CombatAI.best_cast(combat, archange, C)["sort"], "archange_benediction", "puis il soigne l'ange blessé")
	ange.hp = ange.max_hp
	assert_true(CombatAI.best_cast(combat, archange, C).is_empty(), "pas de soin si tout le monde a ses PV")
	var events: Array[Dictionary] = []
	combat._hurt(ange, 999, "acier", events)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PHASE).size(), 1, "seul, il change de sort")
	assert_true(archange.get_spell("archange_benediction") == null)
	cast = CombatAI.best_cast(combat, archange, C)
	assert_eq(cast["sort"], "archange_jugement", "Jugement dernier autour de lui")
	combat._apply_action(archange, cast)
	assert_false(combat.get_fighter("p2").is_alive(), "qui achève la cible exorcisée")


func test_ressources_de_la_tour_a_la_forge() -> void:
	var items := _data.items
	var bonus: Dictionary = Forge.preview("cape", {"plume_de_colombe": 2, "sacre_coeur": 1, "bec_de_colombe": 1, "squelette_de_colombe": 1,
		"tunique_dechiree_de_raphael": 1, "aile_de_raphael": 1, "sacre_coeur_de_raphael": 1}, items, null, false)["bonus"]
	assert_eq(bonus["force"][1], 32, "Sacré : Force et Intelligence, valeurs fixées (2 × 1 + 30)")
	assert_eq(bonus["intelligence"][1], 32)
	assert_eq(bonus["dommages_sacre"][1], 3, "pas de × 3 pour une valeur fixée")
	assert_eq(bonus["pm"][1], 1)
	assert_eq([bonus["resistance_impie"][1], bonus["soins_sacre"][1], bonus["soins"][1]], [3, 10, 30])
	assert_eq(Forge.preview("cape", {"cortex_feral": 2}, items, null, false)["bonus"]["degats_devastateurs"][1], 10, "10 % au plus par objet")


func test_soins_dommages_composes_et_degats_devastateurs() -> void:
	var combat := _fight([["joueur", C], ["ange", C + Vector2i(1, 0)]])
	var player := combat.get_fighter("p0")
	var ange := combat.get_fighter("m1")
	player.soins = 30
	player.element_soins = {"sacre": 10, "acier": 4}
	assert_eq(player.total_heal_bonus("sacre"), 42, "neutres + Sacré + moitié de l'Acier")
	assert_eq(player.total_heal_bonus("givre"), 30)
	player.element_dommages = {"sacre": 3}
	assert_eq(player.element_damage("sacre"), 3, "Dommages Sacré propres")
	player.hp = 10
	var events: Array[Dictionary] = []
	combat._apply_effect(player, player, {"type": Spell.EFFECT_HEAL, "element": "givre", "min": 5, "max": 5}, events)
	assert_eq(player.hp, 10 + Combat.boosted_value(player, "givre", 5) + 30, "les soins s'ajoutent au soin")
	player.devastating = 10
	combat._apply_effect(player, ange, {"type": Spell.EFFECT_DAMAGE, "element": "acier", "min": 20, "max": 20}, events)
	assert_eq(ange.max_hp, 50 - roundi((50 - ange.hp) * 0.1), "10 % des PV perdus en moins sur les PV max")
	player.devastating = 100
	for i in 6:
		ange.hp = ange.max_hp
		combat._apply_effect(player, ange, {"type": Spell.EFFECT_DAMAGE, "element": "acier", "min": 15, "max": 15}, events)
	assert_eq(ange.max_hp, 20, "jamais sous 40 % des PV max du début")
