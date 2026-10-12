class_name Combat
extends RefCounted
## Un combat au tour par tour sur une carte : placement, tours par initiative, PA/PM, sorts.
## Comme `World`, il reçoit des commandes (`execute`) et renvoie des événements (voir `Protocol`).
## Les tours des monstres sont joués automatiquement (voir `CombatAI`), dans la foulée de la
## commande qui leur passe la main.

enum State { PLACEMENT, FIGHTING, FINISHED }

## Obstacles qui ne bloquent pas la ligne de vue.
const SEE_THROUGH_OBSTACLES := ["eau"]
## Garde-fous contre les boucles infinies.
const MAX_AI_ACTIONS := 20
const MAX_ROUNDS := 200

var map: GameMap
var state: State = State.PLACEMENT
## Combattants, dans l'ordre de jeu une fois le combat commencé.
var fighters: Array[Fighter] = []
## Cases où l'équipe des joueurs peut se placer.
var placement_cells: Array[Vector2i] = []
var round_number := 0
## Équipe gagnante (-1 tant que le combat n'est pas fini, ou en cas d'abandon des deux camps).
var winner_team := -1
var rng := RandomNumberGenerator.new()

var _turn_index := -1
## Ordre d'arrivée des combattants, pour départager les égalités d'initiative.
var _arrival: Dictionary = {}


func _init(p_map: GameMap, p_fighters: Array[Fighter], p_placement_cells: Array[Vector2i], seed_value := 0) -> void:
	map = p_map
	fighters = p_fighters
	placement_cells = p_placement_cells
	rng.seed = seed_value


## Événement d'ouverture du combat, avec l'état de départ.
func start() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for fighter in fighters:
		snapshots.append(fighter.to_dict())
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_COMBAT_STARTED,
		"combattants": snapshots,
		"placement": placement_cells.duplicate(),
	}]
	return events


func get_fighter(fighter_id: String) -> Fighter:
	for fighter in fighters:
		if fighter.id == fighter_id:
			return fighter
	return null


## Combattant vivant sur la case, ou `null`.
func fighter_at(cell: Vector2i) -> Fighter:
	for fighter in fighters:
		if fighter.is_alive() and fighter.cell == cell:
			return fighter
	return null


func current_fighter() -> Fighter:
	if state != State.FIGHTING or _turn_index < 0:
		return null
	return fighters[_turn_index]


func enemies_of(fighter: Fighter) -> Array[Fighter]:
	var result: Array[Fighter] = []
	for other in fighters:
		if other.is_alive() and other.team != fighter.team:
			result.append(other)
	return result


func execute(command: Dictionary) -> Array[Dictionary]:
	var type: Variant = command.get("type")
	if typeof(type) == TYPE_STRING:
		if type == Protocol.CMD_PLACE:
			return _place(command)
		if type == Protocol.CMD_READY:
			return _begin_fight(command)
		if type == Protocol.CMD_MOVE:
			return _player_action(command)
		if type == Protocol.CMD_CAST:
			return _player_action(command)
		if type == Protocol.CMD_END_TURN:
			return _player_action(command)
	return _refused(command, Protocol.REASON_UNKNOWN_COMMAND)


# --- Règles consultables par le client et l'IA -----------------------------------------------

func is_free(cell: Vector2i) -> bool:
	return map.is_walkable(cell) and fighter_at(cell) == null


## Cases atteignables avec les PM du combattant, et le chemin pour chacune (4 directions).
func reachable_cells(fighter: Fighter) -> Dictionary:
	var paths := {fighter.cell: [] as Array[Vector2i]}
	var frontier: Array[Vector2i] = [fighter.cell]
	for step in fighter.pm:
		var next_frontier: Array[Vector2i] = []
		for cell in frontier:
			for neighbor in IsoGrid.neighbors_4(cell):
				if paths.has(neighbor) or not is_free(neighbor):
					continue
				var path: Array[Vector2i] = paths[cell].duplicate()
				path.append(neighbor)
				paths[neighbor] = path
				next_frontier.append(neighbor)
		frontier = next_frontier
	paths.erase(fighter.cell)
	return paths


