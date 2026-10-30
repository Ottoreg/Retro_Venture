extends "res://tests/test_case.gd"
## Chronomancien, Voie Impie (GDD § 4.3) : horloge, décalages sur le cadran, échange de place, effets
## des heures ; états nommés (insoignable) et malus de dégâts infligés.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var C := Fixtures.center()
## Le joueur se tient à 3 pas de la cible, hors du cadran.
var START := C + Vector2i(-3, 0)
## Midi des horloges lancées depuis START sur C : vers +x, la direction du lancer.
const NOON := Vector2i(2, 0)

const HOURS := {
	"1": [{"type": "degats", "element": "givre", "min": 10, "max": 10}],
	"2": [{"type": "poison", "element": "givre", "min": 5, "max": 5, "duree": 2}],
	"3": [],
	"5": [{"type": "malus", "carac": "resistance", "element": "impie", "min": 10, "max": 10, "duree": 1}],
	"6": [{"type": "malus", "carac": "pm", "min": 1, "max": 1, "duree": 1}],
	"10": [{"type": "etat", "etat": "insoignable", "duree": 1}],
	"11": [{"type": "malus", "carac": "degats_infliges", "min": 50, "max": 50, "duree": 1}],
	"12": [{"type": "malus", "carac": "pa", "min": 1, "max": 1, "duree": 1}],
}


static func _spells() -> Array:
	var spells := Fixtures.spells()
	for spell: Dictionary in [
		{"id": "horloge", "nom": "Horloge", "cout_pa": 0, "portee": {"min": 0, "max": 6}, "ligne_de_vue": false,
			"effets": [{"type": "horloge", "duree": 2, "cibles": "ennemis", "heures": HOURS}]},
		{"id": "tic", "nom": "Tic", "cout_pa": 0, "portee": {"min": 0, "max": 6}, "ligne_de_vue": false,
			"effets": [{"type": "degats", "element": "impie", "min": 2, "max": 2}, {"type": "decalage_horaire", "heures": 1}]},
		{"id": "tac", "nom": "Tac", "cout_pa": 0, "portee": {"min": 0, "max": 6}, "ligne_de_vue": false,
			"effets": [{"type": "decalage_horaire", "heures": -1}]},
		{"id": "contre", "nom": "Contretemps", "cout_pa": 0, "portee": {"min": 0, "max": 6}, "ligne_de_vue": false,
			"effets": [{"type": "decalage_horaire", "heures": 6}]},
		{"id": "soin_loin", "nom": "Soin lointain", "cout_pa": 0, "portee": {"min": 0, "max": 6}, "ligne_de_vue": false,
			"effets": [{"type": "soin", "element": "acier", "min": 10, "max": 10}]},
	]:
		spell["critique"] = 0
		spells.append(spell)
	return spells


func _fight(monsters: Array, changes := {}) -> Combat:
	var voie := {"id": "chrono", "nom": "Chrono", "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100},
		"sorts": ["horloge", "tic", "tac", "contre", "soin_loin", "frappe"]}
	var races := [{"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test", "sort": "bond",
		"passif": {"nom": "Aucun", "effets": []}}]
	var monster_data := [Fixtures.monster("mannequin", 100, 6, 3, 10, ["frappe"])]
	var data := GameData.from_dicts(_spells(), monster_data, [voie], races, Fixtures.items(), [], [])
	var fighters: Array[Fighter] = []
	var player := data.create_player("chrono", Fixtures.PLAYER, "Testeur")
	player.cell = START
	fighters.append(player)
	for i in monsters.size():
		var fighter := data.create_monster("mannequin", "m%d" % i)
		fighter.cell = monsters[i]
		fighters.append(fighter)
	var placement: Array[Vector2i] = [START]
	var combat := Combat.new(Fixtures.map(changes), fighters, placement, 1)
	combat.start()
	combat.execute(Fixtures.cmd(Protocol.CMD_READY))
	return combat


func _hour(hour: int) -> Vector2i:
	return Combat.clock_cell(C, NOON, hour)


