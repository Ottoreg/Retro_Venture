extends "res://tests/test_case.gd"
## Forge personnalisée (`Forge`) : valeurs des ressources, révélation, aperçu, nom, commande « forger »
## à l'enclume, plans, objet forgé (nom, signature, attaque), sauvegarde et échange.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _world: World
var _anvil := GameMap.plan_cell(6, 6)


func before_each() -> void:
	var voies := [{"id": "test", "nom": "Test", "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100}, "sorts": ["frappe"]}]
	var data := GameData.from_dicts(Fixtures.spells(), [], voies, [], Fixtures.items() + Fixtures.forge_items(),
		[{"id": "forgeron", "nom": "Forgeron", "type": "artisanat"}])
	_world = World.new(Fixtures.map({_anvil: "&"}), data, Callable(), Fixtures.character())
	var path := _world.map.approach_path(_world.position_of(World.PLAYER_ID), _anvil)
	if not path.is_empty():
		_world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": path[-1]})


func _forge(extra: Dictionary) -> Array[Dictionary]:
	var command := {"type": Protocol.CMD_FORGE, "entite": World.PLAYER_ID, "case": _anvil}
	command.merge(extra, true)
	return _world.execute(command)


func _give(item_id: String, quantity := 1) -> void:
	_world.character.inventory.add(_world.data.items[item_id], quantity)


func test_valeur_selon_le_palier() -> void:
	assert_eq(Forge.value("force", 1), 1)
	assert_eq(Forge.value("force", 16), 3)
	assert_eq(Forge.value("force", 30), 5)
	assert_eq(Forge.value("vitalite", 8), 8, "Vitalité : 4 points pour un de Force")
	assert_eq(Forge.value("pa", 50), 1, "PA et PM toujours à 1")
	assert_eq(Forge.value("prospection", 1), 1, "au moins 1")


func test_caracteristiques_cachees_sans_reputation_d_artisan() -> void:
	var character := _world.character
	assert_false(Forge.reveals(character, 1), "jamais forgé : tout est caché")
	var hidden := Forge.preview("anneau", {"minerai": 1, "croc": 2}, _world.data.items, character)
	assert_eq(hidden["cachees"], 2)
	assert_eq(hidden["bonus"], {})
	character.add_job_reputation("forgeron", 1300)
	assert_true(Forge.reveals(character, 8), "réputation de niveau équivalent 8 : palier 8 révélé")
	assert_false(Forge.reveals(character, 9))
	assert_eq(Forge.preview("anneau", {"minerai": 1, "croc": 2}, _world.data.items, character)["bonus"], {"force": [3, 4]})
	character.jobs["forgeron"]["competences"]["precision"] = 5
	assert_eq(Forge.preview("anneau", {"minerai": 1, "croc": 2}, _world.data.items, character)["bonus"], {"force": [4, 4]},
		"Précision au rang 5 : jets au maximum")


func test_apercu() -> void:
	var items := _world.data.items
	var preview := Forge.preview("bottes", {"peau": 1, "croc": 2, "corne": 2}, items)
	assert_eq(preview["erreur"], "")
	assert_eq(preview["palier"], 8, "moyenne des paliers : (1 + 16 + 24) / 5")
	assert_eq(preview["bonus"]["pa"], [1, 1], "une ligne de PA au plus, à 1")
	assert_eq(preview["bonus"]["force"], [3, 4], "jet : 75 % à 100 % du total")
	assert_eq(Forge.preview("bottes", {"croc": 1}, items)["manquantes"], ["cuir"], "les bottes demandent du cuir")
	assert_eq(Forge.preview("bottes", {"croc": 1}, items)["erreur"], Protocol.REASON_MISSING_INGREDIENTS)
	assert_eq(Forge.preview("epee", {"minerai": 1}, items)["manquantes"], ["bois"])
	assert_eq(Forge.preview("bottes", {"peau": 1, "croc": Forge.MAX_RESOURCES}, items)["erreur"], Protocol.REASON_INVALID_COMMAND, "trop de ressources")
	assert_eq(Forge.preview("chaussette", {"peau": 1}, items)["erreur"], Protocol.REASON_INVALID_COMMAND)


func test_nom_fait_de_mots_proposes() -> void:
	assert_eq(Forge.default_words("bottes", {"force": [3, 4], "pa": [1, 1]}), ["Bottes", "rapides"], "accord au féminin pluriel")
	assert_eq(Forge.name_of(["Bague", "costaude"], "anneau", ["force"]), "Bague costaude")
	assert_eq(Forge.name_of(["Anneau", "costaud", "massif"], "anneau", ["force"]), "", "deux mots pour une même ligne")
	assert_eq(Forge.name_of(["Anneau", "rapide"], "anneau", ["force"]), "", "pas de ligne de PA")
	assert_eq(Forge.name_of(["Chapeau"], "anneau", []), "", "nom d'un autre type")
	assert_eq(Forge.name_of("Anneau", "anneau", []), "")


func test_forger_a_l_enclume() -> void:
	var inventory := _world.character.inventory
	_give("peau")
	var refused := _forge({"type_objet": "bottes", "ressources": {"peau": 1, "croc": 2}, "mots": ["Bottes"]})
	assert_eq(refused[0].get("raison"), Protocol.REASON_MISSING_INGREDIENTS, "pas de crocs dans le sac")
	_give("croc", 2)
	assert_eq(_forge({"type_objet": "bottes", "ressources": {"peau": 1, "croc": 2}, "mots": ["Bottes", "rapides"]})[0].get("raison"),
		Protocol.REASON_INVALID_COMMAND, "nom refusé")
	var events := _forge({"type_objet": "bottes", "ressources": {"peau": 1, "croc": 2}, "mots": ["Souliers", "costauds"]})
	assert_eq(events[0]["type"], Protocol.EVT_CRAFTED)
	assert_eq(events[0]["nom"], "Souliers costauds")
	assert_eq(events[0]["metier"], "forgeron")
	assert_eq(inventory.quantity_of("croc"), 0, "ressources consommées")
	var entry: Dictionary = inventory.entries.values().filter(func(e: Dictionary) -> bool: return e["objet"] == "forge_bottes")[0]
	assert_eq(entry["forge"]["artisan"], "Testeur")
	assert_true(int(entry["jets"]["force"]) in [3, 4] and int(entry["jets"]["vitalite"]) in [4, 5], "jets tirés dans leurs plages : %s" % entry["jets"])
	var template := Item.entry_template(entry, _world.data.items)
	assert_eq(template["nom"], "Souliers costauds")
	assert_eq(template["description"], "Créé par Testeur", "signature à la place du texte d'ambiance")
	assert_eq(template["niveau"], 6, "palier : (1 + 8 × 2) / 3")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_JOB)[0]["gain"], Profession.reputation_gain(Forge.REPUTATION_PER_TIER * 6, 6, 0, 0))
	# La sauvegarde garde l'objet forgé.
	var copy := Character.from_dict(_world.character.to_dict(), _world.data.items)
	assert_eq(copy.inventory.entries[entry["uid"]]["forge"], entry["forge"])


