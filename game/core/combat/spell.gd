class_name Spell
extends RefCounted
## Définition d'un sort, lue depuis `data/sorts/` (format : voir `data/README.md`).

const ZONE_CELL := "case"
const ZONE_CIRCLE := "cercle"
## Croix latine : 4 cases en ligne depuis la case visée, dans le sens du lancer, et une case de
## chaque côté de la 3e (le pied de la croix vers le lanceur, la tête au loin). Demande un lancer
## en ligne.
const ZONE_LATIN_CROSS := "croix_latine"
const ZONES := [ZONE_CELL, ZONE_CIRCLE, ZONE_LATIN_CROSS]
## Qui un effet touche dans la zone (défaut : tout le monde).
const TARGETS_ALL := "tous"
const TARGETS_ENEMIES := "ennemis"
const TARGETS_ALLIES := "allies"
const TARGETS := [TARGETS_ALL, TARGETS_ENEMIES, TARGETS_ALLIES]
const EFFECT_DAMAGE := "degats"
const EFFECT_HEAL := "soin"
## Le lanceur se téléporte sur la case visée (qui doit être libre).
const EFFECT_TELEPORT := "teleportation"
## La cible gagne des PA tout de suite (pour le tour en cours).
const EFFECT_GAIN_PA := "gain_pa"
## La cible aura moins de PM à son prochain tour.
const EFFECT_REMOVE_PM := "retrait_pm"
## La cible gagne un bouclier qui absorbe des dégâts jusqu'au début de son prochain tour.
const EFFECT_SHIELD := "bouclier"
## Bonus ou malus temporaire d'une caractéristique (`carac`, voir MODIFIABLE) pendant `duree` tours
## de la cible ; un bonus/malus de PA ou de PM compte aussi tout de suite.
const EFFECT_BONUS := "bonus"
const EFFECT_MALUS := "malus"
## Dégâts au début de chaque tour de la cible, pendant `duree` tours (poison, saignement…).
const EFFECT_POISON := "poison"
## Pousse la cible de `min`–`max` cases en s'éloignant du lanceur (ou du centre d'un piège) ; un
## obstacle ou un combattant l'arrête, avec des dégâts de choc pour chaque case non parcourue.
const EFFECT_PUSH := "poussee"
## Attire la cible de `min`–`max` cases vers le lanceur.
const EFFECT_PULL := "attirance"
## Glyphe : les cases de la zone du sort gardent ses `effets` pendant `duree` tours du lanceur ; ils
## s'appliquent à qui commence son tour dessus.
const EFFECT_GLYPH := "glyphe"
## Piège posé sur la case visée (libre), invisible pour l'équipe adverse : le premier ennemi qui y
## entre le déclenche, ses `effets` touchent la zone du piège (`zone`, une case par défaut).
const EFFECT_TRAP := "piege"
const EFFECT_TYPES := [EFFECT_DAMAGE, EFFECT_HEAL, EFFECT_TELEPORT, EFFECT_GAIN_PA, EFFECT_REMOVE_PM, EFFECT_SHIELD,
	EFFECT_BONUS, EFFECT_MALUS, EFFECT_POISON, EFFECT_PUSH, EFFECT_PULL, EFFECT_GLYPH, EFFECT_TRAP]
## Effets qui posent quelque chose au sol, avec leurs propres `effets` (sans glyphe, piège ni
## téléportation à l'intérieur).
const GROUND_EFFECTS := [EFFECT_GLYPH, EFFECT_TRAP]
## Effets qui durent plusieurs tours (`duree` obligatoire).
const LASTING_EFFECTS := [EFFECT_BONUS, EFFECT_MALUS, EFFECT_POISON, EFFECT_GLYPH]
## Caractéristiques qu'un bonus ou un malus peut changer ; « resistance » demande un `element`.
const MODIFIABLE := ["force", "intelligence", "chance", "agilite", "pa", "pm", "portee", "dommages", "critique", "resistance"]
## Effets chiffrés qui ont un élément : leur valeur monte avec la caractéristique de cet élément
## (un soin Sacré avec la Force et l'Intelligence, un bouclier de Tempête avec l'Agilité, un poison
## de Givre avec la Chance…).
const ELEMENT_EFFECTS := [EFFECT_DAMAGE, EFFECT_HEAL, EFFECT_SHIELD, EFFECT_POISON]
## Chance de coup critique d'un sort sans « critique » (en %).
const DEFAULT_CRIT_CHANCE := 5
## Un coup critique multiplie la valeur tirée des dégâts, soins, boucliers et poisons.
const CRIT_MULTIPLIER := 1.5
## Éléments de base, et éléments composés qui s'appuient chacun sur deux éléments de base : le Sacré
## (Acier + Flamme) et l'Impie (Tempête + Givre).
const BASE_ELEMENTS := ["acier", "flamme", "givre", "tempete"]
const COMPOSITE_ELEMENTS := {"sacre": ["acier", "flamme"], "impie": ["tempete", "givre"]}
const ELEMENTS := ["acier", "flamme", "givre", "tempete", "sacre", "impie"]

