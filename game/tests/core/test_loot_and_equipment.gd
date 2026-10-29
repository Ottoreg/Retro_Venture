extends "res://tests/test_case.gd"
## Butin de fin de combat, équipement porté, arme, kit de départ, initiative, XP en cas de défaite.

const Fixtures := preload("res://tests/helpers/fixtures.gd")


func _world(monsters: Array = ["mannequin"]) -> World:
	var map := Fixtures.map({Fixtures.center(): "1"}, [{"monstres": monsters}])
	return World.new(map, Fixtures.data(), Callable(), Fixtures.character())


func _engage(world: World) -> void:
	world.execute({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": "groupe_1"})


func _stick(world: World, monster_id: String) -> Fighter:
	var monster := world.combat.get_fighter(monster_id)
	var player := world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	return monster


func _command(world: World, type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra, true)
	return world.execute(command)


func _uid_of(world: World, item_id: String) -> String:
	for entry: Dictionary in world.character.inventory.entries.values():
		if entry["objet"] == item_id:
			return entry["uid"]
	return ""


func test_butin_de_victoire() -> void:
	var world := _world()
	_engage(world)
	var monster := _stick(world, "groupe_1_1")
	monster.hp = 1
	_command(world, Protocol.CMD_READY)
	var events := _command(world, Protocol.CMD_CAST, {"sort": "frappe", "cible": monster.cell})
	var ended := Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]
	var names := []
	for drop: Dictionary in ended["butin"]:
		names.append(drop["objet"])
	assert_true("dent" in names and "bague" in names, "butin garanti")
	assert_eq(ended["ecus"], 3)
	assert_eq(world.character.inventory.quantity_of("dent"), 2)
	assert_eq(world.character.inventory.ecus, 3)
	assert_eq(Fixtures.of_type(events, Protocol.EVT_INVENTORY).size(), 1)


func test_la_prospection_augmente_les_chances() -> void:
	# Trésor à 1 % : avec 10 000 de prospection, la chance est de 1 % × 100 = 100 %.
	var world := _world()
	var boots := world.character.inventory.add(world.data.items["bottes"], 1, {"prospection": 9900})
	world.character.inventory.equip(boots, "bottes")
	assert_eq(world.character.prospection(world.data), 10000)
	_engage(world)
	var monster := _stick(world, "groupe_1_1")
	monster.hp = 1
	_command(world, Protocol.CMD_READY)
	var events := _command(world, Protocol.CMD_CAST, {"sort": "frappe", "cible": monster.cell})
	assert_eq(world.character.inventory.quantity_of("tresor"), 1, "trésor garanti avec beaucoup de prospection")
	assert_true(Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]["butin"].size() >= 3)


func test_pas_de_butin_en_cas_de_defaite_mais_la_reputation_des_vaincus() -> void:
	var world := _world(["mannequin", "loup"])
	_engage(world)
	var dummy := _stick(world, "groupe_1_1")
	dummy.hp = 1
	var wolf := world.combat.get_fighter("groupe_1_2")
	var combat := world.combat
	var player := world.combat.get_fighter(World.PLAYER_ID)
	player.hp = 1
	_command(world, Protocol.CMD_READY)
	_command(world, Protocol.CMD_CAST, {"sort": "frappe", "cible": dummy.cell})
	# Le loup vient au contact et achève le joueur.
	wolf.cell = dummy.cell
	var events := _command(world, Protocol.CMD_END_TURN)
	var ended := Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]
	assert_eq(ended["vainqueur"], Fighter.TEAM_MONSTERS)
	# La Frappe sur le mannequin et sa part du monstre vaincu comptent, même en cas de défaite.
	var factor := Progression.difficulty([1, wolf.level], [1])
	var expected: int = Progression.gains(combat.practice[World.PLAYER_ID], factor,
		10 * Progression.KILL_SHARE * factor)["reputation"]
	assert_true(expected > 0)
	assert_eq(ended["reputation"], expected, "la pratique et le mannequin vaincu, en réputation")
	assert_eq(world.character.reputation(), expected)
	assert_false(ended.has("butin"), "pas de butin en cas de défaite")
	assert_eq(world.character.inventory.quantity_of("dent"), 0)


