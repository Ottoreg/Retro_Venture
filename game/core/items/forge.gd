class_name Forge
extends RefCounted
## Forge personnalisée (GDD § 10.4) : à l'enclume de la maison, on choisit un type d'objet et on y met
## des ressources. Chaque ressource de monstre donne une caractéristique (`caracteristique`), d'autant
## plus forte que son palier (`niveau`) est haut ; chaque type demande ses matières (`matiere`). L'objet
## sort avec des jets tirés au hasard, un nom fait de mots proposés et la signature de l'artisan. Un plan
## (objet de type « recette ») donne d'avance le type, les ressources et le nom.

const JOB := "forgeron"
const TYPE_RECIPE := "recette"
## Ressources différentes au plus par objet (cases de l'enclume), matières obligatoires comprises ; la
## quantité de chacune est libre, bornée par le plafond des lignes.
const MAX_SLOTS := 8
## Score d'une ligne au plus (points de Force : `STAT_WEIGHTS`) et lignes au plus par objet. Les essences
## (GDD § 9.2, à venir) pourront dépasser le score d'une ligne.
const MAX_LINE_SCORE := 100
const MAX_LINES := 8
## Une ligne de total T se tire entre T × ROLL_LOW et T (plus haut avec la compétence « precision »).
const ROLL_LOW := 0.75
## Réputation de forgeron de base par palier de l'objet forgé (`Profession.reputation_gain`).
const REPUTATION_PER_TIER := 5
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


## Caractéristiques d'une ressource : `caracteristique` est un nom, ou une liste pour une ressource de
## haut palier qui en donne plusieurs (chacune à sa valeur pleine).
static func stats_of(item: Dictionary) -> Array:
	var stats: Variant = item.get("caracteristique", [])
	return stats if typeof(stats) == TYPE_ARRAY else [stats]


## Valeur d'une ligne au plus : MAX_LINE_SCORE points de Force (1 pour PA, PM et Portée).
static func line_cap(stat: String) -> int:
	return 1 if stat in FIXED_STATS else floori(MAX_LINE_SCORE * STAT_WEIGHTS[stat])


## Caractéristique que donne une ressource de ce palier.
static func value(stat: String, tier: int) -> int:
	return 1 if stat in FIXED_STATS else maxi(1, roundi((1.0 + tier / 8.0) * STAT_WEIGHTS[stat]))


## Vrai si l'artisan voit la caractéristique des ressources de ce palier : il a déjà forgé, et le niveau
## équivalent de sa réputation de forgeron (`Progression.equivalent_level`) atteint le palier.
static func reveals(character: Character, tier: int) -> bool:
	var reputation_value := character.job_reputation(JOB)
	return reputation_value > 0 and tier <= Progression.equivalent_level(reputation_value)


## Aperçu de l'objet : { erreur (raison du protocole, "" si on peut forger), palier, bonus: { stat:
## [min, max] }, cachees (ressources à caractéristique cachée pour `character`), manquantes (matières) }.
## Le plancher des jets suit la Précision de `character` ; `hide` : cacher ce qu'il ne sait pas lire
## (faux pour le serveur et pour un plan, qui montre tout).
static func preview(type: String, resources: Dictionary, items: Dictionary, character: Character = null, hide := true) -> Dictionary:
	var result := {"erreur": "", "palier": 1, "bonus": {}, "cachees": 0, "manquantes": []}
	if not TYPES.has(type) or not items.has(template_id(type)):
		result["erreur"] = Protocol.REASON_INVALID_COMMAND
		return result
	if resources.size() > MAX_SLOTS:
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
		if character != null and hide and item.has("caracteristique") and not reveals(character, tier):
			result["cachees"] += quantity
			continue
		for stat: String in stats_of(item):
			totals[stat] = int(totals.get(stat, 0)) + quantity * value(stat, tier)
	for material: String in TYPES[type]["matieres"]:
		if material not in materials:
			result["manquantes"].append(material)
	if totals.size() > MAX_LINES:
		result["erreur"] = Protocol.REASON_TOO_MANY_LINES
	elif not result["manquantes"].is_empty():
		result["erreur"] = Protocol.REASON_MISSING_INGREDIENTS
	result["palier"] = maxi(1, roundi(float(tiers) / maxi(1, count)))
	var low := ROLL_LOW + (Profession.skill_value(Profession.TYPE_CRAFT, "precision", character.job_rank(JOB, "precision")) / 100.0 if character != null else 0.0)
	for stat: String in totals:
		var total: int = mini(line_cap(stat), totals[stat])
		result["bonus"][stat] = [total if stat in FIXED_STATS else maxi(1, roundi(total * minf(1.0, low))), total]
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


