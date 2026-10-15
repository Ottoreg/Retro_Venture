extends "res://tests/test_case.gd"
## Mini-boss à phases : quand ses PV passent sous un seuil (en % de ses PV max), après n'importe
## quels dégâts, le monstre change de phase une seule fois : nouveaux sorts, effets sur lui-même et
## message. Le champ « boss » exempte un monstre unique de la règle « une élite par famille ».

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _combat: Combat
var _boss: Fighter


## Boss de 40 PV, sans PA ni PM (il ne joue pas) ; phases données.
func _start(phases: Array, hp := 40) -> void:
	var boss := Fixtures.monster("boss", hp, 0, 0, 10, ["frappe"])
	boss["boss"] = true
	boss["phases"] = phases
	var errors := GameData.validate_monster(boss, _spells(), _items())
	assert_eq(errors.size(), 0, "; ".join(errors))
	var base := Fixtures.data()
	var data := GameData.from_dicts(Fixtures.spells(), [boss], base.voies.values(), base.races.values(), Fixtures.items())
	var player := data.create_player("test", Fixtures.PLAYER, "Testeur")
	player.cell = Fixtures.center()
	_boss = data.create_monster("boss", "b")
	_boss.cell = Fixtures.center() + Vector2i(1, 0)
	var fighters: Array[Fighter] = [player, _boss]
	_combat = Combat.new(Fixtures.map(), fighters, [player.cell] as Array[Vector2i], 1)
	_combat.execute(Fixtures.cmd(Protocol.CMD_READY))


func _spells() -> Dictionary:
	var spells := {}
	for raw: Dictionary in Fixtures.spells():
		spells[raw["id"]] = Spell.from_dict(raw)
	return spells


func _items() -> Dictionary:
	var items := {}
	for raw: Dictionary in Fixtures.items():
		items[raw["id"]] = raw
	return items


func _hit(spell_id := "frappe") -> Array[Dictionary]:
	return _combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": _boss.cell}))


func test_phase_declenchee_une_seule_fois() -> void:
	_start([{"pv": 50, "message": "Assez joué !", "sorts": ["tir"],
		"effets": [{"type": "bonus", "carac": "force", "min": 100, "max": 100, "duree": 2}]}])
	assert_true(_boss.get_spell("tir") == null, "pas encore le sort de la phase")
	var events := _hit()
	assert_eq(_boss.hp, 30)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PHASE).size(), 0, "75 % : pas encore")
	events = _hit()
	assert_eq(_boss.hp, 20, "50 % tout juste")
	var phases := Fixtures.of_type(events, Protocol.EVT_PHASE)
	assert_eq(phases.size(), 1, "phase déclenchée")
	assert_eq(phases[0]["entite"], "b")
	assert_eq(phases[0]["message"], "Assez joué !")
	assert_true(_boss.get_spell("tir") != null, "sort de la phase appris")
	assert_eq(_boss.stat("force"), 100, "effet appliqué à lui-même")
	var states := Fixtures.of_type(events, Protocol.EVT_STATES)
	assert_eq(states[-1]["entite"], "b")
	assert_eq(states[-1]["nouveau"]["carac"], "force")
	assert_true(events.find(phases[0]) < events.find(states[-1]), "le message d'abord, puis les effets")
	# Soigné puis blessé à nouveau : la phase ne revient pas.
	_boss.hp = 40
	_combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	events = _hit()
	events.append_array(_hit())
	assert_eq(_boss.hp, 20)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PHASE).size(), 0, "une seule fois")
	assert_eq(_boss.spells.size(), 2, "pas de sort en double")


func test_plusieurs_phases_franchies_d_un_coup() -> void:
	_start([
		{"pv": 90, "message": "Un", "sorts": ["tir"]},
		{"pv": 85, "message": "Deux", "sorts": ["tir", "venin"]},
		{"pv": 10, "message": "Trois"},
	], 20)
	var events := _hit()
	assert_eq(_boss.hp, 10, "de 100 % à 50 %")
	var messages: Array = []
	for event in Fixtures.of_type(events, Protocol.EVT_PHASE):
		messages.append(event["message"])
	assert_eq(str(messages), str(["Un", "Deux"]), "les deux phases franchies, dans l'ordre")
	assert_eq(_boss.spells.size(), 3, "frappe, tir et soin, sans doublon")
	assert_eq(_boss.phases.size(), 1, "reste la dernière")


func test_le_bouclier_d_une_phase_n_annule_pas_la_suivante() -> void:
	# Le coup le laisse à 50 % : la première phase lui donne un bouclier, la seconde (60 %) a quand
	# même été franchie par le coup.
	_start([
		{"pv": 90, "message": "Un", "effets": [{"type": "bouclier", "element": "acier", "min": 8, "max": 8}]},
		{"pv": 60, "message": "Deux"},
	], 20)
	var events := _hit()
	assert_eq(_boss.hp, 10, "10 PV après le coup")
	assert_eq(_boss.shield, 8)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PHASE).size(), 2, "les deux phases")
	assert_true(_boss.phases.is_empty())


