class_name Forge
extends RefCounted
## Forge personnalisée (GDD § 10.4) : à l'enclume de la maison, on choisit un type d'objet et on y met
## des ressources. Chaque ressource de monstre donne une caractéristique (`caracteristique`), d'autant
## plus forte que son palier (`niveau`) est haut ; chaque type demande ses matières (`matiere`). L'objet
## sort avec des jets tirés au hasard, un nom fait de mots proposés et la signature de l'artisan. Un plan
## (objet de type « recette ») donne d'avance le type, les ressources et le nom.

const JOB := "forgeron"
const TYPE_RECIPE := "recette"
## Feuille de papier posée dans la 9e case de l'enclume : elle devient le patron de l'objet forgé (`PATTERN`).
const PAPER := "feuille_de_papier"
const PATTERN := "patron"
## Ressources différentes au plus par objet (cases de l'enclume), matières obligatoires comprises ; la
## quantité de chacune est libre, bornée par le plafond des lignes.
const MAX_SLOTS := 8
## Score d'une ligne au plus (points de score : `STAT_WEIGHTS`) par palier de réputation de forgeron (Apprenti 1 à
## Légende 5, Inconnu compté 1 : `tier`), donc 20 à 100 ; lignes au plus par objet : 160 à 800 points de score par
## objet. Les essences (GDD § 9.2, à venir) pourront dépasser le score d'une ligne.
const LINE_SCORE_PER_TIER := 20
const MAX_TIER := 5
const MAX_LINES := 8
## Une ligne de total T se tire entre T × ROLL_LOW et T (plus haut avec la compétence « precision »).
const ROLL_LOW := 0.75
## Réputation de forgeron de base par palier de l'objet forgé (1 à 5, `Profession.reputation_gain`).
const REPUTATION_PER_TIER := 25
## Caractéristiques à 1 par ressource quel que soit le palier, et à 1 au plus par objet : points de score de ce
## point (indisponible tant que le plafond d'une ligne est plus bas).
const FIXED_STATS := {"pa": 100, "pm": 80, "portee": 60}
## Points de la caractéristique pour un point de score (inverse du score du GDD § 10.4 : le plafond d'une ligne
## en découle, 12 % de résistance pour 8 points par %).
const STAT_WEIGHTS := {"force": 1.0, "intelligence": 1.0, "perception": 1.0, "agilite": 1.0, "vitalite": 4.0,
	"initiative": 10.0, "prospection": 0.34, "dommages": 0.34, "critique": 0.1,
	"soins": 0.34, "degats_devastateurs": 0.1, "degats_devastateurs_fixes": 0.05, "degats_spectraux": 0.1, "degats_spectraux_fixes": 0.05,
	"reduction_degats": 0.0833, "dommages_melee": 0.0333, "tacle": 0.1, "fuite": 0.1, "retrait_pa": 0.2, "retrait_pm": 0.2,
	"epines_brutes": 0.05, "epines_brutes_fixes": 0.0714,
	"epines_acier": 0.0625, "epines_flamme": 0.0625, "epines_givre": 0.0625, "epines_tempete": 0.0625, "epines_sacre": 0.0625, "epines_impie": 0.0625,
	"epines_acier_fixes": 0.0909, "epines_flamme_fixes": 0.0909, "epines_givre_fixes": 0.0909, "epines_tempete_fixes": 0.0909,
	"epines_sacre_fixes": 0.0909, "epines_impie_fixes": 0.0909,
	"dommages_acier": 0.5, "dommages_flamme": 0.5, "dommages_givre": 0.5, "dommages_tempete": 0.5, "dommages_sacre": 0.5, "dommages_impie": 0.5,
	"soins_acier": 0.5, "soins_flamme": 0.5, "soins_givre": 0.5, "soins_tempete": 0.5, "soins_sacre": 0.5, "soins_impie": 0.5,
	"resistance_acier": 0.125, "resistance_flamme": 0.125, "resistance_givre": 0.125, "resistance_tempete": 0.125,
	"resistance_sacre": 0.125, "resistance_impie": 0.125,
	"profusion": 0.3, "flair": 0.5, "dexterite": 0.15, "minutie": 0.1, "epargne": 0.1, "distillation": 0.1, "sagacite": 0.05, "main_verte": 0.2}
