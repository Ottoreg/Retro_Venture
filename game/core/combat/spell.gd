class_name Spell
extends RefCounted
## Définition d'un sort, lue depuis `data/sorts/` (format : voir `data/README.md`).

const ZONE_CELL := "case"
const ZONE_CIRCLE := "cercle"
const EFFECT_DAMAGE := "degats"
const EFFECT_HEAL := "soin"
const ELEMENTS := ["acier", "flamme", "givre", "tempete"]

var id: String
var display_name: String
var description: String
var pa_cost: int
var range_min: int
var range_max: int
var needs_line_of_sight: bool
var zone_type: String
## Rayon de la zone (distance de Manhattan) pour une zone en cercle.
var zone_size: int
## Le lanceur n'est jamais touché par son propre sort (ex. un tourbillon autour de lui).
var excludes_caster: bool
## Nombre de lancers par tour (0 = illimité).
var casts_per_turn: int
## Nombre de tours avant de pouvoir relancer le sort (0 = aucun délai).
var cooldown: int
## Effets, dans l'ordre : { type, element?, min, max }.
var effects: Array[Dictionary] = []


## Liste des erreurs de `data` (vide si le sort est valide).
static func validate(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(data.get("id")) != TYPE_STRING or str(data.get("id")).is_empty():
		errors.append("« id » doit être un texte non vide")
	if typeof(data.get("nom")) != TYPE_STRING:
		errors.append("« nom » doit être un texte")
	if not _is_int_at_least(data.get("cout_pa"), 0):
		errors.append("« cout_pa » doit être un entier positif ou nul")
	var range_data: Variant = data.get("portee")
	if typeof(range_data) != TYPE_DICTIONARY or not _is_int_at_least(range_data.get("min"), 0) \
			or not _is_int_at_least(range_data.get("max"), 0) or int(range_data["min"]) > int(range_data["max"]):
		errors.append("« portee » doit être { min, max } avec 0 ≤ min ≤ max")
	var zone: Variant = data.get("zone", {"type": ZONE_CELL})
	if typeof(zone) != TYPE_DICTIONARY or zone.get("type") not in [ZONE_CELL, ZONE_CIRCLE]:
		errors.append("« zone.type » doit valoir « case » ou « cercle »")
	elif zone["type"] == ZONE_CIRCLE and not _is_int_at_least(zone.get("taille"), 1):
		errors.append("une zone en cercle demande une « taille » d'au moins 1")
	var recast: Variant = data.get("relance", {})
	if typeof(recast) != TYPE_DICTIONARY or not _is_int_at_least(recast.get("par_tour", 0), 0) \
			or not _is_int_at_least(recast.get("delai", 0), 0):
		errors.append("« relance » doit être { par_tour, delai } avec des entiers positifs ou nuls")
	var effects_data: Variant = data.get("effets")
	if typeof(effects_data) != TYPE_ARRAY or effects_data.is_empty():
		errors.append("« effets » doit être une liste non vide")
		return errors
	for effect: Variant in effects_data:
		if typeof(effect) != TYPE_DICTIONARY or effect.get("type") not in [EFFECT_DAMAGE, EFFECT_HEAL]:
			errors.append("effet invalide : %s (types : degats, soin)" % str(effect))
			continue
		if effect["type"] == EFFECT_DAMAGE and effect.get("element") not in ELEMENTS:
			errors.append("effet de dégâts : « element » doit être l'un de %s" % str(ELEMENTS))
		if not _is_int_at_least(effect.get("min"), 0) or not _is_int_at_least(effect.get("max"), 0) \
				or int(effect["min"]) > int(effect["max"]):
			errors.append("effet « %s » : « min » et « max » doivent être des entiers avec min ≤ max" % effect["type"])
	return errors


## Construit le sort. `data` doit avoir été vérifié avec `validate()`.
static func from_dict(data: Dictionary) -> Spell:
	var spell := Spell.new()
	spell.id = data["id"]
	spell.display_name = data["nom"]
	spell.description = str(data.get("description", ""))
	spell.pa_cost = int(data["cout_pa"])
	spell.range_min = int(data["portee"]["min"])
	spell.range_max = int(data["portee"]["max"])
	spell.needs_line_of_sight = bool(data.get("ligne_de_vue", true))
	var zone: Dictionary = data.get("zone", {"type": ZONE_CELL})
	spell.zone_type = zone["type"]
	spell.zone_size = int(zone.get("taille", 0))
	spell.excludes_caster = bool(data.get("lanceur_exclu", false))
	var recast: Dictionary = data.get("relance", {})
	spell.casts_per_turn = int(recast.get("par_tour", 0))
	spell.cooldown = int(recast.get("delai", 0))
	for effect: Dictionary in data["effets"]:
		var copy := effect.duplicate()
		copy["min"] = int(effect["min"])
		copy["max"] = int(effect["max"])
		spell.effects.append(copy)
	return spell


## Cases touchées quand le sort vise `target`.
func zone_cells(target: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [target]
	if zone_type == ZONE_CIRCLE:
		for dy in range(-zone_size, zone_size + 1):
			for dx in range(-zone_size, zone_size + 1):
				var offset := Vector2i(dx, dy)
				if offset != Vector2i.ZERO and absi(dx) + absi(dy) <= zone_size:
					cells.append(target + offset)
	return cells


func deals_damage() -> bool:
	for effect in effects:
		if effect["type"] == EFFECT_DAMAGE:
			return true
	return false


## Dégâts maximaux, pour que l'IA choisisse son meilleur sort.
func max_damage() -> int:
	var total := 0
	for effect in effects:
		if effect["type"] == EFFECT_DAMAGE:
			total += int(effect["max"])
	return total


static func _is_int_at_least(value: Variant, minimum: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return value == floorf(value) and int(value) >= minimum