func test_equiper_et_retirer() -> void:
	var world := _world()
	var data := world.data
	var force_before := world.character.stat("force", data)
	var ring := world.character.inventory.add(data.items["bague"], 1, {"force": 5})
	var events := _command(world, Protocol.CMD_EQUIP, {"objet": ring})
	assert_eq(events[0]["type"], Protocol.EVT_INVENTORY)
	assert_eq(events[1]["type"], Protocol.EVT_CHARACTER)
	assert_eq(world.character.stat("force", data), force_before + 5)
	assert_eq(world.character.inventory.slot_of(ring), "anneau_1")
	var unequip := _command(world, Protocol.CMD_UNEQUIP, {"emplacement": "anneau_1"})
	assert_eq(unequip[0]["type"], Protocol.EVT_INVENTORY)
	assert_eq(world.character.stat("force", data), force_before)
	assert_eq(_command(world, Protocol.CMD_UNEQUIP, {"emplacement": "anneau_1"})[0]["raison"], Protocol.REASON_EMPTY_SLOT)


func test_aucune_condition_d_equipement() -> void:
	# Ni niveau ni caractéristique requis (GDD § 4.5) : seule la difficulté d'obtention compte.
	var world := _world()
	var data := world.data
	var helmet := world.character.inventory.add(data.items["heaume"], 1, {"vitalite": 10})
	assert_eq(_command(world, Protocol.CMD_EQUIP, {"objet": helmet})[0]["type"], Protocol.EVT_INVENTORY, "ancien niveau 3 requis")
	var cloak := world.character.inventory.add(data.items["lourd"], 1, {})
	assert_eq(_command(world, Protocol.CMD_EQUIP, {"objet": cloak})[0]["type"], Protocol.EVT_INVENTORY, "ancienne Force 60 requise")
	var tooth := world.character.inventory.add(data.items["dent"], 1)
	assert_eq(_command(world, Protocol.CMD_EQUIP, {"objet": tooth})[0]["raison"], Protocol.REASON_NOT_EQUIPPABLE)
	assert_eq(_command(world, Protocol.CMD_EQUIP, {"objet": "o999"})[0]["raison"], Protocol.REASON_UNKNOWN_ITEM)


func test_deux_anneaux_identiques_interdits() -> void:
	var world := _world()
	var data := world.data
	var first := world.character.inventory.add(data.items["bague"], 1, {"force": 5})
	var second := world.character.inventory.add(data.items["bague"], 1, {"force": 5})
	_command(world, Protocol.CMD_EQUIP, {"objet": first})
	assert_eq(_command(world, Protocol.CMD_EQUIP, {"objet": second, "emplacement": "anneau_2"})[0]["raison"], Protocol.REASON_ALREADY_WORN)


func test_double_clic_remplace_l_exemplaire_identique_porte() -> void:
	var world := _world()
	var data := world.data
	var inventory := world.character.inventory
	var first := inventory.add(data.items["bague"], 1, {"force": 3})
	var second := inventory.add(data.items["bague"], 1, {"force": 5})
	_command(world, Protocol.CMD_EQUIP, {"objet": first})
	var slot := inventory.slot_of(first)
	assert_eq(_command(world, Protocol.CMD_EQUIP, {"objet": second})[0]["type"], Protocol.EVT_INVENTORY)
	assert_eq(inventory.slot_of(second), slot, "le nouvel exemplaire prend la place de l'ancien")
	assert_eq(inventory.slot_of(first), "", "l'ancien retourne dans le sac")
	assert_eq(inventory.equipped.size(), 1)


func test_jeter() -> void:
	var world := _world()
	world.character.inventory.add(world.data.items["dent"], 5)
	_command(world, Protocol.CMD_DROP, {"objet": "dent", "quantite": 2})
	assert_eq(world.character.inventory.quantity_of("dent"), 3)
	assert_eq(_command(world, Protocol.CMD_DROP, {"objet": "dent", "quantite": 9})[0]["raison"], Protocol.REASON_UNKNOWN_ITEM)


