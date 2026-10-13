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


## Résistance en % à un élément. Pour un élément composé (Sacré, Impie) : sa valeur si elle est donnée,
## sinon la moyenne des résistances aux deux éléments de base.
func resistance(element: String) -> int:
	if resistances.has(element) or not Spell.COMPOSITE_ELEMENTS.has(element):
		return int(resistances.get(element, 0))
	var bases: Array = Spell.COMPOSITE_ELEMENTS[element]
	return roundi((resistance(bases[0]) + resistance(bases[1])) / 2.0)


func stat(stat_name: String) -> int:
	return int(stats.get(stat_name, 0))


## Bonus en % des dégâts de cet élément (la caractéristique associée ; pour un élément composé, la
## moyenne des caractéristiques de ses deux éléments de base).
func power(element: String) -> int:
	if Spell.COMPOSITE_ELEMENTS.has(element):
		var bases: Array = Spell.COMPOSITE_ELEMENTS[element]
		return roundi((power(bases[0]) + power(bases[1])) / 2.0)
	return stat(ELEMENT_STATS.get(element, ""))


func start_turn() -> void:
	pa = max_pa
	pm = maxi(0, max_pm - pm_malus)
	pm_malus = 0
	_casts_this_turn.clear()
	for spell_id: String in _cooldowns.keys():
		_cooldowns[spell_id] -= 1
		if _cooldowns[spell_id] <= 0:
			_cooldowns.erase(spell_id)


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
