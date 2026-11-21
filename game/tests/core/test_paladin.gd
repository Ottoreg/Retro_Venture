extends "res://tests/test_case.gd"
## Paladin (GDD § 4.3) : auras qui suivent leur lanceur (Voie Sacrée), balises, arcs et projectiles renforcés (Voie Tempête),
## passif « Saint Paratonnerre ». Sorts tirés des données du jeu, sans coup critique.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)
const DOWN := Vector2i(0, 1)

var C := Fixtures.center()


func _data() -> GameData:
	var spells := Fixtures.spells()
	var voie: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voies/paladin.json"))
	for spell_id: String in voie["sorts"]:
		var spell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sorts/%s.json" % spell_id))
		spell["critique"] = 0
		spells.append(spell)
	var races := [{"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test", "passif": {"nom": "Aucun", "effets": []}}]
	return GameData.from_dicts(spells, [Fixtures.monster("mannequin", 200, 6, 0, 10, ["frappe"])], [voie], races, Fixtures.items(), [], [])


## Le Paladin en C (rang du passif : `passive`, 0 sans passif) contre des mannequins immobiles.
func _fight(monsters: Array, passive := 0) -> Combat:
	var data := _data()
	var fighters: Array[Fighter] = []
	var player := data.create_player("paladin", Fixtures.PLAYER, "Testeur")
	player.cell = C
	player.passives["saint_paratonnerre"] = passive
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


func _cast(combat: Combat, spell_id: String, target: Vector2i) -> Array[Dictionary]:
	var player := combat.get_fighter(Fixtures.PLAYER)
	player.pa = 20
	player._casts_this_turn.clear()
	player._cooldowns.clear()
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}))


func test_aura_suit_le_paladin() -> void:
	var combat := _fight([C + Vector2i(6, 0)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "paladin_aura_de_bravoure", C)
	assert_eq(combat.auras.size(), 1)
	assert_eq(player.modifier("degats_infliges"), 15, "le Paladin est dans sa propre aura")
	assert_eq(combat.get_fighter("m0").modifier("degats_infliges"), 0, "pas les ennemis")
	combat.execute(Fixtures.cmd(Protocol.CMD_MOVE, {"cible": C + Vector2i(0, 2)}))
	assert_eq(player.modifier("degats_infliges"), 15, "l'aura le suit")
	_cast(combat, "paladin_aura_de_protection", player.cell)
	assert_eq(combat.auras.size(), 1, "une seule aura : la nouvelle remplace l'ancienne")
	assert_eq(player.modifier("degats_infliges"), 0)
	assert_eq(player.resistance("flamme"), 10.0)
	assert_eq(player.resistance("sacre"), 10.0, "un élément composé : la moyenne de ses deux éléments")
	for i in 3:
		combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	assert_eq(combat.auras.size(), 0, "3 tours")
	assert_eq(player.resistance("flamme"), 0.0, "le bonus tombe avec l'aura")


func test_onde_sacree_dans_l_aura() -> void:
	var combat := _fight([C + Vector2i(2, 0), C + Vector2i(0, 1)])
	var far := combat.get_fighter("m0")
	var near := combat.get_fighter("m1")
	_cast(combat, "paladin_onde_sacree", C)
	assert_eq(far.hp, 200, "sans aura : à 1 case seulement")
	assert_true(near.hp < 200)
	_cast(combat, "paladin_aura_de_bravoure", C)
	_cast(combat, "paladin_onde_sacree", C)
	assert_true(far.hp < 200, "avec son aura : toute l'aura")


func test_arcs_entre_balises() -> void:
	var combat := _fight([C + Vector2i(-1, 2)])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "paladin_balise", C + Vector2i(0, 2))
	assert_eq(_cast(combat, "paladin_balise", C + Vector2i(0, 2))[0]["raison"], Protocol.REASON_OCCUPIED, "déjà une balise")
	var events := _cast(combat, "paladin_balise", C + Vector2i(-3, 2))
	assert_eq(combat.arcs().size(), 1, "deux balises alignées à 3 cases : un arc")
	assert_eq(combat.arcs()[0]["cases"].size(), 2)
	assert_true(dummy.hp < 200, "l'ennemi sur la ligne quand l'arc se forme est frappé")
	var hp := dummy.hp
	_cast(combat, "paladin_balise", C + Vector2i(0, -2))
	assert_eq(dummy.hp, hp, "une fois par arc et par tour")
	assert_eq(combat.arcs().size(), 2, "une balise porte deux arcs")
	_cast(combat, "paladin_balise", C + Vector2i(3, -2))
	assert_eq(combat.beacons.size(), 3, "3 balises au plus : la plus ancienne part")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_BEACON).size(), 1)
	combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	assert_eq(combat.arcs().size(), 1)


func test_balise_cassee_par_un_ennemi() -> void:
	var combat := _fight([C + Vector2i(2, 0)])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "paladin_balise", C + Vector2i(2, -1))
	_cast(combat, "paladin_balise", C + Vector2i(2, -3))
	combat._enter_cells(dummy, [C + Vector2i(2, -1)] as Array[Vector2i], [])
	assert_eq(combat.beacons.size(), 1, "un ennemi qui marche dessus la casse")
	assert_eq(combat.arcs().size(), 0, "avec ses arcs")
	_cast(combat, "paladin_balise", C + Vector2i(2, -1))
	assert_eq(combat.beacons.size(), 2)


