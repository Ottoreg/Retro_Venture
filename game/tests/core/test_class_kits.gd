extends "res://tests/test_case.gd"
## Mécaniques des Voies de l'alpha 1 : états élémentaires et « Créer un sort » (Arcaniste), charge
## (Guerrier), retrait des états (Théologue).

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


func _player(combat: Combat) -> Fighter:
	return combat.get_fighter(Fixtures.PLAYER)


func test_etats_elementaires() -> void:
	var combat := _fight([["mannequin", C + Vector2i(3, 0)]])
	var player := _player(combat)
	var events := _cast(combat, "braise", C)
	var states := Fixtures.of_type(events, Protocol.EVT_ELEMENT_STATES)
	assert_eq(states.size(), 1)
	assert_eq(states[0]["etats"], ["flamme"])
	assert_eq(player.pa, 6, "1 PA dépensé, 1 PA rendu")
	assert_eq(player.power("flamme"), Fighter.ELEMENT_STATE_BONUS, "+4 % de dégâts de Flamme par état")
	for i in 3:
		_cast(combat, "frimas", C)
	assert_eq(player.element_states, ["givre", "givre", "givre"] as Array[String], "3 au plus : le plus ancien part")
	assert_eq(player.power("flamme"), 0)
	assert_eq(player.power("givre"), 3 * Fighter.ELEMENT_STATE_BONUS)


func test_composition_des_etats() -> void:
	var combat := _fight([["mannequin", C + Vector2i(3, 0)]])
	var player := _player(combat)
	var composer := player.get_spell("composer")
	assert_eq(composer.state_choices(), PackedStringArray(["flamme+flamme+flamme", "flamme+flamme+givre",
		"flamme+givre+givre", "givre+givre+givre"]), "toutes les combinaisons, triées")
	assert_eq(Spell.combinations_of(["flamme", "givre", "tempete"]).size(), 10, "avec la Tempête : 10 combinaisons")
	assert_eq(_cast(combat, "composer", C)[0]["raison"], Protocol.REASON_INVALID_COMPOSITION, "sans combinaison")
	var odd := combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": "composer", "cible": C, "etats": "givre+flamme+flamme"}))
	assert_eq(odd[0]["raison"], Protocol.REASON_INVALID_COMPOSITION, "clé non triée")
	player.element_states = ["givre"] as Array[String]
	var events := combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": "composer", "cible": C, "etats": "flamme+flamme+givre"}))
	var states := Fixtures.of_type(events, Protocol.EVT_ELEMENT_STATES)
	assert_eq(states.size(), 1)
	assert_true(states[0]["composition"])
	assert_eq(player.element_states, ["flamme", "flamme", "givre"] as Array[String], "les 3 états remplacés d'un coup")
	assert_eq(player.pa, 6, "1 PA dépensé, 1 PA rendu")
	assert_eq(player.power("flamme"), 2 * Fighter.ELEMENT_STATE_BONUS)
	assert_eq(Fixtures.of_type(_cast(combat, "creer", C), Protocol.EVT_SPELL_CREATED)[0]["sort"], "fondu", "puis Créer un sort")
	combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": "composer", "cible": C, "etats": "givre+givre+givre"}))
	assert_eq(player.element_states, ["givre", "givre", "givre"] as Array[String], "relançable dans le tour")


func test_creer_un_sort() -> void:
	var combat := _fight([["mannequin", C + Vector2i(3, 0)]])
	var player := _player(combat)
	_cast(combat, "braise", C)
	var refused := _cast(combat, "creer", C)
	assert_eq(refused[0]["raison"], Protocol.REASON_NO_COMBINATION, "il faut 3 états")
	_cast(combat, "braise", C)
	_cast(combat, "frimas", C)
	var events := _cast(combat, "creer", C)
	var created := Fixtures.of_type(events, Protocol.EVT_SPELL_CREATED)
	assert_eq(created.size(), 1)
	assert_eq(created[0]["sort"], "fondu", "Flamme, Flamme, Givre (dans n'importe quel ordre)")
	assert_eq(created[0]["ancien"], "")
	assert_true(player.get_spell("fondu") != null, "le sort créé est dans la barre")
	var damage := Fixtures.of_type(_cast(combat, "fondu", C + Vector2i(3, 0)), Protocol.EVT_DAMAGE)
	assert_eq(damage[0]["valeur"], 11, "10 + 8 % (deux états Flamme)")
	assert_eq(_cast(combat, "creer", C)[0]["raison"], Protocol.REASON_SPELL_LIMIT, "une création par tour")
	# Deux places : un 2e sort créé s'ajoute, un 3e chasse le plus ancien.
	combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	for i in 3:
		_cast(combat, "frimas", C)
	_cast(combat, "creer", C)
	assert_eq(player.created_spells, ["fondu", "givrage"] as Array[String])
	assert_true(player.get_spell("fondu") != null and player.get_spell("givrage") != null, "deux sorts créés dans la barre")
	combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	for i in 3:
		_cast(combat, "braise", C)
	events = _cast(combat, "creer", C)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_SPELL_CREATED)[0]["ancien"], "fondu", "le plus ancien part")
	assert_eq(player.created_spells, ["givrage", "brasier"] as Array[String])
	assert_true(player.get_spell("fondu") == null)
	# Une combinaison sans sort : refusée.
	_cast(combat, "frimas", C)
	combat.execute(Fixtures.cmd(Protocol.CMD_END_TURN))
	assert_eq(player.element_states, ["flamme", "flamme", "givre"] as Array[String])
	player.element_states = ["flamme", "givre", "givre"] as Array[String]
	assert_eq(_cast(combat, "creer", C)[0]["raison"], Protocol.REASON_NO_COMBINATION)


