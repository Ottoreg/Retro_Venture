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
## Dégâts de choc par case de poussée non parcourue (obstacle, bord ou combattant sur le chemin).
const PUSH_DAMAGE_PER_CELL := 4

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
## Glyphes au sol : { id, lanceur: Fighter, equipe, cases: Array[Vector2i], effets, tours, sort }.
var glyphs: Array[Dictionary] = []
## Pièges posés : { id, lanceur: Fighter, equipe, case, cases (zone d'explosion), effets, sort }.
var traps: Array[Dictionary] = []

## Temps limité (en ligne, GDD § 7.2) : secondes d'un tour de joueur, et du placement ; 0 : illimité
## (solo). Le temps passe par `advance`.
var turn_limit := 0.0
var placement_limit := 0.0
## Joueurs prêts pendant le placement (id → true) : le combat commence quand tous le sont.
var ready: Dictionary = {}
## Joueurs déconnectés (id → true) : leurs tours passent tout seuls, et ils comptent comme prêts.
var absent: Dictionary = {}
## Verrous du combat, au choix de celui qui l'a engagé (en ligne, GDD § 16.5, M2) : fermé, plus
## personne ne le rejoint ; sans spectateurs, plus personne ne le regarde.
var locked := false
var spectators_allowed := true
## Joueurs qui regardent le combat (ids) : ils reçoivent ses événements.
var spectators: Array[String] = []

## Pratique des joueurs pendant le combat, pour leur progression (GDD § 4.5, `Progression`) :
## id → { effet: { élément → PA des sorts à effet réel }, utile: PA des sorts utilitaires qui ont touché
## quelqu'un, pv_recus: PV réellement perdus }. Les PA d'un poison ou d'une glyphe sont répartis sur
## ses tours.
var practice: Dictionary = {}

var _turn_index := -1
## Sort en cours d'effet, pour la pratique : { lanceur: Fighter, pa: float, element: élément du
## premier effet réel (vide sinon), utile: bool } ; vide hors d'un sort de l'équipe des joueurs.
var _credit: Dictionary = {}
## Temps écoulé du placement ou du tour du joueur en cours (avec `turn_limit`).
var _elapsed := 0.0
## Ordre d'arrivée des combattants, pour départager les égalités d'initiative.
var _arrival: Dictionary = {}
var _next_ground_id := 1


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


## Ajoute un joueur pendant le placement (combat rejoint), sur la première case de placement libre ;
## refus s'il n'y en a plus.
func add_player_fighter(fighter: Fighter) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state != State.PLACEMENT:
		return _refused({"type": Protocol.CMD_JOIN_COMBAT}, Protocol.REASON_COMBAT_STARTED)
	for cell in placement_cells:
		if fighter_at(cell) == null:
			fighter.cell = cell
			fighters.append(fighter)
			events.append({"type": Protocol.EVT_FIGHTER_JOINED, "combattant": fighter.to_dict()})
			return events
	return _refused({"type": Protocol.CMD_JOIN_COMBAT}, Protocol.REASON_COMBAT_FULL)


## Combattants des joueurs (vivants ou non).
func player_fighters() -> Array[Fighter]:
	var result: Array[Fighter] = []
	for fighter in fighters:
		if not fighter.is_ai():
			result.append(fighter)
	return result


## Un joueur se déconnecte (`away` vrai) ou revient. Absent, il compte comme prêt et ses tours passent
## tout seuls (le sien tout de suite).
func set_absent(fighter_id: String, away: bool) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var fighter := get_fighter(fighter_id)
	if fighter == null or fighter.is_ai() or absent.has(fighter_id) == away or state == State.FINISHED:
		return events
	if away:
		absent[fighter_id] = true
	else:
		absent.erase(fighter_id)
	events.append({"type": Protocol.EVT_FIGHTER_AWAY, "entite": fighter_id, "absent": away})
	if away and state == State.PLACEMENT and _everyone_ready():
		events.append_array(_start_fighting())
	elif away and current_fighter() == fighter:
		events.append({"type": Protocol.EVT_TURN_ENDED, "entite": fighter_id, "absent": true})
		_next_turn(events)
	return events


