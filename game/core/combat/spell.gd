class_name Spell
extends RefCounted
## Définition d'un sort, lue depuis `data/sorts/` (format : voir `data/README.md`).

const ZONE_CELL := "case"
const ZONE_CIRCLE := "cercle"
## Croix latine centrée sur la case visée (le croisement) : une case de chaque côté, une case
## au-delà (la tête, au loin) et deux en deçà (le pied, vers le lanceur, sans jamais atteindre sa
## case). Demande un lancer en ligne.
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
## Le lanceur gagne un état élémentaire permanent (`element` : flamme, givre ou tempete) : 3 au plus,
## le 4e remplace le plus ancien ; chacun donne `Fighter.ELEMENT_STATE_BONUS` % de dégâts dans son
## élément ; on ne peut pas le retirer. Voir `Fighter.element_states`.
const EFFECT_ELEMENT_STATE := "etat_elementaire"
## Le lanceur choisit d'un coup ses 3 états élémentaires parmi les combinaisons des `elements`
## (flamme, givre, tempete) : la commande de lancer porte la combinaison (`etats`, clé triée comme
## dans « creer_sort »), qui remplace ses états. Voir `state_choices`.
const EFFECT_COMPOSE_STATES := "composition_etats"
## Le lanceur reçoit le sort de `combinaisons` qui correspond à ses 3 états élémentaires (clé :
## les éléments triés, joints par « + », par exemple « flamme+flamme+givre ») ; 2 sorts créés au
## plus, le plus ancien part (voir `Fighter.add_created_spell`).
const EFFECT_CREATE_SPELL := "creer_sort"
## Charge : le lanceur fonce en ligne droite vers la case visée, jusqu'au contact du combattant qui
## s'y trouve (ou jusqu'à la case si elle est libre) ; un obstacle ou un combattant l'arrête avant.
## Les autres effets du sort ne touchent la cible que si la charge arrive au contact.
const EFFECT_CHARGE := "charge"
## Retire à la cible ses états retirables des types de `etats` (bonus, malus, poison).
const EFFECT_REMOVE_STATES := "retrait_etats"
## Horloge (Chronomancien) : pose un cadran au sol autour de la cible, qui passe dans l'état
## « manipulation_temps » pendant `duree` tours (non retirable). `heures` : { "1" … "12" : effets
## appliqués à la cible quand un décalage l'amène sur cette heure } (liste vide : sans effet). Une
## seule horloge par cible : une nouvelle remplace l'ancienne. Voir `Combat.CLOCK_RING`.
const EFFECT_CLOCK := "horloge"
## Décale la cible de `heures` heures sur son horloge (négatif : en arrière) ; sans effet sans
## horloge. Voir `Combat._shift_on_clock`.
const EFFECT_CLOCK_SHIFT := "decalage_horaire"
## État nommé (`etat`, voir NAMED_STATES) pendant `duree` tours de la cible.
const EFFECT_STATE := "etat"
const EFFECT_TYPES := [EFFECT_DAMAGE, EFFECT_HEAL, EFFECT_TELEPORT, EFFECT_GAIN_PA, EFFECT_REMOVE_PM, EFFECT_SHIELD,
	EFFECT_BONUS, EFFECT_MALUS, EFFECT_POISON, EFFECT_PUSH, EFFECT_PULL, EFFECT_GLYPH, EFFECT_TRAP,
	EFFECT_ELEMENT_STATE, EFFECT_COMPOSE_STATES, EFFECT_CREATE_SPELL, EFFECT_CHARGE, EFFECT_REMOVE_STATES,
	EFFECT_CLOCK, EFFECT_CLOCK_SHIFT, EFFECT_STATE]
## Effets sans valeur chiffrée (ni `min` ni `max`).
const VALUELESS_EFFECTS := [EFFECT_TELEPORT, EFFECT_ELEMENT_STATE, EFFECT_COMPOSE_STATES, EFFECT_CREATE_SPELL, EFFECT_CHARGE,
	EFFECT_REMOVE_STATES, EFFECT_CLOCK, EFFECT_CLOCK_SHIFT, EFFECT_STATE]
