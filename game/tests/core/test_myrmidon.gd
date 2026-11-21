extends "res://tests/test_case.gd"
## Myrmidon (GDD § 4.3) : Blindage et terrain démoli (Voie Acier), Gelures, assommer et eau gelée (Voie Givre), provocation
## (Défi, passif « Point de mire »), Garde et Carapace de glace. Sorts tirés des données du jeu, sans coup critique.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


func _data() -> GameData:
	var spells := Fixtures.spells()
	var voie: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voies/myrmidon.json"))
	for spell_id: String in voie["sorts"]:
		var spell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sorts/%s.json" % spell_id))
		spell["critique"] = 0
		spells.append(spell)
	var races := [{"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test", "passif": {"nom": "Aucun", "effets": []}}]
	return GameData.from_dicts(spells, [Fixtures.monster("mannequin", 200, 6, 0, 10, ["frappe"]), Fixtures.monster("coureur", 200, 0, 3, 10, ["frappe"])],
		[voie], races, Fixtures.items(), [], [])


## Le Myrmidon en C (rang + 1 du passif : `passive`) contre des monstres (`kind`), sur une carte changée par `changes`.
func _fight(monsters: Array, kind := "mannequin", changes := {}, passive := 0) -> Combat:
	var data := _data()
	var fighters: Array[Fighter] = []
	var player := data.create_player("myrmidon", Fixtures.PLAYER, "Testeur")
	player.cell = C
	player.passives["point_de_mire"] = passive
	player.max_hp = 500
	player.hp = 500
	fighters.append(player)
	for i in monsters.size():
		var monster := data.create_monster(kind, "m%d" % i)
		monster.cell = monsters[i]
		fighters.append(monster)
	var placement: Array[Vector2i] = [C]
	var combat := Combat.new(Fixtures.map(changes), fighters, placement, 1)
	combat.start()
	combat.execute(Fixtures.cmd(Protocol.CMD_READY))
	return combat


func _cast(combat: Combat, spell_id: String, target: Vector2i) -> Array[Dictionary]:
	combat.get_fighter(Fixtures.PLAYER).pa = 20
	return combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": spell_id, "cible": target}))


func _end_turn(combat: Combat) -> Array[Dictionary]:
	return combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))


func test_blindage() -> void:
	var combat := _fight([C + RIGHT])
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "myrmidon_coup_de_bouclier", C + RIGHT)
	assert_eq(player.stacks(Spell.EFFECT_ARMOR), 1, "un sort de dégâts Acier donne un cran")
	_cast(combat, "myrmidon_serrer_les_rangs", C)
	assert_eq(player.stacks(Spell.EFFECT_ARMOR), 3, "Serrer les rangs : +2 crans")
	assert_eq(player.resistance("acier"), 12.0, "+4 % de résistance par cran")
	assert_eq(player.resistance("impie"), 12.0, "à tous les éléments")
	_cast(combat, "myrmidon_ecrasement", C + RIGHT)
	_cast(combat, "myrmidon_coup_d_epaule", C + RIGHT)
	_cast(combat, "myrmidon_bouclier_lance", C + Vector2i(3, 0))
	assert_eq(player.stacks(Spell.EFFECT_ARMOR), Fighter.ARMOR_MAX, "5 crans au plus")
	var dummy := combat.get_fighter("m0")
	dummy.cell = C + RIGHT
	assert_eq(combat.damage_bonus(player, dummy, combat.get_fighter(Fixtures.PLAYER).get_spell("myrmidon_retour_a_l_envoyeur").effects[0]), 100,
		"Retour à l'envoyeur : +20 % par cran")
	_cast(combat, "myrmidon_retour_a_l_envoyeur", C + RIGHT)
	assert_eq(player.stacks(Spell.EFFECT_ARMOR), 0, "les crans sont dépensés")