## Statistiques de métier (GDD § 10.4) : seulement sur les outils, tirées de la statistique de combat des ressources
## (préfixe « dommages_ » : toutes les lignes qui commencent ainsi), à score égal (`Infusion.score`) ; les autres sont perdues.
const JOB_STATS := {"force": "profusion", "agilite": "dexterite", "initiative": "dexterite", "intelligence": "minutie",
	"critique": "minutie", "perception": "flair", "prospection": "flair", "vitalite": "main_verte", "dommages": "epargne",
	"dommages_": "epargne", "degats_devastateurs": "epargne", "degats_devastateurs_fixes": "epargne", "dommages_melee": "",
	"soins": "fournee", "soins_": "fournee", "resistance_": "distillation", "pa": "sagacite", "pm": "sagacite", "portee": "sagacite"}
## Statistiques de métier utiles par outil (Fournée attend la boulangerie ; Main verte ne sert qu'en instance de métier).
const TOOL_STATS := {Profession.TYPE_HARVEST: ["profusion", "flair", "dexterite", "main_verte", "sagacite"],
	Profession.TYPE_CRAFT: ["minutie", "epargne", "distillation", "sagacite"]}
## Points de score au plus par outil et par palier de forgeron (300 au palier Légende).
const TOOL_SCORE_PER_TIER := 60
## Multiplicateur de la valeur des ressources rares, quel que soit leur palier (sauf PA, PM et Portée).
const RARE_FACTOR := 3
## Dégâts d'une arme forgée en plus par palier au-dessus du 1er (+160 % au palier 5).
const WEAPON_BONUS_PER_TIER := 0.4
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
	"pioche": {"matieres": ["minerai", "bois"], "noms": [["Pioche", "f"], ["Pic", "m"]], "metier": "mineur"},
	"hache": {"matieres": ["minerai", "bois"], "noms": [["Hache", "f"], ["Cognée", "f"]], "metier": "bucheron"},
	"faucille": {"matieres": ["minerai", "bois"], "noms": [["Faucille", "f"], ["Serpette", "f"]], "metier": "agriculteur"},
	"serpe": {"matieres": ["minerai", "bois"], "noms": [["Serpe", "f"], ["Sécateur", "m"]], "metier": "herboriste"},
	"canne_a_peche": {"matieres": ["minerai", "bois"], "noms": [["Canne à pêche", "f"], ["Gaule", "f"]], "metier": "pecheur"},
	"marteau_de_forgeron": {"matieres": ["minerai", "bois"], "noms": [["Marteau de forgeron", "m"], ["Maillet", "m"]], "metier": "forgeron"},
}
const TYPE_NAMES := {"coiffe": "Coiffe", "cape": "Cape", "amulette": "Amulette", "anneau": "Anneau", "ceinture": "Ceinture",
	"bottes": "Bottes", "epee": "Épée", "arc": "Arc", "baton": "Bâton", "dague": "Dague", "masse": "Masse", "sceptre": "Sceptre",
	"pioche": "Pioche", "hache": "Hache", "faucille": "Faucille", "serpe": "Serpe", "canne_a_peche": "Canne à pêche", "marteau_de_forgeron": "Marteau de forgeron"}
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
	"dommages_acier": [["tranchant", "tranchante"], ["acéré", "acérée"]],
	"dommages_flamme": [["brûlant", "brûlante"], ["ardent", "ardente"]],
	"dommages_givre": [["glacial", "glaciale"], ["mordant", "mordante"]],
	"dommages_tempete": [["foudroyant", "foudroyante"], ["tonnant", "tonnante"]],
	"resistance_acier": [["blindé", "blindée"], ["cuirassé", "cuirassée"]],
	"resistance_flamme": [["ignifugé", "ignifugée"], ["incombustible", "incombustible"]],
	"resistance_givre": [["fourré", "fourrée"], ["douillet", "douillette"]],
	"resistance_tempete": [["abrité", "abritée"], ["isolant", "isolante"]],
	"soins": [["guérisseur", "guérisseuse"], ["apaisant", "apaisante"]],
	"degats_devastateurs": [["dévastateur", "dévastatrice"], ["ravageur", "ravageuse"]],
	"degats_devastateurs_fixes": [["destructeur", "destructrice"]], "degats_spectraux": [["spectral", "spectrale"], ["fantomatique", "fantomatique"]],
	"degats_spectraux_fixes": [["hanté", "hantée"]], "reduction_degats": [["rembourré", "rembourrée"], ["matelassé", "matelassée"]],
	"dommages_melee": [["bagarreur", "bagarreuse"], ["teigneux", "teigneuse"]], "tacle": [["collant", "collante"], ["poisseux", "poisseuse"]],
	"fuite": [["fuyant", "fuyante"], ["glissant", "glissante"]], "retrait_pa": [["épuisant", "épuisante"], ["assommant", "assommante"]],
	"retrait_pm": [["entravant", "entravante"], ["pesant", "pesante"]],
	"epines_brutes": [["épineux", "épineuse"], ["hérissé", "hérissée"]], "epines_brutes_fixes": [["piquant", "piquante"]],
	"epines_acier": [["barbelé", "barbelée"]], "epines_acier_fixes": [["clouté", "cloutée"]],
	"epines_flamme": [["cuisant", "cuisante"]], "epines_flamme_fixes": [["urticant", "urticante"]],
	"epines_givre": [["gelé", "gelée"]], "epines_givre_fixes": [["cristallin", "cristalline"]],
	"epines_tempete": [["électrique", "électrique"]], "epines_tempete_fixes": [["crépitant", "crépitante"]],
	"epines_sacre": [["expiatoire", "expiatoire"]], "epines_sacre_fixes": [["pénitent", "pénitente"]],
	"epines_impie": [["sulfureux", "sulfureuse"]], "epines_impie_fixes": [["venimeux", "venimeuse"]],
	"dommages_sacre": [["béni", "bénie"], ["vengeur", "vengeresse"]],
	"dommages_impie": [["maudit", "maudite"], ["impie", "impie"]],
	"soins_acier": [["ferrugineux", "ferrugineuse"]], "soins_flamme": [["réchauffant", "réchauffante"]],
	"soins_givre": [["rafraîchissant", "rafraîchissante"]], "soins_tempete": [["vivifiant", "vivifiante"]],
	"soins_sacre": [["miraculeux", "miraculeuse"], ["angélique", "angélique"]], "soins_impie": [["ténébreux", "ténébreuse"]],
	"profusion": [["généreux", "généreuse"]], "flair": [["fureteur", "fureteuse"]], "dexterite": [["preste", "preste"]],
	"minutie": [["minutieux", "minutieuse"]], "epargne": [["économe", "économe"]], "distillation": [["alchimique", "alchimique"]],
	"sagacite": [["savant", "savante"]], "main_verte": [["fertile", "fertile"]],
	"resistance_sacre": [["sceptique", "sceptique"]], "resistance_impie": [["consacré", "consacrée"], ["exorcisé", "exorcisée"]],
}
## Mots clés au plus dans un nom après le nom du type : adjectifs, mots de famille ou de zone (GDD § 10.4).
const MAX_KEYWORDS := 3
## Panoplies d'objets forgés (barème validé le 11/11/2026, GDD § 10.4) : points de score d'une panoplie complète par
## palier (le plus bas des pièces portées), × `BOSS_SET_FACTOR` pour un boss ; part du total selon les pièces (2 à 7).
const SET_SCORE_PER_TIER := 30
const ADJECTIVE_SET_SCORE_PER_TIER := 25
const BOSS_SET_FACTOR := 1.5
const SET_SHARES := [0.0, 0.0, 0.08, 0.18, 0.32, 0.5, 0.72, 1.0]
## Zones : mot et tendance de leur panoplie (statistique → part en %, proposition provisoire du 10/11/2026).
const ZONES := {
	"brumerive": ["de Brumerive", {"agilite": 50, "dommages_tempete": 30, "fuite": 20}],
	"crasse_roc": ["de Crasse-Roc", {"intelligence": 50, "dommages_flamme": 30, "reduction_degats": 20}],
	"sylvebrume": ["de Sylvebrume", {"perception": 50, "resistance_givre": 30, "prospection": 20}],
	"hautepierre": ["de Hautepierre", {"vitalite": 50, "tacle": 30, "dommages": 20}],
	"tour_celeste": ["de la Tour céleste", {"soins": 50, "dommages_sacre": 30, "resistance_impie": 20}],
}