func _cast(combat: Combat, spell_id: String, target: Vector2i) -> Array[Dictionary]:
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}))


func test_cadran() -> void:
	assert_eq(Combat.CLOCK_RING.size(), 12)
	for i in 12:
		var offset := Combat.CLOCK_RING[i]
		assert_eq(maxi(absi(offset.x), absi(offset.y)), 2, "à 2 cases de la cible")
		assert_false(absi(offset.x) == 2 and absi(offset.y) == 2, "sans les coins")
		# Sens des aiguilles d'une montre à l'écran : chaque heure un peu plus loin que la précédente.
		var here := IsoGrid.cell_to_screen(offset)
		var next := IsoGrid.cell_to_screen(Combat.CLOCK_RING[(i + 1) % 12])
		var turn := fposmod(atan2(next.x, -next.y) - atan2(here.x, -here.y), TAU)
		assert_true(turn > 0.0 and turn < PI / 2, "dans l'ordre des heures à l'écran : %s" % str(offset))
	assert_eq(Combat.clock_noon(START, C), NOON, "midi dans la direction du lancer")
	assert_eq(Combat.clock_noon(C + Vector2i(0, 3), C), Vector2i(0, -2))
	assert_eq(_hour(12), C + Vector2i(2, 0))
	assert_eq(_hour(6), C + Vector2i(-2, 0), "6 h du côté du lanceur")
	assert_eq(Combat.clock_hour(C, NOON, _hour(3)), 3)
	assert_eq(Combat.clock_hour(C, NOON, C), 0, "le centre n'est pas une heure")


func test_cible_placee_a_midi() -> void:
	var combat := _fight([C])
	var dummy := combat.get_fighter("m0")
	var events := _cast(combat, "horloge", C)
	var glyph := Fixtures.of_type(events, Protocol.EVT_GLYPH)[0]
	assert_eq(glyph["centre"], C)
	assert_eq(glyph["midi"], NOON)
	assert_eq(glyph["cases"].size(), 12)
	assert_eq(dummy.cell, _hour(12), "la cible passe aussitôt à 12 h")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TELEPORTED)[0]["heure"], 12)
	assert_eq(dummy.next_turn_pa(), 5, "l'effet de 12 h dès la pose")
	assert_true(dummy.has_state(Spell.STATE_TIME_MANIPULATION), "état Manipulation du temps")


func test_horloge_et_decalages() -> void:
	var combat := _fight([C])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "horloge", C)
	var events := _cast(combat, "tic", dummy.cell)
	var moved := Fixtures.of_type(events, Protocol.EVT_TELEPORTED)[0]
	assert_eq(moved["heure"], 1, "de 12 h, +1 h mène à 1 h")
	assert_eq(dummy.cell, _hour(1))
	var damage := Fixtures.of_type(events, Protocol.EVT_DAMAGE)
	assert_eq(damage.size(), 2, "les dégâts du sort, puis ceux de 1 h")
	assert_eq(damage[1]["element"], "givre")
	assert_eq(dummy.hp, 100 - 2 - 10)
	_cast(combat, "tac", dummy.cell)
	assert_eq(dummy.cell, _hour(12), "−1 h : retour à 12 h")
	assert_eq(dummy.next_turn_pa(), 4, "12 h : −1 PA, en plus de celui de la pose")
	_cast(combat, "contre", dummy.cell)
	assert_eq(dummy.cell, _hour(6), "+6 h : de l'autre côté")
	assert_eq(dummy.next_turn_pm(), 2, "6 h : −1 PM")
	_cast(combat, "tac", dummy.cell)
	_cast(combat, "tac", dummy.cell)
	assert_eq(dummy.cell, _hour(4), "4 h (sans effet pour l'instant)")
	_cast(combat, "tic", dummy.cell)
	assert_true(dummy.resistance("impie") < 0, "5 h : +10 % de dégâts Impie subis")


func test_en_arriere_depuis_midi() -> void:
	var combat := _fight([C])
	_cast(combat, "horloge", C)
	_cast(combat, "tac", _hour(12))
	assert_eq(combat.get_fighter("m0").cell, _hour(11), "−1 h depuis 12 h : 11 h")


