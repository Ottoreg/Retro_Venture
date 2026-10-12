class_name Profession
extends RefCounted
## Règles des métiers (données de `data/metiers/`) : métiers de récolte (bûcheron, mineur), dont les
## ressources sont placées sur les cartes et repoussent, et métiers d'artisanat (forgeron), qui
## fabriquent des objets à partir de recettes.

const TYPE_HARVEST := "recolte"
const TYPE_CRAFT := "artisanat"
const MAX_LEVEL := 100
## Dessin d'une ressource sur la carte.
const APPEARANCES := ["arbre", "rocher"]


## XP de métier totale nécessaire pour atteindre `target_level` (0 pour le niveau 1).
static func xp_for_level(target_level: int) -> int:
	return 5 * target_level * (target_level - 1)


static func level_for_xp(xp: int) -> int:
	var level := 1
	while level < MAX_LEVEL and xp >= xp_for_level(level + 1):
		level += 1
	return level


## Vrai pour un caractère de plan qui place une ressource : lettre majuscule hors de `GameMap.LEGEND`.
static func is_node_char(character: String) -> bool:
	return character.length() == 1 and character >= "A" and character <= "Z" and not GameMap.LEGEND.has(character)


## Liste des erreurs de `data` (vide si le métier est valide).
static func validate(data: Dictionary, known_items: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(data.get("id")) != TYPE_STRING or str(data.get("id")).is_empty():
		errors.append("« id » doit être un texte non vide")
	if typeof(data.get("nom")) != TYPE_STRING:
		errors.append("« nom » doit être un texte")
	var type := str(data.get("type", ""))
	if type == TYPE_HARVEST:
		var nodes: Variant = data.get("ressources")
		if typeof(nodes) != TYPE_ARRAY or nodes.is_empty():
			errors.append("« ressources » doit être une liste non vide")
		else:
			for node: Variant in nodes:
				errors.append_array(_validate_node(node, known_items))
	elif type == TYPE_CRAFT:
		var recipes: Variant = data.get("recettes")
		if typeof(recipes) != TYPE_ARRAY or recipes.is_empty():
			errors.append("« recettes » doit être une liste non vide")
		else:
			for recipe: Variant in recipes:
				errors.append_array(_validate_recipe(recipe, known_items))
	else:
		errors.append("« type » doit valoir « %s » ou « %s »" % [TYPE_HARVEST, TYPE_CRAFT])
	return errors


static func _validate_node(node: Variant, known_items: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(node) != TYPE_DICTIONARY:
		errors.append("ressource : objet attendu")
		return errors
	var label := str(node.get("nom", "?"))
	if typeof(node.get("marqueur")) != TYPE_STRING or not is_node_char(node["marqueur"]):
		errors.append("ressource %s : « marqueur » doit être une lettre majuscule hors de %s" % [label, str(GameMap.LEGEND.keys())])
	if typeof(node.get("nom")) != TYPE_STRING:
		errors.append("ressource : « nom » doit être un texte")
	var item: Dictionary = known_items.get(node.get("objet"), {})
	if item.is_empty() or str(item.get("type")) != Item.TYPE_RESOURCE:
		errors.append("ressource %s : « objet » doit être une ressource connue" % label)
	if not Spell._is_int_at_least(node.get("niveau", 1), 1):
		errors.append("ressource %s : « niveau » doit être un entier ≥ 1" % label)
	if not Spell._is_int_at_least(node.get("xp", 0), 0):
		errors.append("ressource %s : « xp » doit être un entier ≥ 0" % label)
	if not _is_range(node.get("quantite", [1, 1]), 1):
		errors.append("ressource %s : « quantite » doit être [min, max]" % label)
	if not _is_range(node.get("repousse"), 1):
		errors.append("ressource %s : « repousse » doit être [min, max] en secondes" % label)
	if node.get("apparence") not in APPEARANCES:
		errors.append("ressource %s : « apparence » doit valoir %s" % [label, str(APPEARANCES)])
	if typeof(node.get("couleur", "ffffff")) != TYPE_STRING or not Color.html_is_valid(str(node.get("couleur", "ffffff"))):
		errors.append("ressource %s : « couleur » doit être une couleur (« 6f9a3e »)" % label)
	return errors


static func _validate_recipe(recipe: Variant, known_items: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(recipe) != TYPE_DICTIONARY or not known_items.has(recipe.get("objet")):
		errors.append("recette : « objet » doit être un objet connu (%s)" % str(recipe))
		return errors
	var label := str(recipe["objet"])
	if not Spell._is_int_at_least(recipe.get("niveau", 1), 1):
		errors.append("recette %s : « niveau » doit être un entier ≥ 1" % label)
	if not Spell._is_int_at_least(recipe.get("xp", 0), 0):
		errors.append("recette %s : « xp » doit être un entier ≥ 0" % label)
	var ingredients: Variant = recipe.get("ingredients")
	if typeof(ingredients) != TYPE_DICTIONARY or ingredients.is_empty():
		errors.append("recette %s : « ingredients » doit être un objet { ressource: quantité } non vide" % label)
		return errors
	for item_id: Variant in ingredients:
		var item: Dictionary = known_items.get(item_id, {})
		if item.is_empty() or str(item.get("type")) != Item.TYPE_RESOURCE or not Spell._is_int_at_least(ingredients[item_id], 1):
			errors.append("recette %s : ingrédient « %s » invalide (ressource connue et quantité ≥ 1)" % [label, str(item_id)])
	return errors


static func _is_range(value: Variant, minimum: int) -> bool:
	return typeof(value) == TYPE_ARRAY and value.size() == 2 and Spell._is_int_at_least(value[0], minimum) \
		and Spell._is_int_at_least(value[1], minimum) and int(value[0]) <= int(value[1])