func test_charge_jusqu_au_contact() -> void:
	var target := C + Vector2i(4, 0)
	var combat := _fight([["mannequin", target]])
	var events := _cast(combat, "charge", target)
	var charge := Fixtures.of_type(events, Protocol.EVT_CHARGED)[0]
	assert_eq(charge["case"], C + Vector2i(3, 0), "arrêt au contact")
	assert_true(charge["contact"])
	assert_eq(_player(combat).cell, C + Vector2i(3, 0))
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE)[0]["valeur"], 10)


func test_charge_arretee_par_un_obstacle() -> void:
	var target := C + Vector2i(4, 0)
	var combat := _fight([["mannequin", target]], {C + Vector2i(2, 0): "R"})
	var events := _cast(combat, "charge", target)
	var charge := Fixtures.of_type(events, Protocol.EVT_CHARGED)[0]
	assert_eq(charge["case"], C + RIGHT, "arrêt devant le rocher")
	assert_false(charge["contact"])
	assert_true(Fixtures.of_type(events, Protocol.EVT_DAMAGE).is_empty(), "pas de coup sans contact")


func test_charge_vers_une_case_libre() -> void:
	var combat := _fight([["mannequin", C + Vector2i(0, 4)]])
	_cast(combat, "charge", C + Vector2i(3, 0))
	assert_eq(_player(combat).cell, C + Vector2i(3, 0), "la charge sert aussi à se déplacer")
	assert_eq(_cast(combat, "charge", C + Vector2i(1, 1))[0]["raison"], Protocol.REASON_NOT_IN_LINE)


func test_retrait_des_etats() -> void:
	var combat := _fight([["mannequin", C + Vector2i(2, 0)]])
	var player := _player(combat)
	var dummy := combat.get_fighter("m0")
	dummy.states.append({"type": Spell.EFFECT_BONUS, "carac": "force", "valeur": 50, "tours": 3})
	dummy.states.append({"type": Spell.EFFECT_MALUS, "carac": "pm", "valeur": 1, "tours": 3})
	dummy.states.append({"type": Spell.EFFECT_BONUS, "carac": "pm", "valeur": 2, "tours": 3, "retirable": false})
	var events := _cast(combat, "absolution", dummy.cell)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_STATES)[0]["retires"], 1)
	assert_eq(dummy.states.size(), 2, "sur un ennemi : ses bonus retirables seulement")
	player.states.append({"type": Spell.EFFECT_POISON, "element": "acier", "valeur": 5, "tours": 3})
	player.states.append({"type": Spell.EFFECT_MALUS, "carac": "force", "valeur": 10, "tours": 3})
	player.states.append({"type": Spell.EFFECT_BONUS, "carac": "force", "valeur": 10, "tours": 3})
	_cast(combat, "absolution", C)
	assert_eq(player.states.size(), 1, "sur un allié : malus et poisons retirés, bonus gardé")
	player.add_element_state("flamme")
	_cast(combat, "absolution", C)
	assert_eq(player.element_states.size(), 1, "un état élémentaire ne se retire pas")


func test_les_effets_d_une_phase_ne_se_retirent_pas() -> void:
	var combat := _fight([["mannequin", C + Vector2i(2, 0)]])
	var dummy := combat.get_fighter("m0")
	dummy.phases.append({"pv": 90, "message": "Rage !", "sorts": [] as Array[Spell],
		"effets": Spell.normalized_effects([{"type": "bonus", "carac": "force", "min": 30, "max": 30, "duree": 3}])})
	var events: Array[Dictionary] = []
	combat._hurt(dummy, 10, "acier", events)
	assert_eq(dummy.states.size(), 1)
	_cast(combat, "absolution", dummy.cell)
	assert_eq(dummy.states.size(), 1, "le bonus de phase reste")


