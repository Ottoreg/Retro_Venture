extends "res://tests/test_case.gd"
## Chronomancien (GDD § 4.3), sorts du 23/11/2026 : pulsions, retours à une case passée, envoi dans le futur, Écho du
## passé, Arrêt sur image, Rendez-vous, Cristal du temps (inamovible), Sursis, passif « Temps volé », rangs de maîtrise.
## Sorts tirés des données du jeu, sans coup critique.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


func _data() -> GameData:
	var spells := Fixtures.spells()
	var voie: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voies/chronomancien.json"))
	for spell_id: String in voie["sorts"]:
		var spell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sorts/%s.json" % spell_id))
		spell["critique"] = 0
		spells.append(spell)
	var races := [{"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test", "passif": {"nom": "Aucun", "effets": []}}]
	return GameData.from_dicts(spells, [Fixtures.monster("mannequin", 300, 6, 0, 10, ["frappe"])], [voie], races, Fixtures.items(), [], [])


## Le Chronomancien en C (rang + 1 du passif : `passive`) contre des mannequins immobiles.
func _fight(monsters: Array, passive := 0) -> Combat:
	var data := _data()
	var fighters: Array[Fighter] = []
	var player := data.create_player("chronomancien", Fixtures.PLAYER, "Testeur")
	player.cell = C
	player.passives["temps_vole"] = passive
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


func _cast(combat: Combat, spell_id: String, target: Vector2i) -> Array[Dictionary]:
	combat.get_fighter(Fixtures.PLAYER).pa = 20
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}))


func _end_turn(combat: Combat) -> Array[Dictionary]:
	return combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))


func test_pulsion() -> void:
	var combat := _fight([C + Vector2i(2, 0)])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "chronomancien_pulsion_temporelle", dummy.cell)
	assert_eq(dummy.manipulations, 1, "poser une pulsion est une manipulation")
	assert_eq(dummy.hp, 300, "rien tout de suite")
	_end_turn(combat)
	assert_eq(dummy.hp, 300, "rien à son 1er tour")
	_end_turn(combat)
	assert_true(dummy.hp < 300, "elle explose au début de son 2e tour")
	assert_false(dummy.states.any(func(state: Dictionary) -> bool: return state["type"] == Spell.EFFECT_PULSE), "puis disparaît")


func test_deja_vu_et_point_de_depart() -> void:
	var combat := _fight([C + Vector2i(3, 0)])
	var dummy := combat.get_fighter("m0")
	var player := combat.get_fighter(Fixtures.PLAYER)
	_end_turn(combat)
	dummy.cell = C + Vector2i(2, 2)  # Il a bougé pendant son tour.
	_cast(combat, "chronomancien_deja_vu", dummy.cell)
	assert_eq(dummy.cell, C + Vector2i(3, 0), "ramené à sa case du début de son tour")
	assert_eq(dummy.modifier("pm"), -1, "et −1 PM")
	player.cell = C + Vector2i(0, 2)
	_cast(combat, "chronomancien_point_de_depart", player.cell)
	assert_eq(player.cell, C, "Point de départ : retour à sa case du début du tour")


func test_saut_dans_le_futur() -> void:
	var combat := _fight([C + Vector2i(2, 0)])
	var dummy := combat.get_fighter("m0")
	var player := combat.get_fighter(Fixtures.PLAYER)
	var events: Array[Dictionary] = []
	combat._apply_effect(player, dummy, {"type": "poison", "element": "givre", "min": 5, "max": 5, "duree": 3}, events)
	combat._apply_effect(player, dummy, {"type": "bonus", "carac": "force", "min": 50, "max": 50, "duree": 2}, events)
	dummy._cooldowns["frappe"] = 3
	_cast(combat, "chronomancien_saut_dans_le_futur", dummy.cell)
	assert_eq(dummy.hp, 290, "2 tours de poison infligés d'un coup")
	assert_eq(dummy.states.filter(func(state: Dictionary) -> bool: return state["type"] == Spell.EFFECT_POISON)[0]["tours"], 1, "il en reste 1")
	assert_eq(dummy.modifier("force"), 0, "le bonus s'est écoulé")
	assert_eq(dummy.cooldown_of(dummy.get_spell("frappe")), 1, "ses relances baissent de 2")
	combat = _fight([C + Vector2i(2, 0)])
	dummy = combat.get_fighter("m0")
	dummy.boss = true
	combat._apply_effect(combat.get_fighter(Fixtures.PLAYER), dummy, {"type": "bonus", "carac": "force", "min": 50, "max": 50, "duree": 2}, events)
	dummy._cooldowns["frappe"] = 3
	_cast(combat, "chronomancien_saut_dans_le_futur", dummy.cell)
	assert_eq(dummy.modifier("force"), 50, "un boss garde ses bonus")
	assert_eq(dummy.cooldown_of(dummy.get_spell("frappe")), 3, "et ses relances")


