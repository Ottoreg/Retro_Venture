extends RefCounted
## Données et cartes de test partagées par les tests du combat.
## Usage : const Fixtures := preload("res://tests/helpers/fixtures.gd")

const PLAYER := "joueur"

## Carte 9 × 9 sans obstacle ; `center()` est au milieu, toutes les cases à 4 pas ou moins en font partie.
const OPEN_PLAN := [
	"@........",
	" ........",
	".........",
	" ........",
	".........",
	" ........",
	".........",
	" ........",
	".........",
]


static func center() -> Vector2i:
	return GameMap.plan_cell(4, 4)


## Plan ouvert où certaines cases sont remplacées : { Vector2i: "R" }.
@warning_ignore("integer_division")
static func plan_with(changes: Dictionary) -> Array:
	var plan: Array = OPEN_PLAN.duplicate()
	for cell: Vector2i in changes:
		var row := cell.x + cell.y
		var half_column := cell.x - cell.y
		var line_index := row - 1
		var char_index := (half_column - row % 2) / 2
		var line: String = plan[line_index]
		plan[line_index] = line.substr(0, char_index) + changes[cell] + line.substr(char_index + 1)
	return plan


static func map(changes := {}, groups := []) -> GameMap:
	var data := {"id": "test", "plan": plan_with(changes), "groupes": groups}
	var errors := GameMap.validate(data)
	assert(errors.is_empty(), "carte de test invalide : %s" % str(errors))
	return GameMap.from_dict(data)


static func spells() -> Array:
	return [
		{"id": "frappe", "nom": "Frappe", "cout_pa": 3, "portee": {"min": 1, "max": 1}, "relance": {"par_tour": 2},
			"effets": [{"type": "degats", "element": "acier", "min": 10, "max": 10}]},
		{"id": "piqure", "nom": "Piqûre", "cout_pa": 1, "portee": {"min": 1, "max": 1}, "relance": {"par_tour": 2},
			"effets": [{"type": "degats", "element": "acier", "min": 1, "max": 1}]},
		{"id": "tir", "nom": "Tir", "cout_pa": 4, "portee": {"min": 2, "max": 4}, "ligne_de_vue": true,
			"effets": [{"type": "degats", "element": "acier", "min": 5, "max": 5}]},
		{"id": "zone", "nom": "Zone", "cout_pa": 3, "portee": {"min": 0, "max": 0}, "zone": {"type": "cercle", "taille": 1},
			"lanceur_exclu": true, "effets": [{"type": "degats", "element": "acier", "min": 4, "max": 4}]},
		{"id": "soin", "nom": "Soin", "cout_pa": 2, "portee": {"min": 0, "max": 0}, "relance": {"delai": 2},
			"effets": [{"type": "soin", "min": 10, "max": 10}]},
	]


static func monster(id: String, hp: int, pa: int, pm: int, initiative: int, spell_ids: Array, resistances := {}) -> Dictionary:
	return {
		"id": id, "nom": id.capitalize(),
		"caracteristiques": {"pv": hp, "pa": pa, "pm": pm, "initiative": initiative},
		"resistances": resistances, "sorts": spell_ids, "ia": "basique", "xp": 10,
	}


static func data() -> GameData:
	var monsters := [
		monster("mannequin", 30, 0, 0, 10, ["frappe"]),
		monster("blinde", 30, 0, 0, 10, ["frappe"], {"acier": 50}),
		monster("loup", 30, 6, 4, 50, ["frappe"]),
		monster("archer", 30, 6, 3, 50, ["tir"]),
		monster("rapide", 30, 0, 0, 150, ["frappe"]),
	]
	var voies := [{
		"id": "test", "nom": "Test",
		"caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100},
		"sorts": ["frappe", "piqure", "tir", "zone", "soin"],
	}]
	return GameData.from_dicts(spells(), monsters, voies)


## Combat avec le joueur en `player_cell` et des monstres [[id, case], …] (ids m0, m1…).
static func combat(game_map: GameMap, player_cell: Vector2i, monsters: Array) -> Combat:
	var game_data := data()
	var fighters: Array[Fighter] = []
	var player := game_data.create_player("test", PLAYER, "Testeur")
	player.cell = player_cell
	fighters.append(player)
	for i in monsters.size():
		var fighter := game_data.create_monster(monsters[i][0], "m%d" % i)
		fighter.cell = monsters[i][1]
		fighters.append(fighter)
	var placement: Array[Vector2i] = [player_cell, player_cell + Vector2i(-1, 0), player_cell + Vector2i(0, -1)]
	return Combat.new(game_map, fighters, placement, 1)


static func cmd(type: String, extra := {}) -> Dictionary:
	var command := {"type": type, "entite": PLAYER}
	command.merge(extra, true)
	return command


## Événements d'un type donné.
static func of_type(events: Array[Dictionary], type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		if event["type"] == type:
			result.append(event)
	return result