func test_l_ia_ne_compose_pas_et_charge_seulement_au_contact() -> void:
	var combat := _fight([["mannequin", C + Vector2i(4, 0)]], {C + Vector2i(2, 0): "R"})
	var player := _player(combat)
	var charge := player.get_spell("charge")
	assert_eq(CombatAI.evaluate(combat, player, charge, C + Vector2i(4, 0), C), 0.0, "charge arrêtée par le rocher")
	var composing: Array[Spell] = [player.get_spell("braise"), player.get_spell("composer"), player.get_spell("creer")]
	player.spells = composing
	assert_true(CombatAI.best_cast(combat, player, C).is_empty(), "états et création ignorés par l'IA")


func test_validation_des_nouveaux_effets() -> void:
	var base := {"id": "x", "nom": "X", "cout_pa": 1, "portee": {"min": 0, "max": 0}}
	var bad_state := base.duplicate()
	bad_state["effets"] = [{"type": "etat_elementaire", "element": "acier"}]
	assert_false(Spell.validate(bad_state).is_empty(), "état élémentaire d'Acier refusé")
	var bad_composition := base.duplicate()
	bad_composition["effets"] = [{"type": "composition_etats", "elements": ["flamme", "acier"]}]
	assert_false(Spell.validate(bad_composition).is_empty(), "composition avec de l'Acier refusée")
	bad_composition["effets"] = [{"type": "composition_etats", "elements": ["flamme", "flamme"]}]
	assert_false(Spell.validate(bad_composition).is_empty(), "élément en double")
	var bad_combo := base.duplicate()
	bad_combo["effets"] = [{"type": "creer_sort", "combinaisons": {"givre+flamme+flamme": "y"}}]
	assert_false(Spell.validate(bad_combo).is_empty(), "clé non triée")
	var bad_charge := base.duplicate()
	bad_charge["portee"] = {"min": 2, "max": 4}
	bad_charge["effets"] = [{"type": "charge"}]
	assert_false(Spell.validate(bad_charge).is_empty(), "charge sans lancer en ligne")
	var bad_removal := base.duplicate()
	bad_removal["effets"] = [{"type": "retrait_etats", "etats": ["bouclier"]}]
	assert_false(Spell.validate(bad_removal).is_empty())
	var in_trap := base.duplicate()
	in_trap["portee"] = {"min": 1, "max": 2}
	in_trap["effets"] = [{"type": "piege", "effets": [{"type": "charge"}]}]
	assert_false(Spell.validate(in_trap).is_empty(), "pas de charge dans un piège")
	# Combinaison vers un sort inconnu : le sort qui crée est écarté au chargement.
	var creator := base.duplicate()
	creator["effets"] = [{"type": "creer_sort", "combinaisons": {"flamme+flamme+flamme": "absent"}}]
	assert_true(Spell.validate(creator).is_empty())
	var data := GameData.from_dicts([creator], [], [])
	assert_false(data.spells.has("x"))


func test_kit_de_l_arcaniste_dans_les_donnees() -> void:
	var data := GameData.load_all()
	var create: Spell = data.spells["arcaniste_creer_un_sort"]
	var linked: Dictionary = create.create_effect()["sorts"]
	assert_eq(linked.size(), 4, "Flamme ×3, Givre ×3, Flamme ×2 + Givre, Givre ×2 + Flamme")
	for voie_id in ["arcaniste", "guerrier", "rodeur", "theologue"]:
		assert_eq(data.voies[voie_id]["sorts"].size(), 2 if voie_id == "arcaniste" else 5, voie_id)
	assert_eq(data.spells["arcaniste_creer_un_sort"].pa_cost, 2)
	assert_eq(data.voies["arcaniste"]["sorts"], ["arcaniste_composition", "arcaniste_creer_un_sort"],
		"un seul sort de composition à la place de Braise et Frimas")
	var choices: PackedStringArray = (data.spells["arcaniste_composition"] as Spell).state_choices()
	assert_eq(choices.size(), 4)
	for key in choices:
		assert_true(linked.has(key), "chaque combinaison proposée donne un sort : " + key)
	for created: Spell in linked.values():
		assert_eq(created.pa_cost, 4, "tous les sorts créés à 4 PA pendant l'alpha 1 (%s)" % created.id)