func test_equipement_en_combat() -> void:
	var data := Fixtures.data()
	var hero := Fixtures.character()
	var boots := hero.inventory.add(data.items["bottes"], 1, {"pa": 1, "pm": 1, "portee": 1, "initiative": 10, "prospection": 50})
	hero.inventory.equip(boots, "bottes")
	var sword := hero.inventory.add(data.items["epee"], 1, {"force": 2})
	hero.inventory.equip(sword, "arme")
	var fighter := data.create_character_fighter(hero, "joueur")
	assert_eq(fighter.max_pa, 7)
	assert_eq(fighter.max_pm, 4)
	assert_eq(fighter.range_bonus, 2, "passif de race + bottes")
	assert_eq(fighter.initiative, 100 + 52 + 10, "base + Force (50 + 2) + bonus d'initiative")
	assert_eq(fighter.prospection, 150)
	assert_eq(fighter.spells[0].id, "arme", "l'attaque de l'arme en premier")
	assert_eq(fighter.spells[0].display_name, "Épée")


func test_initiative_avec_toutes_les_caracteristiques_offensives() -> void:
	var data := Fixtures.data()
	var hero := Fixtures.character()
	for stat_name in ["force", "intelligence", "perception", "agilite", "vitalite"]:
		hero.gain_stat(stat_name, 5)
	var fighter := data.create_character_fighter(hero, "joueur")
	assert_eq(fighter.initiative, 100 + (50 + 5) + 5 + 5 + 5, "Force, Intelligence, Perception, Agilité ; pas la Vitalité")


func test_kit_de_depart() -> void:
	var data := Fixtures.data()
	var hero := Fixtures.character()
	data.give_starting_kit(hero)
	assert_eq(hero.inventory.ecus, GameData.STARTING_ECUS)
	assert_eq(hero.inventory.equipped_entry("arme")["objet"], "epee")
	assert_eq(hero.inventory.equipped_entry("anneau_1")["objet"], "bague")


func test_sauvegarde_avec_inventaire() -> void:
	var world := _world()
	world.data.give_starting_kit(world.character)
	world.character.inventory.add(world.data.items["dent"], 7)
	var save: Variant = JSON.parse_string(JSON.stringify(world.save_data()))
	var loader := func(_id: String) -> GameMap: return world.map
	var restored := World.from_save(save, world.data, loader)
	assert_eq(restored.character.inventory.quantity_of("dent"), 7)
	assert_eq(restored.character.inventory.equipped_entry("arme")["objet"], "epee")
	assert_eq(restored.character.inventory.ecus, GameData.STARTING_ECUS)


func test_butin_regroupe_par_objet() -> void:
	var found := [
		{"objet": "croc", "nom": "Croc", "rarete": "commun", "quantite": 1},
		{"objet": "peau", "nom": "Peau", "rarete": "commun", "quantite": 1},
		{"objet": "croc", "nom": "Croc", "rarete": "commun", "quantite": 2},
	]
	var merged := World._merged_loot(found)
	assert_eq(merged.size(), 2, "une ligne par objet")
	assert_eq(merged[0]["objet"], "croc")
	assert_eq(merged[0]["quantite"], 3, "1 croc + 2 crocs")
	assert_eq(merged[1]["objet"], "peau")
	assert_eq(found[0]["quantite"], 1, "la liste d'origine n'est pas modifiée")