## Fait passer le temps du placement ou du tour (avec `turn_limit`) : au bout, le combat commence ou
## le tour du joueur passe.
func advance(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if turn_limit <= 0.0:
		return events
	if state == State.PLACEMENT and placement_limit > 0.0:
		_elapsed += delta
		if _elapsed >= placement_limit:
			events.append_array(_start_fighting())
	elif state == State.FIGHTING and current_fighter() != null and not current_fighter().is_ai():
		_elapsed += delta
		if _elapsed >= turn_limit:
			events.append({"type": Protocol.EVT_TURN_ENDED, "entite": current_fighter().id, "temps_ecoule": true})
			_next_turn(events)
	return events


## Secondes restantes du placement ou du tour du joueur (0 sans limite).
func time_left() -> float:
	if turn_limit <= 0.0:
		return 0.0
	return maxf(0.0, (placement_limit if state == State.PLACEMENT else turn_limit) - _elapsed)


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


## Piège posé sur la case (vide s'il n'y en a pas).
func trap_at(cell: Vector2i) -> Dictionary:
	for trap in traps:
		if trap["case"] == cell:
			return trap
	return {}


## Piège d'une autre équipe que `fighter` sur la case : c'est celui qu'il déclenche en y entrant.
func enemy_trap_at(cell: Vector2i, fighter: Fighter) -> Dictionary:
	var trap := trap_at(cell)
	return trap if not trap.is_empty() and trap["equipe"] != fighter.team else {}


## Glyphes qui couvrent la case.
func glyphs_at(cell: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for glyph in glyphs:
		if cell in glyph["cases"]:
			result.append(glyph)
	return result


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
	return map.is_walkable_in_combat(cell) and fighter_at(cell) == null


## Cases atteignables avec les PM du combattant (ou `pm` s'il est donné), et le chemin pour chacune
## (4 directions).
func reachable_cells(fighter: Fighter, pm := -1) -> Dictionary:
	var paths := {fighter.cell: [] as Array[Vector2i]}
	var frontier: Array[Vector2i] = [fighter.cell]
	for step in (fighter.pm if pm < 0 else pm):
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


## Cases qu'un combattant peut atteindre, affichées au survol (GDD § 14.3) : avec ses PM restants
## pendant son tour, sinon avec ceux qu'il aura au début du prochain.
func movement_zone(fighter: Fighter) -> Array[Vector2i]:
	var pm := fighter.pm if fighter == current_fighter() else fighter.next_turn_pm()
	var cells: Array[Vector2i] = []
	cells.assign(reachable_cells(fighter, pm).keys())
	return cells


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
				if distances.has(neighbor) or not map.is_walkable_in_combat(neighbor):
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
	if spell.cast_in_line and from.x != target.x and from.y != target.y:
		return Protocol.REASON_NOT_IN_LINE
	var distance := IsoGrid.distance(from, target)
	if distance < spell.range_min or distance > max_range(fighter, spell):
		return Protocol.REASON_OUT_OF_RANGE
	if spell.needs_line_of_sight and not LineOfSight.is_clear(from, target, _sight_blocker(fighter)):
		return Protocol.REASON_NO_LINE_OF_SIGHT
	return ""


## Sort que « creer_sort » donnerait à `fighter` avec ses états élémentaires actuels (null si le sort
## ne crée rien, ou si la combinaison n'a pas de sort).
func created_spell_for(fighter: Fighter, spell: Spell) -> Spell:
	var effect := spell.create_effect()
	if effect.is_empty() or fighter.element_states.size() < Fighter.ELEMENT_STATE_MAX:
		return null
	return effect.get("sorts", {}).get(Spell.combination_key(fighter.element_states))


## Cases parcourues par une charge de `fighter` vers `target` depuis `origin` : en ligne droite, tant
## que la case suivante est libre, jusqu'au contact d'un combattant sur la case visée (ou jusqu'à la
## case visée si elle est libre). Un piège ennemi arrête la charge sur sa case.
func charge_path(fighter: Fighter, target: Vector2i, origin := Vector2i(-99999, -99999)) -> Array[Vector2i]:
	var cell := fighter.cell if origin == Vector2i(-99999, -99999) else origin
	var step := Spell.direction(cell, target)
	var path: Array[Vector2i] = []
	while cell != target:
		var next := cell + step
		var occupant := fighter_at(next)
		if not map.is_inside(next) or not map.is_walkable_in_combat(next) or (occupant != null and occupant != fighter):
			break
		cell = next
		path.append(cell)
		if not enemy_trap_at(cell, fighter).is_empty():
			break
	return path


## Portée maximale réelle : les sorts à distance (portée de 2 ou plus) profitent des bonus de portée.
func max_range(fighter: Fighter, spell: Spell) -> int:
	return spell.range_max + (fighter.total_range_bonus() if spell.range_max >= 2 else 0)


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
	ready[fighter.id] = true
	if not _everyone_ready():
		var waiting: Array[Dictionary] = [{"type": Protocol.EVT_READY, "entite": fighter.id}]
		return waiting
	return _start_fighting()


func _everyone_ready() -> bool:
	for player in player_fighters():
		if not ready.has(player.id) and not absent.has(player.id):
			return false
	return true


func _start_fighting() -> Array[Dictionary]:
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
	# Fin de tour demandée, ou combattant tombé pendant son tour (piège) : la main passe.
	if command["type"] == Protocol.CMD_END_TURN or (not fighter.is_alive() and state == State.FIGHTING):
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
	if not map.is_walkable_in_combat(target):
		return _refused(command, Protocol.REASON_BLOCKED)
	if target == fighter.cell:
		return _refused(command, Protocol.REASON_ALREADY_THERE)
	if fighter_at(target) != null:
		return _refused(command, Protocol.REASON_OCCUPIED)
	var reachable := reachable_cells(fighter)
	if not reachable.has(target):
		return _refused(command, Protocol.REASON_NOT_ENOUGH_PM)
	var path: Array[Vector2i] = reachable[target]
	# Un piège ennemi arrête la marche sur sa case.
	var trap := {}
	for i in path.size():
		trap = enemy_trap_at(path[i], fighter)
		if not trap.is_empty():
			path = path.slice(0, i + 1)
			break
	var from := fighter.cell
	fighter.cell = path[-1]
	fighter.pm -= path.size()
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_MOVED,
		"entite": fighter.id,
		"depuis": from,
		"chemin": path,
		"pm": fighter.pm,
	}]
	if not trap.is_empty():
		_trigger_trap(trap, fighter, events)
		_check_end(events)
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
	var trap_effect := spell.trap_effect()
	if blocker.is_empty() and not trap_effect.is_empty() and (not is_free(target) or not trap_at(target).is_empty()):
		blocker = Protocol.REASON_BLOCKED if not map.is_walkable_in_combat(target) else Protocol.REASON_OCCUPIED
	if blocker.is_empty() and not spell.create_effect().is_empty() and created_spell_for(fighter, spell) == null:
		blocker = Protocol.REASON_NO_COMBINATION
	var choices := spell.state_choices()
	if blocker.is_empty() and not choices.is_empty() and str(command.get("etats", "")) not in choices:
		blocker = Protocol.REASON_INVALID_COMPOSITION
	if not blocker.is_empty():
		return _refused(command, blocker)

	fighter.register_cast(spell)
	var crit_chance := spell.crit_chance + fighter.total_crit_bonus()
	var critical := crit_chance > 0 and rng.randf() * 100.0 < crit_chance
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_SPELL_CAST,
		"entite": fighter.id,
		"sort": spell.id,
		"cible": target,
		"pa": fighter.pa,
		"critique": critical,
	}]
	if not trap_effect.is_empty():
		events[0]["cache"] = true
	var origin := fighter.cell
	if spell.teleports():
		var from := fighter.cell
		fighter.cell = target
		events.append({"type": Protocol.EVT_TELEPORTED, "entite": fighter.id, "depuis": from, "case": target})
		var trap := enemy_trap_at(target, fighter)
		if not trap.is_empty():
			_trigger_trap(trap, fighter, events)
	# Charge : les effets ne touchent la cible que si le lanceur arrive à son contact.
	var reached := true
	if spell.charges():
		var path := charge_path(fighter, target)
		var from := fighter.cell
		if not path.is_empty():
			fighter.cell = path[-1]
		reached = fighter_at(target) != null and IsoGrid.distance(fighter.cell, target) == 1
		events.append({"type": Protocol.EVT_CHARGED, "entite": fighter.id, "depuis": from, "chemin": path,
			"case": fighter.cell, "contact": reached})
		if not path.is_empty():
			var trap := enemy_trap_at(fighter.cell, fighter)
			if not trap.is_empty():
				_trigger_trap(trap, fighter, events)
		if not fighter.is_alive():
			_check_end(events)
			return events
	if not choices.is_empty():
		fighter.element_states.assign(str(command["etats"]).split("+"))
		events.append({"type": Protocol.EVT_ELEMENT_STATES, "entite": fighter.id, "etats": fighter.element_states.duplicate(),
			"composition": true})
	var created := created_spell_for(fighter, spell)
	if created != null:
		var removed := fighter.add_created_spell(created)
		events.append({"type": Protocol.EVT_SPELL_CREATED, "entite": fighter.id, "sort": created.id, "ancien": removed})
	for effect in spell.effects:
		if effect["type"] == Spell.EFFECT_GLYPH:
			_place_glyph(fighter, spell, effect, spell.zone_cells(target, origin), events)
		elif effect["type"] == Spell.EFFECT_TRAP:
			_place_trap(fighter, spell, effect, target, events)
	_open_credit(fighter, spell.pa_cost)
	var targets: Array[Fighter] = []
	for cell in spell.zone_cells(target, origin) if reached else []:
		var hit := fighter_at(cell)
		if hit != null and not (spell.excludes_caster and hit == fighter):
			targets.append(hit)
	for hit in targets:
		for effect in spell.effects:
			if hit.is_alive() and effect["type"] not in [Spell.EFFECT_TELEPORT, Spell.EFFECT_GLYPH, Spell.EFFECT_TRAP,
					Spell.EFFECT_CHARGE, Spell.EFFECT_CREATE_SPELL, Spell.EFFECT_COMPOSE_STATES] \
					and Spell.affects(effect, fighter, hit):
				_apply_effect(fighter, hit, effect, events, critical, origin, spell.display_name)
	_close_credit()
	_check_end(events)
	return events


