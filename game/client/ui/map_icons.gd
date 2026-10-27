class_name MapIcons
extends RefCounted
## Icônes de la minicarte et de la carte du monde, façon Dofus Rétro : ce qu'on trouve sur chaque
## carte (Pierre de Passage, atelier, marchand, coffre, repaire de mini-boss, quête à prendre ou à
## rendre). Chaque sorte se masque dans la légende de la carte du monde (`Options.hidden_icons`).

const KINDS: Array[String] = ["pierre", "atelier", "marchand", "coffre", "boss", "quete"]
const NAMES := {
	"pierre": "Pierres de Passage",
	"atelier": "Ateliers",
	"marchand": "Marchands",
	"coffre": "Coffres",
	"boss": "Mini-boss",
	"quete": "Quêtes",
}
## Lettre de l'icône (la Pierre de Passage garde son losange bleu).
const LETTERS := {"atelier": "A", "marchand": "M", "coffre": "C", "boss": "B", "quete": "!"}
const COLORS := {
	"pierre": Color("7fd0f0"),
	"atelier": Color("d08a3a"),
	"marchand": Color("e8c95a"),
	"coffre": Color("a07850"),
	"boss": Color("d8483a"),
	"quete": Color("ffd23f"),
}

## Sortes fixes d'une carte (tout sauf les quêtes) et ids de ses PNJ, gardés : id → Array.
static var _fixed: Dictionary = {}
static var _npcs: Dictionary = {}


## Sortes d'icônes de la carte, dans l'ordre de KINDS ; `world` : `ClientState` (ou `World`).
static func of(world: Variant, map_id: String) -> Array[String]:
	if not _fixed.has(map_id):
		var game_map: GameMap = world.map_by_id(map_id)
		_fixed[map_id] = _fixed_kinds(world, game_map) if game_map != null else ([] as Array[String])
		_npcs[map_id] = game_map.npcs.map(func(npc: Dictionary) -> String: return npc["id"]) if game_map != null else []
	var quest := false
	if world.quest_book != null:
		for npc_id: String in _npcs[map_id]:
			quest = quest or world.quest_book.marker(npc_id) in [QuestBook.MARKER_AVAILABLE, QuestBook.MARKER_TURN_IN]
	var found: Array[String] = []
	for kind in KINDS:
		if kind in _fixed[map_id] or (kind == "quete" and quest):
			found.append(kind)
	return found


static func _fixed_kinds(world: Variant, game_map: GameMap) -> Array[String]:
	var kinds: Array[String] = []
	if GameMap.TRAVEL_STONE in game_map.obstacles.values():
		kinds.append("pierre")
	if "coffre" in game_map.obstacles.values():
		kinds.append("coffre")
	for npc: Dictionary in game_map.npcs:
		if not str(npc.get("atelier", "")).is_empty() and "atelier" not in kinds:
			kinds.append("atelier")
		if npc.get("marchand", false) and "marchand" not in kinds:
			kinds.append("marchand")
	var monsters: Dictionary = world.data.monsters if world.data != null else {}
	for group: Dictionary in game_map.groups:
		var ids: Array = group.get("monstres", []) + group.get("parmi", [])
		for monster_id: String in ids:
			if monsters.get(monster_id, {}).get("boss", false) and "boss" not in kinds:
				kinds.append("boss")
	return kinds
