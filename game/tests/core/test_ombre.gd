extends "res://tests/test_case.gd"
## Ombre (GDD § 4.3) : images rémanentes (Voie Tempête), invisibilité, armes d'obscurité, Dans le dos et Monde des
## ombres (Voie Acier), passif « Coup en traître ». Sorts tirés des données du jeu, sans coup critique.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


func _data() -> GameData:
	var spells := Fixtures.spells()
	var voie: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voies/ombre.json"))
	for spell_id: String in voie["sorts"]:
		var spell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sorts/%s.json" % spell_id))
		spell["critique"] = 0
		spells.append(spell)
	voie["sorts"].append("frappe")
	var races := [{"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test", "passif": {"nom": "Aucun", "effets": []}}]
	return GameData.from_dicts(spells, [Fixtures.monster("mannequin", 200, 6, 0, 10, ["frappe"])], [voie], races, Fixtures.items(), [], [])


## L'Ombre en C (rang du passif : `passive`, 0 sans passif) contre des mannequins immobiles.
func _fight(monsters: Array, passive := 0) -> Combat:
	var data := _data()
	var fighters: Array[Fighter] = []
	var player := data.create_player("ombre", Fixtures.PLAYER, "Testeur")
	player.cell = C
	player.passives["coup_en_traitre"] = passive
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


func test_images_remanentes() -> void:
	var combat := _fight([C + Vector2i(4, 0)])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "ombre_survoltage", C)
	assert_eq(combat.images.size(), 1, "Survoltage : une image sur sa case")
	assert_eq(combat.images[0]["case"], C)
	assert_eq(_cast(combat, "ombre_survoltage", C)[0]["raison"], Protocol.REASON_SPELL_LIMIT, "une fois par tour")
	_cast(combat, "ombre_pas_de_l_eclair", C + Vector2i(0, 2))
	assert_eq(combat.images.size(), 2, "un sort de mobilité laisse une image à son départ")
	assert_eq(combat.images[1]["case"], C)
	assert_eq(combat.fighter_at(C), null, "une image ne bloque rien")
	var hp := dummy.hp
	_cast(combat, "ombre_court_circuit", C)
	assert_eq(combat.images.size(), 0, "Court-circuit : les images empilées sur la case explosent")
	assert_eq(dummy.hp, hp, "trop loin pour être touché")


func test_foudroiement() -> void:
	# Une image posée au contact d'un ennemi explose tout de suite (croix d'une case, ennemis seulement).
	var combat := _fight([C + Vector2i(-2, 0)])
	combat.get_fighter(Fixtures.PLAYER).cell = C + Vector2i(-3, 0)
	var events := _cast(combat, "ombre_foudroiement", C + RIGHT)
	assert_eq(combat.get_fighter(Fixtures.PLAYER).cell, C + RIGHT, "Foudroiement traverse la ligne")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_IMAGE_ENDED).size(), 1, "l'image du départ, au contact, explose")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE).size(), 2, "dégâts du passage, puis de l'explosion")


func test_trois_images_au_plus_et_explosion_au_tour_suivant() -> void:
	var combat := _fight([C + Vector2i(-4, 0)])
	for target in [C + Vector2i(0, 1), C + Vector2i(0, 2), C + Vector2i(0, 3), C + Vector2i(1, 3)]:
		if target == C + Vector2i(1, 3):
			assert_eq(combat.images.size(), 3)
		_cast(combat, "ombre_pas_de_l_eclair", target)
		combat.get_fighter(Fixtures.PLAYER)._cooldowns.clear()
		combat.get_fighter(Fixtures.PLAYER)._casts_this_turn.clear()
	assert_eq(combat.images.size(), 3, "la 4e fait exploser la plus ancienne")
	assert_eq(combat.images[0]["case"], C + Vector2i(0, 1))
	var events := _end_turn(combat)
	assert_eq(combat.images.size(), 0, "restées un tour complet : elles explosent au début de son tour")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_IMAGE_ENDED).size(), 3)


func test_invisibilite() -> void:
	var combat := _fight([C + RIGHT], 1)
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	_cast(combat, "ombre_fondu_au_noir", C)
	assert_true(player.is_invisible())
	assert_true(combat.enemies_of(dummy).is_empty(), "l'adversaire ne la voit plus")
	assert_eq(combat.tackle_ratio(player, C), 1.0, "ni taclée ni tacleuse")
	assert_eq(Combat.damage_bonus(player, dummy, {"si_invisible": 25}), 31, "Surin +25 %, Coup en traître +6 %")
	_cast(combat, "ombre_arme_d_obscurite", C + RIGHT)
	assert_true(player.is_invisible(), "l'arme d'obscurité ne la révèle pas")
	_cast(combat, "ombre_surin", C + RIGHT)
	assert_false(player.is_invisible(), "un sort de dégâts la révèle")
	assert_eq(player.ambush, 1, "Coup en traître pendant le reste de son tour")
	assert_eq(player.last_seen, C)
	assert_eq(combat.enemies_of(dummy).size(), 1)