# --- Pratique (progression des joueurs, GDD § 4.5) ---------------------------------------------

## Commence à noter ce que fait un sort de `caster` (s'il est de l'équipe des joueurs) qui a coûté `pa`.
func _open_credit(caster: Fighter, pa: float) -> void:
	_credit = {}
	if caster != null and caster.team == Fighter.TEAM_PLAYERS and pa > 0.0:
		_credit = {"lanceur": caster, "pa": pa, "element": "", "utile": false}


## Inscrit le sort noté dans la pratique de son lanceur : effet réel (par élément) ou utilitaire.
func _close_credit() -> void:
	if _credit.is_empty():
		return
	var caster: Fighter = _credit["lanceur"]
	if not str(_credit["element"]).is_empty():
		_add_practice(caster.id, "effet", float(_credit["pa"]), _credit["element"])
	elif _credit["utile"]:
		_add_practice(caster.id, "utile", float(_credit["pa"]))
	_credit = {}


func _add_practice(fighter_id: String, kind: String, amount: float, element := "") -> void:
	if not practice.has(fighter_id):
		practice[fighter_id] = {"effet": {}, "utile": 0.0, "pv_recus": 0.0}
	var entry: Dictionary = practice[fighter_id]
	if kind == "effet":
		entry["effet"][element] = float(entry["effet"].get(element, 0.0)) + amount
	else:
		entry[kind] = float(entry[kind]) + amount