static func template_id(type: String) -> String:
	return "forge_" + type


## Caractéristiques d'une ressource : `caracteristique` est un nom, ou une liste pour une ressource de
## haut palier qui en donne plusieurs (chacune à sa valeur pleine).
static func stats_of(item: Dictionary) -> Array:
	var stats: Variant = item.get("caracteristique", [])
	return stats if typeof(stats) == TYPE_ARRAY else [stats]


## Palier de forge de `character` (`MAX_TIER` sans personnage : plan ou outil).
static func tier(character: Character) -> int:
	return MAX_TIER if character == null else clampi(Character.tier_index(character.job_reputation(JOB)), 1, MAX_TIER)


## Valeur d'une ligne au plus au palier de forge `forge_tier` (PA, PM et Portée : 1, ou 0 avant leur palier).
static func line_cap(stat: String, forge_tier := MAX_TIER) -> int:
	var score := LINE_SCORE_PER_TIER * forge_tier
	return int(FIXED_STATS[stat] <= score) if stat in FIXED_STATS else floori(score * STAT_WEIGHTS[stat])


## Caractéristique que donne une ressource de ce palier (1 à 5 : palier × poids, × RARE_FACTOR si elle est rare).
static func value(stat: String, tier: int, rare := false) -> int:
	return 1 if stat in FIXED_STATS else maxi(1, roundi(tier * STAT_WEIGHTS[stat])) * (RARE_FACTOR if rare else 1)


