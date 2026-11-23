extends "res://tests/test_case.gd"
## Arcaniste (GDD § 4.3) : sorts utilitaires et leur affinité, mur de glace, passif « Virtuose », Écho arcanique et rangs
## des sorts créés. Sorts tirés des données du jeu, sans coup critique.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


func _data() -> GameData:
	var spells := Fixtures.spells()
	var voie: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voies/arcaniste.json"))
	var create: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sorts/arcaniste_creer_un_sort.json"))
	for spell_id: String in voie["sorts"] + create["effets"][0]["combinaisons"].values():
		var spell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sorts/%s.json" % spell_id))
		spell["critique"] = 0
		spells.append(spell)
	var races := [{"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test", "passif": {"nom": "Aucun", "effets": []}}]
	return GameData.from_dicts(spells, [Fixtures.monster("mannequin", 200, 6, 0, 10, ["frappe"])], [voie], races, Fixtures.items(), [], [])


## L'Arcaniste en C (rang + 1 du passif : `passive`) contre des mannequins.
func _fight(monsters: Array, passive := 0) -> Combat:
	var data := _data()
	var fighters: Array[Fighter] = []
	var player := data.create_player("arcaniste", Fixtures.PLAYER, "Testeur")
	player.cell = C
	if passive > 0:
		player.passives[Fighter.VIRTUOSO] = passive
	player.max_hp = 500
	player.hp = 500
	fighters.append(player)
	for i in monsters.size():
		var monster := data.create_monster("mannequin", "m%d" % i)
		monster.cell = monsters[i]
		fighters.append(monster)
	var placement: Array[Vector2i] = [C]
	var combat := Combat.new(Fixtures.map(), fighters, placement, 1)
	combat.start()
	combat.execute(Fixtures.cmd(Protocol.CMD_READY))
	return combat


func _cast(combat: Combat, spell_id: String, target: Vector2i, extra := {}) -> Array[Dictionary]:
	combat.get_fighter(Fixtures.PLAYER).pa = 20
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}.merged(extra)))


func _compose(combat: Combat, states: String) -> void:
	_cast(combat, "arcaniste_composition", C, {"etats": states})


func test_affinite_des_utilitaires() -> void:
	var combat := _fight([C + RIGHT])
	var player := combat.get_fighter(Fixtures.PLAYER)
	assert_eq(player.get_spell("arcaniste_clignement").range_max, 3)
	_compose(combat, "flamme+givre+tempete")
	assert_eq(player.get_spell("arcaniste_clignement").range_max, 4, "un état Tempête : +1 portée")
	assert_eq(player.get_spell("arcaniste_pieds_geles").effects[0]["max"], 3, "un état Givre : −3 PM")
	_compose(combat, "flamme+flamme+flamme")
	assert_eq(player.get_spell("arcaniste_pieds_geles").effects[0]["max"], 2, "sans état Givre : −2 PM")
	_cast(combat, "arcaniste_retropropulsion", C + RIGHT)
	assert_eq(player.cell, C - RIGHT * 4, "Rétropropulsion : recule de 4 cases avec un état Flamme")


func test_mur_de_glace() -> void:
	var combat := _fight([C + Vector2i(4, 0)])
	var wall := C + Vector2i(2, 0)
	var events := _cast(combat, "arcaniste_mur_de_glace", wall)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TERRAIN).size(), 3, "3 cases en travers")
	for cell in [wall, wall + Vector2i(0, 1), wall - Vector2i(0, 1)]:
		assert_false(combat.walkable(cell), "la glace bloque le passage")
	assert_true(combat._blocks_sight(wall, combat.get_fighter(Fixtures.PLAYER), false), "ni la vue")
	assert_true(combat.demolishable(wall), "un Myrmidon peut la démolir")
	for i in 2:
		combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
		while combat.current_fighter().id != Fixtures.PLAYER:
			combat.execute({"type": Protocol.CMD_END_TURN, "entite": combat.current_fighter().id})
	assert_true(combat.walkable(wall), "fondue au bout de 2 tours")