var id: String
var display_name: String
var description: String
var pa_cost: int
var range_min: int
var range_max: int
var needs_line_of_sight: bool
## La cible doit être sur la même ligne ou la même colonne que le lanceur.
var cast_in_line: bool
var zone_type: String
## Rayon de la zone (distance de Manhattan) pour une zone en cercle.
var zone_size: int
## Le lanceur n'est jamais touché par son propre sort (ex. un tourbillon autour de lui).
var excludes_caster: bool
## Nombre de lancers par tour (0 = illimité).
var casts_per_turn: int
## Nombre de tours avant de pouvoir relancer le sort (0 = aucun délai).
var cooldown: int
## Chance de coup critique de base, en % (s'y ajoute le bonus « critique » du lanceur).
var crit_chance: int
## Effets, dans l'ordre : { type, element?, min, max, cibles? }.
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
	if typeof(zone) != TYPE_DICTIONARY or zone.get("type") not in ZONES:
		errors.append("« zone.type » doit valoir %s" % str(ZONES))
	elif zone["type"] == ZONE_CIRCLE and not _is_int_at_least(zone.get("taille"), 1):
		errors.append("une zone en cercle demande une « taille » d'au moins 1")
	elif zone["type"] == ZONE_LATIN_CROSS and not data.get("lancer_en_ligne", false):
		errors.append("une zone en croix latine demande « lancer_en_ligne »")
	elif zone["type"] == ZONE_LATIN_CROSS and int(data["portee"]["min"]) < 1:
		errors.append("une zone en croix latine demande une portée minimale d'au moins 1 (pour avoir un sens)")
	var recast: Variant = data.get("relance", {})
	if typeof(recast) != TYPE_DICTIONARY or not _is_int_at_least(recast.get("par_tour", 0), 0) \
			or not _is_int_at_least(recast.get("delai", 0), 0):
		errors.append("« relance » doit être { par_tour, delai } avec des entiers positifs ou nuls")
	var crit: Variant = data.get("critique", DEFAULT_CRIT_CHANCE)
	if not _is_int_at_least(crit, 0) or int(crit) > 100:
		errors.append("« critique » doit être un entier de 0 à 100 (chance de coup critique en %)")
	var effects_data: Variant = data.get("effets")
	if typeof(effects_data) != TYPE_ARRAY or effects_data.is_empty():
		errors.append("« effets » doit être une liste non vide")
		return errors
	errors.append_array(_validate_effects(effects_data, true))
	var traps := 0
	for effect: Variant in effects_data:
		if typeof(effect) == TYPE_DICTIONARY and effect.get("type") == EFFECT_TRAP:
			traps += 1
	if traps > 0 and (effects_data.size() > 1 or data.get("zone", {"type": ZONE_CELL}).get("type") != ZONE_CELL):
		errors.append("un sort de piège ne fait que poser son piège (un seul effet, zone « case » : la zone d'explosion va dans le piège)")
	return errors