## Vrai si l'artisan voit la caractéristique des ressources de ce palier : il a déjà forgé, et son palier
## de forgeron (`tier`, Inconnu compté 1) atteint le palier de la ressource.
static func reveals(character: Character, tier: int) -> bool:
	return character.job_reputation(JOB) > 0 and tier <= Forge.tier(character)


## Aperçu de l'objet : { erreur (raison du protocole, "" si on peut forger), palier, bonus: { stat:
## [min, max] }, cachees (ressources à caractéristique cachée pour `character`), manquantes (matières),
## perdues (ressources dont une caractéristique dépasse le palier de forge de `character`, même cachée : id →
## { stat: palier requis }), lieux (mots clés « famille:<id> » et « zone:<id> » permis : ceux d'au moins la moitié des
## ressources différentes à caractéristique) }.
## Le plancher des jets suit la Précision de `character` ; `hide` : cacher ce qu'il ne sait pas lire
## (faux pour le serveur et pour un plan, qui montre tout).
static func preview(type: String, resources: Dictionary, items: Dictionary, character: Character = null, hide := true) -> Dictionary:
	var result := {"erreur": "", "palier": 1, "bonus": {}, "cachees": 0, "manquantes": [], "perdues": {}, "lieux": []}
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
	var places := {}
	var forge_tier := tier(character)
	var tool: bool = TYPES[type].has("metier")
	var budget := TOOL_SCORE_PER_TIER * forge_tier  # Outil : points de score au plus, les lignes en trop sont rognées.
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
		for key: String in ["famille", "zone"]:
			if item.has(key):
				places[key + ":" + item[key]] = places.get(key + ":" + item[key], 0) + 1
		var lines := {}
		for stat: String in stats_of(item):
			var base := int(item.get("valeur", value(stat, tier, item.get("rarete") == "rare")))
			var line := job_stat(stat) if tool else stat
			if tool and line not in TOOL_STATS[tool_type(type)]:
				result["perdues"][item_id] = result["perdues"].get(item_id, {}).merged({stat: 0})
			elif line_cap(line, forge_tier) == 0:
				result["perdues"][item_id] = result["perdues"].get(item_id, {}).merged({stat: ceili(float(FIXED_STATS[stat]) / LINE_SCORE_PER_TIER)})
			else:
				lines[line] = maxi(1, Infusion.value_of(line, Infusion.score(stat, base))) if tool else base
		if character != null and hide and item.has("caracteristique") and not reveals(character, tier):
			result["cachees"] += quantity
			continue
		for line: String in lines:
			totals[line] = int(totals.get(line, 0)) + quantity * lines[line]
	for material: String in TYPES[type]["matieres"]:
		if material not in materials:
			result["manquantes"].append(material)
	if totals.size() > MAX_LINES:
		result["erreur"] = Protocol.REASON_TOO_MANY_LINES
	elif not result["manquantes"].is_empty():
		result["erreur"] = Protocol.REASON_MISSING_INGREDIENTS
	result["palier"] = maxi(1, roundi(float(tiers) / maxi(1, count)))
	var described := resources.keys().filter(func(id: Variant) -> bool: return items[id].has("famille")).size()
	result["lieux"] = places.keys().filter(func(key: String) -> bool: return 2 * places[key] >= described)
	var low := ROLL_LOW + ((Profession.skill_value(Profession.TYPE_CRAFT, "precision", character.job_rank(JOB, "precision"))
		+ character.tool_stat(JOB, "minutie")) / 100.0 if character != null else 0.0)
	for stat: String in totals:
		var total: int = mini(line_cap(stat, forge_tier), totals[stat])
		if tool:
			total = mini(total, floori(budget * STAT_WEIGHTS[stat]))
			budget -= ceili(Infusion.score(stat, total))
			if total <= 0:
				continue
		result["bonus"][stat] = [total if stat in FIXED_STATS else maxi(1, roundi(total * minf(1.0, low))), total]
	return result