## Nom formé de `words` (nom du type puis adjectifs des lignes `stats`, accordés, deux d'une même ligne permis mais jamais
## deux fois le même mot), ou "" si ces mots ne sont pas permis.
static func name_of(words: Variant, type: String, stats: Array) -> String:
	if typeof(words) != TYPE_ARRAY or words.is_empty() or words.size() > MAX_ADJECTIVES + 1 or typeof(words[0]) != TYPE_STRING:
		return ""
	var noun_gender := gender(type, words[0])
	if noun_gender.is_empty():
		return ""
	var adjectives: Array = words.slice(1)
	for word: Variant in adjectives:
		if adjectives.count(word) > 1 or not stats.any(func(stat: String) -> bool:
				return WORDS.get(stat, []).any(func(forms: Array) -> bool: return adjective(forms, noun_gender) == word)):
			return ""
	return " ".join(words)


## Jets de l'objet forgé, tirés dans les plages de l'aperçu.
static func roll(bonus: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var rolled := {}
	for stat: String in bonus:
		rolled[stat] = rng.randi_range(int(bonus[stat][0]), int(bonus[stat][1]))
	return rolled


## Attaque d'une arme forgée : dégâts de base × (1 + (palier − 1) / 20), dans l'élément de la caractéristique
## élémentaire la plus forte de ses lignes (`bonus`, au maximum de leur plage ; celui de l'arme à égalité ou sans).
## Si les deux caractéristiques d'un élément composé (Sacré : Force et Intelligence, Impie : Agilité et Perception)
## sont à 10 % au plus de la plus forte, l'arme frappe dans cet élément composé.
static func scaled_attack(attack: Dictionary, tier: int, bonus := {}) -> Dictionary:
	var scaled := attack.duplicate(true)
	var scores := {}
	for element: String in Fighter.ELEMENT_STATS:
		scores[element] = int(bonus.get(Fighter.ELEMENT_STATS[element], [0, 0])[1])
	var top: int = scores.values().max()
	for effect: Dictionary in scaled.get("effets", []):
		if effect.get("type") == Spell.EFFECT_DAMAGE:
			for key in ["min", "max"]:
				effect[key] = roundi(effect[key] * (1.0 + (tier - 1) / 20.0))
			if top > 0 and scores.get(effect["element"], 0) < top:
				effect["element"] = scores.find_key(top)
			for composite: String in Spell.COMPOSITE_ELEMENTS:
				if top > 0 and Spell.COMPOSITE_ELEMENTS[composite].all(func(base: String) -> bool: return scores[base] >= top * 0.9):
					effect["element"] = composite
	return scaled


## Erreurs d'un plan (`recette` d'un objet de type « recette »).
static func validate_recipe(recipe: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(recipe) != TYPE_DICTIONARY or typeof(recipe.get("nom")) != TYPE_STRING or not TYPES.has(recipe.get("type")) \
			or typeof(recipe.get("ressources")) != TYPE_DICTIONARY or recipe["ressources"].is_empty():
		errors.append("« recette » doit être { nom, type (%s), ressources: { id: quantité } }" % str(TYPES.keys()))
	return errors