func test_coup_en_traitre_rangs_3_et_5() -> void:
	var combat := _fight([C + Vector2i(3, 0)], 6)
	var player := combat.get_fighter(Fixtures.PLAYER)
	_cast(combat, "ombre_fondu_au_noir", C)
	_cast(combat, "ombre_lame_de_jet", C + Vector2i(3, 0))
	assert_true(player.ambush_discount, "rang 3 : 1 PA de moins au prochain sort")
	assert_eq(player.spell_cost(combat.get_fighter(Fixtures.PLAYER).get_spell("ombre_surin")), 2)
	assert_eq(player.modifier("pm"), 1, "rang 5 : +1 PM à la sortie")
	player.pa = 10
	combat.execute(Fixtures.cmd(Protocol.CMD_CAST, {"sort": "ombre_lame_de_jet", "cible": C + Vector2i(3, 0)}))
	assert_eq(player.pa, 8, "le PA de moins ne sert qu'une fois")


func test_arme_d_obscurite_et_dans_le_dos() -> void:
	var combat := _fight([C + Vector2i(2, 0)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	player.cell = C + Vector2i(-4, 0)
	assert_eq(_cast(combat, "ombre_dans_le_dos", dummy.cell)[0]["raison"], Protocol.REASON_OUT_OF_RANGE)
	player.cell = C + Vector2i(-2, 0)
	_cast(combat, "ombre_arme_d_obscurite", dummy.cell)
	player._casts_this_turn.clear()
	_cast(combat, "ombre_arme_d_obscurite", dummy.cell)
	player.cell = C + Vector2i(-4, 0)
	assert_true(combat.marked_by(dummy, player))
	_cast(combat, "ombre_dans_le_dos", dummy.cell)
	assert_eq(player.cell, C + Vector2i(3, 0), "portée 7 sur un ennemi marqué : derrière lui")
	var hp := dummy.hp
	_end_turn(combat)
	assert_true(dummy.hp < hp, "l'arme frappe au début de son tour")
	assert_false(combat.marked_by(dummy, player), "puis disparaît")


func test_cumul_et_execution() -> void:
	var combat := _fight([C + RIGHT])
	var dummy := combat.get_fighter("m0")
	for i in 4:
		_cast(combat, "ombre_entaille", C + RIGHT)
		combat.get_fighter(Fixtures.PLAYER)._casts_this_turn.clear()
	assert_eq(dummy.modifier("resistance", "acier"), -30, "Entaille cumulable 3 fois")
	assert_eq(Combat.damage_bonus(combat.get_fighter(Fixtures.PLAYER), dummy, {"par_malus": 5}), 15, "Exécution : +5 % par malus")


func test_monde_des_ombres() -> void:
	var combat := _fight([C + Vector2i(2, 0), C + Vector2i(0, 3)])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	var events := _cast(combat, "ombre_monde_des_ombres", C + Vector2i(2, 0))
	assert_true(dummy.shadow, "envoyé dans les ombres")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DIMENSION).size(), 1)
	assert_eq(combat.fighter_at(C + Vector2i(2, 0)), null, "plus là pour la dimension de l'Ombre")
	assert_eq(player.cooldown_of(player.get_spell("ombre_monde_des_ombres")), 2, "sur un ennemi : relance dans 2 tours")
	assert_eq(combat.enemies_of(dummy).size(), 0, "il ne voit personne")
	assert_eq(combat.hunt_cells(dummy).size(), 3, "dernière ombre projetée de l'Ombre, lueurs des combattants du dehors")
	_end_turn(combat)
	assert_false(dummy.shadow, "sans Ombre dans la dimension : dehors au bout d'un tour")
	assert_true(dummy.has_state(Spell.STATE_NO_RETURN), "retour impossible")
	player._cooldowns.clear()
	assert_eq(_cast(combat, "ombre_monde_des_ombres", C)[0]["type"], Protocol.EVT_SPELL_CAST, "sur elle-même")
	assert_true(player.shadow)
	# Sortie sur une case occupée dehors : échange de place.
	var other := combat.get_fighter("m1")
	player.cell = other.cell
	player._casts_this_turn.clear()
	_cast(combat, "ombre_monde_des_ombres", player.cell)
	assert_false(player.shadow)
	assert_true(other.shadow, "l'occupant de la case est aspiré dans les ombres")
	assert_true(other.has_state(Spell.STATE_DRAWN))
	assert_true(player.has_state(Spell.STATE_NO_RETURN))
	assert_eq(combat.state, Combat.State.FIGHTING)


func test_passif_debloque_a_apprenti() -> void:
	var data := _data()
	assert_false("ombre_coup_en_traitre" in data.masterable_spells("ombre", 0))
	assert_true("ombre_coup_en_traitre" in data.masterable_spells("ombre", 1000), "palier Apprenti")
	assert_eq(data.voies["ombre"]["sorts"].size(), 21, "20 sorts (et la frappe de test)")
