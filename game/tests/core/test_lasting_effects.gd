extends "res://tests/test_case.gd"
## Coups critiques, bonus et malus temporaires, poisons, poussée, attirance, glyphes, pièges, et
## IA qui s'en sert.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


func _fight(monsters: Array, changes := {}) -> Combat:
	var combat := Fixtures.combat(Fixtures.map(changes), C, monsters)
	combat.start()
	combat.execute(Fixtures.cmd(Protocol.CMD_READY))
	return combat


func _cast(combat: Combat, spell_id: String, target: Vector2i) -> Array[Dictionary]:
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}))


func _end_turn(combat: Combat) -> Array[Dictionary]:
	return combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))


func _player(combat: Combat) -> Fighter:
	return combat.get_fighter(Fixtures.PLAYER)


func test_coup_critique() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	var events := _cast(combat, "fatal", C + RIGHT)
	assert_true(events[0]["critique"], "100 % de critique")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE)[0]["valeur"], 15, "10 × 1,5")
	events = _cast(combat, "frappe", C + RIGHT)
	assert_false(events[0]["critique"], "0 % de critique")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE)[0]["valeur"], 10)


func test_le_bonus_critique_de_l_equipement() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	_player(combat).crit_bonus = 100
	assert_true(_cast(combat, "frappe", C + RIGHT)[0]["critique"])


func test_bonus_de_force_pendant_deux_tours() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	combat.get_fighter("m0").hp = 100
	var events := _cast(combat, "rage", C)
	var states := Fixtures.of_type(events, Protocol.EVT_STATES)
	assert_eq(states.size(), 1)
	assert_eq(states[0]["nouveau"]["carac"], "force")
	assert_eq(_player(combat).stat("force"), 100)
	assert_eq(Fixtures.of_type(_cast(combat, "frappe", C + RIGHT), Protocol.EVT_DAMAGE)[0]["valeur"], 20, "+100 % de dégâts d'acier")
	_end_turn(combat)
	assert_eq(_player(combat).stat("force"), 100, "encore un tour")
	assert_eq(Fixtures.of_type(_cast(combat, "frappe", C + RIGHT), Protocol.EVT_DAMAGE)[0]["valeur"], 20)
	events = _end_turn(combat)
	assert_eq(_player(combat).stat("force"), 0, "tombé à la fin du 2e tour")
	assert_true(Fixtures.of_type(events, Protocol.EVT_STATES)[0]["etats"].is_empty())


func test_malus_de_pm_et_de_resistance() -> void:
	var combat := _fight([["loup", C + Vector2i(4, 0)]])
	var wolf := combat.get_fighter("m0")
	_cast(combat, "boulet", wolf.cell)
	assert_eq(wolf.resistance("acier"), -20.0)
	assert_eq(wolf.next_turn_pm(), 2, "4 PM − 2")
	var events := _end_turn(combat)
	var wolf_turn := Fixtures.of_type(events, Protocol.EVT_TURN_STARTED)[0]
	assert_eq(wolf_turn["pm"], 2)
	for move in Fixtures.of_type(events, Protocol.EVT_MOVED):
		assert_true(move["chemin"].size() <= 2)
	assert_eq(wolf.resistance("acier"), -20.0, "le malus de résistance dure encore un tour")
	assert_eq(wolf.next_turn_pm(), 4, "le malus de PM est tombé")


func test_les_pm_retires_comptent_tout_de_suite() -> void:
	var combat := _fight([["mannequin", C + Vector2i(3, 0)]])
	var player := _player(combat)
	player.states.append({"type": Spell.EFFECT_BONUS, "carac": "pm", "valeur": 0, "tours": 1, "sort": "", "lanceur": player.id})
	combat._add_state(player, {"type": Spell.EFFECT_MALUS, "carac": "pm", "element": "", "valeur": 2, "tours": 1, "sort": "x",
		"lanceur": "m0"}, [] as Array[Dictionary])
	assert_eq(player.pm, 1, "3 − 2")