func test_phase_apres_un_poison_bonus_et_bouclier_sur_soi() -> void:
	_start([{"pv": 95, "message": "Ça pique !",
		"effets": [{"type": "bonus", "carac": "pm", "min": 2, "max": 2, "duree": 2}, {"type": "bouclier", "element": "acier", "min": 7, "max": 7}]}])
	_hit("venin")
	assert_eq(_boss.hp, 40, "le poison n'agit qu'au début de son tour")
	var events := _combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	var damage := Fixtures.of_type(events, Protocol.EVT_DAMAGE)
	assert_eq(damage[0]["source"], "poison")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PHASE).size(), 1, "déclenchée par le poison")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_HEAL).size(), 0)
	assert_eq(_boss.hp, 35, "40 - 5")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_STATUS)[0]["effet"], Spell.EFFECT_SHIELD)
	assert_true(Fixtures.of_type(events, Protocol.EVT_STATES).size() > 0, "bonus de PM posé")


func test_phase_apres_un_choc() -> void:
	# Poussé contre un rocher : les dégâts de choc comptent aussi.
	_start([{"pv": 99, "message": "Aïe"}])
	_combat.map = Fixtures.map({_boss.cell + Vector2i(1, 0): "R"})
	var events := _hit("repousse")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE)[0]["source"], "choc")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PHASE).size(), 1)


func test_phase_apres_un_piege() -> void:
	# Repoussé sur un piège posé derrière lui : les dégâts du piège comptent aussi.
	_start([{"pv": 80, "message": "Un piège ? Quelle bassesse !"}])
	var trap_cell := _boss.cell + Vector2i(1, 0)
	_combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": "chausse_trape", "cible": trap_cell}))
	assert_eq(_combat.traps.size(), 1, "piège posé")
	var events := _hit("repousse")
	assert_eq(_boss.cell, trap_cell, "arrêté sur le piège")
	assert_eq(_boss.hp, 30, "10 dégâts du piège, sans choc")
	var triggered := Fixtures.of_type(events, Protocol.EVT_TRAP_TRIGGERED)
	var phases := Fixtures.of_type(events, Protocol.EVT_PHASE)
	assert_eq(triggered.size(), 1)
	assert_eq(phases.size(), 1, "déclenchée par le piège")
	assert_eq(phases[0]["message"], "Un piège ? Quelle bassesse !")
	assert_true(events.find(triggered[0]) < events.find(phases[0]), "après le déclenchement du piège")


func test_pas_de_phase_pour_un_monstre_vaincu() -> void:
	_start([{"pv": 50, "message": "Jamais vu"}], 10)
	var events := _hit()
	assert_false(_boss.is_alive())
	assert_eq(Fixtures.of_type(events, Protocol.EVT_PHASE).size(), 0)


func test_erreurs_de_validation_des_phases() -> void:
	var cases := [
		[{"phases": {"pv": 50}}, "liste"],
		[{"phases": [{"pv": 0, "message": "a"}]}, "de 1 à 99"],
		[{"phases": [{"pv": 100, "message": "a"}]}, "de 1 à 99"],
		[{"phases": [{"pv": 50, "message": "a"}, {"pv": 60, "message": "b"}]}, "plus bas"],
		[{"phases": [{"pv": 50, "message": "a"}, {"pv": 50, "message": "b"}]}, "plus bas"],
		[{"phases": [{"pv": 50}]}, "« message »"],
		[{"phases": [{"pv": 50, "message": "a", "sorts": ["inconnu"]}]}, "sort inconnu"],
		[{"phases": [{"pv": 50, "message": "a", "effets": [{"type": "bonus", "carac": "vitesse", "min": 1, "max": 1, "duree": 1}]}]}, "carac"],
		[{"phases": [{"pv": 50, "message": "a", "effets": [{"type": "glyphe", "duree": 2, "effets": []}]}]}, "sur soi-même"],
		[{"phases": [{"pv": 50, "message": "a", "effets": [{"type": "teleportation"}]}]}, "sur soi-même"],
		[{"phases": [{"pv": 50, "message": "a", "effets": [{"type": "poussee", "min": 2, "max": 2}]}]}, "sur soi-même"],
		[{"phases": [{"pv": 50, "message": "a", "effets": [{"type": "bouclier", "min": 1, "max": 1}]}]}, "element"],
		[{"phases": [{"pv": 50, "message": "a", "effets": [{"type": "soin", "element": "acier", "min": 1, "max": 1}]}]}, "pas de soin"],
		[{"phases": [{"pv": 50, "message": "a", "sorts": ["soin"]}]}, "pas de soin"],
		[{"phases": [{"pv": 50, "message": "a", "sorts": ["cercle"]}]}, "pas de soin"],
	]
	for case: Array in cases:
		var monster := Fixtures.monster("essai", 20, 6, 3, 10, ["frappe"])
		monster.merge(case[0], true)
		var errors := "; ".join(GameData.validate_monster(monster, _spells(), _items()))
		assert_true(errors.contains(case[1]), "%s : « %s » attendu dans « %s »" % [str(case[0]), case[1], errors])


func test_le_souverain_cendre_est_un_boss_sans_elite() -> void:
	var data := GameData.load_all()
	var boss: Dictionary = data.monsters["souverain_cendre"]
	assert_true(boss.get("boss", false))
	assert_false(boss.has("famille"))
	for monster: Dictionary in data.monsters.values():
		assert_ne(monster.get("famille", ""), "souverain_cendre", "personne n'est de sa famille")
	assert_eq(data.monster_level_range("souverain_cendre"), Vector2i(50, 50), "niveau fixe")
