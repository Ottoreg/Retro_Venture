class_name Profession
extends RefCounted
## Règles des métiers (données de `data/metiers/`) : métiers de récolte (bûcheron, mineur), dont les
## ressources sont placées sur les cartes et repoussent, et métiers d'artisanat (forgeron, qui forge à
## l'enclume : `Forge`). Tout est ouvert dès le début : on gagne de la réputation de métier selon la
## difficulté de ce qu'on récolte ou forge, et des points de maîtrise à placer dans des compétences qui
## améliorent la qualité, sans jamais faire échouer (GDD § 10.2).

const TYPE_HARVEST := "recolte"
const TYPE_CRAFT := "artisanat"
## Dessin d'une ressource sur la carte.
const APPEARANCES := ["arbre", "rocher"]
## Chance qu'une récolte donne la ressource rare du nœud (`rare`) à la place de la ressource de base :
## un seul exemplaire, pour les recettes améliorées.
const RARE_CHANCE := 0.01
## Durée d'une récolte en secondes : base + par palier de la ressource (palier 1 : 1,75 s, 22 : 7 s).
const HARVEST_BASE_TIME := 1.5
const HARVEST_TIME_PER_TIER := 0.25
## Compétences par type de métier : id → [nom, effet par rang (texte : %s = valeur), valeur par rang].
const SKILLS := {
	TYPE_HARVEST: {
		"abondance": ["Abondance", "+%s %% de chances d'une ressource de plus", 20],
		"oeil": ["Œil exercé", "+%s %% de chances de ressource rare", 0.5],
	},
	TYPE_CRAFT: {
		"precision": ["Précision", "+%s %% au plancher des jets (75 %% du maximum au départ)", 5],
	},
}


static func harvest_time(tier: int) -> float:
	return HARVEST_BASE_TIME + HARVEST_TIME_PER_TIER * tier


## Compétences d'un métier de ce type.
static func skills(type: String) -> Array:
	return SKILLS.get(type, {}).keys()


## Effet d'une compétence au rang `rank` (valeur par rang × rang).
static func skill_value(type: String, skill_id: String, rank: int) -> float:
	return float(SKILLS[type][skill_id][2]) * rank


## Réputation de métier gagnée : `base` (celle du nœud, ou de la forge) × 2 × le facteur de difficulté
## du palier contre la réputation de l'artisan (le même qu'en combat : × 1 à sa mesure) + bonus en %.
static func reputation_gain(base: int, tier: int, reputation_value: int, bonus_percent: int) -> int:
	var factor := Progression.difficulty([tier], [Progression.equivalent_level(reputation_value)])
	return roundi(base * 2.0 * factor * (100 + bonus_percent) / 100.0)


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
	elif type != TYPE_CRAFT:
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
	if node.has("rare"):
		var rare: Dictionary = known_items.get(node["rare"], {})
		if rare.is_empty() or str(rare.get("type")) != Item.TYPE_RESOURCE or node["rare"] == node.get("objet"):
			errors.append("ressource %s : « rare » doit être une autre ressource connue" % label)
	if typeof(node.get("couleur", "ffffff")) != TYPE_STRING or not Color.html_is_valid(str(node.get("couleur", "ffffff"))):
		errors.append("ressource %s : « couleur » doit être une couleur (« 6f9a3e »)" % label)
	return errors


static func _is_range(value: Variant, minimum: int) -> bool:
	return typeof(value) == TYPE_ARRAY and value.size() == 2 and Spell._is_int_at_least(value[0], minimum) \
		and Spell._is_int_at_least(value[1], minimum) and int(value[0]) <= int(value[1])
