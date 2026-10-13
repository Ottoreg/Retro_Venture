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


static func map(changes := {}, groups := [], extra := {}) -> GameMap:
	var data := {"id": "test", "plan": plan_with(changes), "groupes": groups}
	data.merge(extra, true)
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
			"effets": [{"type": "soin", "element": "flamme", "min": 10, "max": 10}]},
		{"id": "bond", "nom": "Bond", "cout_pa": 1, "portee": {"min": 1, "max": 3}, "ligne_de_vue": false,
			"effets": [{"type": "teleportation"}]},
		{"id": "elan", "nom": "Élan", "cout_pa": 1, "portee": {"min": 0, "max": 0},
			"effets": [{"type": "gain_pa", "min": 2, "max": 2}]},
		{"id": "entrave", "nom": "Entrave", "cout_pa": 1, "portee": {"min": 1, "max": 1},
			"effets": [{"type": "retrait_pm", "min": 1, "max": 1}]},
		{"id": "sermon", "nom": "Sermon", "cout_pa": 2, "portee": {"min": 1, "max": 4}, "ligne_de_vue": false,
			"lancer_en_ligne": true, "zone": {"type": "croix_latine"}, "effets": [
				{"type": "degats", "element": "acier", "min": 10, "max": 10, "cibles": "ennemis"},
				{"type": "soin", "element": "acier", "min": 10, "max": 10, "cibles": "allies"}]},
	]


static func monster(id: String, hp: int, pa: int, pm: int, initiative: int, spell_ids: Array, resistances := {}) -> Dictionary:
	return {
		"id": id, "nom": id.capitalize(),
		"caracteristiques": {"pv": hp, "pa": pa, "pm": pm, "initiative": initiative},
		"resistances": resistances, "sorts": spell_ids, "ia": "basique", "xp": 10,
		# Butin garanti (taux 1), sauf le trésor (1 %, garanti seulement avec beaucoup de prospection).
		"butin": [
			{"objet": "dent", "taux": 1.0, "quantite": [2, 2]},
			{"objet": "bague", "taux": 1.0},
			{"objet": "tresor", "taux": 0.01},
		],
		"ecus": [3, 3],
	}


static func items() -> Array:
	return [
		{"id": "dent", "nom": "Dent", "type": "ressource", "rarete": "commun"},
		{"id": "tresor", "nom": "Trésor", "type": "ressource", "rarete": "legendaire"},
		{"id": "bague", "nom": "Bague", "type": "anneau", "rarete": "commun", "niveau": 1, "bonus": {"force": [5, 5]}},
		{"id": "heaume", "nom": "Heaume", "type": "coiffe", "rarete": "rare", "niveau": 3, "bonus": {"vitalite": [10, 10]}},
		{"id": "lourd", "nom": "Manteau lourd", "type": "cape", "rarete": "rare", "niveau": 1, "conditions": {"force": 60}},
		{"id": "bottes", "nom": "Bottes", "type": "bottes", "rarete": "epique", "niveau": 1,
			"bonus": {"pa": [1, 1], "pm": [1, 1], "portee": [1, 1], "initiative": [10, 10], "prospection": [50, 50]}},
		{"id": "epee", "nom": "Épée", "type": "arme", "rarete": "commun", "niveau": 1, "bonus": {"force": [1, 3]},
			"attaque": {"cout_pa": 3, "portee": {"min": 1, "max": 1}, "effets": [{"type": "degats", "element": "acier", "min": 20, "max": 20}]}},
	]


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
		"sorts": ["frappe", "piqure", "tir", "zone", "soin", "elan", "entrave", "sermon"],
		"equipement_depart": ["epee", "bague"],
	}]
	var races := [{
		"id": "testeur", "nom": "Testeur", "camp": "allie", "carte_depart": "test",
		"bonus": {"force": 50, "vitalite": 7, "sagesse": 100},
		"passif": {"nom": "Vue perçante", "effet": {"type": "portee", "valeur": 1}},
		"sort": "bond",
	}]
	return GameData.from_dicts(spells(), monsters, voies, races, items())


## Personnage de test : race « testeur » (Force +50, Vitalité +7, Sagesse +100, portée +1, sort « bond »).
static func character() -> Character:
	return Character.create("Testeur", "testeur", "test")


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