func test_hors_du_cadran_on_garde_la_derniere_heure() -> void:
	var combat := _fight([C])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "horloge", C)
	_cast(combat, "tac", _hour(12))
	assert_eq(dummy.cell, _hour(11))
	dummy.cell = C + Vector2i(0, 3)  # Poussé hors du cadran.
	_cast(combat, "tic", dummy.cell)
	assert_eq(dummy.cell, _hour(12), "11 h + 1 h, pas midi + 1 h")


func test_echange_de_place() -> void:
	var one := _hour(1)
	var combat := _fight([C, one])
	var other := combat.get_fighter("m1")
	_cast(combat, "horloge", C)
	var events := _cast(combat, "tic", _hour(12))
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TELEPORTED).size(), 2)
	assert_eq(combat.get_fighter("m0").cell, one)
	assert_eq(other.cell, _hour(12), "l'occupant prend la place de la cible")
	assert_eq(other.hp, 100, "seule la cible subit l'heure")


func test_obstacle_saute() -> void:
	var combat := _fight([C], {_hour(1): "R"})
	assert_eq(Fixtures.of_type(_cast(combat, "horloge", C), Protocol.EVT_GLYPH)[0]["cases"].size(), 11, "pas d'heure sur le rocher")
	_cast(combat, "tic", _hour(12))
	assert_eq(combat.get_fighter("m0").cell, _hour(2), "1 h bloquée : 2 h")


func test_pas_de_seconde_horloge() -> void:
	var combat := _fight([C])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "horloge", C)
	var refused := _cast(combat, "horloge", dummy.cell)
	assert_eq(refused[0]["raison"], Protocol.REASON_ALREADY_MANIPULATED, "pas sur une cible déjà manipulée")
	assert_eq(combat.glyphs.size(), 1)
	assert_eq(combat.glyphs[0]["horloge"]["centre"], C)
	var player := combat.get_fighter(Fixtures.PLAYER)
	assert_eq(CombatAI.evaluate(combat, player, player.get_spell("horloge"), dummy.cell, player.cell), 0.0,
		"l'IA ne la tente pas")


func test_sans_horloge() -> void:
	var combat := _fight([C])
	var events := _cast(combat, "tic", C)
	assert_true(Fixtures.of_type(events, Protocol.EVT_TELEPORTED).is_empty())
	assert_eq(combat.get_fighter("m0").cell, C)
	assert_eq(combat.get_fighter("m0").hp, 98, "les dégâts du sort restent")


func test_apercu_de_l_arrivee() -> void:
	var combat := _fight([C])
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "horloge", C)
	var preview := combat.spell_preview(player, player.get_spell("tac"), _hour(12))
	assert_eq(preview["m0"]["heure"], 11)
	assert_eq(preview["m0"]["arrivee"], _hour(11))


func test_insoignable_et_degats_infliges() -> void:
	var combat := _fight([C])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "horloge", C)
	_cast(combat, "tac", _hour(12))
	assert_eq(dummy.cell, _hour(11))
	assert_eq(Combat.damage_value(dummy, combat.get_fighter(Fixtures.PLAYER), "acier", 10), 5, "11 h : −50 % (test)")
	_cast(combat, "tac", dummy.cell)
	assert_true(dummy.has_state(Spell.STATE_UNHEALABLE), "10 h : insoignable")
	dummy.hp = 50
	var heal := Fixtures.of_type(_cast(combat, "soin_loin", dummy.cell), Protocol.EVT_HEAL)
	assert_eq(heal[0]["valeur"], 0)
	assert_eq(dummy.hp, 50)


func test_fin_de_l_horloge() -> void:
	var combat := _fight([C])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "horloge", C)
	for i in 2:
		combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	assert_true(combat.glyphs.is_empty(), "l'horloge dure 2 tours du lanceur")
	assert_false(dummy.has_state(Spell.STATE_TIME_MANIPULATION))
	_cast(combat, "horloge", dummy.cell)
	dummy.hp = 1
	_cast(combat, "tic", dummy.cell)
	assert_true(combat.glyphs.is_empty(), "la cible vaincue emporte son horloge")


