class_name Item
extends RefCounted
## Règles des objets (données de `data/objets/`) : types, raretés, bonus, jets aléatoires, armes.

const TYPE_RESOURCE := "ressource"
const TYPE_WEAPON := "arme"
## Objet de quête : ni vendu, ni vendable, ni jetable ; donné ou demandé par une quête.
const TYPE_QUEST := "quete"
## Type d'objet → emplacements d'équipement possibles.
const SLOTS_BY_TYPE := {
	"arme": ["arme"], "coiffe": ["coiffe"], "cape": ["cape"], "amulette": ["amulette"],
	"anneau": ["anneau_1", "anneau_2"], "ceinture": ["ceinture"], "bottes": ["bottes"], "outil": ["outil"],
}
const SLOT_NAMES := {
	"arme": "Arme", "coiffe": "Coiffe", "cape": "Cape", "amulette": "Amulette",
	"anneau_1": "Anneau", "anneau_2": "Anneau", "ceinture": "Ceinture", "bottes": "Bottes", "outil": "Outil",
}
const RARITIES := ["commun", "peu_commun", "rare", "epique", "legendaire", "relique"]
const RARITY_NAMES := {
	"commun": "Commun", "peu_commun": "Peu commun", "rare": "Rare",
	"epique": "Épique", "legendaire": "Légendaire", "relique": "Relique",
}
## Prix d'achat chez un marchand (brumes), selon la rareté : équipements et ressources.
const EQUIPMENT_PRICES := {
	"commun": 40, "peu_commun": 120, "rare": 350, "epique": 900, "legendaire": 2500, "relique": 6000,
}
const RESOURCE_PRICES := {
	"commun": 4, "peu_commun": 12, "rare": 35, "epique": 90, "legendaire": 250, "relique": 600,
}
## Palier d'équipement jusqu'auquel le prix ne dépend que de la rareté (voir `tier_price_factor`).
const PRICE_TIER_STEP := 3.0
## Multiplicateur du prix d'un objet forgé par palier (1 à 5, 11/11/2026, à revoir avec la demande dynamique des PNJ).
const FORGED_PRICE_FACTORS := [1, 2, 4, 7, 10]
## Part du prix d'achat que le marchand paie quand on lui revend un objet.
const RESALE_RATE := 0.25
## Bonus que peut donner un équipement, en plus des 6 caractéristiques ; dommages, soins et résistances (%)
## par élément : « dommages_flamme », « soins_sacre », « resistance_givre »… ; statistiques de combat (`Fighter.COMBAT_STATS`).
const EXTRA_STATS := ["prospection", "initiative", "portee", "pa", "pm", "dommages", "soins", "critique",
	"tacle", "fuite", "retrait_pa", "retrait_pm", "reduction_degats", "dommages_melee",
	"degats_spectraux", "degats_spectraux_fixes", "degats_devastateurs", "degats_devastateurs_fixes",
	"epines_brutes", "epines_brutes_fixes", "epines_acier", "epines_acier_fixes", "epines_flamme", "epines_flamme_fixes",
	"epines_givre", "epines_givre_fixes", "epines_tempete", "epines_tempete_fixes", "epines_sacre", "epines_sacre_fixes",
	"epines_impie", "epines_impie_fixes",
	"dommages_acier", "dommages_flamme", "dommages_givre", "dommages_tempete", "dommages_sacre", "dommages_impie",
	"soins_acier", "soins_flamme", "soins_givre", "soins_tempete", "soins_sacre", "soins_impie",
	"resistance_acier", "resistance_flamme", "resistance_givre", "resistance_tempete", "resistance_sacre", "resistance_impie"]
const EXTRA_STAT_NAMES := {
	"profusion": "% Profusion", "flair": "Flair", "dexterite": "% Dextérité", "minutie": "Minutie", "epargne": "% Épargne",
	"distillation": "Distillation", "sagacite": "% Sagacité",
	"prospection": "Prospection", "initiative": "Initiative", "portee": "Portée", "pa": "PA", "pm": "PM",
	"dommages": "Dommages", "soins": "Soins", "critique": "% Critique",
	"tacle": "Tacle", "fuite": "Fuite", "retrait_pa": "Retrait PA", "retrait_pm": "Retrait PM", "reduction_degats": "Réduction de dégâts",
	"dommages_melee": "% Dommages de mêlée", "degats_spectraux": "% Dégâts spectraux", "degats_spectraux_fixes": "Dégâts spectraux",
	"degats_devastateurs": "% Dégâts dévastateurs", "degats_devastateurs_fixes": "Dégâts dévastateurs",
	"epines_brutes": "% Épines brutes", "epines_brutes_fixes": "Épines brutes", "epines_acier": "% Épines Acier", "epines_acier_fixes": "Épines Acier",
	"epines_flamme": "% Épines Flamme", "epines_flamme_fixes": "Épines Flamme", "epines_givre": "% Épines Givre", "epines_givre_fixes": "Épines Givre",
	"epines_tempete": "% Épines Tempête", "epines_tempete_fixes": "Épines Tempête", "epines_sacre": "% Épines Sacré", "epines_sacre_fixes": "Épines Sacré",
	"epines_impie": "% Épines Impie", "epines_impie_fixes": "Épines Impie",
	"dommages_acier": "Dommages Acier", "dommages_flamme": "Dommages Flamme", "dommages_givre": "Dommages Givre",
	"dommages_tempete": "Dommages Tempête", "dommages_sacre": "Dommages Sacré", "dommages_impie": "Dommages Impie",
	"soins_acier": "Soins Acier", "soins_flamme": "Soins Flamme", "soins_givre": "Soins Givre",
	"soins_tempete": "Soins Tempête", "soins_sacre": "Soins Sacré", "soins_impie": "Soins Impie",
	"resistance_acier": "% Résistance Acier", "resistance_flamme": "% Résistance Flamme",
	"resistance_givre": "% Résistance Givre", "resistance_tempete": "% Résistance Tempête",
	"resistance_sacre": "% Résistance Sacré", "resistance_impie": "% Résistance Impie",
}