## Note l'effet réel du sort en cours (le premier élément compte) ; `element` vide : seulement utile.
func _credit_effect(caster: Fighter, element: String) -> void:
	if _credit.is_empty() or _credit["lanceur"] != caster:
		return
	if element.is_empty():
		_credit["utile"] = true
	elif str(_credit["element"]).is_empty():
		_credit["element"] = element


## Dégâts : base × (100 + caractéristique de l'élément du lanceur) % × (100 − résistance de la cible) %,
## plus les Dommages du lanceur (bruts : ni multipliés ni réduits par une résistance).
## Soins, boucliers et poisons : base × (100 + caractéristique de leur élément) %, comme les dégâts
## (règle de tous les effets chiffrés). Le bouclier absorbe les dégâts avant les PV, jusqu'au début du
## prochain tour de celui qui le porte. Coup critique : la valeur tirée des dégâts, soins, boucliers
## et poisons est multipliée par `Spell.CRIT_MULTIPLIER`. `origin` : d'où l'on pousse ou attire.
func _apply_effect(caster: Fighter, target: Fighter, effect: Dictionary, events: Array[Dictionary], critical := false,
		origin := Vector2i(-99999, -99999), source := "", removable := true) -> void:
	var from := caster.cell if origin == Vector2i(-99999, -99999) else origin
	var amount := rng.randi_range(effect["min"], effect["max"])
	if effect["type"] not in [Spell.EFFECT_DAMAGE, Spell.EFFECT_HEAL, Spell.EFFECT_SHIELD, Spell.EFFECT_POISON]:
		_credit_effect(caster, "")  # Effet utilitaire qui touche quelqu'un.
	if critical and effect["type"] in Spell.ELEMENT_EFFECTS:
		amount = roundi(amount * Spell.CRIT_MULTIPLIER)
	match effect["type"]:
		Spell.EFFECT_GAIN_PA:
			target.pa += amount
			events.append({"type": Protocol.EVT_STATUS, "entite": target.id, "effet": Spell.EFFECT_GAIN_PA, "valeur": amount, "pa": target.pa, "pm": target.pm})
		Spell.EFFECT_REMOVE_PM:
			target.pm_malus += amount
			events.append({"type": Protocol.EVT_STATUS, "entite": target.id, "effet": Spell.EFFECT_REMOVE_PM, "valeur": amount, "pa": target.pa, "pm": target.pm})
		Spell.EFFECT_DAMAGE:
			_hurt(target, damage_value(caster, target, effect["element"], amount), effect["element"], events)
		Spell.EFFECT_SHIELD:
			amount = roundi(amount * (100 + caster.power(effect["element"])) / 100.0)
			target.shield += amount
			if not _credit.is_empty() and _credit["lanceur"] == caster and target.team == caster.team:
				target.shield_credit = {"lanceur": caster.id, "pa": float(_credit["pa"]), "element": effect["element"]}
			events.append({"type": Protocol.EVT_STATUS, "entite": target.id, "effet": Spell.EFFECT_SHIELD, "valeur": amount,
				"element": effect["element"], "bouclier": target.shield, "pa": target.pa, "pm": target.pm})
		Spell.EFFECT_HEAL:
			amount = mini(boosted_value(caster, effect["element"], amount), target.max_hp - target.hp)
			target.hp += amount
			if amount > 0 and target.team == caster.team:
				_credit_effect(caster, effect["element"])
			events.append({"type": Protocol.EVT_HEAL, "entite": target.id, "valeur": amount, "element": effect["element"],
				"pv": target.hp})
		Spell.EFFECT_BONUS, Spell.EFFECT_MALUS:
			_add_state(target, {"type": effect["type"], "carac": effect["carac"], "element": str(effect.get("element", "")),
				"valeur": amount, "tours": effect["duree"], "sort": source, "lanceur": caster.id, "retirable": removable}, events)
		Spell.EFFECT_POISON:
			var poison := {"type": Spell.EFFECT_POISON, "element": effect["element"], "valeur": amount,
				"tours": effect["duree"], "sort": source, "lanceur": caster.id, "retirable": removable}
			if not _credit.is_empty() and _credit["lanceur"] == caster and target.team != caster.team:
				poison["pa"] = float(_credit["pa"]) / maxi(1, int(effect["duree"]))  # Pratique : à chaque tour qui blesse.
				_credit["utile"] = true
			_add_state(target, poison, events)
		Spell.EFFECT_ELEMENT_STATE:
			target.add_element_state(effect["element"])
			events.append({"type": Protocol.EVT_ELEMENT_STATES, "entite": target.id, "etats": target.element_states.duplicate(),
				"element": effect["element"]})
		Spell.EFFECT_REMOVE_STATES:
			var kept: Array[Dictionary] = []
			for state in target.states:
				if state["type"] not in effect["etats"] or not state.get("retirable", true):
					kept.append(state)
			var removed := target.states.size() - kept.size()
			if removed > 0:
				target.states = kept
				var event := _states_event(target)
				event["retires"] = removed
				events.append(event)
		Spell.EFFECT_PUSH:
			_push(from, target, amount, false, events)
		Spell.EFFECT_PULL:
			_push(from, target, amount, true, events)