## Statistique de métier que donne une statistique de combat sur un outil ("" : aucune).
static func job_stat(stat: String) -> String:
	return JOB_STATS.get(stat, JOB_STATS.get(stat.get_slice("_", 0) + "_", ""))


## Type de métier d'un outil (récolte ou artisanat).
static func tool_type(type: String) -> String:
	return Profession.TYPE_CRAFT if TYPES[type]["metier"] == JOB else Profession.TYPE_HARVEST


## Nom par défaut : le premier nom du type et l'adjectif de la ligne la plus forte (en points de score ;
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


## Nom formé de `words` (nom du type puis mots clés : adjectifs des lignes `stats`, accordés, deux d'une même ligne permis,
## ou mots de famille et de zone de `places` (mot clé → mot), jamais deux fois le même mot), ou "" s'ils ne sont pas permis.
static func name_of(words: Variant, type: String, stats: Array, places := {}) -> String:
	if typeof(words) != TYPE_ARRAY or words.is_empty() or words.size() > MAX_KEYWORDS + 1 or typeof(words[0]) != TYPE_STRING:
		return ""
	var noun_gender := gender(type, words[0])
	if noun_gender.is_empty():
		return ""
	for word: Variant in words.slice(1):
		if words.count(word) > 1 or keyword(word, noun_gender, stats, places).is_empty():
			return ""
	return " ".join(words)


## Mots clés d'un nom permis (voir `name_of`), sans doublon : deux adjectifs d'une même panoplie n'en font qu'un.
static func keywords(words: Array, type: String, stats: Array, places := {}) -> Array:
	var keys: Array = []
	for word: Variant in words.slice(1):
		var key := keyword(word, gender(type, words[0]), stats, places)
		if key not in keys:
			keys.append(key)
	return keys


## Mot clé d'un mot : « stat:<panoplie d'adjectif> », « famille:<id> » ou « zone:<id> », "" s'il n'est pas permis.
static func keyword(word: Variant, noun_gender: String, stats: Array, places: Dictionary) -> String:
	if places.values().has(word):
		return str(places.find_key(word))
	for stat: String in stats:
		if WORDS.get(stat, []).any(func(forms: Array) -> bool: return adjective(forms, noun_gender) == word):
			return "stat:" + adjective_set(stat)
	return ""


## Panoplie d'un adjectif de `stat` : offensive d'un élément (sa caractéristique et ses Dommages), défensive (Résistance,
## Soins, Épines de l'élément), sinon la statistique elle-même (fixe et % ensemble).
static func adjective_set(stat: String) -> String:
	for element: String in Spell.ELEMENTS:
		if stat == "dommages_" + element or stat == Fighter.ELEMENT_STATS.get(element, "-"):
			return element + "_offensive"
		if stat in ["resistance_" + element, "soins_" + element, "epines_" + element, "epines_%s_fixes" % element]:
			return element + "_defensive"
	return stat.trim_suffix("_fixes")


## Mot d'une famille ou d'une zone (« de Loup », « de Brumerive »).
static func place_word(key: String, data: GameData) -> String:
	var id := key.get_slice(":", 1)
	return str(ZONES.get(id, [""])[0]) if key.begins_with("zone:") else str(data.monsters.get(id, {}).get("mot", ""))


## Statistiques d'une panoplie de mot clé et leur part en % : tendance d'une zone, statistiques des ressources d'une
## famille à parts égales, adjectif offensif (caractéristique 60, Dommages 40) ou défensif (Résistance 60, Soins 40).
static func set_stats(key: String, data: GameData) -> Dictionary:
	var id := key.get_slice(":", 1)
	if key.begins_with("zone:"):
		return ZONES.get(id, ["", {}])[1]
	if key.begins_with("famille:"):
		var stats := data.family_stats(id)
		var shares := {}
		for stat: String in stats:
			shares[stat] = 100.0 / stats.size()
		return shares
	var element := id.get_slice("_", 0)
	if id.ends_with("_offensive"):
		return {Fighter.ELEMENT_STATS[element]: 60, "dommages_" + element: 40} if Fighter.ELEMENT_STATS.has(element) else {"dommages_" + element: 100}
	return {"resistance_" + element: 60, "soins_" + element: 40} if id.ends_with("_defensive") else {id: 100}