func test_conduction_et_enracine() -> void:
	var combat := _fight([C + Vector2i(2, 0)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	_compose(combat, "flamme+flamme+givre")
	var intelligence := player.stat("intelligence")
	_cast(combat, "arcaniste_conduction", C)
	assert_eq(player.stat("intelligence") - intelligence, 30, "+15 par état Flamme")
	var dummy := combat.get_fighter("m0")
	dummy.states.append({"type": Spell.EFFECT_STATE, "etat": Spell.STATE_ROOTED, "valeur": 0, "tours": 1, "sort": "", "lanceur": "", "retirable": true})
	_cast(combat, "arcaniste_appel_d_air", C + Vector2i(2, 0))
	assert_eq(dummy.cell, C + Vector2i(2, 0), "enraciné : ni attiré ni poussé")


func test_virtuose() -> void:
	var combat := _fight([C + Vector2i(3, 0)], 6)
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	for states in ["flamme+flamme+flamme", "givre+givre+givre", "flamme+flamme+givre", "flamme+flamme+flamme"]:
		_compose(combat, states)
		_cast(combat, "arcaniste_echo_arcanique" if player.cast_count(player.get_spell(Fighter.FUSION)) > 0 else Fighter.FUSION, C)
		player._casts_this_turn.clear()
		player._cooldowns.clear()
		var pm := player.pm
		_cast(combat, player.created_spells[-1], C + Vector2i(3, 0))
		if player.stacks(Fighter.VIRTUOSITY) == Fighter.VIRTUOSITY_MAX and states == "flamme+flamme+givre":
			assert_eq(player.pm, pm + 1, "rang 5 : le 3e cran donne +1 PM")
	assert_eq(player.stacks(Fighter.VIRTUOSITY), Fighter.VIRTUOSITY_MAX, "un cran par combinaison différente, 3 au plus")
	assert_eq(combat.damage_bonus(player, dummy, {}), 3 * 8, "+8 % par cran au rang 5")
	assert_eq(player.spell_cost(player.get_spell(Fighter.FUSION)), 0, "rang 3 : Fusion gratuite à 3 crans")
	_cast(combat, player.created_spells[-1], C + Vector2i(3, 0))
	assert_eq(player.stacks(Fighter.VIRTUOSITY), Fighter.VIRTUOSITY_MAX, "le même sort deux fois ne donne rien")


func test_echo_arcanique() -> void:
	var data := _data()
	var combat := _fight([C + Vector2i(3, 0)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	_compose(combat, "givre+givre+givre")
	_cast(combat, Fighter.FUSION, C)
	_compose(combat, "tempete+tempete+tempete")
	var events := _cast(combat, "arcaniste_echo_arcanique", C)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_SPELL_CREATED).size(), 1, "un 2e sort créé dans le tour")
	assert_eq(player.created_spells, ["arcaniste_blizzard", "arcaniste_foudre_en_chaine"])
	player.spells.append((data.spells["arcaniste_echo_arcanique"] as Spell).mastered(5))
	player.spells.erase(player.spells.filter(func(spell: Spell) -> bool: return spell.id == "arcaniste_echo_arcanique" and spell.rank == 0)[0])
	player._cooldowns.clear()
	player._casts_this_turn.clear()
	_compose(combat, "flamme+flamme+flamme")
	_cast(combat, "arcaniste_echo_arcanique", C)
	assert_eq(player.spell_cost(player.get_spell("arcaniste_fournaise")), 3, "rang 5 : 1 PA de moins au 1er lancer")
	_cast(combat, "arcaniste_fournaise", C + Vector2i(3, 0))
	assert_eq(player.spell_cost(player.get_spell("arcaniste_fournaise")), 4, "puis plein tarif")


func test_rangs_des_sorts_crees() -> void:
	var data := _data()
	var chain: Spell = (data.spells["arcaniste_foudre_en_chaine"] as Spell).mastered(5)
	var bounces := chain.effects.filter(func(effect: Dictionary) -> bool: return effect["type"] == Spell.EFFECT_BOUNCE)
	assert_eq(bounces.size(), 3, "rang 5 : un 4e touché")
	assert_eq(bounces[0]["distance"], 3, "rang 3 : rebond jusqu'à 3 cases")
	assert_eq((data.spells["arcaniste_fournaise"] as Spell).mastered(3).effect_of(Spell.EFFECT_GLYPH)["duree"], 3, "glyphe 3 tours")
	assert_eq((data.spells["arcaniste_blizzard"] as Spell).mastered(5).zone_size, 2)
	assert_eq((data.spells["arcaniste_fulgurance"] as Spell).mastered(5).cooldown, 0, "sans relance")
	assert_eq((data.spells["arcaniste_manteau_de_braises"] as Spell).mastered(5).effects[0]["duree"], 3, "+1 tour")