## Dégâts d'un effet de valeur tirée `amount` (voir `_apply_effect`).
static func damage_value(caster: Fighter, target: Fighter, element: String, amount: int) -> int:
	var boosted := amount * (100 + caster.power(element)) / 100.0
	return maxi(0, roundi(boosted * (100 - target.resistance(element)) / 100.0)) + caster.total_dommages()


## Valeur d'un soin, d'un bouclier ou d'un poison, augmentée par la caractéristique de son élément.
static func boosted_value(caster: Fighter, element: String, amount: int) -> int:
	return roundi(amount * (100 + caster.power(element)) / 100.0)


## Prévisualisation d'un sort de `fighter` sur `target` (sans coup critique ni hasard) : pour chaque
## combattant touché, id → { degats: [min, max], soin: [min, max], element } (seulement les
## entrées non nulles ; `element` : celui du premier effet chiffré). Les soins sont limités aux PV
## qui manquent (rien à PV pleins) ; une charge qui n'arriverait pas au contact ne touche personne. Vide si la cible
## n'est pas valide.
func spell_preview(fighter: Fighter, spell: Spell, target: Vector2i) -> Dictionary:
	var preview := {}
	if not targeting_blocker(fighter, spell, target).is_empty():
		return preview
	if spell.charges():
		var path := charge_path(fighter, target)
		var stop := path[-1] if not path.is_empty() else fighter.cell
		if fighter_at(target) == null or IsoGrid.distance(stop, target) != 1:
			return preview
	for cell in spell.zone_cells(target, fighter.cell):
		var hit := fighter_at(cell)
		if hit == null or not hit.is_alive() or (spell.excludes_caster and hit == fighter):
			continue
		var entry := {}
		for effect in spell.effects:
			if effect["type"] not in [Spell.EFFECT_DAMAGE, Spell.EFFECT_HEAL] or not Spell.affects(effect, fighter, hit):
				continue
			var low: int
			var high: int
			var key := "degats"
			if effect["type"] == Spell.EFFECT_DAMAGE:
				low = damage_value(fighter, hit, effect["element"], effect["min"])
				high = damage_value(fighter, hit, effect["element"], effect["max"])
			elif hit.hp >= hit.max_hp:
				continue  # PV pleins : pas de « +0 ».
			else:
				key = "soin"
				var missing := hit.max_hp - hit.hp
				low = mini(boosted_value(fighter, effect["element"], effect["min"]), missing)
				high = mini(boosted_value(fighter, effect["element"], effect["max"]), missing)
			var total: Array = entry.get(key, [0, 0])
			entry[key] = [int(total[0]) + low, int(total[1]) + high]
			if not entry.has("element"):
				entry["element"] = effect["element"]
		if entry.has("degats") or entry.has("soin"):
			preview[hit.id] = entry
	return preview


## Retire des PV (le bouclier absorbe d'abord) ; `element` vide pour des dégâts sans élément (choc).
## Pratique : des PV perdus par un ennemi comptent pour le sort en cours, des dégâts absorbés pour
## celui qui a posé le bouclier, et un joueur note les PV qu'il perd (Vitalité).
func _hurt(target: Fighter, amount: int, element: String, events: Array[Dictionary], source := "") -> void:
	var absorbed := mini(target.shield, amount)
	target.shield -= absorbed
	amount -= absorbed
	var lost := mini(amount, target.hp)
	target.hp = maxi(0, target.hp - amount)
	if lost > 0 and not _credit.is_empty() and (_credit["lanceur"] as Fighter).team != target.team:
		_credit_effect(_credit["lanceur"], element)
	if absorbed > 0 and not target.shield_credit.is_empty():
		var shield_credit := target.shield_credit
		target.shield_credit = {}
		_add_practice(shield_credit["lanceur"], "effet", float(shield_credit["pa"]), shield_credit["element"])
	if lost > 0 and target.team == Fighter.TEAM_PLAYERS:
		_add_practice(target.id, "pv_recus", float(lost))
	var event := {"type": Protocol.EVT_DAMAGE, "entite": target.id, "valeur": amount, "element": element, "pv": target.hp,
		"absorbe": absorbed, "bouclier": target.shield}
	if not source.is_empty():
		event["source"] = source
	events.append(event)
	if not target.is_alive():
		events.append({"type": Protocol.EVT_DIED, "entite": target.id})
		_remove_ground_of(target, events)
	else:
		_check_phases(target, events)