## Effets qui ne concernent que le lanceur ou son déplacement, ou le cadran d'une horloge : jamais
## dans une glyphe, un piège ou une heure d'horloge.
const CASTER_EFFECTS := [EFFECT_TELEPORT, EFFECT_ELEMENT_STATE, EFFECT_COMPOSE_STATES, EFFECT_CREATE_SPELL, EFFECT_CHARGE,
	EFFECT_CLOCK, EFFECT_CLOCK_SHIFT]
## États nommés : « insoignable » (aucun soin ne lui rend de PV) ; « manipulation_temps » (posé par
## une horloge).
const STATE_UNHEALABLE := "insoignable"
const STATE_TIME_MANIPULATION := "manipulation_temps"
const NAMED_STATES := [STATE_UNHEALABLE, STATE_TIME_MANIPULATION]
## Éléments d'un état élémentaire, et états qu'un retrait peut enlever.
const STATE_ELEMENTS := ["flamme", "givre", "tempete"]
const REMOVABLE_STATE_TYPES := [EFFECT_BONUS, EFFECT_MALUS, EFFECT_POISON]
## Effets qui posent quelque chose au sol, avec leurs propres `effets` (sans glyphe, piège ni
## téléportation à l'intérieur).
const GROUND_EFFECTS := [EFFECT_GLYPH, EFFECT_TRAP]
## Effets qui durent plusieurs tours (`duree` obligatoire).
const LASTING_EFFECTS := [EFFECT_BONUS, EFFECT_MALUS, EFFECT_POISON, EFFECT_GLYPH, EFFECT_CLOCK, EFFECT_STATE]
## Caractéristiques qu'un bonus ou un malus peut changer ; « resistance » demande un `element` ;
## « degats_infliges » : % de tous les dégâts infligés (poisons compris).
const MODIFIABLE := ["force", "intelligence", "perception", "agilite", "pa", "pm", "portee", "dommages", "critique", "resistance",
	"degats_infliges"]
## Effets chiffrés qui ont un élément : leur valeur monte avec la caractéristique de cet élément
## (un soin Sacré avec la Force et l'Intelligence, un bouclier de Tempête avec l'Agilité, un poison
## de Givre avec la Perception…).
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
## Maîtrise d'un sort (GDD § 4.5) : chaque rang ajoute ce pourcentage aux valeurs de base des effets
## élémentaires (dégâts, soins, boucliers, poisons) ; rang maximal.
const MASTERY_BONUS_PER_RANK := 10
const MASTERY_MAX_RANK := 5
## Changements qu'un rang de maîtrise peut apporter (« maitrise » : { "3": {…}, "5": {…} }) : ajouts
## (critique, portee_max), nouvelles valeurs (cout_pa, delai, zone_taille) et effets en plus (effets).
const MASTERY_ADDS := ["critique", "portee_max"]
const MASTERY_SETS := ["cout_pa", "delai", "zone_taille"]

var id: String
var display_name: String
var description: String
var pa_cost: int
var range_min: int
var range_max: int
var needs_line_of_sight: bool
## La cible doit être sur la même ligne ou la même colonne que le lanceur.
var cast_in_line: bool
## Portée non modifiable (« portee_fixe ») : les bonus de portée ne s'y ajoutent pas.
var fixed_range: bool
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
## Changements des rangs de maîtrise : rang → { critique?, portee_max?, cout_pa?, delai?, zone_taille?,
## effets? } (voir `mastered`).
var mastery: Dictionary = {}
## Rang de maîtrise de cet exemplaire du sort (0 : celui des données).
var rank := 0


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
	errors.append_array(_validate_mastery(data.get("maitrise", {})))
	var traps := 0
	for effect: Variant in effects_data:
		if typeof(effect) == TYPE_DICTIONARY and effect.get("type") == EFFECT_TRAP:
			traps += 1
	if traps > 0 and (effects_data.size() > 1 or data.get("zone", {"type": ZONE_CELL}).get("type") != ZONE_CELL):
		errors.append("un sort de piège ne fait que poser son piège (un seul effet, zone « case » : la zone d'explosion va dans le piège)")
	for effect: Variant in effects_data:
		if typeof(effect) == TYPE_DICTIONARY and effect.get("type") == EFFECT_CHARGE \
				and (not data.get("lancer_en_ligne", false) or int(data["portee"]["min"]) < 2):
			errors.append("une charge demande « lancer_en_ligne » et une portée minimale d'au moins 2")
	return errors


