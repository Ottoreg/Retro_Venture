class_name Item
extends RefCounted
## Règles des objets (données de `data/objets/`) : types, raretés, bonus, jets aléatoires, armes.

const TYPE_RESOURCE := "ressource"
const TYPE_WEAPON := "arme"
## Type d'objet → emplacements d'équipement possibles.
const SLOTS_BY_TYPE := {
	"arme": ["arme"], "coiffe": ["coiffe"], "cape": ["cape"], "amulette": ["amulette"],
	"anneau": ["anneau_1", "anneau_2"], "ceinture": ["ceinture"], "bottes": ["bottes"],
}
const SLOT_NAMES := {
	"arme": "Arme", "coiffe": "Coiffe", "cape": "Cape", "amulette": "Amulette",
	"anneau_1": "Anneau", "anneau_2": "Anneau", "ceinture": "Ceinture", "bottes": "Bottes",
}
const RARITIES := ["commun", "peu_commun", "rare", "epique", "legendaire", "relique"]
const RARITY_NAMES := {
	"commun": "Commun", "peu_commun": "Peu commun", "rare": "Rare",
	"epique": "Épique", "legendaire": "Légendaire", "relique": "Relique",
}
## Bonus que peut donner un équipement, en plus des 6 caractéristiques.
const EXTRA_STATS := ["prospection", "initiative", "portee", "pa", "pm"]
const EXTRA_STAT_NAMES := {
	"prospection": "Prospection", "initiative": "Initiative", "portee": "Portée", "pa": "PA", "pm": "PM",
}


static func is_equipment(template: Dictionary) -> bool:
	return SLOTS_BY_TYPE.has(template.get("type", ""))


static func bonus_stats() -> Array:
	return Character.STATS + EXTRA_STATS


static func stat_name(stat: String) -> String:
	return Character.STAT_NAMES.get(stat, EXTRA_STAT_NAMES.get(stat, stat))


## Liste des erreurs de `data` (vide si l'objet est valide).
static func validate(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(data.get("id")) != TYPE_STRING or str(data.get("id")).is_empty():
		errors.append("« id » doit être un texte non vide")
	if typeof(data.get("nom")) != TYPE_STRING:
		errors.append("« nom » doit être un texte")
	var type := str(data.get("type", ""))
	if type != TYPE_RESOURCE and not SLOTS_BY_TYPE.has(type):
		errors.append("« type » doit valoir « ressource » ou un type d'équipement : %s" % str(SLOTS_BY_TYPE.keys()))
	if data.get("rarete") not in RARITIES:
		errors.append("« rarete » doit valoir %s" % str(RARITIES))
	if not Spell._is_int_at_least(data.get("niveau", 1), 1):
		errors.append("« niveau » doit être un entier ≥ 1")
	var bonuses: Variant = data.get("bonus", {})
	if typeof(bonuses) != TYPE_DICTIONARY:
		errors.append("« bonus » doit être un objet { caractéristique: [min, max] }")
	else:
		for stat: Variant in bonuses:
			var span: Variant = bonuses[stat]
			if stat not in bonus_stats() or typeof(span) != TYPE_ARRAY or span.size() != 2 \
					or not Spell._is_int_at_least(span[0], 0) or not Spell._is_int_at_least(span[1], 0) or int(span[0]) > int(span[1]):
				errors.append("bonus « %s » : [min, max] attendu, caractéristiques : %s" % [str(stat), str(bonus_stats())])
		if type == TYPE_RESOURCE and not bonuses.is_empty():
			errors.append("une ressource n'a pas de bonus")
	var conditions: Variant = data.get("conditions", {})
	if typeof(conditions) != TYPE_DICTIONARY:
		errors.append("« conditions » doit être un objet { caractéristique: minimum }")
	else:
		for stat: Variant in conditions:
			if stat not in Character.STATS or not Spell._is_int_at_least(conditions[stat], 1):
				errors.append("condition « %s » invalide" % str(stat))
	if type == TYPE_WEAPON:
		var weapon: Variant = data.get("attaque")
		if typeof(weapon) != TYPE_DICTIONARY:
			errors.append("une arme doit avoir une « attaque » (comme un sort : cout_pa, portee, effets…)")
		else:
			for error in Spell.validate(weapon_spell_data(data)):
				errors.append("attaque : %s" % error)
	return errors


## Données de sort de l'attaque d'une arme (id « arme », nom de l'arme).
static func weapon_spell_data(template: Dictionary) -> Dictionary:
	var spell: Dictionary = template.get("attaque", {}).duplicate(true)
	spell["id"] = "arme"
	spell["nom"] = template.get("nom", "Arme")
	if not spell.has("description"):
		spell["description"] = "Attaque avec %s." % str(template.get("nom", "l'arme"))
	return spell


## Tire les bonus d'un équipement au hasard dans leurs plages (« jets »).
static func roll_bonuses(template: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var rolled := {}
	var bonuses: Dictionary = template.get("bonus", {})
	for stat: String in bonuses:
		rolled[stat] = rng.randi_range(int(bonuses[stat][0]), int(bonuses[stat][1]))
	return rolled
