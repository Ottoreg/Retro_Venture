extends "res://tests/test_case.gd"

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _items := {}


func before_each() -> void:
	_items = {}
	for item: Dictionary in Fixtures.items():
		_items[item["id"]] = item


func test_objets_de_test_valides() -> void:
	for item: Dictionary in Fixtures.items():
		assert_eq(Item.validate(item).size(), 0, "objet %s" % item["id"])


func test_objets_invalides() -> void:
	var cases := {
		"type inconnu": {"id": "x", "nom": "X", "type": "chaussette", "rarete": "commun"},
		"rareté inconnue": {"id": "x", "nom": "X", "type": "coiffe", "rarete": "divin"},
		"bonus mal formé": {"id": "x", "nom": "X", "type": "coiffe", "rarete": "commun", "bonus": {"force": 3}},
		"bonus inconnu": {"id": "x", "nom": "X", "type": "coiffe", "rarete": "commun", "bonus": {"charisme": [1, 2]}},
		"ressource avec bonus": {"id": "x", "nom": "X", "type": "ressource", "rarete": "commun", "bonus": {"force": [1, 2]}},
		"arme sans attaque": {"id": "x", "nom": "X", "type": "arme", "rarete": "commun"},
	}
	for label: String in cases:
		assert_true(Item.validate(cases[label]).size() > 0, label)


func test_ressources_empilees_et_equipements_uniques() -> void:
	var inventory := Inventory.new()
	assert_eq(inventory.add(_items["dent"], 2), "dent")
	assert_eq(inventory.add(_items["dent"], 3), "dent")
	assert_eq(inventory.quantity_of("dent"), 5)
	var first := inventory.add(_items["bague"], 1, {"force": 5})
	var second := inventory.add(_items["bague"], 1, {"force": 4})
	assert_ne(first, second, "chaque équipement a son propre uid")
	assert_eq(inventory.entries.size(), 3)
	assert_true(inventory.remove("dent", 5))
	assert_false(inventory.entries.has("dent"))
	assert_false(inventory.remove("dent", 1))


func test_inventaire_plein() -> void:
	var inventory := Inventory.new()
	for i in Inventory.MAX_ENTRIES:
		inventory.add(_items["bague"], 1, {})
	assert_true(inventory.is_full())
	assert_eq(inventory.add(_items["bague"], 1, {}), "", "plus de place")
	assert_eq(inventory.add(_items["dent"], 1), "", "même pour une nouvelle ressource")


func test_equipement_et_bonus() -> void:
	var inventory := Inventory.new()
	var ring := inventory.add(_items["bague"], 1, {"force": 5})
	var other := inventory.add(_items["bague"], 1, {"force": 3})
	inventory.equip(ring, "anneau_1")
	inventory.equip(other, "anneau_2")
	assert_eq(inventory.bonus("force"), 8)
	inventory.equip(ring, "anneau_2")
	assert_eq(inventory.slot_of(ring), "anneau_2", "déplacé")
	assert_eq(inventory.bonus("force"), 5)
	inventory.unequip("anneau_2")
	assert_eq(inventory.bonus("force"), 0)
	inventory.equip(ring, "anneau_1")
	inventory.remove(ring)
	assert_false(inventory.equipped.has("anneau_1"), "jeté : retiré de son emplacement")


func test_sauvegarde_de_l_inventaire() -> void:
	var inventory := Inventory.new()
	inventory.ecus = 42
	inventory.add(_items["dent"], 4)
	var ring := inventory.add(_items["bague"], 1, {"force": 5})
	inventory.equip(ring, "anneau_1")
	var saved: Variant = JSON.parse_string(JSON.stringify(inventory.to_dict()))
	var copy := Inventory.from_dict(saved, _items)
	assert_eq(copy.ecus, 42)
	assert_eq(copy.quantity_of("dent"), 4)
	assert_eq(copy.bonus("force"), 5)
	assert_eq(copy.add(_items["bague"], 1, {}), "o2", "la numérotation continue")
	var unknown := Inventory.from_dict(saved, {})
	assert_eq(unknown.entries.size(), 0, "objets inconnus ignorés")
