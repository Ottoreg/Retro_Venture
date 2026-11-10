class_name Infusion
extends RefCounted
## Infusion d'essences (nom provisoire, GDD § 10.4) : à l'enclume, le forgeron infuse des ressources identiques en une
## essence qui porte la valeur de forge d'une de leurs caractéristiques (« miroir » : la caractéristique opposée, à score
## égal, au palier Maître). Appliquée à un équipement, l'essence ajoute sa ligne en exo (200 points de score d'exo par
## objet) ou renforce une ligne de son jet ; chaque ligne reste sous 100 points de score. Un échec perd l'essence,
## jamais l'objet ; une essence parfaite (× 5 ressources) réussit toujours.

const TEMPLATE := "essence"
## Ressources par essence selon la rareté (commune, rare, légendaire), × `PERFECT_FACTOR` pour une essence parfaite.
const QUANTITIES := {"commun": 20, "peu_commun": 20, "rare": 10, "epique": 10, "legendaire": 2, "relique": 2}
const PERFECT_FACTOR := 5
const MAX_EXO_SCORE := 200
## Réussite : 100 % − la moitié des points de score de l'essence, entre `MIN_CHANCE` et `MAX_CHANCE`.
const MIN_CHANCE := 10
const MAX_CHANCE := 95
## Palier de réputation de forgeron de l'infusion miroir (Maître).
const MIRROR_TIER := 4
## Caractéristiques opposées (GDD § 10.4) ; deux miroirs pour les Dommages et Soins élémentaires (au choix).
const MIRRORS := {"force": ["agilite"], "agilite": ["force"], "intelligence": ["perception"], "perception": ["intelligence"],
	"dommages": ["soins"], "soins": ["dommages"], "vitalite": ["epines_brutes"], "epines_brutes": ["vitalite"],
	"degats_devastateurs": ["degats_spectraux"], "degats_spectraux": ["degats_devastateurs"],
	"degats_devastateurs_fixes": ["degats_spectraux_fixes"], "degats_spectraux_fixes": ["degats_devastateurs_fixes"],
	"tacle": ["fuite"], "fuite": ["tacle"], "retrait_pa": ["retrait_pm"], "retrait_pm": ["retrait_pa"],
	"portee": ["dommages_melee"], "dommages_melee": ["portee"]}
const ELEMENT_MIRRORS := {"acier": "tempete", "tempete": "acier", "flamme": "givre", "givre": "flamme", "sacre": "impie", "impie": "sacre"}


## Miroirs possibles de `stat` (vide si elle n'en a pas).
static func mirrors(stat: String) -> Array:
	for prefix in ["dommages_", "soins_", "resistance_"]:
		var element := stat.trim_prefix(prefix)
		if stat.begins_with(prefix) and ELEMENT_MIRRORS.has(element):
			return [prefix + ELEMENT_MIRRORS[element]] + ([("soins_" if prefix == "dommages_" else "dommages_") + element] if prefix != "resistance_" else [])
	return MIRRORS.get(stat, [])


## Points de score de `value` points de `stat` (PA, PM, Portée : `Forge.FIXED_STATS` par point).
static func score(stat: String, value: float) -> float:
	return value * Forge.FIXED_STATS[stat] if stat in Forge.FIXED_STATS else value / Forge.STAT_WEIGHTS[stat]


## Valeur de `stat` pour `points` points de score (arrondie, au plancher pour PA, PM et Portée).
static func value_of(stat: String, points: float) -> int:
	return floori(points / Forge.FIXED_STATS[stat]) if stat in Forge.FIXED_STATS else roundi(points * Forge.STAT_WEIGHTS[stat])


## Essence tirée de `resource` : { erreur, quantite, essence: { caracteristique, valeur, parfaite } }. `stat` : une
## caractéristique de la ressource, ou un de ses miroirs (`mirror_allowed` : palier Maître).
static func essence(resource: Dictionary, stat: String, perfect: bool, mirror_allowed: bool) -> Dictionary:
	var stats := Forge.stats_of(resource)
	var source := stat if stat in stats else ""
	for candidate: String in stats:
		if source.is_empty() and stat in mirrors(candidate):
			source = candidate
	if source.is_empty() or (source != stat and not mirror_allowed):
		return {"erreur": Protocol.REASON_INVALID_COMMAND}
	var base := int(resource.get("valeur", Forge.value(source, int(resource.get("niveau", 1)), resource.get("rarete") == "rare")))
	var value := base if source == stat else value_of(stat, score(source, base))
	return {"erreur": "" if value > 0 else Protocol.REASON_INVALID_COMMAND,
		"quantite": int(QUANTITIES.get(resource.get("rarete", "commun"), 20)) * (PERFECT_FACTOR if perfect else 1),
		"essence": {"caracteristique": stat, "valeur": value, "parfaite": perfect}}


## Chance de réussite d'une essence, en %.
static func chance(essence_data: Dictionary) -> int:
	return 100 if essence_data["parfaite"] else clampi(roundi(100 - score(essence_data["caracteristique"], essence_data["valeur"]) / 2.0), MIN_CHANCE, MAX_CHANCE)


## Ce que ferait l'essence sur l'entrée d'inventaire `entry` : { erreur, renfort (vrai si la ligne est sur le jet),
## valeur (de la ligne après) }. Refusée si la ligne ou l'exo dépasseraient leur plafond.
static func apply_preview(entry: Dictionary, essence_data: Dictionary) -> Dictionary:
	var stat: String = essence_data["caracteristique"]
	var exo: Dictionary = entry.get("exo", {})
	var reinforce: bool = entry["jets"].has(stat) and not exo.has(stat)
	var after := int(entry["jets"].get(stat, 0)) + int(essence_data["valeur"])
	var exo_score := 0.0
	for exo_stat: String in exo:
		exo_score += score(exo_stat, exo[exo_stat])
	var full := after > Forge.line_cap(stat) or (not reinforce and exo_score + score(stat, essence_data["valeur"]) > MAX_EXO_SCORE + 0.01)
	return {"erreur": Protocol.REASON_TOO_MANY_LINES if full else "", "renfort": reinforce, "valeur": after}


## Applique l'essence à `entry` (après `apply_preview` sans erreur).
static func apply(entry: Dictionary, essence_data: Dictionary) -> void:
	var stat: String = essence_data["caracteristique"]
	var reinforce: bool = apply_preview(entry, essence_data)["renfort"]
	entry["jets"][stat] = int(entry["jets"].get(stat, 0)) + int(essence_data["valeur"])
	if not reinforce:
		entry["exo"] = entry.get("exo", {})
		entry["exo"][stat] = int(entry["exo"].get(stat, 0)) + int(essence_data["valeur"])


## Nom affiché d'une essence.
static func essence_name(essence_data: Dictionary) -> String:
	return "Essence%s de %s +%d" % [" parfaite" if essence_data["parfaite"] else "", Item.stat_name(essence_data["caracteristique"]), essence_data["valeur"]]