func test_forger_avec_un_plan_et_une_arme() -> void:
	assert_eq(_forge({"recette": "plan_bague"})[0].get("raison"), Protocol.REASON_UNKNOWN_ITEM, "plan absent du sac")
	_give("plan_bague")
	_give("minerai")
	_give("croc", 2)
	var events := _forge({"recette": "plan_bague"})
	assert_eq(events[0]["nom"], "Bague du test", "le plan donne son nom")
	assert_eq(_world.character.inventory.quantity_of("plan_bague"), 1, "le plan reste dans le sac")
	_give("minerai")
	_give("bois")
	_give("croc", 4)
	_forge({"type_objet": "epee", "ressources": {"minerai": 1, "bois": 1, "croc": 4}, "mots": ["Glaive"]})
	var weapon: Dictionary = _world.character.inventory.entries.values().filter(func(e: Dictionary) -> bool: return e["objet"] == "forge_epee")[0]
	assert_eq(weapon["forge"]["palier"], 6)
	assert_eq(Item.entry_template(weapon, _world.data.items)["attaque"]["effets"][0]["min"], 13, "dégâts × (1 + 5 / 20)")
	_world.character.inventory.equip(weapon["uid"], "arme")
	var fighter := _world.data.create_character_fighter(_world.character, "j")
	assert_eq(fighter.weapon_tier, 6)
	var copy := _world.data.create_profile_fighter(fighter.profile(), "j")
	assert_eq(copy.spells[0].effects[0]["min"], 13, "la copie du combat garde l'attaque forgée")


func test_enclume_a_cote() -> void:
	assert_eq(_world.execute({"type": Protocol.CMD_USE, "entite": World.PLAYER_ID, "case": _anvil})[0]["type"], Protocol.EVT_ANVIL)
	_world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": GameMap.plan_cell(1, 1)})
	_give("minerai")
	assert_eq(_forge({"type_objet": "anneau", "ressources": {"minerai": 1}, "mots": ["Anneau"]})[0].get("raison"), Protocol.REASON_TOO_FAR)