## Phases d'un monstre (voir `Fighter.phases`) : chaque seuil de PV atteint ou franchi (en % des PV
## max) déclenche sa phase, une seule fois, dans l'ordre. Le monstre apprend ses sorts, puis
## s'applique ses effets (il en est le lanceur). Appelé après chaque perte de PV (sort, poison,
## piège, choc). Les seuils sont comparés aux PV laissés par les dégâts : le soin d'une phase
## n'empêche pas les suivantes franchies du même coup.
func _check_phases(fighter: Fighter, events: Array[Dictionary]) -> void:
	var reached := fighter.hp
	while not fighter.phases.is_empty() and fighter.is_alive() \
			and reached * 100 <= int(fighter.phases[0]["pv"]) * fighter.max_hp:
		var phase: Dictionary = fighter.phases.pop_front()
		for spell: Spell in phase["sorts"]:
			if fighter.get_spell(spell.id) == null:
				fighter.spells.append(spell)
		events.append({"type": Protocol.EVT_PHASE, "entite": fighter.id, "message": phase["message"]})
		for effect: Dictionary in phase["effets"]:
			if fighter.is_alive():
				# Les effets d'une phase ne peuvent pas être retirés (ils font partie du combat du boss).
				_apply_effect(fighter, fighter, effect, events, false, fighter.cell, fighter.display_name, false)


## Pose un état (bonus, malus, poison). Un bonus ou malus de PA ou de PM compte tout de suite.
func _add_state(target: Fighter, new_state: Dictionary, events: Array[Dictionary]) -> void:
	target.states.append(new_state)
	var signed := int(new_state["valeur"]) * (1 if new_state["type"] == Spell.EFFECT_BONUS else -1)
	if new_state.get("carac") == "pa":
		target.pa = maxi(0, target.pa + signed)
	if new_state.get("carac") == "pm":
		target.pm = maxi(0, target.pm + signed)
	var event := _states_event(target)
	event["nouveau"] = {"type": new_state["type"], "carac": new_state.get("carac", ""), "element": new_state.get("element", ""),
		"valeur": new_state["valeur"], "tours": new_state["tours"], "sort": new_state["sort"]}
	events.append(event)


func _states_event(fighter: Fighter) -> Dictionary:
	return {"type": Protocol.EVT_STATES, "entite": fighter.id, "etats": fighter.states_snapshot(), "pa": fighter.pa, "pm": fighter.pm}


## Pousse (ou attire) `target` de `distance` cases depuis `from`, en ligne droite. Un obstacle, le
## bord ou un combattant l'arrête ; une poussée arrêtée fait des dégâts de choc par case manquée. Un
## piège ennemi arrête aussi le mouvement et se déclenche.
func _push(from: Vector2i, target: Fighter, distance: int, pull: bool, events: Array[Dictionary]) -> void:
	if target.cell == from or distance <= 0:
		return
	var step := Spell.direction(from, target.cell) * (-1 if pull else 1)
	var start := target.cell
	var moved := 0
	var trap := {}
	while moved < distance:
		var next := target.cell + step
		if not is_free(next):
			break
		target.cell = next
		moved += 1
		trap = enemy_trap_at(next, target)
		if not trap.is_empty():
			break
	if moved > 0:
		events.append({"type": Protocol.EVT_PUSHED, "entite": target.id, "depuis": start, "case": target.cell})
	if not trap.is_empty():
		_trigger_trap(trap, target, events)
	elif not pull and moved < distance:
		_hurt(target, (distance - moved) * PUSH_DAMAGE_PER_CELL, "", events, "choc")


# --- Glyphes et pièges ---------------------------------------------------------------------------

func _place_glyph(caster: Fighter, spell: Spell, effect: Dictionary, cells: Array[Vector2i], events: Array[Dictionary]) -> void:
	var inside: Array[Vector2i] = []
	for cell in cells:
		if map.is_inside(cell) and map.is_walkable_in_combat(cell):
			inside.append(cell)
	var glyph := {"id": _next_ground_id, "lanceur": caster, "equipe": caster.team, "cases": inside, "effets": effect["effets"],
		"tours": int(effect["duree"]), "sort": spell.display_name, "pa": float(spell.pa_cost) / maxi(1, int(effect["duree"]))}
	_next_ground_id += 1
	glyphs.append(glyph)
	var element := ""
	for glyph_effect: Dictionary in effect["effets"]:
		if element.is_empty() and glyph_effect["type"] in Spell.ELEMENT_EFFECTS:
			element = glyph_effect["element"]
	events.append({"type": Protocol.EVT_GLYPH, "id": glyph["id"], "lanceur": caster.id, "equipe": caster.team,
		"cases": inside, "tours": glyph["tours"], "sort": glyph["sort"], "element": element})


