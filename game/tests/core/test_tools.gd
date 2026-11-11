extends "res://tests/test_case.gd"
## Statistiques de métier sur les outils (GDD § 10.4) : stat de métier tirée de la stat de combat des ressources,
## lignes inutiles perdues, plafond de 60 points de score par palier, effets (récolte, forge, infusion, réputation).

const Fixtures := preload("res://tests/helpers/fixtures.gd")


func _items() -> Dictionary:
	var items := {}
	for item: Dictionary in Fixtures.forge_items():
		items[item["id"]] = item
	for stat: String in ["force", "perception", "agilite", "pa"]:
		items[stat] = {"id": stat, "type": "ressource", "niveau": 5, "caracteristique": stat}
	return items


func _tool(character: Character, template_id: String, rolls: Dictionary) -> void:
	var uid := character.inventory.add({"id": template_id, "nom": "Outil", "type": "outil"}, 1, rolls)
	character.inventory.equip(uid, "outil")


func test_statistique_de_metier_des_ressources() -> void:
	assert_eq(Forge.job_stat("force"), "profusion")
	assert_eq(Forge.job_stat("dommages_flamme"), "epargne", "Dommages élémentaires : Épargne")
	assert_eq(Forge.job_stat("resistance_givre"), "distillation")
	assert_eq(Forge.job_stat("dommages_melee"), "", "pas d'équivalent")
	var preview := Forge.preview("pioche", {"minerai": 1, "bois": 1, "croc": 10, "peau": 1}, _items())
	assert_eq(preview["bonus"], {"profusion": [8, 10]}, "Force → Profusion à score égal, 1 au moins par ressource")
	assert_eq(preview["perdues"], {"peau": {"vitalite": 0}}, "Main verte ne sert pas encore : perdue")
	assert_eq(Forge.preview("marteau_de_forgeron", {"minerai": 1, "bois": 1, "croc": 1}, _items())["perdues"], {"croc": {"force": 0}},
		"Profusion ne sert pas au forgeron")


func test_plafond_de_l_outil() -> void:
	var bonus: Dictionary = Forge.preview("pioche", {"minerai": 1, "bois": 1, "force": 50, "perception": 50, "agilite": 100, "pa": 1}, _items())["bonus"]
	assert_eq(bonus.keys(), ["profusion", "flair", "dexterite"], "300 points de score au palier 5 : la 4e ligne est rognée")
	assert_eq([bonus["profusion"][1], bonus["flair"][1], bonus["dexterite"][1]], [30, 50, 15], "lignes pleines")


func test_effets_de_l_outil() -> void:
	var character := Fixtures.character()
	_tool(character, "forge_pioche", {"dexterite": 20, "minutie": 10})
	assert_eq(character.tool_stat("mineur", "dexterite"), 20)
	assert_eq(character.tool_stat("bucheron", "dexterite"), 0, "un outil ne sert qu'à son métier")
	assert_eq(character.tool_stat(Forge.JOB, "minutie"), 0)
	assert_almost_eq(Profession.harvest_time(10, 0, 20), 3.2, 0.001, "Dextérité : −20 %")
	assert_eq(Profession.harvest_time(1, 0, 90), Profession.HARVEST_MIN_TIME, "1 s au moins")
	assert_eq(Infusion.chance({"caracteristique": "force", "valeur": 50, "parfaite": false}, 10), 85, "Distillation : +10 points")
	assert_eq(Infusion.chance({"caracteristique": "force", "valeur": 2, "parfaite": false}, 10), Infusion.MAX_CHANCE)


func test_epargne_et_minutie_a_la_forge() -> void:
	var anvil := GameMap.plan_cell(6, 6)
	var voies := [{"id": "test", "nom": "Test", "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100}, "sorts": ["frappe"]}]
	var data := GameData.from_dicts(Fixtures.spells(), [], voies, [], Fixtures.items() + Fixtures.forge_items(), [{"id": "forgeron", "nom": "Forgeron", "type": "artisanat"}])
	var world := World.new(Fixtures.map({anvil: "&"}), data, Callable(), Fixtures.character())
	var path := world.map.approach_path(world.position_of(World.PLAYER_ID), anvil)
	world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": path[-1]})
	var inventory := world.character.inventory
	_tool(world.character, "forge_marteau_de_forgeron", {"epargne": 100, "minutie": 25})
	assert_eq(Forge.preview("anneau", {"minerai": 1, "croc": 10}, data.items, world.character, false)["bonus"]["force"], [20, 20], "Minutie : plancher à 100 %")
	inventory.add(data.items["minerai"], 1)
	inventory.add(data.items["croc"], 2)
	var events := world.execute({"type": Protocol.CMD_FORGE, "entite": World.PLAYER_ID, "case": anvil, "type_objet": "anneau",
		"ressources": {"minerai": 1, "croc": 2}, "mots": ["Anneau"]})
	assert_eq(events[0]["epargne"], {"minerai": 1, "croc": 2}, "Épargne 100 % : rien n'est consommé")
	assert_eq([inventory.quantity_of("minerai"), inventory.quantity_of("croc")], [1, 2])