func test_gelures_et_gel() -> void:
	var combat := _fight([C + Vector2i(2, 0)], "coureur")
	var runner := combat.get_fighter("m0")
	_cast(combat, "myrmidon_morsure_du_froid", C + Vector2i(2, 0))
	assert_eq(runner.stacks(Spell.EFFECT_FROSTBITE), 1)
	var events := _end_turn(combat)
	var removals := Fixtures.of_type(events, Protocol.EVT_STATUS).filter(func(event: Dictionary) -> bool: return event["effet"] == Spell.EFFECT_REMOVE_PM)
	assert_eq(removals.size(), 1, "au début de son tour, il perd 1 PM par Gelure")
	assert_eq(removals[0]["pm"], 2)
	runner.cell = C + Vector2i(2, 0)
	for spell_id in ["myrmidon_morsure_du_froid", "myrmidon_entrave"]:
		_cast(combat, spell_id, runner.cell)
	assert_eq(runner.stacks(Spell.EFFECT_FROSTBITE), Combat.FROST_MAX, "3 Gelures au plus")
	events = _end_turn(combat)
	assert_true(Fixtures.of_type(events, Protocol.EVT_STATUS).any(func(event: Dictionary) -> bool: return event["effet"] == "gele"), "à 3 Gelures, il est gelé")
	assert_eq(runner.stacks(Spell.EFFECT_FROSTBITE), 0, "puis elles tombent")


func test_bris_de_glace() -> void:
	var combat := _fight([C + RIGHT])
	var dummy := combat.get_fighter("m0")
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "myrmidon_morsure_du_froid", C + RIGHT)
	_cast(combat, "myrmidon_coup_glace", C + RIGHT)
	assert_eq(combat.damage_bonus(player, dummy, player.get_spell("myrmidon_bris_de_glace").effects[0]), 50, "+25 % par Gelure")
	_cast(combat, "myrmidon_bris_de_glace", C + RIGHT)
	assert_eq(dummy.stacks(Spell.EFFECT_FROSTBITE), 0, "les Gelures tombent")


func test_assommer() -> void:
	var combat := _fight([C + RIGHT])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "myrmidon_coup_sur_le_casque", C + RIGHT)
	assert_true(dummy.has_state(Spell.STATE_STUNNED))
	var hp := combat.get_fighter(Fixtures.PLAYER).hp
	var events := _end_turn(combat)
	assert_true(Fixtures.of_type(events, Protocol.EVT_TURN_ENDED).any(func(event: Dictionary) -> bool: return event.get("assomme", false)), "il passe son tour")
	assert_eq(combat.get_fighter(Fixtures.PLAYER).hp, hp, "sans frapper")
	combat._apply_effect(combat.get_fighter(Fixtures.PLAYER), dummy, {"type": "etat", "etat": "assomme", "duree": 1, "min": 0, "max": 0}, events)
	assert_false(dummy.has_state(Spell.STATE_STUNNED), "une fois par ennemi et par combat")
	combat = _fight([C + RIGHT])
	combat.get_fighter("m0").boss = true
	_cast(combat, "myrmidon_coup_sur_le_casque", C + RIGHT)
	assert_false(combat.get_fighter("m0").has_state(Spell.STATE_STUNNED), "un boss n'est pas assommé")
	assert_eq(combat.get_fighter("m0").next_turn_pa(), 3, "il perd 3 PA à la place")


func test_demolition_et_belier() -> void:
	var rock := C + Vector2i(2, 0)
	var combat := _fight([C + Vector2i(4, 0)], "mannequin", {rock: "R"})
	assert_eq(_cast(combat, "myrmidon_demolition", C + Vector2i(1, 1))[0]["raison"], Protocol.REASON_NOT_DEMOLISHABLE, "rien à démolir")
	assert_false(combat.walkable(rock))
	var events := _cast(combat, "myrmidon_demolition", rock)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_TERRAIN).size(), 1)
	assert_true(combat.walkable(rock), "le rocher est démoli pour le combat")
	assert_true(Combat.from_snapshot(combat.snapshot(), combat.map, _data(), {}) != null)
	assert_true(combat.map.obstacles.has(rock), "la carte, elle, ne change pas")
	combat = _fight([C + Vector2i(4, 0)], "mannequin", {rock: "A"})
	_cast(combat, "myrmidon_belier", C + Vector2i(4, 0))
	assert_eq(combat.get_fighter(Fixtures.PLAYER).cell, C + Vector2i(3, 0), "le Bélier renverse l'arbre et arrive au contact")
	assert_true(combat.walkable(rock))