func _place_trap(caster: Fighter, spell: Spell, effect: Dictionary, cell: Vector2i, events: Array[Dictionary]) -> void:
	var zone: Dictionary = effect["zone"]
	var cells: Array[Vector2i] = []
	for zone_cell in Spell.circle_cells(cell, int(zone.get("taille", 0)) if zone["type"] == Spell.ZONE_CIRCLE else 0):
		if map.is_inside(zone_cell):
			cells.append(zone_cell)
	var trap := {"id": _next_ground_id, "lanceur": caster, "equipe": caster.team, "case": cell, "cases": cells,
		"effets": effect["effets"], "sort": spell.display_name, "pa": spell.pa_cost}
	_next_ground_id += 1
	traps.append(trap)
	events.append({"type": Protocol.EVT_TRAP, "id": trap["id"], "lanceur": caster.id, "equipe": caster.team,
		"case": cell, "cases": cells, "sort": trap["sort"]})


## Déclenche un piège : il disparaît, ses effets touchent sa zone (selon leurs `cibles`).
func _trigger_trap(trap: Dictionary, victim: Fighter, events: Array[Dictionary]) -> void:
	traps.erase(trap)
	events.append({"type": Protocol.EVT_TRAP_TRIGGERED, "id": trap["id"], "entite": victim.id, "case": trap["case"],
		"cases": trap["cases"], "sort": trap["sort"]})
	var caster: Fighter = trap["lanceur"]
	var hits: Array[Fighter] = []
	for cell: Vector2i in trap["cases"]:
		var hit := fighter_at(cell)
		if hit != null:
			hits.append(hit)
	var outer := _credit
	_open_credit(caster, float(trap.get("pa", 0)))
	for hit in hits:
		for effect: Dictionary in trap["effets"]:
			if hit.is_alive() and Spell.affects(effect, caster, hit):
				_apply_effect(caster, hit, effect, events, false, trap["case"], trap["sort"])
	_close_credit()
	_credit = outer


## Un combattant vaincu emporte ses glyphes et ses pièges.
func _remove_ground_of(fighter: Fighter, events: Array[Dictionary]) -> void:
	for glyph in glyphs.duplicate():
		if glyph["lanceur"] == fighter:
			glyphs.erase(glyph)
			events.append({"type": Protocol.EVT_GLYPH_ENDED, "id": glyph["id"]})
	for trap in traps.duplicate():
		if trap["lanceur"] == fighter:
			traps.erase(trap)
			events.append({"type": Protocol.EVT_TRAP_ENDED, "id": trap["id"]})


## Début du tour de `fighter` : ses glyphes perdent un tour, puis ses poisons et les glyphes sous
## ses pieds agissent.
func _start_of_turn_effects(fighter: Fighter, events: Array[Dictionary]) -> void:
	for glyph in glyphs.duplicate():
		if glyph["lanceur"] == fighter:
			glyph["tours"] = int(glyph["tours"]) - 1
			if int(glyph["tours"]) <= 0:
				glyphs.erase(glyph)
				events.append({"type": Protocol.EVT_GLYPH_ENDED, "id": glyph["id"]})
	for poison in fighter.states.duplicate():
		if poison["type"] != Spell.EFFECT_POISON or not fighter.is_alive():
			continue
		var caster := get_fighter(poison["lanceur"])
		var element: String = poison["element"]
		var boosted := int(poison["valeur"]) * (100 + (caster.power(element) if caster != null else 0)) / 100.0
		_open_credit(caster, float(poison.get("pa", 0.0)))
		_hurt(fighter, maxi(0, roundi(boosted * (100 - fighter.resistance(element)) / 100.0)), element, events, "poison")
		_close_credit()
	for glyph in glyphs_at(fighter.cell):
		_open_credit(glyph["lanceur"], float(glyph.get("pa", 0.0)))
		for effect: Dictionary in glyph["effets"]:
			if fighter.is_alive() and Spell.affects(effect, glyph["lanceur"], fighter):
				_apply_effect(glyph["lanceur"], fighter, effect, events, false, fighter.cell, glyph["sort"])
		_close_credit()


# --- Enchaînement des tours ------------------------------------------------------------------

## Passe la main au combattant suivant ; joue les tours des monstres jusqu'au prochain joueur.
func _next_turn(events: Array[Dictionary]) -> void:
	while state == State.FIGHTING:
		if _turn_index >= 0 and fighters[_turn_index].end_turn():
			events.append(_states_event(fighters[_turn_index]))
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
		if turn_limit > 0.0 and not fighter.is_ai():
			events[-1]["duree"] = turn_limit
		_start_of_turn_effects(fighter, events)
		if not fighter.is_alive():
			_check_end(events)
			continue
		if not fighter.is_ai() and not absent.has(fighter.id):
			_elapsed = 0.0
			return
		if fighter.is_ai():
			_play_ai_turn(fighter, events)
		if state == State.FIGHTING:
			events.append({"type": Protocol.EVT_TURN_ENDED, "entite": fighter.id} if fighter.is_ai()
				else {"type": Protocol.EVT_TURN_ENDED, "entite": fighter.id, "absent": true})


