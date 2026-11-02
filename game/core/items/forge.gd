class_name Forge
extends RefCounted
## Forge personnalisée (GDD § 10.4) : à l'enclume de la maison, on choisit un type d'objet et on y met
## des ressources. Chaque ressource de monstre donne une caractéristique (`caracteristique`), d'autant
## plus forte que son palier (`niveau`) est haut ; chaque type demande ses matières (`matiere`). L'objet
## sort avec des jets tirés au hasard, un nom fait de mots proposés et la signature de l'artisan. Un plan
## (objet de type « recette ») donne d'avance le type, les ressources et le nom.

const JOB := "forgeron"
const TYPE_RECIPE := "recette"
## Ressources au plus par objet, matières obligatoires comprises.
const MAX_RESOURCES := 6
## Une ligne de total T se tire entre T × ROLL_LOW et T.
const ROLL_LOW := 0.75
## XP de forgeron par palier de l'objet forgé.
const XP_PER_TIER := 5
## Caractéristiques à 1 par ressource quel que soit le palier, et à 1 au plus par objet.
const FIXED_STATS := ["pa", "pm", "portee"]
## Points de la caractéristique pour un point de Force (d'après le score du GDD § 10.4).
const STAT_WEIGHTS := {"force": 1.0, "intelligence": 1.0, "perception": 1.0, "agilite": 1.0, "vitalite": 4.0,
	"initiative": 10.0, "prospection": 0.34, "dommages": 0.34, "critique": 0.1}
const MATERIALS := ["cuir", "tissu", "minerai", "bois"]
## Type d'objet à l'enclume (modèle `forge_<type>`) → matières obligatoires et noms proposés [nom, genre].
const TYPES := {
	"coiffe": {"matieres": ["tissu"], "noms": [["Coiffe", "f"], ["Chapeau", "m"], ["Bonnet", "m"], ["Heaume", "m"]]},
	"cape": {"matieres": ["tissu"], "noms": [["Cape", "f"], ["Manteau", "m"], ["Pèlerine", "f"]]},
	"amulette": {"matieres": ["minerai"], "noms": [["Amulette", "f"], ["Médaillon", "m"], ["Pendentif", "m"]]},
	"anneau": {"matieres": ["minerai"], "noms": [["Anneau", "m"], ["Bague", "f"], ["Chevalière", "f"]]},
	"ceinture": {"matieres": ["cuir"], "noms": [["Ceinture", "f"], ["Ceinturon", "m"]]},
	"bottes": {"matieres": ["cuir"], "noms": [["Bottes", "fp"], ["Souliers", "mp"], ["Sandales", "fp"]]},
	"epee": {"matieres": ["minerai", "bois"], "noms": [["Épée", "f"], ["Lame", "f"], ["Glaive", "m"]]},
	"arc": {"matieres": ["minerai", "bois"], "noms": [["Arc", "m"], ["Fronde", "f"]]},
	"baton": {"matieres": ["minerai", "bois"], "noms": [["Bâton", "m"], ["Canne", "f"]]},
	"dague": {"matieres": ["minerai", "bois"], "noms": [["Dague", "f"], ["Couteau", "m"], ["Surin", "m"]]},
	"masse": {"matieres": ["minerai", "bois"], "noms": [["Masse", "f"], ["Marteau", "m"], ["Gourdin", "m"]]},
	"sceptre": {"matieres": ["minerai", "bois"], "noms": [["Sceptre", "m"], ["Baguette", "f"]]},
}
const TYPE_NAMES := {"coiffe": "Coiffe", "cape": "Cape", "amulette": "Amulette", "anneau": "Anneau", "ceinture": "Ceinture",
	"bottes": "Bottes", "epee": "Épée", "arc": "Arc", "baton": "Bâton", "dague": "Dague", "masse": "Masse", "sceptre": "Sceptre"}
## Adjectifs proposés par caractéristique : [masculin, féminin] (pluriel : + « s », sauf après s ou x).
const WORDS := {
	"force": [["costaud", "costaude"], ["massif", "massive"], ["rancunier", "rancunière"]],
	"intelligence": [["flamboyant", "flamboyante"], ["torride", "torride"], ["enflammé", "enflammée"]],
	"perception": [["givré", "givrée"], ["frileux", "frileuse"], ["perçant", "perçante"]],
	"agilite": [["venteux", "venteuse"], ["leste", "leste"], ["virevoltant", "virevoltante"]],
	"vitalite": [["robuste", "robuste"], ["dodu", "dodue"], ["increvable", "increvable"]],
	"initiative": [["pressé", "pressée"], ["matinal", "matinale"]],
	"prospection": [["fouineur", "fouineuse"], ["chanceux", "chanceuse"]],
	"dommages": [["cogneur", "cogneuse"], ["brutal", "brutale"]],
	"critique": [["précis", "précise"], ["vicieux", "vicieuse"]],
	"pa": [["rapide", "rapide"], ["fulgurant", "fulgurante"]],
	"pm": [["voyageur", "voyageuse"], ["infatigable", "infatigable"]],
	"portee": [["lointain", "lointaine"], ["clairvoyant", "clairvoyante"]],
}
const MAX_ADJECTIVES := 2


static func template_id(type: String) -> String:
	return "forge_" + type


## Caractéristique que donne une ressource de ce palier.
static func value(stat: String, tier: int) -> int:
	return 1 if stat in FIXED_STATS else maxi(1, roundi((1.0 + tier / 8.0) * STAT_WEIGHTS[stat]))


## Vrai si l'artisan voit la caractéristique des ressources de ce palier : il a déjà forgé, et son
## niveau de forgeron atteint le palier.
static func reveals(character: Character, tier: int) -> bool:
	return character.job_xp(JOB) > 0 and tier <= character.job_level(JOB)