## Nombre de pas (4 directions) entre chaque case et la source la plus proche, en contournant
## obstacles et combattants (sauf `ignored`). Les sources elles-mêmes valent 0.
func distances_from(sources: Array[Vector2i], ignored: Fighter = null) -> Dictionary:
	var distances := {}
	var frontier: Array[Vector2i] = []
	for source in sources:
		distances[source] = 0
		frontier.append(source)
	while not frontier.is_empty():
		var next_frontier: Array[Vector2i] = []
		for cell in frontier:
			for neighbor in IsoGrid.neighbors_4(cell):
				if distances.has(neighbor) or not map.is_walkable(neighbor):
					continue
				var occupant := fighter_at(neighbor)
				if occupant != null and occupant != ignored:
					continue
				distances[neighbor] = distances[cell] + 1
				next_frontier.append(neighbor)
		frontier = next_frontier
	return distances


## Raison pour laquelle `fighter` ne peut pas viser `target` avec `spell` depuis `origin`
## (sa case actuelle par défaut) ; vide si la cible est valide. Ne vérifie pas les PA.
func targeting_blocker(fighter: Fighter, spell: Spell, target: Vector2i, origin := Vector2i(-99999, -99999)) -> String:
	var from := fighter.cell if origin == Vector2i(-99999, -99999) else origin
	if not map.is_inside(target):
		return Protocol.REASON_OUT_OF_MAP
	var distance := IsoGrid.distance(from, target)
	if distance < spell.range_min or distance > max_range(fighter, spell):
		return Protocol.REASON_OUT_OF_RANGE
	if spell.needs_line_of_sight and not LineOfSight.is_clear(from, target, _sight_blocker(fighter)):
		return Protocol.REASON_NO_LINE_OF_SIGHT
	return ""


## Portée maximale réelle : les sorts à distance (portée de 2 ou plus) profitent des bonus de portée.
func max_range(fighter: Fighter, spell: Spell) -> int:
	return spell.range_max + (fighter.range_bonus if spell.range_max >= 2 else 0)


## Cases à portée du sort, avec et sans ligne de vue (pour l'affichage).
func spell_range(fighter: Fighter, spell: Spell) -> Dictionary:
	var result := {"visibles": [] as Array[Vector2i], "masquees": [] as Array[Vector2i]}
	var reach := max_range(fighter, spell)
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var cell := fighter.cell + Vector2i(dx, dy)
			var blocker := targeting_blocker(fighter, spell, cell)
			if blocker.is_empty():
				result["visibles"].append(cell)
			elif blocker == Protocol.REASON_NO_LINE_OF_SIGHT:
				result["masquees"].append(cell)
	return result


# --- Placement -------------------------------------------------------------------------------

func _place(command: Dictionary) -> Array[Dictionary]:
	if state != State.PLACEMENT:
		return _refused(command, Protocol.REASON_WRONG_PHASE)
	var fighter := _command_fighter(command)
	var target: Variant = command.get("cible")
	if fighter == null or fighter.is_ai():
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if typeof(target) != TYPE_VECTOR2I:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if target not in placement_cells:
		return _refused(command, Protocol.REASON_NOT_PLACEMENT_CELL)
	var occupant := fighter_at(target)
	if occupant != null and occupant != fighter:
		return _refused(command, Protocol.REASON_OCCUPIED)
	fighter.cell = target
	var events: Array[Dictionary] = [{"type": Protocol.EVT_PLACED, "entite": fighter.id, "case": fighter.cell}]
	return events


func _begin_fight(command: Dictionary) -> Array[Dictionary]:
	if state != State.PLACEMENT:
		return _refused(command, Protocol.REASON_WRONG_PHASE)
	var fighter := _command_fighter(command)
	if fighter == null or fighter.is_ai():
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	state = State.FIGHTING
	# Ordre de jeu : initiative décroissante ; à égalité, les joueurs d'abord, puis l'ordre d'arrivée.
	_arrival.clear()
	for i in fighters.size():
		_arrival[fighters[i]] = i
	fighters.sort_custom(_plays_before)
	var order: Array[String] = []
	for f in fighters:
		order.append(f.id)
	var events: Array[Dictionary] = [{"type": Protocol.EVT_FIGHT_BEGINS, "ordre": order}]
	_next_turn(events)
	return events


# --- Actions du combattant dont c'est le tour --------------------------------------------------

func _player_action(command: Dictionary) -> Array[Dictionary]:
	if state != State.FIGHTING:
		return _refused(command, Protocol.REASON_WRONG_PHASE)
	var fighter := _command_fighter(command)
	if fighter == null:
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if fighter != current_fighter() or fighter.is_ai():
		return _refused(command, Protocol.REASON_NOT_YOUR_TURN)
	var events := _apply_action(fighter, command)
	if command["type"] == Protocol.CMD_END_TURN:
		_next_turn(events)
	return events