func test_glissade_et_degel() -> void:
	var combat := _fight([C + Vector2i(3, 0)], "mannequin", {C + RIGHT: "E", C + Vector2i(2, 0): "E"})
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "myrmidon_glissade", C + Vector2i(3, 0))
	assert_eq(player.cell, C + Vector2i(2, 0), "il glisse sur l'eau gelée jusqu'au contact")
	assert_eq(combat.terrain[C + RIGHT]["etat"], "gel")
	for i in Combat.FREEZE_TURNS:
		_end_turn(combat)
	assert_false(combat.terrain.has(C + Vector2i(2, 0)), "l'eau dégèle au bout de 3 tours")
	assert_true(combat.walkable(player.cell) and player.cell != C + Vector2i(2, 0), "il est mis au sec")


func test_provocation() -> void:
	var combat := _fight([C + Vector2i(2, 0)], "mannequin", {}, 1)
	var dummy := combat.get_fighter("m0")
	var player := combat.get_fighter(Fixtures.PLAYER)
	var ally := _data().create_player("myrmidon", "allie", "Allié")
	ally.cell = C + Vector2i(0, 3)
	combat.fighters.append(ally)
	combat._provoke(player, dummy, 2, "Défi", [] as Array[Dictionary])
	assert_eq(combat.provoker_id(dummy), player.id)
	assert_eq(combat.provoker_for_ai(dummy), player, "son IA vise le Myrmidon")
	assert_eq(combat.damage_bonus(dummy, ally, {}), -20, "−20 % contre tout autre")
	assert_eq(combat.damage_bonus(dummy, player, {}), 0, "rien contre lui")
	dummy.boss = true
	combat._provoke(player, dummy, 2, "Défi", [] as Array[Dictionary])
	assert_eq(combat.damage_bonus(dummy, ally, {}), -10, "moitié moins pour un boss")
	assert_eq(combat.provoker_for_ai(dummy), null, "qui reste libre")


func test_point_de_mire() -> void:
	var combat := _fight([C + Vector2i(2, 0), C + Vector2i(0, 4)], "mannequin", {}, 6)
	var provoked := Fixtures.of_type(_end_turn(combat), Protocol.EVT_STATES).filter(func(event: Dictionary) -> bool:
		return event.has("nouveau") and event["nouveau"]["etat"] == Spell.STATE_PROVOKED)
	assert_eq(provoked.size(), 1, "l'aura provoque un ennemi qui y commence son tour, pas un plus loin (3 cases au rang 3)")
	assert_eq(provoked[0]["entite"], "m0")
	assert_eq(provoked[0]["nouveau"]["valeur"], 30, "20 % + 2 % par rang")
	# Rang 5 : contrecoup de 10 % quand un provoqué le frappe au contact.
	var dummy := combat.get_fighter("m0")
	dummy.cell = C + RIGHT
	combat._provoke(combat.get_fighter(Fixtures.PLAYER), dummy, 1, "Point de mire", [] as Array[Dictionary])
	var hp := dummy.hp
	var events: Array[Dictionary] = []
	combat._apply_effect(dummy, combat.get_fighter(Fixtures.PLAYER), {"type": "degats", "element": "acier", "min": 20, "max": 20}, events)
	assert_true(dummy.hp < hp, "contrecoup")


func test_garde_et_carapace() -> void:
	var combat := _fight([C + RIGHT])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var ally := _data().create_player("myrmidon", "allie", "Allié")
	ally.cell = C + Vector2i(0, 2)
	combat.fighters.append(ally)
	_cast(combat, "myrmidon_garde", ally.cell)
	assert_true(ally.has_state(Spell.STATE_GUARDED))
	var events: Array[Dictionary] = []
	combat._apply_effect(combat.get_fighter("m0"), ally, {"type": "degats", "element": "acier", "min": 20, "max": 20}, events)
	assert_eq(ally.max_hp - ally.hp, 10, "la moitié des dégâts pour l'allié")
	assert_eq(player.max_hp - player.hp, 10, "l'autre moitié pour le Myrmidon")
	_cast(combat, "myrmidon_carapace_de_glace", C)
	assert_true(player.shield > 0)
	_end_turn(combat)  # Le mannequin au contact le frappe.
	assert_eq(combat.get_fighter("m0").stacks(Spell.EFFECT_FROSTBITE), 2, "qui le frappe au contact prend une Gelure (deux coups : deux Gelures)")