func test_heure_d_avance() -> void:
	var combat := _fight([C + Vector2i(2, 0)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "chronomancien_rendez_vous", C + Vector2i(2, 0))
	assert_eq(player.cell, C + Vector2i(2, 0), "Rendez-vous : échange de place avec un ennemi")
	assert_eq(player.cooldown_of(player.get_spell("chronomancien_rendez_vous")), 2)
	_cast(combat, "chronomancien_heure_d_avance", player.cell)
	assert_eq(player.cooldown_of(player.get_spell("chronomancien_rendez_vous")), 1, "Heure d'avance : relances −1")


func test_echo_du_passe() -> void:
	var combat := _fight([C + Vector2i(2, 0)])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "chronomancien_echo_du_passe", dummy.cell)
	assert_eq(dummy.hp, 300, "sans manipulation, rien")
	combat = _fight([C + Vector2i(2, 0)])
	dummy = combat.get_fighter("m0")
	dummy.manipulations = 9
	_cast(combat, "chronomancien_echo_du_passe", dummy.cell)
	assert_true(dummy.hp <= 300 - 18 and dummy.hp >= 300 - 24 - 5, "3 à 4 par manipulation, 6 au plus")


func test_arret_sur_image() -> void:
	var combat := _fight([C + Vector2i(3, 0), C + Vector2i(0, 2)])
	var dummy := combat.get_fighter("m0")
	var events := _cast(combat, "chronomancien_arret_sur_image", C + Vector2i(0, 2))
	assert_eq(Fixtures.of_type(events, Protocol.EVT_REFUSED)[0]["raison"], Protocol.REASON_NO_CLOCK, "sans horloge : refusé")
	_cast(combat, "chronomancien_horloge", dummy.cell)
	assert_eq(dummy.manipulations, 1, "l'heure atteinte (12 h) est une manipulation")
	combat.clock_of(dummy)["horloge"]["heure"] = 12
	var pa_malus := func() -> int: return dummy.states.filter(func(state: Dictionary) -> bool: return state.get("carac") == "pa").size()
	var before: int = pa_malus.call()
	_cast(combat, "chronomancien_arret_sur_image", dummy.cell)
	assert_eq(pa_malus.call(), before + 1, "l'heure atteinte (12 h : −1 PA) rejoue son effet")
	assert_eq(dummy.manipulations, 1, "sans compter comme une manipulation")


func test_cristal_du_temps() -> void:
	var combat := _fight([C + Vector2i(2, 0)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	_cast(combat, "chronomancien_cristal_du_temps", C)
	assert_true(player.shield > 0 and player.has_state(Spell.STATE_STEADY))
	var events: Array[Dictionary] = []
	combat._push(dummy.cell, player, 2, false, events)
	assert_eq(player.cell, C, "inamovible : pas poussé")
	combat._apply_effect(player, dummy, {"type": "etat", "etat": "inamovible", "duree": 1, "min": 0, "max": 0}, events)
	events = _cast(combat, "chronomancien_rendez_vous", dummy.cell)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_REFUSED)[0]["raison"], Protocol.REASON_STEADY, "ni échangé")


func test_sursis() -> void:
	var combat := _fight([C + Vector2i(2, 0)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	player.hp = 400
	_cast(combat, "chronomancien_sursis", C)
	assert_eq(player.hp, 450, "rend 50 % des PV perdus depuis le début de son tour précédent")


func test_temps_vole() -> void:
	var combat := _fight([C + Vector2i(2, 0)], 2)
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	_cast(combat, "chronomancien_pulsion_temporelle", dummy.cell)
	_cast(combat, "chronomancien_pulsion_temporelle", dummy.cell)
	assert_eq(player.stacks(Combat.SECONDS), 2, "une seconde volée par manipulation d'un ennemi")
	assert_eq(combat.damage_bonus(player, dummy, {"type": "degats"}), 4, "+2 % par seconde au rang 1")
	combat = _fight([C + Vector2i(2, 0)], 4)
	player = combat.get_fighter(Fixtures.PLAYER)
	var events: Array[Dictionary] = []
	for i in 5:
		combat._manipulated(player, combat.get_fighter("m0"), events)
	assert_eq([player.pa_next, player.stacks(Combat.SECONDS)], [1, 0], "rang 3 : 5 secondes dépensées pour 1 PA")
	_end_turn(combat)
	assert_eq(player.pa, player.max_pa + 1, "au début de son prochain tour")


func test_rangs() -> void:
	var data := _data()
	assert_eq((data.spells["chronomancien_tic"] as Spell).mastered(3).casts_per_turn, 3, "Tic rang 3 : 3 fois par tour")
	assert_eq((data.spells["chronomancien_horloge"] as Spell).mastered(3).effect_of(Spell.EFFECT_CLOCK)["duree"], 4, "Horloge rang 3 : cadran 4 tours")
	assert_eq((data.spells["chronomancien_horloge"] as Spell).effect_of(Spell.EFFECT_CLOCK)["duree"], 3, "sans changer le sort de base")
	assert_eq((data.spells["chronomancien_horloge"] as Spell).mastered(5).range_max, 4, "rang 5 : 3 ou 4 cases")
	assert_true((data.spells["chronomancien_tic"] as Spell).mastered(5).effects.any(func(effect: Dictionary) -> bool: return effect.get("si_critique", false)),
		"Tic rang 5 : une heure de plus en coup critique")
