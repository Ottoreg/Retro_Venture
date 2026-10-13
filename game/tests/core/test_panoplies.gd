extends "res://tests/test_case.gd"
## Panoplies : bonus qui grandit avec le nombre de pièces portées, validation des données.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

const SET_ITEMS := [
	{"id": "casque_test", "nom": "Casque", "type": "coiffe", "rarete": "commun", "niveau": 1, "bonus": {"force": [1, 1]}},
	{"id": "anneau_test", "nom": "Anneau", "type": "anneau", "rarete": "commun", "niveau": 1, "bonus": {"force": [1, 1]}},
	{"id": "bottes_test", "nom": "Bottes", "type": "bottes", "rarete": "commun", "niveau": 1, "bonus": {"force": [1, 1]}},
]
const TEST_SET := {
	"id": "test", "nom": "Panoplie de test", "objets": ["casque_test", "anneau_test", "bottes_test"],
	"bonus": {"2": {"force": 10}, "3": {"force": 20, "dommages": 2, "pa": 1}},
}


func _data(sets: Array = [TEST_SET]) -> GameData:
	var base := Fixtures.data()
	var items := Fixtures.items()
	items.append_array(SET_ITEMS)
	return GameData.from_dicts(Fixtures.spells(), [], base.voies.values(), base.races.values(), items, [], [], sets)


func _wear(character: Character, data: GameData, item_id: String, slot: String) -> void:
	var template: Dictionary = data.items[item_id]
	var uid := character.inventory.add(template, 1, Item.roll_bonuses(template, RandomNumberGenerator.new()))
	character.inventory.equip(uid, slot)


func test_le_bonus_grandit_avec_les_pieces_portees() -> void:
	var data := _data()
	assert_eq(data.item_sets["anneau_test"], "test")
	var character := Fixtures.character()
	var force := character.stat("force", data)
	_wear(character, data, "casque_test", "coiffe")
	assert_eq(character.stat("force", data), force + 1, "une pièce : pas de bonus de panoplie")
	_wear(character, data, "anneau_test", "anneau_1")
	assert_eq(data.worn_sets(character.inventory), {"test": 2})
	assert_eq(character.stat("force", data), force + 2 + 10, "deux pièces : +10 Force")
	var pa_before := data.create_character_fighter(character, Fixtures.PLAYER).max_pa
	_wear(character, data, "bottes_test", "bottes")
	assert_eq(character.stat("force", data), force + 3 + 20, "trois pièces : le palier remplace le précédent")
	assert_eq(character.extra("dommages", data), 2)
	assert_eq(character.sheet(data)["dommages"], 2, "dans la fiche")
	var fighter := data.create_character_fighter(character, Fixtures.PLAYER)
	assert_eq(fighter.max_pa, pa_before + 1, "+1 PA en combat")
	assert_eq(fighter.dommages, 2)
	character.inventory.unequip("bottes")
	assert_eq(character.stat("force", data), force + 2 + 10, "on retire une pièce : palier précédent")


func test_panoplies_invalides() -> void:
	var cases := {
		"objet inconnu": {"objets": ["casque_test", "fantome"]},
		"une seule pièce": {"objets": ["casque_test"]},
		"ressource": {"objets": ["casque_test", "dent"]},
		"palier trop grand": {"bonus": {"4": {"force": 5}}},
		"palier sous 2": {"bonus": {"1": {"force": 5}}},
		"bonus inconnu": {"bonus": {"2": {"charisme": 5}}},
	}
	for label: String in cases:
		var raw := TEST_SET.duplicate(true)
		raw.merge(cases[label], true)
		assert_true(_data([]).validate_set(raw).size() > 0, label)
	# Un objet ne peut pas être dans deux panoplies.
	var other := TEST_SET.duplicate(true)
	other["id"] = "autre"
	assert_true(_data().validate_set(other).size() > 0, "seconde panoplie refusée : ses objets sont déjà pris")
