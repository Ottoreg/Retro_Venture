extends "res://tests/test_case.gd"
## Démoniste (GDD § 4.3) : serviteurs joués par le joueur de leur maître (Voie Impie), embrasement des cases et variantes
## (Voie Flamme), passif « Pacte de feu ». Sorts tirés des données du jeu, sans coup critique.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const SERVANT_SPELLS := ["diablotin_fourche", "diablotin_crachat_de_soufre", "molosse_morsure", "molosse_grognement", "succube_soin_rh",
	"succube_prime_de_motivation", "succube_pause_cafe"]

var C := Fixtures.center()


func _data() -> GameData:
	var spells := Fixtures.spells()
	var voie: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voies/demoniste.json"))
	for spell_id: String in voie["sorts"] + SERVANT_SPELLS:
		var spell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sorts/%s.json" % spell_id))
		spell["critique"] = 0
		spells.append(spell)
	var races := [{"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test", "passif": {"nom": "Aucun", "effets": []}}]
	return GameData.from_dicts(spells, [Fixtures.monster("mannequin", 200, 6, 0, 10, ["frappe"])], [voie], races, Fixtures.items(), [], [])


## Le Démoniste en C (rang du passif : `pact`, 0 sans) contre des mannequins immobiles.
func _fight(monsters: Array, pact := 0, data := _data()) -> Combat:
	var fighters: Array[Fighter] = []
	var player := data.create_player("demoniste", Fixtures.PLAYER, "Testeur")
	player.cell = C
	if pact > 0:
		player.passives["pacte_de_feu"] = pact
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


func _cast(combat: Combat, spell_id: String, target: Vector2i, servant := "") -> Array[Dictionary]:
	var caster := combat.get_fighter(servant if servant != "" else Fixtures.PLAYER)
	caster.pa = 20
	caster._cooldowns.clear()
	caster._casts_this_turn.clear()
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}.merged({"serviteur": servant} if servant != "" else {})))


func test_serviteur_joue_par_le_joueur() -> void:
	var combat := _fight([C + Vector2i(4, 0)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var events := _cast(combat, "demoniste_appel_du_diablotin", C + Vector2i(1, 0))
	var summoned := Fixtures.of_type(events, Protocol.EVT_SUMMONED)
	assert_eq(summoned.size(), 1, "un Diablotin")
	var imp := combat.get_fighter(summoned[0]["combattant"]["id"])
	assert_eq(imp.master, Fixtures.PLAYER)
	assert_false(imp.is_ai(), "contrôlé par le joueur, pas par l'IA")
	assert_eq(imp.max_hp, roundi(player.max_hp * 0.3), "30 % des PV du maître")
	assert_eq(imp.stats, player.stats, "les caractéristiques du maître")
	assert_eq(summoned[0]["ordre"][1], imp.id, "il joue juste après son maître")
	assert_eq(combat.player_fighters().size(), 1, "pas un joueur de plus")
	combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	assert_eq(combat.current_fighter(), imp, "son tour attend le joueur")
	var refused := combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN, {"serviteur": "m0"}))
	assert_eq(refused[0]["raison"], Protocol.REASON_UNKNOWN_ENTITY, "pas le serviteur d'un autre")
	var moved := combat.execute(Fixtures.cmd(Protocol.CMD_MOVE, {"serviteur": imp.id, "cible": C + Vector2i(2, 0)}))
	assert_eq(moved[0]["type"], Protocol.EVT_MOVED, "le joueur le déplace")
	var hp := combat.get_fighter("m0").hp
	_cast(combat, "diablotin_fourche", C + Vector2i(4, 0), imp.id)
	assert_true(combat.get_fighter("m0").hp < hp, "il frappe avec les sorts que le joueur choisit")
	assert_true(combat.practice.has(Fixtures.PLAYER) and not combat.practice.has(imp.id), "sa pratique va à son maître")


