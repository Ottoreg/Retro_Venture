class_name Fighter
extends RefCounted
## Un combattant : personnage joueur ou monstre.

const TEAM_PLAYERS := 0
const TEAM_MONSTERS := 1

var id: String
var display_name: String
var team: int
## Identifiant du monstre ou de la Voie, pour l'affichage.
var kind: String
var cell: Vector2i
var max_hp: int
var hp: int
var max_pa: int
var pa: int
var max_pm: int
var pm: int
var initiative: int
## Résistance en % par élément (négatif = faiblesse).
var resistances: Dictionary = {}
var spells: Array[Spell] = []
## Comportement d'IA ; vide pour un combattant contrôlé par un joueur.
var ai: String = ""
## XP rapportée par ce combattant quand il est vaincu.
var xp: int = 0
## Race (personnages joueurs), pour l'affichage.
var race: String = ""
## Caractéristiques : vitalite, sagesse, force, intelligence, chance, agilite.
var stats: Dictionary = {}
## Portée supplémentaire des sorts à distance (passif de race, équipement…).
var range_bonus: int = 0
## PM retirés pour le prochain tour (effet « retrait_pm »).
var pm_malus: int = 0
## Prospection (joueurs) : augmente les chances de butin.
var prospection: int = 100
## Dommages : dégâts bruts ajoutés à chaque ligne de dégâts, sans élément ni résistance.
var dommages: int = 0
## Bouclier : points de dégâts absorbés avant les PV, jusqu'au début de son prochain tour.
var shield: int = 0
## Chance de coup critique en plus (en %, équipement).
var crit_bonus: int = 0
## États en cours (bonus, malus, poisons) : { type, carac, element, valeur, min, max, tours, sort,
## lanceur }. `tours` : fins de tour de ce combattant avant que l'état ne tombe.
var states: Array[Dictionary] = []

## Caractéristique qui augmente les dégâts de chaque élément.
const ELEMENT_STATS := {"acier": "force", "flamme": "intelligence", "givre": "chance", "tempete": "agilite"}

var _casts_this_turn: Dictionary = {}
var _cooldowns: Dictionary = {}


func is_alive() -> bool:
	return hp > 0


func is_ai() -> bool:
	return not ai.is_empty()


func get_spell(spell_id: String) -> Spell:
	for spell in spells:
		if spell.id == spell_id:
			return spell
	return null


## Résistance en % à un élément. Pour un élément composé (Sacré, Impie) : la moyenne des résistances
## aux deux éléments de base, plus sa résistance propre (10 % Flamme, 5 % Acier, 5 % Sacré : 12,5 %).
func resistance(element: String) -> float:
	var own := float(resistances.get(element, 0)) + modifier("resistance", element)
	if not Spell.COMPOSITE_ELEMENTS.has(element):
		return own
	var bases: Array = Spell.COMPOSITE_ELEMENTS[element]
	return (resistance(bases[0]) + resistance(bases[1])) / 2.0 + own


func stat(stat_name: String) -> int:
	return int(stats.get(stat_name, 0)) + modifier(stat_name)


## Somme des bonus moins les malus en cours sur cette caractéristique (`element` pour les résistances).
func modifier(carac: String, element := "") -> int:
	var total := 0
	for state in states:
		if state.get("carac") == carac and (carac != "resistance" or state.get("element") == element):
			total += int(state["valeur"]) * (1 if state["type"] == Spell.EFFECT_BONUS else -1 if state["type"] == Spell.EFFECT_MALUS else 0)
	return total


## Portée en plus des sorts à distance : passif, équipement et états.
func total_range_bonus() -> int:
	return range_bonus + modifier("portee")


## Dommages : équipement et états (jamais négatifs).
func total_dommages() -> int:
	return maxi(0, dommages + modifier("dommages"))


## Chance de coup critique en plus : équipement et états.
func total_crit_bonus() -> int:
	return crit_bonus + modifier("critique")


## PA et PM qu'il aura au début de son prochain tour.
func next_turn_pa() -> int:
	return maxi(0, max_pa + modifier("pa"))


func next_turn_pm() -> int:
	return maxi(0, max_pm - pm_malus + modifier("pm"))


## Bonus en % des dégâts de cet élément : 1 % par point de la caractéristique associée ; pour un élément
## composé, de chacune des deux (Sacré : Force + Intelligence ; Impie : Agilité + Chance).
func power(element: String) -> int:
	if Spell.COMPOSITE_ELEMENTS.has(element):
		var bases: Array = Spell.COMPOSITE_ELEMENTS[element]
		return power(bases[0]) + power(bases[1])
	return stat(ELEMENT_STATS.get(element, ""))


func start_turn() -> void:
	shield = 0
	pa = next_turn_pa()
	pm = next_turn_pm()
	pm_malus = 0
	_casts_this_turn.clear()
	for spell_id: String in _cooldowns.keys():
		_cooldowns[spell_id] -= 1
		if _cooldowns[spell_id] <= 0:
			_cooldowns.erase(spell_id)


## Fin de son tour : chaque état perd un tour ; renvoie vrai si au moins un état est tombé.
func end_turn() -> bool:
	var kept: Array[Dictionary] = []
	for state in states:
		state["tours"] = int(state["tours"]) - 1
		if int(state["tours"]) > 0:
			kept.append(state)
	var changed := kept.size() != states.size()
	states = kept
	return changed


## États pour l'affichage : { type, carac, element, valeur, tours, sort }.
func states_snapshot() -> Array:
	var result: Array = []
	for state in states:
		result.append({"type": state["type"], "carac": state.get("carac", ""), "element": state.get("element", ""),
			"valeur": state.get("valeur", 0), "min": state.get("min", 0), "max": state.get("max", 0),
			"tours": state["tours"], "sort": state.get("sort", "")})
	return result


## Raison pour laquelle le sort ne peut pas être lancé maintenant (vide si possible).
func cast_blocker(spell: Spell) -> String:
	if spell.pa_cost > pa:
		return Protocol.REASON_NOT_ENOUGH_PA
	if spell.casts_per_turn > 0 and int(_casts_this_turn.get(spell.id, 0)) >= spell.casts_per_turn:
		return Protocol.REASON_SPELL_LIMIT
	if _cooldowns.has(spell.id):
		return Protocol.REASON_SPELL_COOLDOWN
	return ""


func register_cast(spell: Spell) -> void:
	pa -= spell.pa_cost
	_casts_this_turn[spell.id] = int(_casts_this_turn.get(spell.id, 0)) + 1
	if spell.cooldown > 0:
		_cooldowns[spell.id] = spell.cooldown


## Tours restants avant de pouvoir relancer le sort (0 si disponible).
func cooldown_of(spell: Spell) -> int:
	return int(_cooldowns.get(spell.id, 0))


## Instantané envoyé au client dans les événements.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"nom": display_name,
		"equipe": team,
		"type": kind,
		"race": race,
		"case": cell,
		"pv": hp,
		"pv_max": max_hp,
		"pa": max_pa,
		"pm": max_pm,
		"initiative": initiative,
		"ia": is_ai(),
	}