func test_poison() -> void:
	var combat := _fight([["mannequin", C + Vector2i(2, 0)]])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "venin", dummy.cell)
	assert_eq(dummy.hp, 30, "rien tout de suite")
	for turn in 3:
		var events := _end_turn(combat)
		var damage := Fixtures.of_type(events, Protocol.EVT_DAMAGE)
		assert_eq(damage.size(), 1, "tour %d" % turn)
		assert_eq(damage[0]["source"], "poison")
	assert_eq(dummy.hp, 15, "3 × 5")
	assert_eq(Fixtures.of_type(_end_turn(combat), Protocol.EVT_DAMAGE).size(), 0, "le poison est fini")


func test_poussee_et_choc() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	var dummy := combat.get_fighter("m0")
	var events := _cast(combat, "repousse", dummy.cell)
	assert_eq(dummy.cell, C + Vector2i(3, 0))
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PUSHED)[0]["case"], C + Vector2i(3, 0))
	assert_eq(dummy.hp, 30, "pas de choc")
	# Contre un rocher : une case parcourue, une manquée.
	combat = _fight([["mannequin", C + RIGHT]], {C + Vector2i(3, 0): "R"})
	dummy = combat.get_fighter("m0")
	events = _cast(combat, "repousse", dummy.cell)
	assert_eq(dummy.cell, C + Vector2i(2, 0))
	var damage := Fixtures.of_type(events, Protocol.EVT_DAMAGE)
	assert_eq(damage[0]["valeur"], Combat.PUSH_DAMAGE_PER_CELL)
	assert_eq(damage[0]["source"], "choc")


func test_attirance() -> void:
	var combat := _fight([["mannequin", C + Vector2i(4, 0)]])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "grappin", dummy.cell)
	assert_eq(dummy.cell, C + RIGHT, "3 cases vers le lanceur")
	assert_eq(dummy.hp, 30, "pas de choc en attirant")


func test_glyphe_soigne_les_allies_et_ralentit_les_ennemis() -> void:
	var combat := _fight([["loup", C + Vector2i(1, 0)]])
	var player := _player(combat)
	player.hp = 30
	var events := _cast(combat, "cercle", C)
	var glyph := Fixtures.of_type(events, Protocol.EVT_GLYPH)
	assert_eq(glyph.size(), 1)
	assert_eq(glyph[0]["cases"].size(), 5)
	assert_eq(glyph[0]["element"], "acier", "l'élément de son premier effet chiffré (sa couleur à l'écran)")
	events = _end_turn(combat)
	# Le loup commence son tour dans la glyphe : −2 PM tout de suite.
	var slowed := Fixtures.of_type(events, Protocol.EVT_STATES)
	assert_eq(slowed[0]["entite"], "m0")
	assert_eq(slowed[0]["nouveau"]["carac"], "pm")
	assert_eq(slowed[0]["pm"], 2)
	# Le joueur commence le sien dedans : soigné de 10 (moins les coups du loup).
	var heals := Fixtures.of_type(events, Protocol.EVT_HEAL)
	assert_eq(heals.size(), 1)
	assert_eq(heals[0]["entite"], Fixtures.PLAYER)
	assert_eq(heals[0]["valeur"], 10)
	assert_eq(combat.glyphs.size(), 1, "encore active")
	events = _end_turn(combat)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_GLYPH_ENDED).size(), 1, "2 tours du lanceur")
	assert_true(combat.glyphs.is_empty())


func test_piege_arrete_la_victime_et_se_declenche() -> void:
	var combat := _fight([["mannequin", C + Vector2i(4, 0)]])
	var dummy := combat.get_fighter("m0")
	var events := _cast(combat, "chausse_trape", C + Vector2i(2, 0))
	assert_true(events[0]["cache"], "cible cachée à l'autre équipe")
	var trap := Fixtures.of_type(events, Protocol.EVT_TRAP)
	assert_eq(trap[0]["equipe"], Fighter.TEAM_PLAYERS)
	_assert_refused(_cast(combat, "chausse_trape", dummy.cell), Protocol.REASON_SPELL_LIMIT)
	# Attiré à travers le piège : il s'arrête dessus.
	events = _cast(combat, "grappin", dummy.cell)
	assert_eq(dummy.cell, C + Vector2i(2, 0))
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TRAP_TRIGGERED).size(), 1)
	assert_eq(dummy.hp, 20)
	assert_eq(dummy.next_turn_pm(), 0)
	assert_true(combat.traps.is_empty(), "un piège ne sert qu'une fois")