func test_limite_et_fin_des_serviteurs() -> void:
	var combat := _fight([C + Vector2i(4, 0)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "demoniste_appel_du_diablotin", C + Vector2i(1, 0))
	_cast(combat, "demoniste_appel_du_molosse", C + Vector2i(-1, 0))
	assert_eq(combat.servants_of(player).size(), 2)
	assert_eq(_cast(combat, "demoniste_appel_de_la_succube", C + Vector2i(0, 1))[0]["raison"], Protocol.REASON_TOO_MANY_SERVANTS, "2 au plus")
	assert_eq(combat.max_servants(player), 2)
	player.passives["pacte_de_feu"] = 6
	assert_eq(combat.max_servants(player), 3, "un 3e au rang 5 du passif")
	assert_eq(_cast(combat, "demoniste_appel_de_la_succube", C + Vector2i(1, 0))[0]["raison"], Protocol.REASON_OCCUPIED, "sur une case libre")
	var dog := combat.servants_of(player)[1]
	assert_eq(dog.combat_stat("tacle"), 10, "le Molosse tacle")
	# Permutation, puis Sacrifice.
	var dog_cell := dog.cell
	_cast(combat, "demoniste_permutation", dog_cell)
	assert_eq(player.cell, dog_cell, "Permutation : échange de place avec son serviteur")
	assert_eq(_cast(combat, "demoniste_permutation", C + Vector2i(4, 0))[0]["raison"], Protocol.REASON_NOT_SERVANT)
	var imp := combat.servants_of(player)[0]
	combat.get_fighter("m0").cell = imp.cell + Vector2i(1, 0)
	var hp := combat.get_fighter("m0").hp
	_cast(combat, "demoniste_sacrifice", imp.cell)
	assert_false(imp.is_alive(), "Sacrifice : le serviteur explose")
	assert_true(combat.get_fighter("m0").hp < hp - 8, "dégâts autour de lui, plus une part de ses PV")
	# Le maître vaincu emporte ses serviteurs ; un camp où il ne reste que des serviteurs a perdu.
	player.hp = 1
	combat._hurt(player, 5, "", [] as Array[Dictionary])
	assert_false(dog.is_alive(), "le Molosse disparaît avec son maître")
	combat._check_end([] as Array[Dictionary])
	assert_eq(combat.winner_team, Fighter.TEAM_MONSTERS)


func test_rangs_des_invocations() -> void:
	var data := _data()
	var spell: Spell = data.spells["demoniste_appel_du_diablotin"].mastered(5)
	var combat := _fight([C + Vector2i(4, 0)], 0, data)
	var player := combat.get_fighter(Fixtures.PLAYER)
	player.spells[0] = spell
	_cast(combat, "demoniste_appel_du_diablotin", C + Vector2i(1, 0))
	var imp := combat.servants_of(player)[0]
	assert_eq(imp.max_pm, 4, "rang 3 : +1 PM")
	assert_eq(imp.spells.size(), 2, "rang 5 : un sort de plus")
	assert_eq(imp.spells[0].rank, 5, "ses sorts au rang du sort d'invocation")


func test_embrasement_et_variantes() -> void:
	var combat := _fight([C + Vector2i(3, 0)])
	var dummy := combat.get_fighter("m0")
	var events := _cast(combat, "demoniste_mise_a_feu", C + Vector2i(3, 0))
	assert_eq(combat.ember_level(C + Vector2i(3, 0)), 2, "Mise à feu : 2 niveaux d'un coup")
	assert_eq(combat.ember_level(C + Vector2i(4, 0)), 2, "toute la zone")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_EMBERS).size(), 1)
	_cast(combat, "demoniste_escarbille", C + Vector2i(3, 0))
	assert_eq(combat.ember_level(C + Vector2i(3, 0)), 3)
	_cast(combat, "demoniste_escarbille", C + Vector2i(3, 0))
	assert_eq(combat.ember_level(C + Vector2i(3, 0)), Combat.CALCINED, "calcinée à la 4e fois")
	var player := combat.get_fighter(Fixtures.PLAYER)
	player.pa = 10
	player._casts_this_turn.clear()
	combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": "demoniste_escarbille", "cible": C + Vector2i(3, 0)}))
	assert_eq(player.pa, 9, "Escarbille sur une case calcinée rend 1 PA")
	var effects := combat._ember_variant(player.get_spell("demoniste_fournaise"), C + Vector2i(4, 0), [] as Array[Vector2i])
	assert_eq(effects[0]["min"], roundi(13 * 1.2), "+10 % par niveau de la case visée")
	effects = combat._ember_variant(player.get_spell("demoniste_mur_de_flammes"), C + Vector2i(4, 0), [] as Array[Vector2i])
	assert_eq(effects[0]["duree"], 3, "Mur de flammes : un tour de plus par niveau")
	effects = combat._ember_variant(player.get_spell("demoniste_mur_de_flammes"), C + Vector2i(3, 0), [] as Array[Vector2i])
	assert_eq(effects[0]["type"], Spell.EFFECT_DAMAGE, "sur une case calcinée, il ne tient pas : dégâts tout de suite")
	# Brûlure au début du tour d'un ennemi sur une case embrasée (pas calcinée).
	dummy.cell = C + Vector2i(4, 0)
	var hp := dummy.hp
	combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	assert_eq(hp - dummy.hp, Combat.EMBER_BURN * 2, "2 × niveau de dégâts Flamme")
	# Explosion de cendres : consomme l'embrasement de la zone.
	var heat := combat._heat_of(Spell.circle_cells(C + Vector2i(3, 0), 2))
	hp = dummy.hp
	_cast(combat, "demoniste_explosion_de_cendres", C + Vector2i(3, 0))
	assert_true(hp - dummy.hp >= heat * 2 / Combat.ASHES_DIVISOR, "dégâts par niveau retiré ÷ 5")
	assert_eq(combat.ember_level(C + Vector2i(3, 0)), 0, "tout s'éteint")
	assert_eq(_cast(combat, "demoniste_explosion_de_cendres", C + Vector2i(3, 0))[0]["raison"], Protocol.REASON_NO_EMBERS)