## Aperçu de l'objet : { erreur (raison du protocole, "" si on peut forger), palier, bonus: { stat:
## [min, max] }, cachees (ressources à caractéristique cachée pour `character`), manquantes (matières) }.
## Sans `character`, tout est visible (le serveur). `revealed` : un plan montre tout.
static func preview(type: String, resources: Dictionary, items: Dictionary, character: Character = null) -> Dictionary:
	var result := {"erreur": "", "palier": 1, "bonus": {}, "cachees": 0, "manquantes": []}
	if not TYPES.has(type) or not items.has(template_id(type)):
		result["erreur"] = Protocol.REASON_INVALID_COMMAND
		return result
	var count := 0
	var tiers := 0
	var totals := {}
	var materials: Array = []
	for item_id: Variant in resources:
		var item: Dictionary = items.get(item_id, {})
		if item.get("type") != Item.TYPE_RESOURCE or typeof(resources[item_id]) not in [TYPE_INT, TYPE_FLOAT] or int(resources[item_id]) < 1:
			result["erreur"] = Protocol.REASON_INVALID_COMMAND
			return result
		var quantity := int(resources[item_id])
		var tier := int(item.get("niveau", 1))
		count += quantity
		tiers += quantity * tier
		materials.append(item.get("matiere", ""))
		var stat: String = item.get("caracteristique", "")
		if character != null and not stat.is_empty() and not reveals(character, tier):
			result["cachees"] += quantity
		elif not stat.is_empty():
			totals[stat] = int(totals.get(stat, 0)) + quantity * value(stat, tier)
	for material: String in TYPES[type]["matieres"]:
		if material not in materials:
			result["manquantes"].append(material)
	if count > MAX_RESOURCES:
		result["erreur"] = Protocol.REASON_INVALID_COMMAND
	elif not result["manquantes"].is_empty():
		result["erreur"] = Protocol.REASON_MISSING_INGREDIENTS
	result["palier"] = maxi(1, roundi(float(tiers) / maxi(1, count)))
	for stat: String in totals:
		var total: int = mini(1, totals[stat]) if stat in FIXED_STATS else totals[stat]
		result["bonus"][stat] = [total if stat in FIXED_STATS else maxi(1, roundi(total * ROLL_LOW)), total]
	return result


## Nom par défaut : le premier nom du type et l'adjectif de la ligne la plus forte (en points de Force ;
## PA, PM et Portée l'emportent toujours).
static func default_words(type: String, bonus: Dictionary) -> Array:
	var words: Array = [TYPES[type]["noms"][0][0]]
	var best := ""
	for stat: String in bonus:
		if best.is_empty() or bonus[stat][1] * STAT_WEIGHTS.get(best, 0.01) > bonus[best][1] * STAT_WEIGHTS.get(stat, 0.01):
			best = stat
	if not best.is_empty():
		words.append(adjective(WORDS[best][0], gender(type, words[0])))
	return words


## Genre du nom (« m », « f », « mp », « fp »), ou "" s'il n'est pas proposé pour ce type.
static func gender(type: String, noun: String) -> String:
	for entry: Array in TYPES.get(type, {}).get("noms", []):
		if entry[0] == noun:
			return entry[1]
	return ""


## Adjectif accordé : `forms` = [masculin, féminin].
static func adjective(forms: Array, noun_gender: String) -> String:
	var word: String = forms[1] if noun_gender.begins_with("f") else forms[0]
	return word + "s" if noun_gender.ends_with("p") and not word.ends_with("s") and not word.ends_with("x") else word


## Nom formé de `words` (nom du type puis adjectifs de caractéristiques différentes de `stats`, accordés),
## ou "" si ces mots ne sont pas permis.
static func name_of(words: Variant, type: String, stats: Array) -> String:
	if typeof(words) != TYPE_ARRAY or words.is_empty() or words.size() > MAX_ADJECTIVES + 1 or typeof(words[0]) != TYPE_STRING:
		return ""
	var noun_gender := gender(type, words[0])
	if noun_gender.is_empty():
		return ""
	var used: Array = []
	for word: Variant in words.slice(1):
		var found := ""
		for stat: String in stats:
			for forms: Array in WORDS.get(stat, []):
				if stat not in used and adjective(forms, noun_gender) == word:
					found = stat
		if found.is_empty():
			return ""
		used.append(found)
	return " ".join(words)


## Jets de l'objet forgé, tirés dans les plages de l'aperçu.
static func roll(bonus: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var rolled := {}
	for stat: String in bonus:
		rolled[stat] = rng.randi_range(int(bonus[stat][0]), int(bonus[stat][1]))
	return rolled


## Attaque d'une arme forgée : dégâts de base × (1 + (palier − 1) / 20).
static func scaled_attack(attack: Dictionary, tier: int) -> Dictionary:
	var scaled := attack.duplicate(true)
	for effect: Dictionary in scaled.get("effets", []):
		if effect.get("type") == Spell.EFFECT_DAMAGE:
			for key in ["min", "max"]:
				effect[key] = roundi(effect[key] * (1.0 + (tier - 1) / 20.0))
	return scaled


## Erreurs d'un plan (`recette` d'un objet de type « recette »).
static func validate_recipe(recipe: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(recipe) != TYPE_DICTIONARY or typeof(recipe.get("nom")) != TYPE_STRING or not TYPES.has(recipe.get("type")) \
			or typeof(recipe.get("ressources")) != TYPE_DICTIONARY or recipe["ressources"].is_empty():
		errors.append("« recette » doit être { nom, type (%s), ressources: { id: quantité } }" % str(TYPES.keys()))
	return errors