static func _validate_mastery(mastery_data: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(mastery_data) != TYPE_DICTIONARY:
		return PackedStringArray(["« maitrise » doit être un objet { rang : changements }"])
	for key: Variant in mastery_data:
		var changes: Variant = mastery_data[key]
		if not str(key).is_valid_int() or int(str(key)) < 1 or int(str(key)) > MASTERY_MAX_RANK or typeof(changes) != TYPE_DICTIONARY:
			errors.append("« maitrise » : « %s » doit être un rang de 1 à %d, vers un objet de changements" % [str(key), MASTERY_MAX_RANK])
			continue
		for change: Variant in changes:
			if change == "effets":
				if typeof(changes["effets"]) != TYPE_ARRAY or changes["effets"].is_empty():
					errors.append("« maitrise.%s.effets » doit être une liste non vide" % str(key))
				else:
					errors.append_array(_validate_effects(changes["effets"], false))
			elif change in MASTERY_ADDS:
				if typeof(changes[change]) not in [TYPE_INT, TYPE_FLOAT] or changes[change] != floorf(changes[change]):
					errors.append("« maitrise.%s.%s » doit être un entier" % [str(key), str(change)])
			elif change in MASTERY_SETS:
				if not _is_int_at_least(changes[change], 0):
					errors.append("« maitrise.%s.%s » doit être un entier positif ou nul" % [str(key), str(change)])
			else:
				errors.append("« maitrise.%s » : changement inconnu « %s » (%s, effets)" % [str(key), str(change),
					str(MASTERY_ADDS + MASTERY_SETS)])
	return errors


static func _validate_effects(effects_data: Array, top_level: bool) -> PackedStringArray:
	var errors: PackedStringArray = []
	for effect: Variant in effects_data:
		if typeof(effect) != TYPE_DICTIONARY or effect.get("type") not in EFFECT_TYPES:
			errors.append("effet invalide : %s (types : %s)" % [str(effect), str(EFFECT_TYPES)])
			continue
		var type: String = effect["type"]
		if not top_level and (type in GROUND_EFFECTS or type in CASTER_EFFECTS):
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
		if type == EFFECT_ELEMENT_STATE and effect.get("element") not in STATE_ELEMENTS:
			errors.append("effet « %s » : « element » doit être l'un de %s" % [type, str(STATE_ELEMENTS)])
		if type == EFFECT_COMPOSE_STATES:
			var elements: Variant = effect.get("elements")
			if typeof(elements) != TYPE_ARRAY or elements.is_empty() \
					or elements.any(func(element: Variant) -> bool: return element not in STATE_ELEMENTS or elements.count(element) > 1):
				errors.append("effet « composition_etats » : « elements » doit être une liste sans doublon parmi %s" % str(STATE_ELEMENTS))
		if type == EFFECT_CREATE_SPELL:
			var combinations: Variant = effect.get("combinaisons")
			if typeof(combinations) != TYPE_DICTIONARY or combinations.is_empty():
				errors.append("effet « creer_sort » : « combinaisons » doit être un objet { « élément+élément+élément » : id du sort }")
			else:
				for key: Variant in combinations:
					var parts := str(key).split("+")
					var sorted_parts := Array(parts)
					sorted_parts.sort()
					if parts.size() != Fighter.ELEMENT_STATE_MAX or sorted_parts != Array(parts) \
							or sorted_parts.any(func(part: String) -> bool: return part not in STATE_ELEMENTS) \
							or typeof(combinations[key]) != TYPE_STRING:
						errors.append("effet « creer_sort » : combinaison invalide « %s » (3 éléments de %s, triés, joints par « + », vers un id de sort)" % [str(key), str(STATE_ELEMENTS)])
		if type == EFFECT_STATE and effect.get("etat") not in NAMED_STATES:
			errors.append("effet « etat » : « etat » doit être l'un de %s" % str(NAMED_STATES))
		if type == EFFECT_CLOCK:
			var hours: Variant = effect.get("heures")
			if typeof(hours) != TYPE_DICTIONARY or hours.keys().any(func(key: Variant) -> bool:
					return not str(key).is_valid_int() or int(str(key)) < 1 or int(str(key)) > 12):
				errors.append("effet « horloge » : « heures » doit être un objet { « 1 » … « 12 » : liste d'effets }")
			else:
				for key: Variant in hours:
					if typeof(hours[key]) != TYPE_ARRAY:
						errors.append("effet « horloge » : l'heure %s doit être une liste d'effets (vide : sans effet)" % str(key))
					else:
						errors.append_array(_validate_effects(hours[key], false))
		if type == EFFECT_CLOCK_SHIFT:
			var shift: Variant = effect.get("heures")
			if typeof(shift) not in [TYPE_INT, TYPE_FLOAT] or shift != floorf(shift) or int(shift) == 0 or absi(int(shift)) > 11:
				errors.append("effet « decalage_horaire » : « heures » doit être un entier non nul de -11 à 11")
		if type == EFFECT_REMOVE_STATES:
			var kinds: Variant = effect.get("etats")
			if typeof(kinds) != TYPE_ARRAY or kinds.is_empty() or kinds.any(func(kind: Variant) -> bool: return kind not in REMOVABLE_STATE_TYPES):
				errors.append("effet « retrait_etats » : « etats » doit être une liste non vide parmi %s" % str(REMOVABLE_STATE_TYPES))
		if type in VALUELESS_EFFECTS:
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
	spell.fixed_range = bool(data.get("portee_fixe", false))
	var zone: Dictionary = data.get("zone", {"type": ZONE_CELL})
	spell.zone_type = zone["type"]
	spell.zone_size = int(zone.get("taille", 0))
	spell.excludes_caster = bool(data.get("lanceur_exclu", false))
	var recast: Dictionary = data.get("relance", {})
	spell.casts_per_turn = int(recast.get("par_tour", 0))
	spell.cooldown = int(recast.get("delai", 0))
	spell.crit_chance = int(data.get("critique", DEFAULT_CRIT_CHANCE))
	spell.effects = normalized_effects(data["effets"])
	var mastery_data: Dictionary = data.get("maitrise", {})
	for key: String in mastery_data:
		spell.mastery[int(key)] = mastery_data[key].duplicate(true)
	return spell


## Ce sort au rang de maîtrise `level` (GDD § 4.5) : valeurs de base des effets élémentaires
## +`MASTERY_BONUS_PER_RANK` % par rang (glyphes et pièges compris), puis les changements de chaque
## rang atteint, dans l'ordre. Le sort lui-même au rang 0.
func mastered(level: int) -> Spell:
	level = clampi(level, 0, MASTERY_MAX_RANK)
	if level == 0:
		return self
	var copy := Spell.new()
	for property in ["id", "display_name", "description", "pa_cost", "range_min", "range_max", "needs_line_of_sight",
			"cast_in_line", "fixed_range", "zone_type", "zone_size", "excludes_caster", "casts_per_turn", "cooldown", "crit_chance"]:
		copy.set(property, get(property))
	copy.mastery = mastery
	copy.rank = level
	copy.effects = _scaled_effects(effects, 100 + MASTERY_BONUS_PER_RANK * level)
	var ranks := mastery.keys()
	ranks.sort()
	for rank_reached: int in ranks:
		if rank_reached > level:
			break
		var changes: Dictionary = mastery[rank_reached]
		copy.crit_chance += int(changes.get("critique", 0))
		copy.range_max += int(changes.get("portee_max", 0))
		copy.pa_cost = int(changes.get("cout_pa", copy.pa_cost))
		copy.cooldown = int(changes.get("delai", copy.cooldown))
		copy.zone_size = int(changes.get("zone_taille", copy.zone_size))
		copy.effects.append_array(normalized_effects(changes.get("effets", [])))
	return copy


## Effets dont les valeurs élémentaires sont multipliées par `percent` %.
static func _scaled_effects(source: Array[Dictionary], percent: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for effect in source:
		var copy := effect.duplicate(true)
		if effect["type"] in ELEMENT_EFFECTS:
			copy["min"] = roundi(int(effect["min"]) * percent / 100.0)
			copy["max"] = roundi(int(effect["max"]) * percent / 100.0)
		if effect.has("effets"):
			var inner: Array[Dictionary] = []
			inner.assign(effect["effets"])
			copy["effets"] = _scaled_effects(inner, percent)
		if effect["type"] == EFFECT_CLOCK:
			for hour: String in effect["heures"]:
				var hour_effects: Array[Dictionary] = []
				hour_effects.assign(effect["heures"][hour])
				copy["heures"][hour] = _scaled_effects(hour_effects, percent)
		result.append(copy)
	return result


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
		if effect["type"] == EFFECT_CLOCK:
			var hours := {}
			for key: Variant in effect.get("heures", {}):
				hours[str(int(str(key)))] = normalized_effects(effect["heures"][key])
			copy["heures"] = hours
		if effect["type"] == EFFECT_CLOCK_SHIFT:
			copy["heures"] = int(effect["heures"])
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
		cells.append(target + forward)
		cells.append(target + side)
		cells.append(target - side)
		for i in range(1, mini(3, IsoGrid.distance(origin, target))):
			cells.append(target - forward * i)
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


func charges() -> bool:
	for effect in effects:
		if effect["type"] == EFFECT_CHARGE:
			return true
	return false


## Effet « creer_sort » du sort (vide s'il n'en a pas).
func create_effect() -> Dictionary:
	for effect in effects:
		if effect["type"] == EFFECT_CREATE_SPELL:
			return effect
	return {}


## Le sort sert à composer les états élémentaires ou à créer un sort (l'IA ne sait pas encore s'en
## servir).
func composes() -> bool:
	for effect in effects:
		if effect["type"] in [EFFECT_ELEMENT_STATE, EFFECT_COMPOSE_STATES, EFFECT_CREATE_SPELL]:
			return true
	return false


## Combinaisons qu'un sort « composition_etats » propose (clés triées, comme « flamme+flamme+givre »),
## dans l'ordre des éléments ; vide si le sort n'en a pas.
func state_choices() -> PackedStringArray:
	for effect in effects:
		if effect["type"] == EFFECT_COMPOSE_STATES:
			return combinations_of(effect["elements"])
	return PackedStringArray()


## Toutes les combinaisons de 3 états tirées de `elements` (clés triées), dans l'ordre alphabétique.
static func combinations_of(elements: Array) -> PackedStringArray:
	var sorted_elements := elements.duplicate()
	sorted_elements.sort()
	var choices: PackedStringArray = []
	_add_choices(sorted_elements, [], 0, choices)
	return choices


static func _add_choices(elements: Array, picked: Array, from: int, choices: PackedStringArray) -> void:
	if picked.size() == Fighter.ELEMENT_STATE_MAX:
		choices.append("+".join(PackedStringArray(picked)))
		return
	for i in range(from, elements.size()):
		_add_choices(elements, picked + [elements[i]], i, choices)


## Clé de combinaison de `states` (états élémentaires) : les éléments triés, joints par « + ».
static func combination_key(states: Array) -> String:
	var sorted_states := states.duplicate()
	sorted_states.sort()
	return "+".join(PackedStringArray(sorted_states))


func teleports() -> bool:
	for effect in effects:
		if effect["type"] == EFFECT_TELEPORT:
			return true
	return false


static func _is_int_at_least(value: Variant, minimum: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return value == floorf(value) and int(value) >= minimum