func _play_ai_turn(fighter: Fighter, events: Array[Dictionary]) -> void:
	var has_moved := false
	for i in MAX_AI_ACTIONS:
		var action := CombatAI.next_action(self, fighter, has_moved)
		if action.is_empty():
			return
		has_moved = has_moved or action["type"] == Protocol.CMD_MOVE
		var result := _apply_action(fighter, action)
		events.append_array(result)
		if result.is_empty() or result[0]["type"] == Protocol.EVT_REFUSED or state != State.FIGHTING or not fighter.is_alive():
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
	# Tableau de l'écran de fin : chaque combattant, son camp et s'il est encore debout.
	var roster: Array[Dictionary] = []
	for fighter in fighters:
		roster.append({"id": fighter.id, "nom": fighter.display_name, "type": fighter.kind, "niveau": fighter.level,
			"equipe": fighter.team, "vivant": fighter.is_alive()})
	events.append({"type": Protocol.EVT_COMBAT_ENDED, "vainqueur": team, "xp": xp, "tours": maxi(round_number, 1),
		"combattants": roster})


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


# --- Copie du client -----------------------------------------------------------------------------

## Instantané du combat tel que le voit un joueur de l'équipe `team` (pour la copie de l'état de son
## client, `ClientState`) : combattants, tour, glyphes, et seulement les pièges de son équipe. Pas de
## graine aléatoire (GDD § 16.5 : rien de sensible n'est envoyé au client).
func snapshot(team := Fighter.TEAM_PLAYERS) -> Dictionary:
	var fighter_states: Array = []
	for fighter in fighters:
		fighter_states.append(fighter.snapshot())
		if not fighter.is_ai():
			fighter_states[-1]["profil"] = fighter.profile()
	var arrival: Array = []
	for fighter: Fighter in _arrival:
		arrival.append([fighter.id, _arrival[fighter]])
	var ground: Array = []
	for glyph in glyphs:
		ground.append(_ground_snapshot(glyph))
	var own_traps: Array = []
	for trap in traps:
		if trap["equipe"] == team:
			own_traps.append(_ground_snapshot(trap))
	return {
		"carte": map.id,
		"etat": state,
		"tour": _turn_index,
		"manche": round_number,
		"vainqueur": winner_team,
		"placement": placement_cells.duplicate(),
		"combattants": fighter_states,
		"arrivee": arrival,
		"glyphes": ground,
		"pieges": own_traps,
		"prochain_sol": _next_ground_id,
		"prets": ready.keys(),
		"absents": absent.keys(),
		"temps_restant": time_left(),
		"limite_tour": turn_limit,
		"limite_placement": placement_limit,
		"ferme": locked,
		"spectateurs_permis": spectators_allowed,
	}


static func _ground_snapshot(ground: Dictionary) -> Dictionary:
	var copy := ground.duplicate(true)
	copy["lanceur"] = (ground["lanceur"] as Fighter).id
	return copy


## Combat recréé d'après un instantané (voir `snapshot`), pour les lectures du client (portées,
## déplacements possibles, aperçu des sorts…) : les combattants viennent des données (`p_data`), un
## joueur d'après son personnage (`characters` : id → Character). `null` si un combattant manque.
static func from_snapshot(saved: Dictionary, p_map: GameMap, p_data: GameData, characters: Dictionary) -> Combat:
	var restored: Array[Fighter] = []
	for fighter_state: Dictionary in saved["combattants"]:
		var fighter_id: String = fighter_state["id"]
		var fighter: Fighter = null
		if characters.has(fighter_id):
			fighter = p_data.create_character_fighter(characters[fighter_id], fighter_id)
		elif fighter_state.has("profil"):
			fighter = p_data.create_profile_fighter(fighter_state["profil"], fighter_id)  # Un allié.
		else:
			fighter = p_data.create_monster(fighter_state["type"], fighter_id, int(fighter_state["niveau"]))
		if fighter == null:
			return null
		fighter.restore(fighter_state)
		restored.append(fighter)
	var placement: Array[Vector2i] = []
	placement.assign(saved["placement"])
	var combat := Combat.new(p_map, restored, placement)
	combat.state = int(saved["etat"]) as State
	combat._turn_index = int(saved["tour"])
	combat.round_number = int(saved["manche"])
	combat.winner_team = int(saved["vainqueur"])
	combat._next_ground_id = int(saved["prochain_sol"])
	for fighter_id: String in saved.get("prets", []):
		combat.ready[fighter_id] = true
	for fighter_id: String in saved.get("absents", []):
		combat.absent[fighter_id] = true
	combat.turn_limit = float(saved.get("limite_tour", 0.0))
	combat.placement_limit = float(saved.get("limite_placement", 0.0))
	combat.locked = bool(saved.get("ferme", false))
	combat.spectators_allowed = bool(saved.get("spectateurs_permis", true))
	combat._elapsed = maxf(0.0, (combat.placement_limit if combat.state == State.PLACEMENT else combat.turn_limit) - float(saved.get("temps_restant", 0.0)))
	for pair: Array in saved["arrivee"]:
		var fighter := combat.get_fighter(pair[0])
		if fighter != null:
			combat._arrival[fighter] = int(pair[1])
	for kind: String in ["glyphes", "pieges"]:
		for ground: Dictionary in saved[kind]:
			var copy := ground.duplicate(true)
			copy["lanceur"] = combat.get_fighter(ground["lanceur"])
			if copy["lanceur"] == null:
				continue
			if kind == "glyphes":
				combat.glyphs.append(copy)
			else:
				combat.traps.append(copy)
	return combat