## Applique une action (déplacement, sort ou fin de tour) du combattant dont c'est le tour.
func _apply_action(fighter: Fighter, command: Dictionary) -> Array[Dictionary]:
	var type: String = command["type"]
	if type == Protocol.CMD_MOVE:
		return _move(fighter, command)
	if type == Protocol.CMD_CAST:
		return _cast(fighter, command)
	var events: Array[Dictionary] = [{"type": Protocol.EVT_TURN_ENDED, "entite": fighter.id}]
	return events


func _move(fighter: Fighter, command: Dictionary) -> Array[Dictionary]:
	var target: Variant = command.get("cible")
	if typeof(target) != TYPE_VECTOR2I:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if not map.is_inside(target):
		return _refused(command, Protocol.REASON_OUT_OF_MAP)
	if not map.is_walkable(target):
		return _refused(command, Protocol.REASON_BLOCKED)
	if target == fighter.cell:
		return _refused(command, Protocol.REASON_ALREADY_THERE)
	if fighter_at(target) != null:
		return _refused(command, Protocol.REASON_OCCUPIED)
	var reachable := reachable_cells(fighter)
	if not reachable.has(target):
		return _refused(command, Protocol.REASON_NOT_ENOUGH_PM)
	var path: Array[Vector2i] = reachable[target]
	var from := fighter.cell
	fighter.cell = target
	fighter.pm -= path.size()
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_MOVED,
		"entite": fighter.id,
		"depuis": from,
		"chemin": path,
		"pm": fighter.pm,
	}]
	return events


func _cast(fighter: Fighter, command: Dictionary) -> Array[Dictionary]:
	var spell_id: Variant = command.get("sort")
	var target: Variant = command.get("cible")
	if typeof(spell_id) != TYPE_STRING or typeof(target) != TYPE_VECTOR2I:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var spell := fighter.get_spell(spell_id)
	if spell == null:
		return _refused(command, Protocol.REASON_UNKNOWN_SPELL)
	var blocker := fighter.cast_blocker(spell)
	if blocker.is_empty():
		blocker = targeting_blocker(fighter, spell, target)
	if blocker.is_empty() and spell.teleports() and target != fighter.cell and not is_free(target):
		blocker = Protocol.REASON_OCCUPIED if fighter_at(target) != null else Protocol.REASON_BLOCKED
	if not blocker.is_empty():
		return _refused(command, blocker)

	fighter.register_cast(spell)
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_SPELL_CAST,
		"entite": fighter.id,
		"sort": spell.id,
		"cible": target,
		"pa": fighter.pa,
	}]
	if spell.teleports():
		var from := fighter.cell
		fighter.cell = target
		events.append({"type": Protocol.EVT_TELEPORTED, "entite": fighter.id, "depuis": from, "case": target})
	var targets: Array[Fighter] = []
	for cell in spell.zone_cells(target):
		var hit := fighter_at(cell)
		if hit != null and not (spell.excludes_caster and hit == fighter):
			targets.append(hit)
	for hit in targets:
		for effect in spell.effects:
			if hit.is_alive() and effect["type"] != Spell.EFFECT_TELEPORT:
				_apply_effect(fighter, hit, effect, events)
	_check_end(events)
	return events


## Dégâts : base × (100 + caractéristique de l'élément du lanceur) % × (100 − résistance de la cible) %.
## Soins : base × (100 + intelligence du lanceur) %.
func _apply_effect(caster: Fighter, target: Fighter, effect: Dictionary, events: Array[Dictionary]) -> void:
	var amount := rng.randi_range(effect["min"], effect["max"])
	if effect["type"] == Spell.EFFECT_GAIN_PA:
		target.pa += amount
		events.append({"type": Protocol.EVT_STATUS, "entite": target.id, "effet": Spell.EFFECT_GAIN_PA, "valeur": amount, "pa": target.pa, "pm": target.pm})
		return
	if effect["type"] == Spell.EFFECT_REMOVE_PM:
		target.pm_malus += amount
		events.append({"type": Protocol.EVT_STATUS, "entite": target.id, "effet": Spell.EFFECT_REMOVE_PM, "valeur": amount, "pa": target.pa, "pm": target.pm})
		return
	if effect["type"] == Spell.EFFECT_DAMAGE:
		var element: String = effect["element"]
		var boosted := amount * (100 + caster.power(element)) / 100.0
		amount = maxi(0, roundi(boosted * (100 - target.resistance(element)) / 100.0))
		target.hp = maxi(0, target.hp - amount)
		events.append({"type": Protocol.EVT_DAMAGE, "entite": target.id, "valeur": amount, "element": element, "pv": target.hp})
		if not target.is_alive():
			events.append({"type": Protocol.EVT_DIED, "entite": target.id})
	elif effect["type"] == Spell.EFFECT_HEAL:
		amount = roundi(amount * (100 + caster.stat("intelligence")) / 100.0)
		amount = mini(amount, target.max_hp - target.hp)
		target.hp += amount
		events.append({"type": Protocol.EVT_HEAL, "entite": target.id, "valeur": amount, "pv": target.hp})