## Bonus des panoplies d'objets forgés des entrées `entries` (portées) : stat → valeur.
static func set_bonuses(entries: Array, data: GameData) -> Dictionary:
	var tiers := {}
	for entry: Dictionary in entries:
		for key: String in entry.get("forge", {}).get("mots_cles", []):
			tiers[key] = tiers.get(key, []) + [int(entry["forge"].get("palier", 1))]
	var totals := {}
	for key: String in tiers:
		var bonus := set_bonus(key, tiers[key], data)
		for stat: String in bonus:
			totals[stat] = int(totals.get(stat, 0)) + bonus[stat]
	return totals


## Bonus d'une panoplie de mot clé portée en pièces de paliers `tiers` : elle prend le plus bas ; PA, PM et Portée
## seulement à 7 pièces et si leur part vaut au moins le double de leur score (sinon, et pour le reste, des Dommages).
static func set_bonus(key: String, tiers: Array, data: GameData) -> Dictionary:
	var count := mini(tiers.size(), SET_SHARES.size() - 1)
	var boss: bool = key.begins_with("famille:") and data.monsters.get(key.get_slice(":", 1), {}).get("boss", false)
	var score: float = (ADJECTIVE_SET_SCORE_PER_TIER if key.begins_with("stat:") else SET_SCORE_PER_TIER) * tiers.min() \
		* (BOSS_SET_FACTOR if boss else 1.0) * SET_SHARES[count]
	var stats := set_stats(key, data)
	var totals := {}
	for stat: String in stats:
		var points: float = score * stats[stat] / 100.0
		var line := stat
		if stat in FIXED_STATS:
			if count == SET_SHARES.size() - 1 and points >= 2 * FIXED_STATS[stat]:
				totals[stat] = int(totals.get(stat, 0)) + 1
				points -= FIXED_STATS[stat]
			line = "dommages"
		var value := Infusion.value_of(line, points)
		if value > 0:
			totals[line] = int(totals.get(line, 0)) + value
	return totals


## Nom d'une panoplie de mot clé : mot de la famille ou de la zone, ou statistique (« Flamme offensive », « Tacle »).
static func set_title(key: String, data: GameData) -> String:
	var id := key.get_slice(":", 1)
	if not key.begins_with("stat:"):
		return place_word(key, data)
	return id.get_slice("_", 0).capitalize() + " " + id.get_slice("_", 1) if id.ends_with("_offensive") or id.ends_with("_defensive") else Item.stat_name(id)


## Jets de l'objet forgé, tirés dans les plages de l'aperçu.
static func roll(bonus: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var rolled := {}
	for stat: String in bonus:
		rolled[stat] = rng.randi_range(int(bonus[stat][0]), int(bonus[stat][1]))
	return rolled


## Attaque d'une arme forgée : dégâts de base × (1 + (palier − 1) × `WEAPON_BONUS_PER_TIER`), dans l'élément de la caractéristique
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
				effect[key] = roundi(effect[key] * (1.0 + (tier - 1) * WEAPON_BONUS_PER_TIER))
			if top > 0 and scores.get(effect["element"], 0) < top:
				effect["element"] = scores.find_key(top)
			for composite: String in Spell.COMPOSITE_ELEMENTS:
				if top > 0 and Spell.COMPOSITE_ELEMENTS[composite].all(func(base: String) -> bool: return scores[base] >= top * 0.9):
					effect["element"] = composite
	return scaled


## Erreurs d'un plan (`recette` d'un objet de type « recette ») : un type d'objet forgé, ou un objet tout fait (`objet` :
## la clé d'un donjon, GDD § 12.2, en attendant le Joaillier).
static func validate_recipe(recipe: Variant) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(recipe) != TYPE_DICTIONARY or typeof(recipe.get("nom")) != TYPE_STRING or not (TYPES.has(recipe.get("type"))
			or typeof(recipe.get("objet")) == TYPE_STRING) or typeof(recipe.get("ressources")) != TYPE_DICTIONARY or recipe["ressources"].is_empty():
		errors.append("« recette » doit être { nom, type (%s) ou objet, ressources: { id: quantité } }" % str(TYPES.keys()))
	return errors
