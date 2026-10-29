class_name Progression
extends RefCounted
## Progression par la pratique en combat (GDD § 4.5) : ce que rapporte un combat en réputation de
## la classe active et en caractéristiques, d'après ce que chacun y a fait (`Combat.practice`) et
## un facteur de difficulté qui compare la menace des monstres à la force du groupe. Les chiffres
## sont des pistes, réglées avec `tools/simulation.gd`.

## Réputation par PA d'un sort à effet réel (dégâts sur un ennemi, soin de PV perdus, bouclier qui
## absorbe) ; un sort utilitaire qui touche quelqu'un en rapporte `UTILITY_SHARE`.
const REPUTATION_PER_PA := 2.0
const UTILITY_SHARE := 0.5
## Réputation d'un monstre vaincu : cette part de son XP, partagée entre les joueurs du combat.
const KILL_SHARE := 0.25
## Caractéristique de l'élément d'un sort à effet réel, par PA (avant le ralentissement).
const STAT_PER_PA := 0.03
## Vitalité par PV réellement perdu.
const VITALITY_PER_HP := 0.02
## Plafonds d'un combat (contre les combats sans fin) : PA comptés, PV perdus comptés.
const MAX_PA_PER_COMBAT := 60.0
const MAX_HP_PER_COMBAT := 200.0
## Les caractéristiques montent plus lentement près du plafond : × (1 − points / plafond), au moins
## ce minimum.
const MIN_STAT_PACE := 0.2
## Facteur de difficulté selon le rapport des niveaux (somme des niveaux des monstres / somme des
## niveaux équivalents des joueurs) : points [rapport, facteur], interpolés, bornés aux extrémités.
const DIFFICULTY_POINTS := [[0.4, 0.1], [1.0, 0.5], [2.0, 1.0], [3.0, 1.5]]
## Niveau équivalent le plus haut (interne au calcul, jamais affiché).
const MAX_EQUIVALENT_LEVEL := 60
## Réputation qui vaut un niveau équivalent : la courbe d'XP de l'ancien système sans le × 3,5
## (passer du niveau n à n + 1 coûtait 60·n + 20·n² XP), pour qu'un personnage converti garde sa force.
const OLD_XP_RATE := 3.5


## Niveau équivalent d'une réputation de classe (1 au départ) : la force du joueur dans le facteur de
## difficulté (GDD § 4.5, « tirée de sa réputation »).
static func equivalent_level(reputation_value: int) -> int:
	var level := 1
	var needed := 0.0
	while level < MAX_EQUIVALENT_LEVEL:
		needed += (60.0 * level + 20.0 * level * level) / OLD_XP_RATE
		if reputation_value < needed:
			break
		level += 1
	return level


## Facteur de difficulté d'un combat : niveaux des monstres contre niveaux équivalents des joueurs.
static func difficulty(monster_levels: Array, player_levels: Array) -> float:
	var threat := 0.0
	for level: Variant in monster_levels:
		threat += maxf(1.0, float(level))
	var strength := 0.0
	for level: Variant in player_levels:
		strength += maxf(1.0, float(level))
	if threat <= 0.0:
		return 0.0
	var ratio := threat / maxf(1.0, strength)
	var points: Array = DIFFICULTY_POINTS
	if ratio <= float(points[0][0]):
		return float(points[0][1])
	for i in range(1, points.size()):
		if ratio <= float(points[i][0]):
			var low: Array = points[i - 1]
			var high: Array = points[i]
			var weight := (ratio - float(low[0])) / (float(high[0]) - float(low[0]))
			return lerpf(float(low[1]), float(high[1]), weight)
	return float(points[-1][1])


## Menace d'un combat en mots, d'après son facteur de difficulté (affichage : bulle des groupes,
## carte du monde).
static func threat_name(factor: float) -> String:
	if factor < 0.2:
		return "négligeable"
	if factor < 0.75:
		return "faible"
	if factor < 1.25:
		return "à votre mesure"
	return "redoutable"


## Caractéristiques d'un élément, avec leur part : Acier → Force, Flamme → Intelligence, Givre →
## Perception, Tempête → Agilité ; Sacré et Impie : leurs deux éléments par moitié.
static func element_stats(element: String) -> Dictionary:
	if Spell.COMPOSITE_ELEMENTS.has(element):
		var shares := {}
		for base: String in Spell.COMPOSITE_ELEMENTS[element]:
			shares[Fighter.ELEMENT_STATS[base]] = 0.5
		return shares
	if Fighter.ELEMENT_STATS.has(element):
		return {Fighter.ELEMENT_STATS[element]: 1.0}
	return {}


## Gains d'un joueur pour sa pratique d'un combat (`entry` : voir `Combat.practice`), au facteur de
## difficulté `factor`, plus `kill_reputation` (sa part des monstres vaincus, déjà multipliée par le
## facteur) : { reputation: int, caracteristiques: { carac → points (non arrondis, avant le
## ralentissement) } }.
static func gains(entry: Dictionary, factor: float, kill_reputation := 0.0) -> Dictionary:
	var effective := 0.0
	var by_element: Dictionary = entry.get("effet", {})
	for element: String in by_element:
		effective += float(by_element[element])
	var utility := float(entry.get("utile", 0.0))
	var counted := effective + utility
	var scale := 1.0 if counted <= MAX_PA_PER_COMBAT else MAX_PA_PER_COMBAT / counted
	var reputation_value := (effective + utility * UTILITY_SHARE) * scale * REPUTATION_PER_PA * factor + kill_reputation
	var stats := {}
	for element: String in by_element:
		var shares := element_stats(element)
		for stat_name: String in shares:
			stats[stat_name] = float(stats.get(stat_name, 0.0)) \
				+ float(by_element[element]) * scale * float(shares[stat_name]) * STAT_PER_PA * factor
	var hurt := minf(float(entry.get("pv_recus", 0.0)), MAX_HP_PER_COMBAT)
	if hurt > 0.0:
		stats["vitalite"] = hurt * VITALITY_PER_HP * factor
	return {"reputation": roundi(reputation_value), "caracteristiques": stats}


## Rythme de montée d'une caractéristique qui a déjà `points` sur un plafond de `cap`.
static func stat_pace(points: int, cap: int) -> float:
	return maxf(MIN_STAT_PACE, 1.0 - float(points) / maxf(1.0, float(cap)))