func test_instantane() -> void:
	var combat := _fight([C])
	_cast(combat, "horloge", C)
	var saved: Dictionary = Protocol.decode(Protocol.encode({"type": "test", "combat": combat.snapshot()}))["combat"]
	assert_eq(saved["glyphes"].size(), 1)
	assert_eq(saved["glyphes"][0]["horloge"]["cible"], "m0")
	assert_eq(saved["glyphes"][0]["horloge"]["centre"], C, "le centre redevient une case")


func test_portee_fixe() -> void:
	var combat := _fight([C])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var spell := Spell.from_dict({"id": "x", "nom": "X", "cout_pa": 1, "portee": {"min": 3, "max": 3},
		"portee_fixe": true, "effets": [{"type": "degats", "element": "impie", "min": 1, "max": 1}]})
	player.range_bonus = 2
	assert_eq(combat.max_range(player, spell), 3, "le bonus de portée ne compte pas")
	assert_true(spell.mastered(3).fixed_range)


func test_validation() -> void:
	var base := {"id": "x", "nom": "X", "cout_pa": 1, "portee": {"min": 0, "max": 0}}
	var bad := base.duplicate()
	bad["effets"] = [{"type": "decalage_horaire", "heures": 0}]
	assert_false(Spell.validate(bad).is_empty(), "décalage nul")
	bad["effets"] = [{"type": "horloge", "duree": 2, "heures": {"13": []}}]
	assert_false(Spell.validate(bad).is_empty(), "heure 13")
	bad["effets"] = [{"type": "horloge", "duree": 2, "heures": {"1": [{"type": "decalage_horaire", "heures": 1}]}}]
	assert_false(Spell.validate(bad).is_empty(), "pas de décalage dans une heure")
	bad["effets"] = [{"type": "etat", "etat": "endormi", "duree": 1}]
	assert_false(Spell.validate(bad).is_empty(), "état inconnu")
	var good := base.duplicate()
	good["effets"] = [{"type": "horloge", "duree": 2, "heures": HOURS}]
	assert_true(Spell.validate(good).is_empty(), str(Spell.validate(good)))


func test_kit_du_chronomancien() -> void:
	var data := GameData.load_all()
	var voie: Dictionary = data.voies["chronomancien"]
	assert_eq(voie["sorts"].size(), 6)
	for spell_id: String in voie["sorts"]:
		assert_true(data.spells.has(spell_id), spell_id)
		for effect: Dictionary in (data.spells[spell_id] as Spell).effects:
			if effect.has("element"):
				assert_eq(effect["element"], "impie", "Voie Impie : " + spell_id)
	var horloge: Spell = data.spells["chronomancien_horloge"]
	assert_eq([horloge.range_min, horloge.range_max], [3, 3], "la 3e case")
	for spell_id: String in voie["sorts"]:
		if spell_id != "chronomancien_horloge":
			assert_true((data.spells[spell_id] as Spell).range_max >= 6, "atteint 11 h et 1 h : " + spell_id)
	assert_true(horloge.cast_in_line, "en ligne, sans diagonale")
	assert_true(horloge.fixed_range, "portée non modifiable")
	var clock: Dictionary = horloge.effects[1]
	assert_eq(clock["type"], Spell.EFFECT_CLOCK)
	assert_eq(clock["heures"].size(), 12, "les 12 heures")
	for hour in ["3", "4", "9"]:
		assert_true(clock["heures"][hour].is_empty(), "%s h : sans effet tant que tacle et esquive manquent" % hour)
	var shifts := []
	for spell_id: String in voie["sorts"]:
		for effect: Dictionary in (data.spells[spell_id] as Spell).effects:
			if effect["type"] == Spell.EFFECT_CLOCK_SHIFT:
				shifts.append(effect["heures"])
	shifts.sort()
	assert_eq(shifts, [-3, -1, 1, 3, 6])