static func is_equipment(template: Dictionary) -> bool:
	return SLOTS_BY_TYPE.has(template.get("type", ""))


static func bonus_stats() -> Array:
	return Character.STATS + EXTRA_STATS


static func stat_name(stat: String) -> String:
	return Character.STAT_NAMES.get(stat, EXTRA_STAT_NAMES.get(stat, stat))


## Prix d'achat d'un objet chez un marchand.
static func buy_price(template: Dictionary) -> int:
	var prices: Dictionary = EQUIPMENT_PRICES if is_equipment(template) else RESOURCE_PRICES
	var price := int(prices.get(template.get("rarete", "commun"), prices["commun"]))
	if is_equipment(template):
		# Sans condition pour l'équiper, le palier d'un équipement le rend plus cher (GDD § 9.2).
		price = roundi(price * tier_price_factor(int(template.get("niveau", 1)), str(template.get("id", "")).begins_with("forge_")))
	return price


## Multiplicateur du prix d'un équipement selon son palier (`niveau`) : objet forgé (palier 1 à 5),
## `FORGED_PRICE_FACTORS` ; sinon × 1 jusqu'au palier `PRICE_TIER_STEP`, puis palier / `PRICE_TIER_STEP`
## (palier 15 : × 5, palier 30 : × 10).
static func tier_price_factor(tier: int, forged := false) -> float:
	return float(FORGED_PRICE_FACTORS[clampi(tier, 1, FORGED_PRICE_FACTORS.size()) - 1]) if forged else maxf(1.0, float(tier) / PRICE_TIER_STEP)


## Prix de revente d'un objet à un marchand : une part du prix d'achat, au moins 1 brume.
static func sell_price(template: Dictionary) -> int:
	return maxi(1, floori(buy_price(template) * RESALE_RATE))


## Liste des erreurs de `data` (vide si l'objet est valide).
## Vrai si les marchands vendent cet objet (`"boutique": false` : trophées de boss, objets rares
## qu'on ne trouve qu'en butin).
static func is_sold(template: Dictionary) -> bool:
	return template.get("boutique", true) == true and template.get("type") != TYPE_QUEST


static func validate(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(data.get("boutique", true)) != TYPE_BOOL:
		errors.append("« boutique » doit valoir true ou false")
	if typeof(data.get("id")) != TYPE_STRING or str(data.get("id")).is_empty():
		errors.append("« id » doit être un texte non vide")
	if typeof(data.get("nom")) != TYPE_STRING:
		errors.append("« nom » doit être un texte")
	var type := str(data.get("type", ""))
	if type not in [TYPE_RESOURCE, TYPE_QUEST, Forge.TYPE_RECIPE] and not SLOTS_BY_TYPE.has(type):
		errors.append("« type » doit valoir « ressource », « quete », « recette » ou un type d'équipement : %s" % str(SLOTS_BY_TYPE.keys()))
	if type == Forge.TYPE_RECIPE:
		errors.append_array(Forge.validate_recipe(data.get("recette")))
	var stats: Array = Forge.stats_of(data) if data.has("caracteristique") else ["force"]
	if stats.is_empty() or stats.any(func(s: Variant) -> bool: return s not in Forge.STAT_WEIGHTS.keys() + Forge.FIXED_STATS.keys()) \
			or data.get("matiere", "cuir") not in Forge.MATERIALS or (data.has("valeur") and not Spell._is_int_at_least(data["valeur"], 1)):
		errors.append("« caracteristique » doit valoir %s, « matiere » %s et « valeur » un entier ≥ 1" % [str(Forge.STAT_WEIGHTS.keys() + Forge.FIXED_STATS.keys()), str(Forge.MATERIALS)])
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
		if not is_equipment(data) and not bonuses.is_empty():
			errors.append("seul un équipement a des bonus")
	if data.has("conditions"):
		errors.append("« conditions » n'existe plus : aucune condition pour équiper un objet (GDD § 9.2)")
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


## Modèle d'un objet de l'inventaire (`entry`) : celui de `items`, ou, pour un objet forgé (`forge` :
## { nom, artisan, palier, bonus }), son nom, son palier, ses plages, son attaque et sa signature.
static func entry_template(entry: Dictionary, items: Dictionary) -> Dictionary:
	var template: Dictionary = items.get(entry.get("objet", ""), {})
	var forged: Dictionary = entry.get("forge", {})
	if forged.is_empty() or template.is_empty():
		return template
	template = template.duplicate(true)
	template.merge({"nom": forged["nom"], "niveau": forged["palier"], "bonus": forged["bonus"].duplicate(true),
		"description": "Créé par %s" % forged["artisan"]}, true)
	if forged.has("patron"):
		template["patron"] = forged["patron"].duplicate(true)
	if template.has("attaque"):
		template["attaque"] = Forge.scaled_attack(template["attaque"], int(forged["palier"]), forged["bonus"])
	return template


## Tire les bonus d'un équipement au hasard dans leurs plages (« jets »).
static func roll_bonuses(template: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var rolled := {}
	var bonuses: Dictionary = template.get("bonus", {})
	for stat: String in bonuses:
		rolled[stat] = rng.randi_range(int(bonuses[stat][0]), int(bonuses[stat][1]))
	return rolled