func test_un_monstre_evite_les_arcs() -> void:
	var combat := _fight([C + Vector2i(-2, -1)])
	var dummy := combat.get_fighter("m0")
	dummy.pm = 8
	_cast(combat, "paladin_balise", C + Vector2i(0, -3))
	_cast(combat, "paladin_balise", C + Vector2i(0, 2))
	var paths := combat.reachable_cells(dummy)
	var path: Array = paths[C + Vector2i(2, -1)]
	assert_false(path.any(func(cell: Vector2i) -> bool: return cell.x == C.x and cell.y > C.y - 3 and cell.y < C.y + 2),
		"le chemin contourne l'arc quand il peut")
	assert_true(paths.has(C + Vector2i(0, -1)), "une case d'arc reste atteignable")


func test_projectile_renforce_par_un_arc() -> void:
	var combat := _fight([C + Vector2i(4, 0)])
	var spell := combat.get_fighter(Fixtures.PLAYER).get_spell("paladin_etincelle")
	assert_eq(combat.arcs_crossed(combat.get_fighter(Fixtures.PLAYER), spell, C + Vector2i(4, 0)), 0)
	_cast(combat, "paladin_balise", C + Vector2i(2, -2))
	_cast(combat, "paladin_balise", C + Vector2i(2, 2))
	assert_eq(combat.arcs_crossed(combat.get_fighter(Fixtures.PLAYER), spell, C + Vector2i(4, 0)), 1, "la ligne traverse l'arc")
	var events := _cast(combat, "paladin_etincelle", C + Vector2i(4, 0))
	assert_eq(events[0].get("arcs"), 1)
	var marteau := combat.get_fighter(Fixtures.PLAYER).get_spell("paladin_marteau_lance")
	assert_eq(combat.arcs_crossed(combat.get_fighter(Fixtures.PLAYER), marteau, C + Vector2i(4, 0)), 0, "seulement les projectiles")


func test_surtension_et_saut_d_eclair() -> void:
	var combat := _fight([C + Vector2i(0, 1), C + Vector2i(-3, 2)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "paladin_balise", C + Vector2i(-3, 1))
	_cast(combat, "paladin_balise", C + Vector2i(2, 1))
	var on_arc := combat.get_fighter("m0")
	var beside := combat.get_fighter("m1")
	var hp := on_arc.hp
	assert_eq(_cast(combat, "paladin_surtension", C + Vector2i(1, 1))[0]["raison"], Protocol.REASON_NO_BEACON)
	_cast(combat, "paladin_surtension", C + Vector2i(-3, 1))
	assert_true(on_arc.hp < hp, "l'ennemi sur l'arc, même déjà frappé ce tour")
	assert_true(beside.hp < 200, "l'ennemi au contact de la balise")
	_cast(combat, "paladin_saut_d_eclair", C + Vector2i(2, 1))
	assert_eq(player.cell, C + Vector2i(2, 1), "échange de place avec sa balise")
	assert_eq(combat.beacon_at(C)["lanceur"], player)


func test_electrocution_sur_un_arc() -> void:
	var combat := _fight([C + Vector2i(0, 1), C + Vector2i(0, -1)])
	_cast(combat, "paladin_balise", C + Vector2i(-2, 1))
	_cast(combat, "paladin_balise", C + Vector2i(2, 1))
	assert_eq(combat.arcs().size(), 1)
	_cast(combat, "paladin_electrocution", C + Vector2i(0, 1))
	_cast(combat, "paladin_electrocution", C + Vector2i(0, -1))
	assert_eq(combat.get_fighter("m0").modifier("pa"), -1, "−1 PA de plus sur un arc")
	assert_eq(combat.get_fighter("m1").modifier("pa"), 0)


func test_paratonnerre_vivant() -> void:
	var combat := _fight([C + Vector2i(2, 2)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var pm := player.pm
	_cast(combat, "paladin_paratonnerre_vivant", C)
	assert_eq(player.pm, pm + 1, "+1 PM")
	_cast(combat, "paladin_balise", C + Vector2i(0, 4))
	assert_eq(combat.arcs().size(), 1, "il sert de balise")
	combat.execute(Fixtures.cmd(Protocol.CMD_MOVE, {"cible": C + RIGHT}))
	assert_eq(combat.arcs().size(), 0, "la balise vivante bouge avec lui")


func test_saint_paratonnerre() -> void:
	var combat := _fight([C + Vector2i(3, 0)], 4)  # Rang 3.
	var player := combat.get_fighter(Fixtures.PLAYER)
	assert_eq(combat.paladin_bonus(player), 0, "ni aura ni arc")
	_cast(combat, "paladin_aura_de_bravoure", C)
	assert_eq(combat.paladin_bonus(player), 9, "5 + rang + 1 %")
	assert_eq(combat.aura_radius(combat.aura_of(player)), 3, "rang 3 : rayon +1")
	assert_eq(combat.max_beacons(player), 3)
	player.passives["saint_paratonnerre"] = 6
	assert_eq(combat.max_beacons(player), 4, "rang 5 : une 4e balise")


func test_balises_et_auras_dans_l_instantane() -> void:
	var combat := _fight([C + Vector2i(3, 0)])
	_cast(combat, "paladin_aura_de_bravoure", C)
	_cast(combat, "paladin_balise", C + Vector2i(0, 3))
	var saved := combat.snapshot()
	assert_eq(saved["auras"].size(), 1)
	assert_eq(saved["balises"].size(), 1)
	assert_eq(Protocol.decode(Protocol.encode({"type": "test", "etat": saved}))["etat"]["balises"][0]["case"], C + Vector2i(0, 3))