func test_sac_plein_le_butin_entre_en_surplus_et_bloque_les_combats() -> void:
	var map := Fixtures.map({Fixtures.center(): "1", Fixtures.center() + Vector2i(0, 3): "2"},
		[{"monstres": ["mannequin"]}, {"monstres": ["mannequin"]}])
	var world := World.new(map, Fixtures.data(), Callable(), Fixtures.character())
	var inventory := world.character.inventory
	inventory.capacity = inventory.entries.size()  # Sac plein.
	assert_true(inventory.is_full())
	assert_false(inventory.is_overloaded())
	_engage(world)
	var monster := _stick(world, "groupe_1_1")
	monster.hp = 1
	_command(world, Protocol.CMD_READY)
	var events := _command(world, Protocol.CMD_CAST, {"sort": "frappe", "cible": monster.cell})
	var ended := Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]
	assert_eq(inventory.quantity_of("dent"), 2, "rien n'est perdu : le butin entre en surplus")
	assert_eq(inventory.quantity_of("bague"), 1)
	assert_true(inventory.is_overloaded(), "le sac déborde")
	assert_true(ended["surcharge"], "la fin de combat le signale")
	for drop: Dictionary in ended["butin"]:
		assert_false(drop.has("perdu"))

	# Pas de nouveau combat tant que le sac déborde.
	var refused := _command(world, Protocol.CMD_ENGAGE, {"groupe": "groupe_2"})
	assert_eq(refused[0]["type"], Protocol.EVT_REFUSED)
	assert_eq(refused[0]["raison"], Protocol.REASON_INVENTORY_OVERLOADED)
	assert_false(world.in_combat())
	# On jette ce qu'il faut : le combat redevient possible.
	for item_id: String in ["dent", "bague"]:
		for entry: Dictionary in inventory.entries.values():
			if entry["objet"] == item_id:
				_command(world, Protocol.CMD_DROP, {"objet": entry["uid"], "quantite": int(entry["quantite"])})
				break
	assert_false(inventory.is_overloaded())
	_command(world, Protocol.CMD_ENGAGE, {"groupe": "groupe_2"})
	assert_true(world.in_combat(), "place faite : on peut combattre")


func test_limite_de_butin_par_monstre_partagee_entre_joueurs() -> void:
	var wolf := {"butin": [{"objet": "croc", "taux": 1.0, "quantite": [1, 2]}]}
	for seed_value in 50:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var loot := Loot.roll([wolf], {"a": 100, "b": 100, "c": 100}, rng)
		var total := 0
		for player_id: String in loot:
			for drop: Dictionary in loot[player_id]:
				total += int(drop["quantite"])
		assert_eq(total, 2, "2 crocs au plus pour ce loup, tous joueurs confondus (graine %d)" % seed_value)
	# Deux loups : chacun a sa propre limite.
	var rng := RandomNumberGenerator.new()
	var loot := Loot.roll([wolf, wolf], {"a": 100, "b": 100}, rng)
	var total := 0
	for player_id: String in loot:
		for drop: Dictionary in loot[player_id]:
			total += int(drop["quantite"])
	assert_eq(total, 4)


func test_le_plus_prospecteur_tire_en_premier() -> void:
	var monster := {"butin": [{"objet": "cape", "taux": 1.0}]}
	var rng := RandomNumberGenerator.new()
	var loot := Loot.roll([monster], {"a": 100, "b": 250, "c": 120}, rng)
	assert_eq(Loot.turn_order({"a": 100, "b": 250, "c": 120}, rng), ["b", "c", "a"])
	assert_eq(loot["b"], [{"objet": "cape", "quantite": 1}], "une seule cape, pour le plus prospecteur")
	assert_true(loot["a"].is_empty() and loot["c"].is_empty())


func test_passif_chapardeur_prospection_et_ecus() -> void:
	var world := _world()
	world.data.races["chapardeur"] = {"id": "chapardeur", "nom": "Chapardeur", "camp": "ennemi", "carte_depart": "test",
		"passif": {"nom": "Chapardeur", "effets": [{"type": "prospection", "valeur": 20}, {"type": "ecus", "valeur": 20}]}}
	assert_true(GameData.validate_race(world.data.races["chapardeur"], world.data.spells).is_empty())
	world.character.race_id = "chapardeur"
	assert_eq(world.character.prospection(world.data), 120)
	_engage(world)
	assert_eq(world.combat.get_fighter(World.PLAYER_ID).prospection, 120)
	var monster := _stick(world, "groupe_1_1")
	monster.hp = 1
	_command(world, Protocol.CMD_READY)
	var events := _command(world, Protocol.CMD_CAST, {"sort": "frappe", "cible": monster.cell})
	assert_eq(Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]["ecus"], 4, "3 brumes + 20 %, arrondi")
	assert_eq(world.character.inventory.ecus, 4)