func test_on_ne_pose_pas_un_piege_sur_un_combattant() -> void:
	var combat := _fight([["mannequin", C + Vector2i(2, 0)]])
	_assert_refused(_cast(combat, "chausse_trape", C + Vector2i(2, 0)), Protocol.REASON_OCCUPIED)


func test_marcher_sur_un_piege_ennemi() -> void:
	var combat := _fight([["piegeur", C + Vector2i(4, 4)]])
	var trapper := combat.get_fighter("m0")
	var trap_cell := C + Vector2i(2, 0)
	combat._place_trap(trapper, trapper.get_spell("chausse_trape"), trapper.get_spell("chausse_trape").trap_effect(), trap_cell, [] as Array[Dictionary])
	var events := combat.execute(Fixtures.cmd(Protocol.CMD_MOVE, {"cible": C + Vector2i(3, 0)}))
	var move := Fixtures.of_type(events, Protocol.EVT_MOVED)[0]
	assert_eq(move["chemin"][-1], trap_cell, "la marche s'arrête sur le piège")
	assert_eq(_player(combat).cell, trap_cell)
	assert_eq(_player(combat).hp, 40)
	assert_eq(_player(combat).pm, 0, "3 PM − 2 de marche, puis −3 (au plus tout)")
	# Un allié du poseur passe dessus sans rien déclencher.
	combat._place_trap(trapper, trapper.get_spell("chausse_trape"), trapper.get_spell("chausse_trape").trap_effect(), C + Vector2i(3, 3), [] as Array[Dictionary])
	assert_true(combat.enemy_trap_at(C + Vector2i(3, 3), trapper).is_empty())


func test_un_combattant_vaincu_emporte_ses_glyphes_et_pieges() -> void:
	var combat := _fight([["mannequin", C + RIGHT]])
	_cast(combat, "cercle", C)
	_cast(combat, "chausse_trape", C + Vector2i(-2, 0))
	var events: Array[Dictionary] = []
	combat._hurt(_player(combat), 999, "acier", events)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_GLYPH_ENDED).size(), 1)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TRAP_ENDED).size(), 1)


# --- IA ---

func test_ia_soutien_soigne_un_allie_blesse() -> void:
	var combat := _fight([["druide", C + Vector2i(4, 0)], ["mannequin", C + Vector2i(2, 2)]])
	combat.get_fighter("m1").hp = 10
	var events := _end_turn(combat)
	var heals := Fixtures.of_type(events, Protocol.EVT_HEAL)
	assert_eq(heals.size(), 2, "deux soins avec 6 PA : 15, puis les 5 qui manquent")
	assert_eq(heals[0]["entite"], "m1")
	assert_eq(combat.get_fighter("m1").hp, 30)


func test_ia_pose_sa_glyphe_quand_elle_est_blessee_au_contact() -> void:
	var combat := _fight([["druide", C + RIGHT]])
	combat.get_fighter("m0").hp = 10
	var events := _end_turn(combat)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_GLYPH).size(), 1)


func test_ia_distance_pose_un_piege_tire_et_recule() -> void:
	var combat := _fight([["piegeur", C + Vector2i(2, 0)]])
	var events := _end_turn(combat)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TRAP).size(), 1, "piège posé près du joueur")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TRAP)[0]["equipe"], Fighter.TEAM_MONSTERS)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE).size(), 1, "un tir")
	assert_true(IsoGrid.distance(combat.get_fighter("m0").cell, C) >= 3, "il a reculé")


func test_ia_ne_lance_pas_un_sort_inutile() -> void:
	# Druide en pleine forme, loin de tout : ni soin ni glyphe ; il se rapproche.
	var combat := _fight([["druide", C + Vector2i(4, 4)]])
	var events := _end_turn(combat)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_SPELL_CAST).size(), 0)


func _assert_refused(events: Array[Dictionary], reason: String) -> void:
	assert_eq(events.size(), 1)
	if events.size() == 1:
		assert_eq(events[0]["type"], Protocol.EVT_REFUSED)
		assert_eq(events[0]["raison"], reason)
