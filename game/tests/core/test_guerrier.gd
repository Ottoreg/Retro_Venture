extends "res://tests/test_case.gd"
## Guerrier (GDD § 4.3) : passif « Rancune », Prix du sang (coût en PV) et sorts de la Voie Impie, sorts Acier ajoutés.
## Sorts tirés des données du jeu, sans coup critique.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const RIGHT := Vector2i(1, 0)

var C := Fixtures.center()


func _data() -> GameData:
	var spells := Fixtures.spells()
	var voie: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voies/guerrier.json"))
	for spell_id: String in voie["sorts"]:
		var spell: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sorts/%s.json" % spell_id))
		spell["critique"] = 0
		spells.append(spell)
	var races := [{"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test", "passif": {"nom": "Aucun", "effets": []}}]
	return GameData.from_dicts(spells, [Fixtures.monster("mannequin", 200, 6, 0, 10, ["frappe"])], [voie], races, Fixtures.items(), [], [])


## Le Guerrier en C (100 PV, rang + 1 du passif : `passive`) contre des mannequins.
func _fight(monsters: Array, passive := 0) -> Combat:
	var data := _data()
	var fighters: Array[Fighter] = []
	var player := data.create_player("guerrier", Fixtures.PLAYER, "Testeur")
	player.cell = C
	player.passives["rancune"] = passive
	player.max_hp = 100
	player.hp = 100
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


func test_vingt_sorts_et_passif() -> void:
	var data := GameData.load_all()
	assert_eq(data.voies["guerrier"]["sorts"].size(), 20, "10 Acier + 10 Impie")
	assert_false(data.voies["guerrier"].has("sorts_rang_2"), "plus de sorts de rang II")
	assert_eq(data.voies["guerrier"]["passif"]["effet"], "rancune")
	assert_eq(data.spells["guerrier_serment_de_sang"].mastered(3).hp_cost, 12, "cout_pv au rang 3")
	assert_eq(data.spells["guerrier_lame_impie"].mastered(3).effects[0]["vol"], 40, "valeurs : champ d'effet changé")
	assert_eq(data.spells["guerrier_malediction"].mastered(5).effects[1]["duree"], 3)


func test_prix_du_sang() -> void:
	var combat := _fight([C + RIGHT])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var events := _cast(combat, "guerrier_serment_de_sang", C)
	assert_eq(player.hp, 85, "15 % des PV max payés")
	assert_eq(player.pa, 20 - 1 + 2, "+2 PA")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DAMAGE)[0]["source"], "Prix du sang")
	player.shield = 50
	_cast(combat, "guerrier_lame_impie", C + RIGHT)
	assert_eq(player.shield, 50, "le prix passe à travers le bouclier")
	player.hp = 3
	assert_eq(player.cast_blocker(player.get_spell("guerrier_lame_impie")), Protocol.REASON_NOT_ENOUGH_HP, "jamais mortel")


func test_rancune() -> void:
	var combat := _fight([C + RIGHT], 1)
	var player := combat.get_fighter(Fixtures.PLAYER)
	combat._hurt(player, 12, "acier", [])
	assert_eq(player.stacks(Fighter.RAGE), 2, "un cran par 5 PV perdus")
	assert_eq(player.rage_hp, 2, "le reste est gardé")
	combat._hurt(player, 40, "acier", [])
	assert_eq(player.stacks(Fighter.RAGE), 5, "5 crans au plus au rang 0")
	var dummy := combat.get_fighter("m0")
	var fendoir := player.get_spell("guerrier_fendoir")
	assert_eq(combat.damage_bonus(player, dummy, fendoir.effects[0]), 5 * (Fighter.RAGE_BONUS + 6), "+3 % par cran, +6 % de Fendoir")
	_cast(combat, "guerrier_fendoir", C + RIGHT)
	assert_eq(player.stacks(Fighter.RAGE), 0, "Fendoir dépense les crans")
	player.shield = 20
	combat._hurt(player, 20, "acier", [])
	assert_eq(player.stacks(Fighter.RAGE), 0, "avant le rang 3, un bouclier ne donne pas de Rancune")
	player.passives["rancune"] = 6
	player.shield = 20
	combat._hurt(player, 50, "acier", [])
	assert_eq(player.stacks(Fighter.RAGE), 10, "rang 5 : 10 crans, bouclier compris")
	assert_true(player.rage_crit, "au 10e cran, prochain coup de mêlée critique")
	var events := _cast(combat, "guerrier_frappe", C + RIGHT)
	assert_true(Fixtures.of_type(events, Protocol.EVT_SPELL_CAST)[0]["critique"])
	assert_false(player.rage_crit, "une seule fois")


func test_sorts_impie() -> void:
	var combat := _fight([C + RIGHT])
	var player := combat.get_fighter(Fixtures.PLAYER)
	var dummy := combat.get_fighter("m0")
	var rage := player.get_spell("guerrier_rage_du_damne").effects[0]
	player.hp = 50
	assert_eq(combat.damage_bonus(player, dummy, rage), 50, "+1 % par % de PV manquant")
	player.hp = 10
	assert_eq(combat.damage_bonus(player, dummy, rage), 60, "60 % au plus")
	player.hp = 100
	var execution := player.get_spell("guerrier_execution").effects[0]
	assert_eq(combat.damage_bonus(player, dummy, execution), 0)
	dummy.hp = 50
	assert_eq(combat.damage_bonus(player, dummy, execution), 30, "+30 % sous 30 % des PV")
	dummy.hp = 200
	player.hp = 80
	_cast(combat, "guerrier_lame_impie", C + RIGHT)
	assert_true(player.hp > 77, "Lame impie vole de la vie après en avoir payé 3")
	player.hp = 100
	player.hp_paid = 10
	_cast(combat, "guerrier_armure_de_sang", C)
	assert_eq(player.shield, 2 * (10 + 0), "bouclier de 2 × les PV payés ce tour (Armure de sang ne coûte rien)")
	_cast(combat, "guerrier_malediction", C + RIGHT)
	assert_eq(dummy.resistance("acier"), -15.0, "−15 % de résistance Acier")
	assert_eq(dummy.resistance("impie"), -15.0, "et Impie")


func test_sorts_acier_ajoutes() -> void:
	var combat := _fight([C + Vector2i(3, 0)])
	var dummy := combat.get_fighter("m0")
	_cast(combat, "guerrier_crochet", dummy.cell)
	assert_eq(dummy.cell, C + RIGHT, "Crochet attire jusqu'au contact")
	_cast(combat, "guerrier_recul_strategique", C + Vector2i(0, 3))
	assert_eq(combat.get_fighter(Fixtures.PLAYER).cell, C + Vector2i(0, 3), "Recul stratégique : saut sur une case libre")
