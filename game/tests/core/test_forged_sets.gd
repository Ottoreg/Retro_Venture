extends "res://tests/test_case.gd"
## Panoplies d'objets forgés (GDD § 10.4, `Forge.keywords`, `Forge.set_bonus`) : mots clés du nom, mots de famille et
## de zone permis à la majorité des ressources, barème des bonus, enregistrement à la forge.

const Fixtures := preload("res://tests/helpers/fixtures.gd")


func _data(boss := false) -> GameData:
	var items: Array = Fixtures.items() + Fixtures.forge_items()
	for item: Dictionary in items:
		if item["id"] in ["croc", "corne"]:
			item.merge({"famille": "loup" if item["id"] == "croc" else "ours", "zone": "brumerive"})
		if item["id"] == "peau":
			item.merge({"famille": "ours", "zone": "sylvebrume"})
	var loup := Fixtures.monster("loup", 10, 6, 3, 10, ["frappe"])
	loup.merge({"mot": "de Loup", "boss": boss})
	var ours := Fixtures.monster("ours", 10, 6, 3, 10, ["frappe"])
	ours["mot"] = "d'Ours"
	return GameData.from_dicts(Fixtures.spells(), [loup, ours], [], [], items)


func _pieces(key: String, tiers: Array) -> Array:
	return tiers.map(func(tier: int) -> Dictionary: return {"forge": {"palier": tier, "mots_cles": [key]}})


func test_mots_cles_du_nom() -> void:
	var places := {"famille:loup": "de Loup", "zone:brumerive": "de Brumerive"}
	var words := ["Anneau", "costaud", "massif", "de Loup"]
	assert_eq(Forge.name_of(words, "anneau", ["force"], places), "Anneau costaud massif de Loup", "trois mots clés au plus")
	assert_eq(Forge.keywords(words, "anneau", ["force"], places), ["stat:acier_offensive", "famille:loup"], "deux adjectifs d'une ligne : un mot clé")
	assert_eq(Forge.name_of(words + ["de Brumerive"], "anneau", ["force"], places), "", "pas de quatrième mot clé")
	assert_eq(Forge.name_of(["Anneau", "de Loup"], "anneau", ["force"]), "", "mot de famille non permis")
	assert_eq(Forge.adjective_set("intelligence"), "flamme_offensive")
	assert_eq(Forge.adjective_set("resistance_givre"), "givre_defensive")
	assert_eq(Forge.adjective_set("epines_brutes_fixes"), "epines_brutes", "fixe et % : même panoplie")


func test_mots_de_famille_et_de_zone_a_la_majorite() -> void:
	var items := _data().items
	var lieux: Array = Forge.preview("anneau", {"minerai": 1, "croc": 1, "corne": 1}, items)["lieux"]
	lieux.sort()
	assert_eq(lieux, ["famille:loup", "famille:ours", "zone:brumerive"], "la moitié suffit ; la matière ne compte pas")
	lieux = Forge.preview("bottes", {"croc": 1, "corne": 1, "peau": 1}, items)["lieux"]
	lieux.sort()
	assert_eq(lieux, ["famille:ours", "zone:brumerive"], "deux ressources sur trois")


func test_bareme_des_panoplies() -> void:
	var data := _data()
	assert_eq(data.family_stats("ours"), ["vitalite", "pa"], "statistiques des ressources de la famille")
	assert_eq(Forge.set_bonus("famille:loup", [2, 2, 2, 2, 2, 2, 2], data), {"force": 60}, "30 × palier pour 7 pièces")
	assert_eq(Forge.set_bonus("famille:loup", [3, 2], data), {"force": 5}, "8 % à 2 pièces, palier le plus bas")
	assert_eq(Forge.set_bonus("stat:force", [2, 2, 2, 2, 2, 2, 2], data), {"force": 50}, "adjectif : 25 × palier")
	assert_eq(Forge.set_bonus("famille:loup", [2, 2, 2, 2, 2, 2, 2], _data(true)), {"force": 90}, "boss × 1,5")
	assert_eq(Forge.set_bonus("zone:brumerive", [1, 1, 1, 1, 1, 1, 1], data)["agilite"], 15, "tendance de zone")
	assert_eq(Forge.set_bonus("famille:ours", [5, 5, 5, 5, 5, 5, 5], data), {"dommages": 26, "vitalite": 300},
		"PA : seulement si sa part vaut le double de son score, sinon des Dommages")
	var entries := _pieces("famille:loup", [1, 1]) + _pieces("stat:force", [1, 1])
	assert_eq(Forge.set_bonuses(entries, data), {"force": 2 + 2}, "panoplies cumulées")


func test_forge_enregistre_les_mots_cles() -> void:
	var data := _data()
	var anvil := GameMap.plan_cell(6, 6)
	var voies := [{"id": "test", "nom": "Test", "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100}, "sorts": ["frappe"]}]
	data = GameData.from_dicts(Fixtures.spells(), data.monsters.values(), voies, [], data.items.values(), [{"id": "forgeron", "nom": "Forgeron", "type": "artisanat"}])
	var world := World.new(Fixtures.map({anvil: "&"}), data, Callable(), Fixtures.character())
	var path := world.map.approach_path(world.position_of(World.PLAYER_ID), anvil)
	world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": path[-1]})
	var inventory := world.character.inventory
	inventory.add(data.items["minerai"], 2)
	inventory.add(data.items["croc"], 2)
	var command := {"type": Protocol.CMD_FORGE, "entite": World.PLAYER_ID, "case": anvil, "type_objet": "anneau", "ressources": {"minerai": 1, "croc": 1}}
	for words: Array in [["Anneau", "costaud", "de Loup"], ["Anneau", "de Brumerive"]]:
		command["mots"] = words
		assert_eq(world.execute(command)[0]["type"], Protocol.EVT_CRAFTED, " ".join(words))
	var forged := inventory.entries.values().filter(func(entry: Dictionary) -> bool: return entry.has("forge"))
	assert_eq(forged.map(func(entry: Dictionary) -> Array: return entry["forge"]["mots_cles"]), [["stat:acier_offensive", "famille:loup"], ["zone:brumerive"]])