# --- Enchaînement des tours ------------------------------------------------------------------

## Passe la main au combattant suivant ; joue les tours des monstres jusqu'au prochain joueur.
func _next_turn(events: Array[Dictionary]) -> void:
	while state == State.FIGHTING:
		_turn_index += 1
		if _turn_index >= fighters.size():
			_turn_index = 0
		if _turn_index == 0:
			round_number += 1
			if round_number > MAX_ROUNDS:
				_finish(-1, events)
				return
		var fighter := fighters[_turn_index]
		if not fighter.is_alive():
			continue
		fighter.start_turn()
		events.append({"type": Protocol.EVT_TURN_STARTED, "entite": fighter.id, "tour": round_number, "pa": fighter.pa, "pm": fighter.pm})
		if not fighter.is_ai():
			return
		_play_ai_turn(fighter, events)
		if state == State.FIGHTING:
			events.append({"type": Protocol.EVT_TURN_ENDED, "entite": fighter.id})


func _play_ai_turn(fighter: Fighter, events: Array[Dictionary]) -> void:
	var has_moved := false
	for i in MAX_AI_ACTIONS:
		var action := CombatAI.next_action(self, fighter, has_moved)
		if action.is_empty():
			return
		has_moved = has_moved or action["type"] == Protocol.CMD_MOVE
		var result := _apply_action(fighter, action)
		events.append_array(result)
		if result.is_empty() or result[0]["type"] == Protocol.EVT_REFUSED or state != State.FIGHTING:
			return


func _check_end(events: Array[Dictionary]) -> void:
	var alive_teams := {}
	for fighter in fighters:
		if fighter.is_alive():
			alive_teams[fighter.team] = true
	if alive_teams.size() == 1:
		_finish(alive_teams.keys()[0], events)
	elif alive_teams.is_empty():
		_finish(-1, events)


func _finish(team: int, events: Array[Dictionary]) -> void:
	state = State.FINISHED
	winner_team = team
	# XP des ennemis vaincus, même en cas de défaite : ceux qui sont tombés comptent.
	var xp := 0
	for fighter in fighters:
		if fighter.team != Fighter.TEAM_PLAYERS and not fighter.is_alive():
			xp += fighter.xp
	events.append({"type": Protocol.EVT_COMBAT_ENDED, "vainqueur": team, "xp": xp})


# --- Utilitaires -----------------------------------------------------------------------------

func _command_fighter(command: Dictionary) -> Fighter:
	var fighter_id: Variant = command.get("entite")
	if typeof(fighter_id) != TYPE_STRING:
		return null
	return get_fighter(fighter_id)


func _plays_before(a: Fighter, b: Fighter) -> bool:
	if a.initiative != b.initiative:
		return a.initiative > b.initiative
	if a.team != b.team:
		return a.team < b.team
	return _arrival[a] < _arrival[b]


## Fonction « cette case bloque-t-elle la vue ? » pour un tir de `shooter`.
func _sight_blocker(shooter: Fighter) -> Callable:
	return _blocks_sight.bind(shooter)


func _blocks_sight(cell: Vector2i, shooter: Fighter) -> bool:
	if map.obstacles.has(cell) and map.obstacles[cell] not in SEE_THROUGH_OBSTACLES:
		return true
	var occupant := fighter_at(cell)
	return occupant != null and occupant != shooter


func _refused(command: Dictionary, reason: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_REFUSED,
		"commande": str(command.get("type", "")),
		"raison": reason,
	}]
	return events
