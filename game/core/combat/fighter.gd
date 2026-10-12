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


func resistance(element: String) -> int:
	return int(resistances.get(element, 0))


func start_turn() -> void:
	pa = max_pa
	pm = max_pm
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
		"case": cell,
		"pv": hp,
		"pv_max": max_hp,
		"pa": max_pa,
		"pm": max_pm,
		"initiative": initiative,
		"ia": is_ai(),
	}
