extends "res://tests/test_case.gd"
## Infusion d'essences (`Infusion`, GDD § 10.4) : essence tirée de ressources identiques, essence parfaite, miroir au
## palier Maître, application en exo ou en renfort, plafonds, chance de réussite.

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


func _infuse(extra: Dictionary) -> Array[Dictionary]:
	return _world.execute({"type": Protocol.CMD_INFUSE, "entite": World.PLAYER_ID, "case": _anvil}.merged(extra))


func _essence_uid() -> String:
	for entry: Dictionary in _world.character.inventory.entries.values():
		if entry["objet"] == Infusion.TEMPLATE:
			return entry["uid"]
	return ""


func test_essence_de_ressources_identiques() -> void:
	var items := _world.data.items
	_world.character.inventory.add(items["croc"], 25)
	assert_eq(_infuse({"ressource": "croc", "caracteristique": "force", "parfaite": true})[0]["raison"], Protocol.REASON_MISSING_INGREDIENTS,
		"essence parfaite : 100 communes")
	var events := _infuse({"ressource": "croc", "caracteristique": "force"})
	assert_eq(events[0]["essence"], {"caracteristique": "force", "valeur": Forge.value("force", 8), "parfaite": false})
	assert_eq(_world.character.inventory.quantity_of("croc"), 5, "20 communes")
	assert_eq(events[0]["nom"], "Essence de Force +%d" % Forge.value("force", 8))
	assert_eq(_infuse({"ressource": "croc", "caracteristique": "agilite"})[0]["raison"], Protocol.REASON_INVALID_COMMAND, "miroir : Maître")
	assert_eq(Infusion.essence(items["corne"], "pa", false, false)["quantite"], 10, "rare : 10")
	assert_eq(Infusion.essence(items["croc"], "agilite", false, true)["essence"]["valeur"], Forge.value("force", 8), "Force ↔ Agilité, même score")
	assert_eq(Infusion.essence(items["peau"], "epines_brutes", false, true)["essence"]["valeur"], 0, "Vitalité 1 point de score : 0 % d'épines")
	assert_eq(Infusion.essence(items["peau"], "epines_brutes", false, true)["erreur"], Protocol.REASON_INVALID_COMMAND)
	assert_eq(Infusion.mirrors("dommages_flamme"), ["dommages_givre", "soins_flamme"], "deux miroirs, au choix")
	assert_eq(Infusion.mirrors("pa"), [], "rien pour PA")


func test_appliquer_en_exo_ou_en_renfort() -> void:
	var inventory := _world.character.inventory
	var ring := inventory.add(_world.data.items["forge_anneau"], 1, {"force": 10})
	var essence := {"caracteristique": "force", "valeur": 5, "parfaite": true}
	inventory.add(_world.data.items["essence"], 1, {}, false, {"nom": "E", "artisan": "", "palier": 1, "bonus": {}, "essence": essence})
	var events := _infuse({"essence": _essence_uid(), "objet": ring})
	assert_true(events[0]["reussi"], "une essence parfaite réussit toujours")
	assert_eq(inventory.entries[ring]["jets"]["force"], 15, "renfort de la ligne du jet")
	assert_false(inventory.entries[ring].has("exo"), "un renfort ne compte pas dans l'exo")
	var pa := {"caracteristique": "pa", "valeur": 1, "parfaite": true}
	inventory.add(_world.data.items["essence"], 1, {}, false, {"nom": "E", "artisan": "", "palier": 1, "bonus": {}, "essence": pa})
	_infuse({"essence": _essence_uid(), "objet": ring})
	assert_eq(inventory.entries[ring]["exo"], {"pa": 1}, "ligne exo")
	Infusion.apply(inventory.entries[ring], {"caracteristique": "pm", "valeur": 1, "parfaite": true})
	assert_eq(Infusion.apply_preview(inventory.entries[ring], {"caracteristique": "portee", "valeur": 1, "parfaite": true})["erreur"],
		Protocol.REASON_TOO_MANY_LINES, "PA 100 + PM 80 + Portée 60 : plus de 200 points d'exo")
	assert_eq(Infusion.apply_preview(inventory.entries[ring], {"caracteristique": "force", "valeur": 90, "parfaite": true})["erreur"],
		Protocol.REASON_TOO_MANY_LINES, "100 points de score par ligne")
	var saved := Inventory.from_dict(inventory.to_dict(), _world.data.items)
	assert_eq(saved.entries[ring]["exo"], {"pa": 1, "pm": 1}, "l'exo se sauvegarde")


func test_chance_selon_le_poids() -> void:
	assert_eq(Infusion.chance({"caracteristique": "pa", "valeur": 1, "parfaite": false}), 50)
	assert_eq(Infusion.chance({"caracteristique": "force", "valeur": 3, "parfaite": false}), 95, "plafond")
	assert_eq(Infusion.chance({"caracteristique": "resistance_givre", "valeur": 4, "parfaite": false}), 84)
	assert_eq(Infusion.chance({"caracteristique": "pa", "valeur": 1, "parfaite": true}), 100)