func test_embrasement_par_dimension_et_portee() -> void:
	var combat := _fight([C + Vector2i(0, 4)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	assert_eq(_cast(combat, "demoniste_pas_de_braise", C + Vector2i(4, 0))[0]["raison"], Protocol.REASON_OUT_OF_RANGE, "portée 3")
	_cast(combat, "demoniste_escarbille", C + Vector2i(4, 0))
	assert_eq(_cast(combat, "demoniste_pas_de_braise", C + Vector2i(4, 0))[0]["type"], Protocol.EVT_SPELL_CAST, "portée 6 vers une case embrasée")
	assert_eq(player.cell, C + Vector2i(4, 0))
	assert_eq(combat.ember_level(C + Vector2i(4, 0), true), 0, "rien dans le Monde des ombres")
	player.shadow = true
	combat.dimension = true
	_cast(combat, "demoniste_escarbille", C + Vector2i(-2, 0))
	assert_eq(combat.ember_level(C + Vector2i(-2, 0), true), 1, "les ombres ont leur propre embrasement")
	assert_eq(combat.ember_level(C + Vector2i(-2, 0), false), 0)


func test_pacte_de_feu() -> void:
	var combat := _fight([C + Vector2i(3, 0)], 1)
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	assert_eq(combat.damage_bonus(player, dummy, {}), 0, "pas sur une case embrasée")
	_cast(combat, "demoniste_escarbille", dummy.cell)
	assert_eq(combat.damage_bonus(player, dummy, {}), 6, "+6 % contre une cible sur une case embrasée")
	assert_eq(combat.damage_bonus(player, dummy, {"par_serviteur": 20}), 6, "Main du Malin : aucun serviteur")
	player.passives["pacte_de_feu"] = 4
	_cast(combat, "demoniste_appel_du_diablotin", C + Vector2i(1, 0))
	var imp := combat.servants_of(player)[0]
	assert_eq(imp.max_hp, roundi(player.max_hp * 0.3), "case pas embrasée : PV normaux")
	assert_eq(combat.damage_bonus(imp, dummy, {}), 9, "ses serviteurs aussi")
	assert_eq(combat.damage_bonus(player, dummy, {"par_serviteur": 20}), 29, "+20 % par serviteur vivant")
	_cast(combat, "demoniste_escarbille", C + Vector2i(0, 2))
	_cast(combat, "demoniste_appel_du_molosse", C + Vector2i(0, 2))
	assert_eq(combat.servants_of(player)[1].max_hp, roundi(player.max_hp * 0.8 * 1.2), "rang 3 : +20 % de PV sur une case embrasée")


func test_copie_du_client() -> void:
	var combat := _fight([C + Vector2i(4, 0)])
	_cast(combat, "demoniste_appel_du_diablotin", C + Vector2i(1, 0))
	_cast(combat, "demoniste_escarbille", C + Vector2i(0, 3))
	var data := _data()
	var copy := Combat.from_snapshot(Protocol.decode(Protocol.encode({"type": "x", "combat": combat.snapshot()}))["combat"], Fixtures.map(), data, {})
	assert_true(copy != null, "serviteur recréé chez le client")
	assert_eq(copy.fighters[1].master, Fixtures.PLAYER)
	assert_eq(copy.fighters[1].spells.size(), 1)
	assert_eq(copy.ember_level(C + Vector2i(0, 3)), 1, "embrasement copié")


func test_passif_debloque_a_apprenti() -> void:
	var data := _data()
	assert_false("demoniste_pacte_de_feu" in data.masterable_spells("demoniste", 0))
	assert_true("demoniste_pacte_de_feu" in data.masterable_spells("demoniste", 1000), "palier Apprenti")
	assert_eq(data.voies["demoniste"]["sorts"].size(), 20, "20 sorts")