static func _validate_effects(effects_data: Array, top_level: bool) -> PackedStringArray:
	var errors: PackedStringArray = []
	for effect: Variant in effects_data:
		if typeof(effect) != TYPE_DICTIONARY or effect.get("type") not in EFFECT_TYPES:
			errors.append("effet invalide : %s (types : %s)" % [str(effect), str(EFFECT_TYPES)])
			continue
		var type: String = effect["type"]
		if not top_level and (type in GROUND_EFFECTS or type == EFFECT_TELEPORT):
			errors.append("effet « %s » interdit dans une glyphe ou un piège" % type)
			continue
		if effect.get("cibles", TARGETS_ALL) not in TARGETS:
			errors.append("effet « %s » : « cibles » doit être l'un de %s" % [type, str(TARGETS)])
		if type in LASTING_EFFECTS and not _is_int_at_least(effect.get("duree"), 1):
			errors.append("effet « %s » : « duree » (en tours) doit être un entier ≥ 1" % type)
		if type in GROUND_EFFECTS:
			var inner: Variant = effect.get("effets")
			if typeof(inner) != TYPE_ARRAY or inner.is_empty():
				errors.append("effet « %s » : « effets » doit être une liste non vide" % type)
			else:
				errors.append_array(_validate_effects(inner, false))
			if type == EFFECT_TRAP:
				var zone: Variant = effect.get("zone", {"type": ZONE_CELL})
				if typeof(zone) != TYPE_DICTIONARY or zone.get("type") not in [ZONE_CELL, ZONE_CIRCLE] \
						or (zone["type"] == ZONE_CIRCLE and not _is_int_at_least(zone.get("taille"), 1)):
					errors.append("piège : « zone » doit être { type: case } ou { type: cercle, taille ≥ 1 }")
			continue
		if type == EFFECT_TELEPORT:
			continue
		if type in ELEMENT_EFFECTS and effect.get("element") not in ELEMENTS:
			errors.append("effet « %s » : « element » doit être l'un de %s" % [type, str(ELEMENTS)])
		if type in [EFFECT_BONUS, EFFECT_MALUS]:
			if effect.get("carac") not in MODIFIABLE:
				errors.append("effet « %s » : « carac » doit être l'un de %s" % [type, str(MODIFIABLE)])
			elif effect["carac"] == "resistance" and effect.get("element") not in ELEMENTS:
				errors.append("effet « %s » de résistance : « element » doit être l'un de %s" % [type, str(ELEMENTS)])
		if not _is_int_at_least(effect.get("min"), 0) or not _is_int_at_least(effect.get("max"), 0) \
				or int(effect["min"]) > int(effect["max"]):
			errors.append("effet « %s » : « min » et « max » doivent être des entiers avec min ≤ max" % type)
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
	spell.cast_in_line = bool(data.get("lancer_en_ligne", false))
	var zone: Dictionary = data.get("zone", {"type": ZONE_CELL})
	spell.zone_type = zone["type"]
	spell.zone_size = int(zone.get("taille", 0))
	spell.excludes_caster = bool(data.get("lanceur_exclu", false))
	var recast: Dictionary = data.get("relance", {})
	spell.casts_per_turn = int(recast.get("par_tour", 0))
	spell.cooldown = int(recast.get("delai", 0))
	spell.crit_chance = int(data.get("critique", DEFAULT_CRIT_CHANCE))
	spell.effects = normalized_effects(data["effets"])
	return spell


## Effets avec leurs valeurs par défaut (min, max, cibles, duree ; effets des glyphes et pièges).
static func normalized_effects(effects_data: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for effect: Dictionary in effects_data:
		var copy := effect.duplicate(true)
		copy["min"] = int(effect.get("min", 0))
		copy["max"] = int(effect.get("max", 0))
		copy["cibles"] = str(effect.get("cibles", TARGETS_ALL))
		copy["duree"] = int(effect.get("duree", 0))
		if effect.has("effets"):
			copy["effets"] = normalized_effects(effect["effets"])
		if effect["type"] == EFFECT_TRAP:
			copy["zone"] = effect.get("zone", {"type": ZONE_CELL}).duplicate()
		result.append(copy)
	return result


## Cases touchées quand le sort vise `target` depuis `origin` (la case du lanceur, qui donne le sens
## des zones orientées).
func zone_cells(target: Vector2i, origin := target) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [target]
	if zone_type == ZONE_LATIN_CROSS:
		var forward := direction(origin, target)
		var side := Vector2i(-forward.y, forward.x)
		for i in range(1, 4):
			cells.append(target + forward * i)
		cells.append(target + forward * 2 + side)
		cells.append(target + forward * 2 - side)
	if zone_type == ZONE_CIRCLE:
		cells = circle_cells(target, zone_size)
	return cells


## Cases à `size` pas au plus de `center` (distance de Manhattan), le centre en premier.
static func circle_cells(center: Vector2i, size: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [center]
	for dy in range(-size, size + 1):
		for dx in range(-size, size + 1):
			var offset := Vector2i(dx, dy)
			if offset != Vector2i.ZERO and absi(dx) + absi(dy) <= size:
				cells.append(center + offset)
	return cells


## Sens du lancer de `from` vers `to`, le long de l'axe le plus long (vers +x si les cases sont
## confondues).
static func direction(from: Vector2i, to: Vector2i) -> Vector2i:
	var delta := to - from
	if delta == Vector2i.ZERO:
		return Vector2i(1, 0)
	if absi(delta.x) >= absi(delta.y):
		return Vector2i(signi(delta.x), 0)
	return Vector2i(0, signi(delta.y))


## L'effet touche-t-il `target`, quand `caster` lance le sort ?
static func affects(effect: Dictionary, caster: Fighter, target: Fighter) -> bool:
	match effect.get("cibles", TARGETS_ALL):
		TARGETS_ENEMIES:
			return target.team != caster.team
		TARGETS_ALLIES:
			return target.team == caster.team
	return true


## Effet du sort qui pose un piège (vide s'il n'y en a pas).
func trap_effect() -> Dictionary:
	for effect in effects:
		if effect["type"] == EFFECT_TRAP:
			return effect
	return {}


func teleports() -> bool:
	for effect in effects:
		if effect["type"] == EFFECT_TELEPORT:
			return true
	return false


static func _is_int_at_least(value: Variant, minimum: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return value == floorf(value) and int(value) >= minimum
