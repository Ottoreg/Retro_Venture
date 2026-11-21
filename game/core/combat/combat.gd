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
## Tacle et fuite (GDD § 7.2) : quitter une case au contact d'ennemis coûte des PM (réglage pour tester son intérêt).
const TACKLE := true
## Esquive des retraits de PA / PM au plus, en %.
const MAX_DODGE := 90
## Épines : renvoi au plus, en part des dégâts subis ; part spectrale et dévastatrice au plus des dégâts infligés.
const MAX_THORNS := 0.6
const MAX_SPECTRAL := 0.5
## Cadran d'une horloge (Chronomancien, GDD § 4.3) : les 12 cases à 2 pas de la cible, sans les coins
## du carré 5 × 5, par rapport au centre, rangées dans le sens des aiguilles d'une montre tel qu'on
## le voit à l'écran (isométrique). Le cadran s'oriente selon le lanceur : 12 h est la case à 2 pas du
## centre dans la direction où il regarde en lançant (vers la cible), et les heures suivent ce sens.
const CLOCK_RING: Array[Vector2i] = [Vector2i(0, -2), Vector2i(1, -2), Vector2i(2, -1), Vector2i(2, 0),
	Vector2i(2, 1), Vector2i(1, 2), Vector2i(0, 2), Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(-2, 0), Vector2i(-2, -1),
	Vector2i(-1, -2)]

var map: GameMap
var state: State = State.PLACEMENT
## Combattants, dans l'ordre de jeu une fois le combat commencé.
var fighters: Array[Fighter] = []
## Cases où l'équipe des joueurs peut se placer.
var placement_cells: Array[Vector2i] = []
var round_number := 0
## Équipe gagnante (-1 tant que le combat n'est pas fini, ou en cas d'abandon des deux camps).
var winner_team := -1
## PV max de chaque combattant à son premier coup reçu (plancher des dégâts dévastateurs).
var _max_hp_at_start: Dictionary = {}
var rng := RandomNumberGenerator.new()
## Glyphes au sol : { id, lanceur: Fighter, equipe, cases: Array[Vector2i], effets, tours, sort }.
var glyphs: Array[Dictionary] = []
## Pièges posés : { id, lanceur: Fighter, equipe, case, cases (zone d'explosion), effets, sort }.
var traps: Array[Dictionary] = []
## Ombre (GDD § 4.3) : images rémanentes { id, lanceur: Fighter, equipe, case, ombres, manche, effets, sort }, et
## dimension où se jouent les règles en ce moment (vrai : le Monde des ombres) : celle du combattant qui agit, ou de qui
## regarde le combat chez un client. Seuls les combattants, glyphes, pièges et images de cette dimension comptent.
var images: Array[Dictionary] = []
var dimension := false
## Échanges de place à la sortie des ombres (case ou id → manche) : un seul par case et par combattant et par manche.
var _swaps := {}
## Images d'un lanceur au plus ; tours dans les ombres ; tours sans retour après en être sorti (une Ombre : 1).
const MAX_IMAGES := 3
const SHADOW_TURNS := 2
const NO_RETURN_TURNS := 2
## Classe qui garde les autres dans les ombres : sans elle dans la dimension, on en sort au bout d'un tour.
const SHADOW_CLASS := "ombre"
## Démoniste (GDD § 4.3) : embrasement des cases, une table par dimension ([normal, ombres]) : case → { niveau : 1 à 3, puis
## `CALCINED` (calcinée), equipe et lanceur : du dernier qui l'a embrasée }. Variantes : +`EMBER_BONUS` % aux valeurs d'un sort
## de la Voie Flamme par niveau de la case visée ; un ennemi qui commence son tour sur une case embrasée (pas calcinée) perd
## `EMBER_BURN` × niveau PV (Flamme). Serviteurs : `MAX_SERVANTS` en même temps (un de plus au rang 5 du passif).
var embers: Array[Dictionary] = [{}, {}]
const CALCINED := 4
const EMBER_BONUS := 10
const EMBER_BURN := 2
const MAX_SERVANTS := 2
## Paladin (GDD § 4.3) : auras qui suivent leur lanceur (une par Paladin ; { id, lanceur, equipe, taille, tours, effets,
## sort }), balises ({ id, lanceur, equipe, ombres, case, porteur : id d'un combattant qui sert de balise, tours, effets,
## sort }) reliées par des arcs ; coups d'arc déjà reçus ce tour (« arc:combattant »).
var auras: Array[Dictionary] = []
var beacons: Array[Dictionary] = []
var _arc_hits := {}
const PALADIN_PASSIVE := "saint_paratonnerre"
const MAX_BEACONS := 3
const ARC_LENGTH := 6
const ARC_BONUS := 25
const MAX_ARCS_CROSSED := 2

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
		if not fighter.is_ai() and fighter.master.is_empty():
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
	elif away and current_fighter() != null and current_fighter().controller() == fighter_id:
		events.append({"type": Protocol.EVT_TURN_ENDED, "entite": current_fighter().id, "absent": true})
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
		if fighter.is_alive() and fighter.cell == cell and fighter.shadow == dimension:
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
	return trap if not trap.is_empty() and trap["equipe"] != fighter.team and trap.get("ombres", false) == fighter.shadow else {}


## Glyphes qui couvrent la case.
func glyphs_at(cell: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for glyph in glyphs:
		if cell in glyph["cases"] and glyph.get("ombres", false) == dimension:
			result.append(glyph)
	return result


func enemies_of(fighter: Fighter) -> Array[Fighter]:
	var result: Array[Fighter] = []
	for other in fighters:
		if other.is_alive() and other.team != fighter.team and other.shadow == fighter.shadow and not other.is_invisible():
			result.append(other)
	return result


## Où chercher les ennemis que `fighter` ne voit pas (IA) : leur dernière case vue (invisibles, ou dans l'autre
## dimension), et, depuis les ombres, les lueurs de tous ceux qui sont dehors.
func hunt_cells(fighter: Fighter) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for other in fighters:
		if other.is_alive() and other.team != fighter.team and other.last_seen != Fighter.NO_CELL \
				and (other.shadow != fighter.shadow or other.is_invisible()):
			cells.append(other.last_seen)
		if other.is_alive() and fighter.shadow and not other.shadow:
			cells.append(other.cell)
	return cells


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
## Un monstre évite les arcs ennemis quand un autre chemin existe.
func reachable_cells(fighter: Fighter, pm := -1) -> Dictionary:
	var avoided := arc_cells(fighter) if fighter.is_ai() else {}
	var paths := _paths(fighter, pm, avoided)
	return paths if avoided.is_empty() else _paths(fighter, pm, {}).merged(paths, true)


func _paths(fighter: Fighter, pm: int, avoided: Dictionary) -> Dictionary:
	var paths := {fighter.cell: [] as Array[Vector2i]}
	var frontier: Array[Vector2i] = [fighter.cell]
	for step in (fighter.pm if pm < 0 else pm):
		var next_frontier: Array[Vector2i] = []
		for cell in frontier:
			for neighbor in IsoGrid.neighbors_4(cell):
				if paths.has(neighbor) or not is_free(neighbor) or avoided.has(neighbor):
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
	var pm := roundi((fighter.pm if fighter == current_fighter() else fighter.next_turn_pm()) * tackle_ratio(fighter, fighter.cell))
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
	var aimed := fighter_at(target)
	var reach := maxi(max_range(fighter, spell), maxi(spell.marked_range if aimed != null and marked_by(aimed, fighter) else 0,
		spell.ember_range if ember_level(target) > 0 else 0))
	if distance < spell.range_min or distance > reach:
		return Protocol.REASON_OUT_OF_RANGE
	if spell.needs_line_of_sight and not LineOfSight.is_clear(from, target, _blocks_sight.bind(fighter, spell.zone_type != Spell.ZONE_LINE)):
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


## Portée maximale réelle : les sorts à distance (portée de 2 ou plus) profitent des bonus de portée,
## sauf à portée fixe.
func max_range(fighter: Fighter, spell: Spell) -> int:
	return spell.range_max + (fighter.total_range_bonus() if spell.range_max >= 2 and not spell.fixed_range else 0)


## Cases à portée du sort, avec et sans ligne de vue (pour l'affichage).
func spell_range(fighter: Fighter, spell: Spell) -> Dictionary:
	var result := {"visibles": [] as Array[Vector2i], "masquees": [] as Array[Vector2i]}
	var reach := maxi(max_range(fighter, spell), maxi(spell.marked_range, spell.ember_range))
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
	# Comme Dofus, les camps alternent (celui du plus rapide commence), le surplus d'un camp à la fin.
	_arrival.clear()
	for i in fighters.size():
		_arrival[fighters[i]] = i
	fighters.sort_custom(_plays_before)
	var camps := [fighters.filter(func(f: Fighter) -> bool: return f.team == fighters[0].team),
		fighters.filter(func(f: Fighter) -> bool: return f.team != fighters[0].team)]
	fighters.clear()
	for i in maxi(camps[0].size(), camps[1].size()):
		for camp: Array in camps:
			if i < camp.size():
				fighters.append(camp[i])
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
	dimension = fighter.shadow
	var events: Array[Dictionary] = [{"type": Protocol.EVT_TURN_ENDED, "entite": fighter.id}]
	if type in [Protocol.CMD_MOVE, Protocol.CMD_CAST]:
		events = _move(fighter, command) if type == Protocol.CMD_MOVE else _cast(fighter, command)
	_refresh_auras(events)
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
		if not trap.is_empty() or not _images_near(path[i], fighter).is_empty():  # Un piège ou une image arrête la marche.
			path = path.slice(0, i + 1)
			break
	# Tacle : chaque case quittée au contact d'ennemis garde seulement une part des PM (`tackle_ratio`).
	var walked: Array[Vector2i] = []
	var lost := 0
	for next in path:
		var kept := roundi(fighter.pm * tackle_ratio(fighter, walked[-1] if not walked.is_empty() else fighter.cell))
		lost += fighter.pm - kept
		fighter.pm = kept
		if fighter.pm <= 0:
			break
		walked.append(next)
		fighter.pm -= 1
	if walked.size() < path.size():
		trap = {}
	var events: Array[Dictionary] = []
	if lost > 0:
		events.append({"type": Protocol.EVT_STATUS, "entite": fighter.id, "effet": "tacle", "valeur": lost, "pa": fighter.pa, "pm": fighter.pm})
	if walked.is_empty():
		return events
	var from := fighter.cell
	fighter.cell = walked[-1]
	events.append({"type": Protocol.EVT_MOVED, "entite": fighter.id, "depuis": from, "chemin": walked, "pm": fighter.pm})
	_seen(fighter)
	_enter_cells(fighter, walked, events)
	if not trap.is_empty() and fighter.is_alive():
		_trigger_trap(trap, fighter, events)
	_check_images(fighter, events)
	_check_end(events)
	return events


## Part des PM gardés en quittant `cell` : (fuite + 2) / (2 × (tacle des ennemis au contact + 2)), au plus 1 ; 1 sans
## ennemi au contact (les inblocables ne taclent pas et ne sont pas taclés).
func tackle_ratio(fighter: Fighter, cell: Vector2i) -> float:
	if not TACKLE or fighter.has_state(Spell.STATE_UNBLOCKABLE) or fighter.is_invisible():
		return 1.0
	var tacklers := IsoGrid.neighbors_4(cell).map(fighter_at).filter(func(other: Fighter) -> bool:
		return other != null and other.team != fighter.team and not other.has_state(Spell.STATE_UNBLOCKABLE) and not other.is_invisible())
	if tacklers.is_empty():
		return 1.0
	return minf(1.0, (fighter.escape() + 2) / (2.0 * (tacklers.reduce(func(sum: int, other: Fighter) -> int: return sum + other.tackle(), 0) + 2)))


## Points d'un retrait de PA ou de PM (`carac`) qui touchent `target` : un adversaire esquive chaque point à
## (son retrait − celui du lanceur) % de chances, de 0 à `MAX_DODGE` (GDD § 10.4).
func _landed_removal(caster: Fighter, target: Fighter, carac: String, amount: int, events: Array[Dictionary]) -> int:
	var chance := 0 if caster.team == target.team else clampi(target.combat_stat("retrait_" + carac) - caster.combat_stat("retrait_" + carac), 0, MAX_DODGE)
	var landed := amount
	for i in (amount if chance > 0 else 0):
		landed -= int(rng.randi_range(1, 100) <= chance)
	if landed < amount:
		events.append({"type": Protocol.EVT_STATUS, "entite": target.id, "effet": "esquive", "carac": carac, "valeur": amount - landed,
			"pa": target.pa, "pm": target.pm})
	return landed


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
	if blocker.is_empty() and spell.places_clock() and fighter_at(target) != null \
			and fighter_at(target).has_state(Spell.STATE_TIME_MANIPULATION):
		blocker = Protocol.REASON_ALREADY_MANIPULATED
	var aimed := fighter_at(target)
	var behind: Vector2i = target + Spell.direction(fighter.cell, target)
	if blocker.is_empty() and not spell.effect_of(Spell.EFFECT_BEHIND).is_empty():
		blocker = Protocol.REASON_NO_TARGET if aimed == null else "" if is_free(behind) else Protocol.REASON_BLOCKED
	if blocker.is_empty() and not spell.effect_of(Spell.EFFECT_SHADOW_WORLD).is_empty():
		blocker = Protocol.REASON_NO_TARGET if aimed == null else Protocol.REASON_NO_RETURN if not aimed.shadow \
			and aimed.has_state(Spell.STATE_NO_RETURN) else Protocol.REASON_DRAWN if aimed.shadow and aimed.has_state(Spell.STATE_DRAWN) else ""
	if blocker.is_empty() and not spell.effect_of(Spell.EFFECT_DETONATE).is_empty() \
			and not images.any(func(image: Dictionary) -> bool: return image["lanceur"] == fighter and image["case"] == target):
		blocker = Protocol.REASON_NO_IMAGE
	if blocker.is_empty() and not spell.effect_of(Spell.EFFECT_SUMMON).is_empty():
		blocker = Protocol.REASON_TOO_MANY_SERVANTS if servants_of(fighter).size() >= max_servants(fighter) else "" if is_free(target) \
			else Protocol.REASON_OCCUPIED if aimed != null else Protocol.REASON_BLOCKED
	if blocker.is_empty() and spell.effects.any(func(effect: Dictionary) -> bool: return effect["type"] in [Spell.EFFECT_SWAP, Spell.EFFECT_SACRIFICE]) \
			and (aimed == null or aimed.master != fighter.id):
		blocker = Protocol.REASON_NOT_SERVANT
	if blocker.is_empty() and not spell.effect_of(Spell.EFFECT_ASHES).is_empty() and _heat_of(spell.zone_cells(target, fighter.cell)) == 0:
		blocker = Protocol.REASON_NO_EMBERS
	if blocker.is_empty() and not spell.create_effect().is_empty() and created_spell_for(fighter, spell) == null:
		blocker = Protocol.REASON_NO_COMBINATION
	if blocker.is_empty() and not spell.effect_of(Spell.EFFECT_BEACON).is_empty() and (not is_free(target) or not beacon_at(target).is_empty()):
		blocker = Protocol.REASON_OCCUPIED if map.is_walkable_in_combat(target) else Protocol.REASON_BLOCKED
	if blocker.is_empty() and spell.effects.any(func(effect: Dictionary) -> bool: return effect["type"] in [Spell.EFFECT_SURGE, Spell.EFFECT_BEACON_SWAP]):
		var aimed_beacon := beacon_at(target)
		blocker = Protocol.REASON_NO_BEACON if aimed_beacon.is_empty() or aimed_beacon["lanceur"] != fighter \
			or (not spell.effect_of(Spell.EFFECT_BEACON_SWAP).is_empty() and (aimed_beacon["porteur"] != "" or aimed != null)) else ""
	var choices := spell.state_choices()
	if blocker.is_empty() and not choices.is_empty() and str(command.get("etats", "")) not in choices:
		blocker = Protocol.REASON_INVALID_COMPOSITION
	if not blocker.is_empty():
		return _refused(command, blocker)

	fighter.register_cast(spell)
	if spell.enemy_cooldown > 0 and aimed != null and aimed.team != fighter.team:
		fighter._cooldowns[spell.id] = spell.enemy_cooldown
	var crit_chance := spell.crit_chance + fighter.total_crit_bonus()
	var critical := crit_chance > 0 and rng.randf() * 100.0 < crit_chance
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_SPELL_CAST,
		"entite": fighter.id,
		"sort": spell.id,
		"cible": target,
		"pa": fighter.pa,
		"critique": critical,
		"ombres": fighter.shadow,
	}]
	_seen(fighter)  # Dans les ombres, son ombre est projetée dehors, sur sa case.
	var zone := spell_zone(fighter, spell, target)
	var cast_effects := _ember_variant(spell, target, zone)
	var crossed := arcs_crossed(fighter, spell, target)
	if crossed > 0:  # Projectile renforcé par les arcs traversés.
		events[0]["arcs"] = crossed
		cast_effects.assign(cast_effects.map(func(effect: Dictionary) -> Dictionary:
			return effect.merged({"bonus_arcs": ARC_BONUS * crossed}) if effect["type"] == Spell.EFFECT_DAMAGE else effect))
	if not trap_effect.is_empty():
		events[0]["cache"] = true
	var origin := fighter.cell
	if spell.teleports():
		var from := fighter.cell
		fighter.cell = target
		events.append({"type": Protocol.EVT_TELEPORTED, "entite": fighter.id, "depuis": from, "case": target})
		_enter_cells(fighter, [target], events)
		var trap := enemy_trap_at(target, fighter)
		if not trap.is_empty():
			_trigger_trap(trap, fighter, events)
	if not spell.effect_of(Spell.EFFECT_BEHIND).is_empty():
		fighter.cell = behind
		events.append({"type": Protocol.EVT_TELEPORTED, "entite": fighter.id, "depuis": origin, "case": behind})
		_seen(fighter)
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
		_enter_cells(fighter, path, events)
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
	for effect in cast_effects:
		if effect["type"] == Spell.EFFECT_GLYPH:
			_place_glyph(fighter, spell, effect, spell.zone_cells(target, origin), events)
		elif effect["type"] == Spell.EFFECT_SUMMON:
			_summon(fighter, spell, effect, target, events)
		elif effect["type"] == Spell.EFFECT_TRAP:
			_place_trap(fighter, spell, effect, target, events)
		elif effect["type"] == Spell.EFFECT_IMAGE:
			_place_image(fighter, spell, effect, origin, events)
		elif effect["type"] == Spell.EFFECT_AURA:
			_place_aura(fighter, spell, effect, events)
		elif effect["type"] == Spell.EFFECT_BEACON:
			_place_beacon(fighter, spell.display_name, effect, target, "", events)
		elif effect["type"] == Spell.EFFECT_BEACON_SWAP:
			_swap_with_beacon(fighter, beacon_at(target), events)
	var elements := {}
	for effect in cast_effects:
		if effect["type"] in [Spell.EFFECT_DAMAGE, Spell.EFFECT_HEAL, Spell.EFFECT_POISON, Spell.EFFECT_BOUNCE, Spell.EFFECT_SACRIFICE]:
			elements[effect["element"]] = true
	_open_credit(fighter, spell.pa_cost, elements.keys())
	var targets: Array[Fighter] = []
	for cell in zone if reached else []:
		var hit := fighter_at(cell)
		# Un invisible n'est pas visé directement par l'adversaire : seule une zone le touche.
		if hit != null and not (spell.excludes_caster and hit == fighter) \
				and not (hit.is_invisible() and hit.team != fighter.team and spell.zone_type == Spell.ZONE_CELL):
			targets.append(hit)
	for effect in cast_effects.filter(func(effect: Dictionary) -> bool: return effect.get("sur_lanceur", false)):
		_apply_effect(fighter, fighter, effect, events, critical, origin, spell.display_name)
	for hit in targets:
		var chain: Array[Fighter] = [hit]
		for effect in cast_effects:
			if effect["type"] == Spell.EFFECT_BOUNCE:
				_bounce(fighter, chain, effect, events, critical, spell.display_name)
			elif hit.is_alive() and effect["type"] not in [Spell.EFFECT_TELEPORT, Spell.EFFECT_GLYPH, Spell.EFFECT_TRAP,
					Spell.EFFECT_CHARGE, Spell.EFFECT_CREATE_SPELL, Spell.EFFECT_COMPOSE_STATES, Spell.EFFECT_IMAGE,
					Spell.EFFECT_DETONATE, Spell.EFFECT_BEHIND, Spell.EFFECT_SUMMON, Spell.EFFECT_AURA, Spell.EFFECT_BEACON, Spell.EFFECT_SURGE,
					Spell.EFFECT_BEACON_SWAP] and not effect.get("sur_lanceur", false) \
					and Spell.affects(effect, fighter, hit) and not (effect.get("premier_lancer", false) and fighter.cast_count(spell) > 1) \
					and not (effect.get("sur_arc", false) and not arc_cells(hit).has(hit.cell)):
				_apply_effect(fighter, hit, effect, events, critical, origin, spell.display_name)
	var detonate := spell.effect_of(Spell.EFFECT_DETONATE)
	for image in images.duplicate() if not detonate.is_empty() else []:
		if image["lanceur"] == fighter and image["case"] == target:
			_explode(image, int(detonate.get("bonus", 0)), events)
	var surge := spell.effect_of(Spell.EFFECT_SURGE)
	if not surge.is_empty():
		_surge(fighter, beacon_at(target), int(surge.get("multiplicateur", 100)), events)
	if spell.effects.any(func(effect: Dictionary) -> bool: return effect["type"] == Spell.EFFECT_DAMAGE):
		for cell in zone:  # Un coup ennemi sur sa case casse une balise.
			var hit_beacon := beacon_at(cell)
			if not hit_beacon.is_empty() and hit_beacon["equipe"] != fighter.team and hit_beacon["porteur"] == "":
				_break_beacon(hit_beacon, events)
	_close_credit()
	_ignite(fighter, zone, -CALCINED if not spell.effect_of(Spell.EFFECT_ASHES).is_empty() else int(spell.calcined.get("embrase", spell.ignites))
		if ember_level(target) == CALCINED else spell.ignites, events)
	# Invisible : un sort de dégâts non discret la révèle.
	if fighter.is_invisible() and not spell.discreet and spell.effects.any(func(effect: Dictionary) -> bool: return effect["type"] == Spell.EFFECT_DAMAGE):
		fighter.states.assign(fighter.states.filter(func(state: Dictionary) -> bool: return state.get("etat") != Spell.STATE_INVISIBLE))
		events.append(_states_event(fighter))
		_out_of_hiding(fighter, events)
	_check_images(fighter, events)
	_check_end(events)
	return events


## Rebond (voir `Spell.EFFECT_BOUNCE`) : `chain` liste ceux déjà touchés, le dernier en tête de saut.
func _bounce(caster: Fighter, chain: Array[Fighter], effect: Dictionary, events: Array[Dictionary], critical: bool, source: String) -> void:
	var from := chain[-1].cell
	var next: Fighter = null
	for other in fighters:
		var distance := IsoGrid.distance(from, other.cell)
		if other.is_alive() and other.team != caster.team and other.shadow == caster.shadow and other not in chain and distance <= int(effect["distance"]) \
				and (next == null or distance < IsoGrid.distance(from, next.cell)):
			next = other
	if next != null:
		chain.append(next)
		_apply_effect(caster, next, {"type": Spell.EFFECT_DAMAGE, "element": effect["element"], "min": effect["min"], "max": effect["max"]},
			events, critical, Vector2i(-99999, -99999), source)


# --- Pratique (progression des joueurs, GDD § 4.5) ---------------------------------------------

## Commence à noter ce que fait un sort de `caster` (s'il est de l'équipe des joueurs) qui a coûté `pa` ;
## `elements` : ceux de ses dégâts, soins et poisons, qui se partagent ses PA s'il a un effet réel.
func _open_credit(caster: Fighter, pa: float, elements := []) -> void:
	_credit = {}
	if caster != null and caster.team == Fighter.TEAM_PLAYERS and pa > 0.0:
		_credit = {"lanceur": caster, "pa": pa, "element": "", "elements": elements, "utile": false}


## Inscrit le sort noté dans la pratique de son lanceur : effet réel (PA partagés à égalité entre les
## éléments du sort, ou l'élément qui a touché s'il n'en est pas) ou utilitaire.
func _close_credit() -> void:
	if _credit.is_empty():
		return
	var caster: Fighter = _credit["lanceur"]
	if not str(_credit["element"]).is_empty():
		var elements: Array = _credit["elements"] if _credit["element"] in _credit["elements"] else [_credit["element"]]
		for element: String in elements:
			_add_practice(caster.id, "effet", float(_credit["pa"]) / elements.size(), element)
	elif _credit["utile"]:
		_add_practice(caster.id, "utile", float(_credit["pa"]))
	_credit = {}


func _add_practice(fighter_id: String, kind: String, amount: float, element := "") -> void:
	var fighter := get_fighter(fighter_id)
	fighter_id = fighter.controller() if fighter != null else fighter_id  # Un serviteur fait progresser son maître.
	if not practice.has(fighter_id):
		practice[fighter_id] = {"effet": {}, "utile": 0.0, "pv_recus": 0.0}
	var entry: Dictionary = practice[fighter_id]
	if kind == "effet":
		entry["effet"][element] = float(entry["effet"].get(element, 0.0)) + amount
	else:
		entry[kind] = float(entry[kind]) + amount


## Note l'effet réel du sort en cours (le premier élément qui touche) ; `element` vide : seulement utile.
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
			amount = _landed_removal(caster, target, "pm", amount, events)
			if amount == 0:
				return
			target.pm_malus += amount
			events.append({"type": Protocol.EVT_STATUS, "entite": target.id, "effet": Spell.EFFECT_REMOVE_PM, "valeur": amount, "pa": target.pa, "pm": target.pm})
		Spell.EFFECT_DAMAGE:
			var hp_before := target.hp
			var dealt := damage_value(caster, target, effect["element"], roundi(amount * (100 + damage_bonus(caster, target, effect)) / 100.0))
			var suffered := _hurt(target, dealt, effect["element"], events)
			_devastate(caster, target, dealt, hp_before - target.hp, events)
			_thorns(caster, target, dealt, suffered, events)
			var stolen := mini(hp_before - target.hp, caster.max_hp - caster.hp)
			if effect.get("vol", false) and caster.is_alive() and stolen > 0 and not caster.has_state(Spell.STATE_UNHEALABLE):
				caster.hp += stolen  # Vol de vie : le lanceur reprend les PV qu'il a fait perdre.
				events.append({"type": Protocol.EVT_HEAL, "entite": caster.id, "valeur": stolen, "element": effect["element"], "pv": caster.hp})
		Spell.EFFECT_SHIELD:
			amount = roundi(amount * (100 + caster.power(effect["element"])) / 100.0)
			target.shield += amount
			if not _credit.is_empty() and _credit["lanceur"] == caster and target.team == caster.team:
				target.shield_credit = {"lanceur": caster.id, "pa": float(_credit["pa"]), "element": effect["element"]}
			events.append({"type": Protocol.EVT_STATUS, "entite": target.id, "effet": Spell.EFFECT_SHIELD, "valeur": amount,
				"element": effect["element"], "bouclier": target.shield, "pa": target.pa, "pm": target.pm})
		Spell.EFFECT_HEAL:
			amount = mini(heal_value(caster, target, effect, amount), target.max_hp - target.hp)
			if target.has_state(Spell.STATE_UNHEALABLE):
				amount = 0
			target.hp += amount
			if amount > 0 and target.team == caster.team:
				_credit_effect(caster, effect["element"])
			events.append({"type": Protocol.EVT_HEAL, "entite": target.id, "valeur": amount, "element": effect["element"],
				"pv": target.hp})
		Spell.EFFECT_BONUS, Spell.EFFECT_MALUS:
			if effect["type"] == Spell.EFFECT_MALUS and effect["carac"] in ["pa", "pm"]:
				amount = _landed_removal(caster, target, effect["carac"], amount, events)
				if amount == 0:
					return
			_add_state(target, {"type": effect["type"], "carac": effect["carac"], "element": str(effect.get("element", "")),
				"valeur": amount, "tours": effect["duree"], "sort": source, "lanceur": caster.id, "retirable": removable,
				"cumul": int(effect.get("cumul", 0))}, events)
		Spell.EFFECT_SHADOW_WEAPON:
			if target.states.filter(func(state: Dictionary) -> bool: return state["type"] == Spell.EFFECT_SHADOW_WEAPON).size() < 2:
				_add_state(target, {"type": Spell.EFFECT_SHADOW_WEAPON, "element": effect["element"], "valeur": amount, "tours": 99,
					"sort": source, "lanceur": caster.id, "retirable": false}, events)
		Spell.EFFECT_SHADOW_WORLD:
			_cross(target, events)
		Spell.EFFECT_LIVING_BEACON:
			_place_beacon(caster, source, effect, target.cell, target.id, events)
		Spell.EFFECT_SWAP:
			var from_cell := caster.cell
			caster.cell = target.cell
			target.cell = from_cell
			for moved: Fighter in [caster, target]:
				events.append({"type": Protocol.EVT_TELEPORTED, "entite": moved.id, "depuis": target.cell if moved == caster else caster.cell,
					"case": moved.cell, "echange": true})
		Spell.EFFECT_SACRIFICE:  # Le serviteur explose : dégâts autour de lui, plus une part de ses PV restants.
			var extra := roundi(target.hp * int(effect.get("part_pv", 0)) / 100.0)
			_kill(target, events)
			for cell in Spell.circle_cells(target.cell, 1):
				var hit := fighter_at(cell)
				if hit != null and hit.team != caster.team:
					_apply_effect(caster, hit, {"type": Spell.EFFECT_DAMAGE, "element": effect["element"], "min": int(effect["min"]) + extra,
						"max": int(effect["max"]) + extra}, events, critical, target.cell, source)
		Spell.EFFECT_POISON:
			var poison := {"type": Spell.EFFECT_POISON, "element": effect["element"], "valeur": amount,
				"tours": effect["duree"], "sort": source, "lanceur": caster.id, "retirable": removable}
			if not _credit.is_empty() and _credit["lanceur"] == caster and target.team != caster.team:
				poison["pa"] = float(_credit["pa"]) / maxi(1, int(effect["duree"]))  # Pratique : à chaque tour qui blesse.
				_credit["utile"] = true
			_add_state(target, poison, events)
		Spell.EFFECT_STATE:
			_add_state(target, {"type": Spell.EFFECT_STATE, "etat": effect["etat"], "valeur": 0, "tours": effect["duree"],
				"sort": source, "lanceur": caster.id, "retirable": removable}, events)
		Spell.EFFECT_CLOCK:
			_place_clock(caster, target, effect, from, source, events)
		Spell.EFFECT_CLOCK_SHIFT:
			_shift_on_clock(target, int(effect["heures"]), events)
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


## % de dégâts en plus d'un effet de dégâts de l'Ombre : « si_invisible » (lanceur invisible), « par_malus » (par malus
## de la cible) et passif « Coup en traître » (5 + rang + 1 %, invisible ou juste sorti des ombres ou de l'invisibilité) ;
## du Démoniste : « par_serviteur » (par serviteur vivant) et passif « Pacte de feu » (5 + rang + 1 %, lui et ses serviteurs,
## contre une cible sur une case embrasée ou calcinée).
func damage_bonus(caster: Fighter, target: Fighter, effect: Dictionary) -> int:
	var hidden := caster.is_invisible() or caster.ambush > 0
	var pact := int(caster.passives.get("pacte_de_feu", 0))
	return (int(effect.get("si_invisible", 0)) if caster.is_invisible() else 0) \
		+ int(effect.get("par_serviteur", 0)) * servants_of(caster).size() \
		+ (5 + pact if pact > 0 and ember_level(target.cell, target.shadow) > 0 else 0) \
		+ int(effect.get("par_malus", 0)) * target.states.filter(func(state: Dictionary) -> bool: return state["type"] == Spell.EFFECT_MALUS).size() \
		+ (5 + int(caster.passives.get("coup_en_traitre", 0)) if hidden and int(caster.passives.get("coup_en_traitre", 0)) > 0 else 0) \
		+ int(effect.get("bonus_arcs", 0)) + paladin_bonus(caster)


## Dégâts d'un effet de valeur tirée `amount` (voir `_apply_effect`) : au contact, × (100 + dommages de mêlée
## du lanceur − réduction de mêlée de la cible) % ; puis moins la réduction de dégâts fixe de la cible.
static func damage_value(caster: Fighter, target: Fighter, element: String, amount: int) -> int:
	var boosted := amount * (100 + caster.power(element)) / 100.0 * dealt_factor(caster)
	var dealt := maxi(0, roundi(boosted * (100 - target.resistance(element)) / 100.0)) + caster.total_dommages() + caster.element_damage(element)
	if IsoGrid.distance(caster.cell, target.cell) == 1:
		dealt = roundi(dealt * (100 + caster.combat_stat("dommages_melee") - int(target.passives.get("reduction_melee", 0))) / 100.0)
	return maxi(0, dealt - target.combat_stat("reduction_degats"))


## Multiplicateur des dégâts infligés par `caster` (bonus et malus « degats_infliges », jamais négatif).
static func dealt_factor(caster: Fighter) -> float:
	return maxf(0.0, (100 + caster.modifier("degats_infliges")) / 100.0) if caster != null else 1.0


## Valeur d'un soin, d'un bouclier ou d'un poison, augmentée par la caractéristique de son élément.
static func boosted_value(caster: Fighter, element: String, amount: int) -> int:
	return roundi(amount * (100 + caster.power(element)) / 100.0)


## Soin de valeur tirée `amount` : en % des PV max de la cible si l'effet a `pourcent_pv`, sinon augmenté par la
## caractéristique de son élément et les soins du lanceur.
static func heal_value(caster: Fighter, target: Fighter, effect: Dictionary, amount: int) -> int:
	if effect.get("pourcent_pv", false):
		return roundi(target.max_hp * amount / 100.0)
	return boosted_value(caster, effect["element"], amount) + caster.total_heal_bonus(effect["element"])


## Prévisualisation d'un sort de `fighter` sur `target` (sans coup critique ni hasard) : pour chaque
## combattant touché, id → { degats: [min, max], soin: [min, max], element, heure, arrivee } (seulement
## les entrées non nulles ; `element` : celui du premier effet chiffré ; `heure` et `arrivee` : où un
## décalage sur son horloge l'enverrait). Les soins sont limités aux PV
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
	var crossed := ARC_BONUS * arcs_crossed(fighter, spell, target)
	for cell in spell_zone(fighter, spell, target):
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
				var bonus := 100 + damage_bonus(fighter, hit, effect) + crossed
				low = damage_value(fighter, hit, effect["element"], roundi(effect["min"] * bonus / 100.0))
				high = damage_value(fighter, hit, effect["element"], roundi(effect["max"] * bonus / 100.0))
			elif hit.hp >= hit.max_hp or hit.has_state(Spell.STATE_UNHEALABLE):
				continue  # PV pleins ou insoignable : pas de « +0 ».
			else:
				key = "soin"
				var missing := hit.max_hp - hit.hp
				low = mini(heal_value(fighter, hit, effect, effect["min"]), missing)
				high = mini(heal_value(fighter, hit, effect, effect["max"]), missing)
			var total: Array = entry.get(key, [0, 0])
			entry[key] = [int(total[0]) + low, int(total[1]) + high]
			if not entry.has("element"):
				entry["element"] = effect["element"]
		for effect in spell.effects:
			if effect["type"] == Spell.EFFECT_CLOCK_SHIFT and Spell.affects(effect, fighter, hit) and not entry.has("heure"):
				var arrival := clock_destination(hit, int(effect["heures"]))
				if int(arrival["heure"]) > 0:
					entry["heure"] = arrival["heure"]
					entry["arrivee"] = arrival["case"]
		if entry.has("degats") or entry.has("soin") or entry.has("heure"):
			preview[hit.id] = entry
	return preview


## Retire des PV (le bouclier absorbe d'abord) ; `element` vide pour des dégâts sans élément (choc).
## Pratique : des PV perdus par un ennemi comptent pour le sort en cours, des dégâts absorbés pour
## celui qui a posé le bouclier, et un joueur note les PV qu'il perd (Vitalité). Renvoie les dégâts subis
## (après le bouclier).
func _hurt(target: Fighter, amount: int, element: String, events: Array[Dictionary], source := "") -> int:
	if element == "sacre" and target.has_state(Spell.STATE_EXORCISM):
		# Exorcisme : les premiers dégâts Sacré achèvent la cible, bouclier compris.
		amount = target.hp + target.shield
		target.states.assign(target.states.filter(func(state: Dictionary) -> bool: return state.get("etat") != Spell.STATE_EXORCISM))
		events.append(_states_event(target))
	var absorbed := mini(target.shield, amount)
	target.shield -= absorbed
	amount -= absorbed
	if amount >= target.hp and target.passives.get("deja_mort", 0) > 0:
		target.passives.erase("deja_mort")  # Déjà mort : survit au coup fatal à 1 PV, une fois par combat.
		amount = target.hp - 1
	var lost := mini(amount, target.hp)
	target.hp = maxi(0, target.hp - amount)
	if lost > 0 and not _credit.is_empty() and (_credit["lanceur"] as Fighter).team != target.team:
		_credit_effect(_credit["lanceur"], element)
	if absorbed > 0 and not target.shield_credit.is_empty():
		var shield_credit := target.shield_credit
		target.shield_credit = {}
		_add_practice(shield_credit["lanceur"], "effet", float(shield_credit["pa"]), shield_credit["element"])
	if lost > 0 and target.team == Fighter.TEAM_PLAYERS and target.master.is_empty():
		_add_practice(target.id, "pv_recus", float(lost))
	var event := {"type": Protocol.EVT_DAMAGE, "entite": target.id, "valeur": amount, "element": element, "pv": target.hp,
		"absorbe": absorbed, "bouclier": target.shield}
	if not source.is_empty():
		event["source"] = source
	events.append(event)
	if not target.is_alive():
		events.append({"type": Protocol.EVT_DIED, "entite": target.id})
		_check_alone(target.team, events)
		_remove_ground_of(target, events)
		for servant in servants_of(target):  # Ses serviteurs disparaissent avec lui.
			_kill(servant, events)
	else:
		_check_phases(target, events)
	return amount


## Dégâts dévastateurs (GDD § 4.4) : une part des dégâts infligés (fixe + %, au plus `MAX_SPECTRAL` d'entre eux et
## des PV perdus) baisse aussi les PV max de la cible, sans la descendre sous 40 % de ses PV max du début du combat.
func _devastate(caster: Fighter, target: Fighter, dealt: int, lost: int, events: Array[Dictionary]) -> void:
	var start_max: int = _max_hp_at_start.get_or_add(target.id, target.max_hp)
	var cut := mini(mini(_part(caster, "degats_devastateurs", dealt), lost), target.max_hp - ceili(start_max * 0.4))
	if cut > 0 and target.is_alive():
		target.max_hp -= cut
		events.append({"type": Protocol.EVT_STATUS, "entite": target.id, "effet": "devastation", "valeur": cut, "pv_max": target.max_hp,
			"pa": target.pa, "pm": target.pm})


## Part fixe + % de `dealt` d'une statistique de `fighter` (dégâts spectraux, dévastateurs), au plus `MAX_SPECTRAL`.
static func _part(fighter: Fighter, stat_name: String, dealt: int) -> int:
	return mini(fighter.combat_stat(stat_name + "_fixes") + roundi(dealt * fighter.combat_stat(stat_name) / 100.0), floori(dealt * MAX_SPECTRAL))


## Épines (GDD § 4.4) : `target` renvoie à son adversaire `attacker` une part des dégâts subis moins leur part
## spectrale : un jet par sorte (fixe + %), au plus `MAX_THORNS` des dégâts comptés à eux tous (au prorata) ; l'épine
## élémentaire est réduite par la résistance de l'attaquant, toutes par sa réduction fixe. Jamais d'épine sur épine.
func _thorns(attacker: Fighter, target: Fighter, dealt: int, suffered: int, events: Array[Dictionary]) -> void:
	if attacker == null or not attacker.is_alive() or attacker.team == target.team:
		return
	var counted := maxi(0, suffered - _part(attacker, "degats_spectraux", dealt))
	var rolls := {}
	for kind: String in Fighter.THORN_KINDS:
		var value := target.combat_stat("epines_%s_fixes" % kind) + counted * target.combat_stat("epines_" + kind) / 100.0
		if value > 0 and counted > 0:
			rolls[kind] = value
	var total: float = rolls.values().reduce(func(sum: float, value: float) -> float: return sum + value, 0.0)
	for kind: String in rolls:
		var value: float = rolls[kind] * minf(1.0, counted * MAX_THORNS / total)
		if kind != "brutes":
			value *= (100 - attacker.resistance(kind)) / 100.0
		var returned := roundi(value) - attacker.combat_stat("reduction_degats")
		if returned > 0 and attacker.is_alive():
			_hurt(attacker, returned, "" if kind == "brutes" else kind, events, "epines")


## Dernier en vie de son camp : un monstre à sorts « seul » les échange (Archange Raphaël), une fois.
func _check_alone(team: int, events: Array[Dictionary]) -> void:
	var alive := fighters.filter(func(fighter: Fighter) -> bool: return fighter.team == team and fighter.is_alive())
	if alive.size() != 1 or (alive[0] as Fighter).alone_spells.is_empty():
		return
	var last: Fighter = alive[0]
	for i in last.spells.size():
		last.spells[i] = last.alone_spells.get(last.spells[i].id, last.spells[i])
	last.alone_spells = {}
	events.append({"type": Protocol.EVT_PHASE, "entite": last.id, "message": last.alone_message})


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
	var cap := int(new_state.get("cumul", 0))
	var same := target.states.filter(func(state: Dictionary) -> bool: return state.get("sort") == new_state["sort"] and state.get("carac") == new_state.get("carac"))
	for i in (same.size() - cap + 1) if cap > 0 else 0:
		target.states.erase(same[i])  # Cumulable `cumul` fois : le plus ancien part.
	target.states.append(new_state)
	var signed := int(new_state["valeur"]) * (1 if new_state["type"] == Spell.EFFECT_BONUS else -1)
	if new_state.get("carac") == "pa":
		target.pa = maxi(0, target.pa + signed)
	if new_state.get("carac") == "pm":
		target.pm = maxi(0, target.pm + signed)
	var event := _states_event(target)
	event["nouveau"] = {"type": new_state["type"], "carac": new_state.get("carac", ""), "element": new_state.get("element", ""),
		"valeur": new_state["valeur"], "tours": new_state["tours"], "sort": new_state["sort"], "etat": new_state.get("etat", "")}
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
	var passed: Array[Vector2i] = []
	while moved < distance:
		var next := target.cell + step
		if not is_free(next):
			break
		target.cell = next
		passed.append(next)
		moved += 1
		trap = enemy_trap_at(next, target)
		if not trap.is_empty():
			break
	if moved > 0:
		events.append({"type": Protocol.EVT_PUSHED, "entite": target.id, "depuis": start, "case": target.cell})
		_check_images(target, events)
		_enter_cells(target, passed, events)
	if not target.is_alive():
		return
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
	var glyph := {"id": _next_ground_id, "lanceur": caster, "equipe": caster.team, "ombres": caster.shadow, "cases": inside, "effets": effect["effets"],
		"tours": int(effect["duree"]), "sort": spell.display_name, "pa": float(spell.pa_cost) / maxi(1, int(effect["duree"]))}
	_next_ground_id += 1
	glyphs.append(glyph)
	var element := ""
	for glyph_effect: Dictionary in effect["effets"]:
		if element.is_empty() and glyph_effect["type"] in Spell.ELEMENT_EFFECTS:
			element = glyph_effect["element"]
	events.append({"type": Protocol.EVT_GLYPH, "id": glyph["id"], "lanceur": caster.id, "equipe": caster.team, "ombres": caster.shadow,
		"cases": inside, "tours": glyph["tours"], "sort": glyph["sort"], "element": element})


func _place_trap(caster: Fighter, spell: Spell, effect: Dictionary, cell: Vector2i, events: Array[Dictionary]) -> void:
	var zone: Dictionary = effect["zone"]
	var cells: Array[Vector2i] = []
	for zone_cell in Spell.circle_cells(cell, int(zone.get("taille", 0)) if zone["type"] == Spell.ZONE_CIRCLE else 0):
		if map.is_inside(zone_cell):
			cells.append(zone_cell)
	var trap := {"id": _next_ground_id, "lanceur": caster, "equipe": caster.team, "ombres": caster.shadow, "case": cell, "cases": cells,
		"effets": effect["effets"], "sort": spell.display_name, "pa": spell.pa_cost}
	_next_ground_id += 1
	traps.append(trap)
	events.append({"type": Protocol.EVT_TRAP, "id": trap["id"], "lanceur": caster.id, "equipe": caster.team, "ombres": caster.shadow,
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


## Retire une glyphe ; celle d'une horloge emporte l'état « manipulation_temps » de sa cible.
func _end_glyph(glyph: Dictionary, events: Array[Dictionary]) -> void:
	glyphs.erase(glyph)
	events.append({"type": Protocol.EVT_GLYPH_ENDED, "id": glyph["id"]})
	if not glyph.has("horloge"):
		return
	var target := get_fighter(str(glyph["horloge"]["cible"]))
	if target == null:
		return
	var kept: Array[Dictionary] = []
	for state in target.states:
		if state.get("etat") != Spell.STATE_TIME_MANIPULATION:
			kept.append(state)
	if kept.size() != target.states.size():
		target.states = kept
		if target.is_alive():
			events.append(_states_event(target))


# --- Horloge (Chronomancien) ----------------------------------------------------------------------

## Horloge dont `fighter` est la cible (vide s'il n'en a pas).
func clock_of(fighter: Fighter) -> Dictionary:
	for glyph in glyphs:
		if glyph.has("horloge") and str(glyph["horloge"]["cible"]) == fighter.id:
			return glyph
	return {}


## Heure de `cell` (1 à 12) sur le cadran centré en `center` dont midi est à `noon` (décalage depuis
## le centre, l'une des 4 cases à 2 pas en ligne) ; 0 hors du cadran.
static func clock_hour(center: Vector2i, noon: Vector2i, cell: Vector2i) -> int:
	var index := CLOCK_RING.find(cell - center)
	if index < 0:
		return 0
	var hour := posmod(index - CLOCK_RING.find(noon), 12)
	return 12 if hour == 0 else hour


## Case de l'heure `hour` (1 à 12) du cadran centré en `center` dont midi est à `noon`.
static func clock_cell(center: Vector2i, noon: Vector2i, hour: int) -> Vector2i:
	return center + CLOCK_RING[posmod(CLOCK_RING.find(noon) + hour, 12)]


## Midi d'une horloge posée par un lanceur en `from` sur une cible en `center` : à 2 pas du centre,
## dans la direction du lancer.
static func clock_noon(from: Vector2i, center: Vector2i) -> Vector2i:
	return Spell.direction(from, center) * 2


## Pose l'horloge de `effect` autour de `target` (qui en change si elle en avait une), orientée par la
## direction du lancer depuis `from`, puis place aussitôt la cible à 12 h (avec l'effet de 12 h).
func _place_clock(caster: Fighter, target: Fighter, effect: Dictionary, from: Vector2i, source: String,
		events: Array[Dictionary]) -> void:
	var old := clock_of(target)
	if not old.is_empty():
		_end_glyph(old, events)
	var center := target.cell
	var noon := clock_noon(from, center)
	var cells: Array[Vector2i] = []
	for offset in CLOCK_RING:
		if map.is_inside(center + offset) and map.is_walkable_in_combat(center + offset):
			cells.append(center + offset)
	var glyph := {"id": _next_ground_id, "lanceur": caster, "equipe": caster.team, "cases": cells, "effets": [],
		"tours": int(effect["duree"]), "sort": source, "pa": 0.0,
		"horloge": {"centre": center, "midi": noon, "cible": target.id, "heure": 12, "heures": effect["heures"].duplicate(true)}}
	_next_ground_id += 1
	glyphs.append(glyph)
	events.append({"type": Protocol.EVT_GLYPH, "id": glyph["id"], "lanceur": caster.id, "equipe": caster.team,
		"cases": cells, "tours": glyph["tours"], "sort": source, "element": "impie", "centre": center, "midi": noon,
		"cible": target.id})
	_add_state(target, {"type": Spell.EFFECT_STATE, "etat": Spell.STATE_TIME_MANIPULATION, "valeur": 0,
		"tours": int(effect["duree"]), "sort": source, "lanceur": caster.id, "retirable": false}, events)
	_move_on_clock(target, _clock_arrival(target, glyph, 12, 1), true, events)


## Case où un décalage de `hours` heures enverrait `target` sur son horloge (sa case s'il n'a pas
## d'horloge ou si aucune heure n'est praticable), et l'heure atteinte (0 si rien ne bouge). Le décalage
## part de la dernière heure atteinte, même si la cible a été poussée hors du cadran depuis.
func clock_destination(target: Fighter, hours: int) -> Dictionary:
	var clock := clock_of(target)
	if clock.is_empty() or hours == 0:
		return {"case": target.cell, "heure": 0}
	var start := int(clock["horloge"]["heure"])
	return _clock_arrival(target, clock, posmod(start + hours - 1, 12) + 1, signi(hours))


## Première heure praticable à partir de `hour` sur l'horloge `clock`, en avançant de `step` (±1) : une
## heure hors de la carte ou sur un obstacle est sautée. { case, heure } ; heure 0 si rien ne bouge.
func _clock_arrival(target: Fighter, clock: Dictionary, hour: int, step: int) -> Dictionary:
	var center: Vector2i = clock["horloge"]["centre"]
	var noon: Vector2i = clock["horloge"]["midi"]
	for i in 12:
		var cell := clock_cell(center, noon, hour)
		if cell == target.cell:
			break
		if map.is_inside(cell) and map.is_walkable_in_combat(cell):
			return {"case": cell, "heure": hour}
		hour = posmod(hour - 1 + step, 12) + 1
	return {"case": target.cell, "heure": 0}


## Décale `target` sur son horloge (voir `clock_destination`) et lui applique l'heure atteinte.
func _shift_on_clock(target: Fighter, hours: int, events: Array[Dictionary]) -> void:
	_move_on_clock(target, clock_destination(target, hours), true, events)


## Envoie `target` sur la case de `arrival` ({ case, heure }, rien si heure 0). Un combattant sur la
## case d'arrivée échange sa place avec lui ; un piège ennemi sur une case d'arrivée se déclenche.
## Avec `hour_effects`, les effets de l'heure atteinte s'appliquent ensuite à la cible, avec le poseur
## de l'horloge pour lanceur.
func _move_on_clock(target: Fighter, arrival: Dictionary, hour_effects: bool, events: Array[Dictionary]) -> void:
	var hour: int = arrival["heure"]
	if hour == 0:
		return
	var clock := clock_of(target)
	var cell: Vector2i = arrival["case"]
	var from := target.cell
	var other := fighter_at(cell)
	target.cell = cell
	clock["horloge"]["heure"] = hour  # Dernière heure atteinte : le prochain décalage en part.
	events.append({"type": Protocol.EVT_TELEPORTED, "entite": target.id, "depuis": from, "case": cell, "heure": hour})
	if other != null:
		other.cell = from
		events.append({"type": Protocol.EVT_TELEPORTED, "entite": other.id, "depuis": cell, "case": from, "echange": true})
	for moved: Fighter in [target, other]:
		if moved != null and moved.is_alive():
			var trap := enemy_trap_at(moved.cell, moved)
			if not trap.is_empty():
				_trigger_trap(trap, moved, events)
	if not hour_effects:
		return
	var caster: Fighter = clock["lanceur"]
	for effect: Dictionary in clock["horloge"]["heures"].get(str(hour), []):
		if target.is_alive() and Spell.affects(effect, caster, target):
			_apply_effect(caster, target, effect, events, false, cell, "%s (%d h)" % [clock["sort"], hour])


## Un combattant vaincu emporte ses glyphes et ses pièges.
func _remove_ground_of(fighter: Fighter, events: Array[Dictionary]) -> void:
	for glyph in glyphs.duplicate():
		if glyph["lanceur"] == fighter or str(glyph.get("horloge", {}).get("cible", "")) == fighter.id:
			_end_glyph(glyph, events)
	for trap in traps.duplicate():
		if trap["lanceur"] == fighter:
			traps.erase(trap)
			events.append({"type": Protocol.EVT_TRAP_ENDED, "id": trap["id"]})
	for image in images.duplicate():
		if image["lanceur"] == fighter:
			images.erase(image)
			events.append({"type": Protocol.EVT_IMAGE_ENDED, "id": image["id"], "explose": false, "cases": []})
	for aura in auras.duplicate():
		if aura["lanceur"] == fighter:
			_end_aura(aura, events)
	for beacon in beacons.duplicate():
		if beacon["lanceur"] == fighter or beacon["porteur"] == fighter.id:
			_break_beacon(beacon, events)


## Début du tour de `fighter` : ses glyphes perdent un tour, puis ses poisons et les glyphes sous
## ses pieds agissent.
func _start_of_turn_effects(fighter: Fighter, events: Array[Dictionary]) -> void:
	for glyph in glyphs.duplicate():
		if glyph["lanceur"] == fighter:
			glyph["tours"] = int(glyph["tours"]) - 1
			if int(glyph["tours"]) <= 0:
				_end_glyph(glyph, events)
	var lasting: Array[Dictionary] = auras.duplicate()
	lasting.append_array(beacons.filter(func(beacon: Dictionary) -> bool: return beacon["porteur"] != ""))
	for ground in lasting:  # Auras et balises vivantes perdent un tour.
		if ground["lanceur"] == fighter:
			ground["tours"] = int(ground["tours"]) - 1
			if int(ground["tours"]) <= 0 and ground in auras:
				_end_aura(ground, events)
			elif int(ground["tours"]) <= 0:
				_break_beacon(ground, events)
	for arc in arcs():  # Commence son tour sur un arc ennemi.
		if fighter.is_alive() and arc["equipe"] != fighter.team and arc["ombres"] == fighter.shadow and fighter.cell in arc["cases"]:
			_shock(arc["a"], fighter, 100, events, arc["id"])
	for image in images.duplicate():
		if image["lanceur"] == fighter and int(image["manche"]) < round_number and image in images:
			_explode(image, 0, events)  # Restée un tour complet.
	for poison in fighter.states.duplicate():
		if poison["type"] not in [Spell.EFFECT_POISON, Spell.EFFECT_SHADOW_WEAPON] or not fighter.is_alive():
			continue
		if poison["type"] == Spell.EFFECT_SHADOW_WEAPON:  # Arme d'obscurité : frappe une fois, puis disparaît.
			fighter.states.erase(poison)
			events.append(_states_event(fighter))
		var caster := get_fighter(poison["lanceur"])
		var element: String = poison["element"]
		var boosted := int(poison["valeur"]) * (100 + (caster.power(element) if caster != null else 0)) / 100.0 * dealt_factor(caster)
		_open_credit(caster, float(poison.get("pa", 0.0)))
		var dealt := maxi(0, roundi(boosted * (100 - fighter.resistance(element)) / 100.0) - fighter.combat_stat("reduction_degats"))
		_thorns(caster, fighter, dealt, _hurt(fighter, dealt, element, events, "poison" if poison["type"] == Spell.EFFECT_POISON else poison["sort"]), events)
		_close_credit()
	var ember: Dictionary = embers[int(fighter.shadow)].get(fighter.cell, {})
	if fighter.is_alive() and int(ember.get("niveau", CALCINED)) < CALCINED and ember["equipe"] != fighter.team:
		_hurt(fighter, maxi(0, roundi(EMBER_BURN * int(ember["niveau"]) * (100 - fighter.resistance("flamme")) / 100.0)), "flamme", events, "Embrasement")
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
		if _turn_index >= 0:
			_end_of_turn(fighters[_turn_index], events)
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
		dimension = fighter.shadow
		_arc_hits.clear()
		fighter.start_turn()
		events.append({"type": Protocol.EVT_TURN_STARTED, "entite": fighter.id, "tour": round_number, "pa": fighter.pa, "pm": fighter.pm})
		if turn_limit > 0.0 and not fighter.is_ai():
			events[-1]["duree"] = turn_limit
		_start_of_turn_effects(fighter, events)
		_refresh_auras(events)
		if not fighter.is_alive():
			_check_end(events)
			continue
		if not fighter.is_ai() and not absent.has(fighter.controller()):
			_elapsed = 0.0
			return
		if fighter.is_ai():
			_play_ai_turn(fighter, events)
		if state == State.FIGHTING:
			events.append({"type": Protocol.EVT_TURN_ENDED, "entite": fighter.id} if fighter.is_ai()
				else {"type": Protocol.EVT_TURN_ENDED, "entite": fighter.id, "absent": true})


## Fin du tour de `fighter` : ses états perdent un tour ; l'invisibilité tombée le montre ; il sort des ombres
## quand son séjour est fini, ou tout de suite sans Ombre dans la dimension.
func _end_of_turn(fighter: Fighter, events: Array[Dictionary]) -> void:
	var was_invisible := fighter.is_invisible()
	fighter.ambush = maxi(0, fighter.ambush - 1)
	fighter.ambush_discount = fighter.ambush_discount and fighter.ambush > 0
	if fighter.end_turn():
		events.append(_states_event(fighter))
	if was_invisible and not fighter.is_invisible() and fighter.is_alive():
		_out_of_hiding(fighter, events)
	if fighter.shadow and fighter.is_alive() and (not fighter.has_state(Spell.STATE_SHADOW) or not fighters.any(func(other: Fighter) -> bool:
			return other.is_alive() and other.shadow and other.kind == SHADOW_CLASS)):
		dimension = true
		_cross(fighter, events)


# --- Ombre : images rémanentes et Monde des ombres (GDD § 4.3) -----------------------------------

## Le combattant est vu par l'adversaire (ni invisible, ou dans les ombres où son ombre se projette) : l'IA s'en souvient.
func _seen(fighter: Fighter) -> void:
	if not fighter.is_invisible():
		fighter.last_seen = fighter.cell


## Sortie de l'invisibilité ou des ombres : coup en traître pendant son tour (ou le suivant), avec les rangs 3
## (1 PA de moins à son prochain sort) et 5 (+1 PM) du passif.
func _out_of_hiding(fighter: Fighter, events: Array[Dictionary]) -> void:
	_seen(fighter)
	var rank := int(fighter.passives.get("coup_en_traitre", 0)) - 1
	if rank < 0:
		return
	fighter.ambush = 1
	fighter.ambush_discount = rank >= 3
	if rank >= 5:
		_add_state(fighter, {"type": Spell.EFFECT_BONUS, "carac": "pm", "valeur": 1, "tours": 1, "sort": "Coup en traître",
			"lanceur": fighter.id, "retirable": false}, events)


## Images ennemies de `fighter` (de sa dimension) à son contact ou sous lui en `cell`.
func _images_near(cell: Vector2i, fighter: Fighter) -> Array[Dictionary]:
	var near: Array[Dictionary] = []
	for image in images:
		if image["equipe"] != fighter.team and image["ombres"] == fighter.shadow and IsoGrid.distance(image["case"], cell) <= 1:
			near.append(image)
	return near


## Un ennemi arrivé au contact d'images (ou dessus) les fait exploser.
func _check_images(fighter: Fighter, events: Array[Dictionary]) -> void:
	for image in _images_near(fighter.cell, fighter) if fighter.is_alive() else []:
		if image in images:
			_explode(image, 0, events)


func _place_image(caster: Fighter, spell: Spell, effect: Dictionary, cell: Vector2i, events: Array[Dictionary]) -> void:
	var own := images.filter(func(image: Dictionary) -> bool: return image["lanceur"] == caster)
	if own.size() >= MAX_IMAGES:
		_explode(own[0], 0, events)  # La plus ancienne explose.
	var image := {"id": _next_ground_id, "lanceur": caster, "equipe": caster.team, "case": cell, "ombres": caster.shadow,
		"manche": round_number, "effets": effect["effets"], "sort": spell.display_name, "pa": float(spell.pa_cost)}
	_next_ground_id += 1
	images.append(image)
	events.append({"type": Protocol.EVT_IMAGE, "id": image["id"], "lanceur": caster.id, "equipe": caster.team, "case": cell,
		"ombres": caster.shadow})
	for enemy in fighters:
		if enemy.is_alive() and enemy.team != caster.team and enemy.shadow == caster.shadow and IsoGrid.distance(enemy.cell, cell) <= 1 and image in images:
			_explode(image, 0, events)


## Une image explose : ses effets (+`bonus` % aux valeurs) touchent la croix d'une case autour d'elle, dans sa dimension.
func _explode(image: Dictionary, bonus: int, events: Array[Dictionary]) -> void:
	images.erase(image)
	var cells := Spell.circle_cells(image["case"], 1)
	events.append({"type": Protocol.EVT_IMAGE_ENDED, "id": image["id"], "explose": true, "cases": cells})
	var outer := [dimension, _credit]
	dimension = image["ombres"]
	var caster: Fighter = image["lanceur"]
	var hits: Array[Fighter] = []
	hits.assign(cells.map(fighter_at).filter(func(hit: Fighter) -> bool: return hit != null))
	_open_credit(caster, float(image["pa"]))
	var effects: Array[Dictionary] = []
	effects.assign(image["effets"])
	for effect: Dictionary in Spell._scaled_effects(effects, 100 + bonus):
		for hit in hits:
			if hit.is_alive() and Spell.affects(effect, caster, hit):
				_apply_effect(caster, hit, effect, events, false, image["case"], image["sort"])
	_close_credit()
	dimension = outer[0]
	_credit = outer[1]


## `fighter` passe dans l'autre dimension sur sa case. Un combattant de l'autre dimension sur cette case échange avec
## lui (une fois par case et par combattant et par manche) s'il peut passer : pas « retour impossible » pour entrer, pas
## « aspiré » pour sortir ; sinon `fighter` arrive sur la case libre la plus proche.
func _cross(fighter: Fighter, events: Array[Dictionary]) -> void:
	var outer := dimension
	dimension = not fighter.shadow
	var cell := fighter.cell
	var other := fighter_at(cell)
	var swap := other != null and not other.has_state(Spell.STATE_NO_RETURN if dimension == false else Spell.STATE_DRAWN) \
		and [cell, other.id, fighter.id].all(func(key: Variant) -> bool: return _swaps.get(key, -1) != round_number)
	if other != null and not swap:
		fighter.cell = _nearest_free(cell)
	fighter.shadow = dimension
	_on_cross(fighter, swap, events)
	if swap:
		for key: Variant in [cell, other.id, fighter.id]:
			_swaps[key] = round_number
		other.shadow = not dimension
		_on_cross(other, true, events)
		if other.shadow:  # Entré par échange : il n'en ressort pas tout de suite par un sort.
			_add_state(other, {"type": Spell.EFFECT_STATE, "etat": Spell.STATE_DRAWN, "valeur": 0, "tours": 1, "sort": "Monde des ombres",
				"lanceur": fighter.id, "retirable": false}, events)
	dimension = outer
	_check_images(fighter, events)


## Entrée (séjour de `SHADOW_TURNS` tours) ou sortie (retour impossible, coup en traître) des ombres.
func _on_cross(fighter: Fighter, swapped: bool, events: Array[Dictionary]) -> void:
	fighter.states.assign(fighter.states.filter(func(state: Dictionary) -> bool:
		return state.get("etat") not in [Spell.STATE_SHADOW, Spell.STATE_NO_RETURN, Spell.STATE_DRAWN]))
	events.append({"type": Protocol.EVT_DIMENSION, "entite": fighter.id, "ombres": fighter.shadow, "case": fighter.cell, "echange": swapped})
	_add_state(fighter, {"type": Spell.EFFECT_STATE, "etat": Spell.STATE_SHADOW if fighter.shadow else Spell.STATE_NO_RETURN, "valeur": 0,
		"tours": SHADOW_TURNS if fighter.shadow else 1 if fighter.kind == SHADOW_CLASS else NO_RETURN_TURNS, "sort": "Monde des ombres",
		"lanceur": fighter.id, "retirable": false}, events)
	if not fighter.shadow:
		_out_of_hiding(fighter, events)


## Case libre la plus proche de `cell` dans la dimension en cours (`cell` si aucune).
func _nearest_free(cell: Vector2i) -> Vector2i:
	for size in range(1, map.width + map.height):
		for candidate in Spell.circle_cells(cell, size):
			if IsoGrid.distance(cell, candidate) == size and map.is_inside(candidate) and is_free(candidate):
				return candidate
	return cell


# --- Démoniste : serviteurs et embrasement (GDD § 4.3) ---------------------------------------------

## Serviteurs vivants de `fighter`.
func servants_of(fighter: Fighter) -> Array[Fighter]:
	return fighters.filter(func(other: Fighter) -> bool: return other.master == fighter.id and other.is_alive())


## Serviteurs que `fighter` peut avoir en même temps : un de plus au rang 5 du passif « Pacte de feu ».
func max_servants(fighter: Fighter) -> int:
	return MAX_SERVANTS + int(int(fighter.passives.get("pacte_de_feu", 0)) > 5)


## Niveau d'embrasement d'une case (0 à `CALCINED`) dans la dimension `shadow` (celle en cours par défaut).
func ember_level(cell: Vector2i, shadow := dimension) -> int:
	return int(embers[int(shadow)].get(cell, {}).get("niveau", 0))


## Somme des niveaux d'embrasement des cases (une calcinée compte `CALCINED`).
func _heat_of(cells: Array[Vector2i]) -> int:
	return cells.reduce(func(total: int, cell: Vector2i) -> int: return total + ember_level(cell), 0)


## Effets d'un sort lancé sur `target` selon l'embrasement de la case : sur une case calcinée, ceux de « calcinee » en plus
## (ou à la place, avec « seuls ») ; valeurs +`EMBER_BONUS` % par niveau (et le « bonus » d'une case calcinée) ; durée
## d'une glyphe à « duree_embrasement » + 1 tour par niveau ; « cendres » : dégâts × somme des niveaux de la zone.
func _ember_variant(spell: Spell, target: Vector2i, zone: Array[Vector2i]) -> Array[Dictionary]:
	if spell.ignites < 0:
		return spell.effects
	var level := ember_level(target)
	var calcined: Dictionary = spell.calcined if level == CALCINED else {}
	var effects: Array[Dictionary] = []
	effects.assign(([] if calcined.get("seuls", false) else spell.effects) + calcined.get("effets", []))
	effects = Spell._scaled_effects(effects, 100 + EMBER_BONUS * level + int(calcined.get("bonus", 0)))
	for effect in effects:
		if effect.get("duree_embrasement", false):
			effect["duree"] = int(effect["duree"]) + level
		if effect["type"] == Spell.EFFECT_ASHES:
			var heat := _heat_of(zone)
			effect.merge({"type": Spell.EFFECT_DAMAGE, "min": int(effect["min"]) * heat, "max": int(effect["max"]) * heat}, true)
	return effects


## Ajoute `amount` niveaux d'embrasement (négatif : retire) aux cases praticables de la zone, dans la dimension de `caster`.
func _ignite(caster: Fighter, cells: Array[Vector2i], amount: int, events: Array[Dictionary]) -> void:
	var changed: Array = []
	for cell in cells if amount != 0 else []:
		if map.is_inside(cell) and map.is_walkable_in_combat(cell):
			var level := clampi(ember_level(cell, caster.shadow) + amount, 0, CALCINED)
			if level == 0:
				embers[int(caster.shadow)].erase(cell)
			else:
				embers[int(caster.shadow)][cell] = {"niveau": level, "equipe": caster.team, "lanceur": caster.id}
			changed.append({"case": cell, "niveau": level})
	if not changed.is_empty():
		events.append({"type": Protocol.EVT_EMBERS, "ombres": caster.shadow, "braises": changed})


## Invoque le serviteur de l'effet sur `cell` : PV en % de ceux du lanceur (+20 % sur une case embrasée au rang 3 du passif), ses
## caractéristiques, ses sorts au rang du sort d'invocation (+1 PM au rang 3, des sorts en plus au rang 5). Il joue juste après
## son maître (et ses autres serviteurs), contrôlé par le même joueur.
func _summon(caster: Fighter, spell: Spell, effect: Dictionary, cell: Vector2i, events: Array[Dictionary]) -> void:
	var spec: Dictionary = effect["serviteur"]
	var servant := Fighter.new()
	servant.id = "%s~%d" % [caster.id, _next_ground_id]
	_next_ground_id += 1
	servant.display_name = spec["nom"]
	servant.kind = spec["id"]
	servant.team = caster.team
	servant.tier = 0
	servant.master = caster.id
	servant.cell = cell
	servant.shadow = caster.shadow
	var pact := int(caster.passives.get("pacte_de_feu", 0))
	servant.max_hp = maxi(1, roundi(caster.max_hp * int(spec["pv"]) / 100.0 * (1.2 if pact > 3 and ember_level(cell) > 0 else 1.0)))
	servant.hp = servant.max_hp
	servant.max_pa = int(spec["pa"])
	servant.max_pm = int(spec["pm"]) + int(spell.rank >= 3)
	servant.stats = caster.stats.duplicate()
	servant.combat_stats = spec.get("stats_combat", {}).duplicate()
	if pact > 0:
		servant.passives["pacte_de_feu"] = pact
	for linked: Spell in spec["liens"] + (spec["liens_rang_5"] if spell.rank >= 5 else []):
		servant.spells.append(linked.mastered(spell.rank))
		if spell.rank > 0:
			servant.masteries[linked.id] = spell.rank
	var index := fighters.find(caster) + 1
	while index < fighters.size() and fighters[index].master == caster.id:
		index += 1
	fighters.insert(index, servant)
	_turn_index += int(index <= _turn_index)
	_arrival[servant] = _arrival.size()
	var shown := servant.to_dict()
	events.append({"type": Protocol.EVT_SUMMONED, "combattant": shown, "ordre": fighters.map(func(f: Fighter) -> String: return f.id)})


## `target` tombe tout de suite (serviteur sacrifié, maître vaincu).
func _kill(target: Fighter, events: Array[Dictionary]) -> void:
	target.hp = 0
	events.append({"type": Protocol.EVT_DIED, "entite": target.id})
	_remove_ground_of(target, events)


## `target` porte-t-il une arme d'obscurité de `caster` ?
func marked_by(target: Fighter, caster: Fighter) -> bool:
	return target.states.any(func(state: Dictionary) -> bool: return state["type"] == Spell.EFFECT_SHADOW_WEAPON and state.get("lanceur") == caster.id)


# --- Paladin : auras, balises et arcs (GDD § 4.3) -------------------------------------------------

## Zone d'un sort : celle de ses données, ou l'aura du lanceur (« zone_aura » ; rayon 1 sans aura).
func spell_zone(fighter: Fighter, spell: Spell, target: Vector2i) -> Array[Vector2i]:
	var aura := aura_of(fighter)
	return Spell.circle_cells(fighter.cell, aura_radius(aura) if not aura.is_empty() else 1) if spell.aura_zone else spell.zone_cells(target, fighter.cell)


func aura_of(fighter: Fighter) -> Dictionary:
	for aura in auras:
		if aura["lanceur"] == fighter:
			return aura
	return {}


## Rayon d'une aura : sa taille, +1 au rang 3 du passif.
func aura_radius(aura: Dictionary) -> int:
	return int(aura["taille"]) + int(int((aura["lanceur"] as Fighter).passives.get(PALADIN_PASSIVE, 0)) >= 4)


func in_aura(aura: Dictionary, fighter: Fighter) -> bool:
	var caster: Fighter = aura["lanceur"]
	return caster.is_alive() and fighter.team == aura["equipe"] and fighter.shadow == caster.shadow \
		and IsoGrid.distance(caster.cell, fighter.cell) <= aura_radius(aura)


## Une nouvelle aura remplace celle du même Paladin.
func _place_aura(caster: Fighter, spell: Spell, effect: Dictionary, events: Array[Dictionary]) -> void:
	if not aura_of(caster).is_empty():
		_end_aura(aura_of(caster), events)
	var aura := {"id": _next_ground_id, "lanceur": caster, "equipe": caster.team, "taille": int(effect["taille"]),
		"tours": int(effect["duree"]) + spell.aura_turns, "effets": effect["effets"], "sort": spell.display_name}
	_next_ground_id += 1
	auras.append(aura)
	events.append({"type": Protocol.EVT_AURA, "id": aura["id"], "lanceur": caster.id, "taille": aura_radius(aura), "sort": aura["sort"]})


func _end_aura(aura: Dictionary, events: Array[Dictionary]) -> void:
	auras.erase(aura)
	events.append({"type": Protocol.EVT_AURA_ENDED, "id": aura["id"]})


## Bonus des auras : chaque allié dedans porte leurs effets (une même aura de deux Paladins ne compte qu'une fois, la plus
## forte), qu'il perd en sortant.
func _refresh_auras(events: Array[Dictionary]) -> void:
	for fighter in fighters:
		var wanted := {}
		for aura in auras if fighter.is_alive() else []:
			for effect: Dictionary in aura["effets"] if in_aura(aura, fighter) else []:
				var key := "%s|%s|%s" % [aura["sort"], effect["carac"], effect.get("element", "")]
				if int(wanted.get(key, {}).get("valeur", -1)) < int(effect["min"]):
					wanted[key] = {"type": effect["type"], "carac": effect["carac"], "element": str(effect.get("element", "")), "valeur": int(effect["min"]),
						"tours": int(aura["tours"]), "sort": aura["sort"], "lanceur": (aura["lanceur"] as Fighter).id, "retirable": false, "aura": true}
		var worn := fighter.states.filter(func(state: Dictionary) -> bool: return state.get("aura", false))
		var signature := func(states: Array) -> Array:
			var keys := states.map(func(state: Dictionary) -> String: return "%s|%s|%s|%d|%d" % [state["sort"], state["carac"], state["element"], state["valeur"], state["tours"]])
			keys.sort()
			return keys
		if signature.call(worn) != signature.call(wanted.values()):
			for state in worn:
				fighter.states.erase(state)
			fighter.states.append_array(wanted.values())
			events.append(_states_event(fighter))


## % de dégâts du passif « Saint Paratonnerre » (5 + rang + 1) pour qui est dans l'aura ou sur un arc d'un Paladin allié.
func paladin_bonus(fighter: Fighter) -> int:
	var best := 0
	for paladin in fighters:
		var rank := int(paladin.passives.get(PALADIN_PASSIVE, 0))
		if rank <= 0 or paladin.team != fighter.team or not paladin.is_alive():
			continue
		var aura := aura_of(paladin)
		if (not aura.is_empty() and in_aura(aura, fighter)) or arcs(paladin).any(func(arc: Dictionary) -> bool:
				return fighter.cell in arc["cases"] and arc["ombres"] == fighter.shadow):
			best = maxi(best, 5 + rank)
	return best


## Balise (de la dimension en cours) sur `cell` ; vide s'il n'y en a pas.
func beacon_at(cell: Vector2i) -> Dictionary:
	for beacon in beacons:
		if beacon_cell(beacon) == cell and beacon["ombres"] == dimension:
			return beacon
	return {}


func beacon_cell(beacon: Dictionary) -> Vector2i:
	return get_fighter(beacon["porteur"]).cell if beacon["porteur"] != "" else beacon["case"]


func max_beacons(fighter: Fighter) -> int:
	return MAX_BEACONS + int(int(fighter.passives.get(PALADIN_PASSIVE, 0)) >= 6)


## Pose une balise (ou fait d'un combattant `carrier` une balise vivante, une seule par Paladin, hors du compte) ; au-delà
## du nombre permis, la plus ancienne part. Les arcs formés frappent aussitôt.
func _place_beacon(caster: Fighter, source: String, effect: Dictionary, cell: Vector2i, carrier: String, events: Array[Dictionary]) -> void:
	var own := beacons.filter(func(beacon: Dictionary) -> bool: return beacon["lanceur"] == caster and (beacon["porteur"] != "") == (carrier != ""))
	if own.size() >= (1 if carrier != "" else max_beacons(caster)):
		_break_beacon(own[0], events)
	var beacon := {"id": _next_ground_id, "lanceur": caster, "equipe": caster.team, "ombres": caster.shadow, "case": cell, "porteur": carrier,
		"tours": int(effect["duree"]), "effets": effect["effets"], "sort": source}
	_next_ground_id += 1
	beacons.append(beacon)
	events.append({"type": Protocol.EVT_BEACON, "id": beacon["id"], "lanceur": caster.id, "equipe": caster.team, "ombres": caster.shadow, "case": cell,
		"porteur": carrier})
	_shock_arcs(caster, events)


func _break_beacon(beacon: Dictionary, events: Array[Dictionary]) -> void:
	beacons.erase(beacon)
	events.append({"type": Protocol.EVT_BEACON_ENDED, "id": beacon["id"]})


## Saut d'éclair : le Paladin et sa balise échangent leurs cases.
func _swap_with_beacon(fighter: Fighter, beacon: Dictionary, events: Array[Dictionary]) -> void:
	var from := fighter.cell
	fighter.cell = beacon["case"]
	beacon["case"] = from
	events.append({"type": Protocol.EVT_TELEPORTED, "entite": fighter.id, "depuis": from, "case": fighter.cell})
	events.append({"type": Protocol.EVT_BEACON, "id": beacon["id"], "lanceur": fighter.id, "equipe": fighter.team, "ombres": beacon["ombres"],
		"case": from, "porteur": ""})
	_shock_arcs(fighter, events)


## Arcs entre deux balises d'un même Paladin (de `caster` seulement s'il est donné), dans la même dimension, alignées sur une
## ligne ou une colonne, à `ARC_LENGTH` cases au plus, sans obstacle entre elles : { id, a, b, equipe, ombres, cases (entre
## les deux) }.
func arcs(caster: Fighter = null) -> Array[Dictionary]:
	var points: Array = beacons.filter(func(beacon: Dictionary) -> bool: return caster == null or beacon["lanceur"] == caster).map(
		func(beacon: Dictionary) -> Dictionary: return beacon.merged({"case": beacon_cell(beacon), "ombres": beacon["ombres"] if beacon["porteur"] == ""
			else get_fighter(beacon["porteur"]).shadow}, true))
	var result: Array[Dictionary] = []
	for link: Dictionary in link_beacons(points, map):
		result.append(link)
	return result


## Arcs entre des balises { id, lanceur, case, ombres } (partagé avec l'affichage du client).
static func link_beacons(points: Array, p_map: GameMap) -> Array:
	var result: Array = []
	for i in points.size():
		for j in range(i + 1, points.size()):
			var a: Dictionary = points[i]
			var b: Dictionary = points[j]
			var gap: int = IsoGrid.distance(a["case"], b["case"])
			if a["lanceur"] != b["lanceur"] or a["ombres"] != b["ombres"] or (a["case"].x != b["case"].x and a["case"].y != b["case"].y) \
					or gap < 2 or gap > ARC_LENGTH:
				continue
			var cells: Array[Vector2i] = []
			for k in range(1, gap):
				cells.append(a["case"] + Spell.direction(a["case"], b["case"]) * k)
			if cells.all(p_map.is_walkable_in_combat):
				result.append({"id": "%d-%d" % [a["id"], b["id"]], "a": a, "b": b, "equipe": a.get("equipe", 0), "ombres": a["ombres"], "cases": cells})
	return result


## Cases des arcs ennemis de `fighter` (dans sa dimension), case → true.
func arc_cells(fighter: Fighter) -> Dictionary:
	var cells := {}
	for arc in arcs() if not beacons.is_empty() else []:
		if arc["equipe"] != fighter.team and arc["ombres"] == fighter.shadow:
			for cell: Vector2i in arc["cases"]:
				cells[cell] = true
	return cells


## Arcs de `fighter` que traverse la ligne d'un sort « projectile » vers `target` (`MAX_ARCS_CROSSED` au plus).
func arcs_crossed(fighter: Fighter, spell: Spell, target: Vector2i) -> int:
	if not spell.projectile or beacons.is_empty():
		return 0
	var line: Array[Vector2i] = []
	LineOfSight.is_clear(fighter.cell, target, func(cell: Vector2i) -> bool:
		line.append(cell)
		return false)
	return mini(MAX_ARCS_CROSSED, arcs(fighter).filter(func(arc: Dictionary) -> bool:
		return arc["ombres"] == fighter.shadow and line.any(func(cell: Vector2i) -> bool: return cell in arc["cases"])).size())


## `fighter` passe par `cells` : il casse les balises ennemies où il entre et prend les coups des arcs ennemis.
func _enter_cells(fighter: Fighter, cells: Array[Vector2i], events: Array[Dictionary]) -> void:
	for cell in cells if not beacons.is_empty() else []:
		var beacon := beacon_at(cell)
		if not beacon.is_empty() and beacon["equipe"] != fighter.team and beacon["porteur"] == "" and beacon["ombres"] == fighter.shadow:
			_break_beacon(beacon, events)
		for arc in arcs():
			if fighter.is_alive() and arc["equipe"] != fighter.team and arc["ombres"] == fighter.shadow and cell in arc["cases"]:
				_shock(arc["a"], fighter, 100, events, arc["id"])


## Les arcs de `caster` frappent les ennemis qui s'y trouvent (une fois par arc et par tour).
func _shock_arcs(caster: Fighter, events: Array[Dictionary]) -> void:
	for arc in arcs(caster):
		for enemy in fighters:
			if enemy.is_alive() and enemy.team != caster.team and enemy.shadow == arc["ombres"] and enemy.cell in arc["cases"]:
				_shock(arc["a"], enemy, 100, events, arc["id"])


## Surtension : les ennemis sur un arc de la balise ou à son contact subissent ses effets × `percent` %.
func _surge(caster: Fighter, beacon: Dictionary, percent: int, events: Array[Dictionary]) -> void:
	var cell := beacon_cell(beacon)
	var cells := Spell.circle_cells(cell, 1)
	for arc in arcs(caster):
		if arc["a"]["id"] == beacon["id"] or arc["b"]["id"] == beacon["id"]:
			cells.append_array(arc["cases"])
	for enemy in fighters.duplicate():
		if enemy.is_alive() and enemy.team != caster.team and enemy.shadow == beacon["ombres"] and enemy.cell in cells:
			_shock(beacon, enemy, percent, events)


## Effets d'une balise sur `victim` (× `percent` %) ; `arc_id` : une seule fois par arc et par tour.
func _shock(beacon: Dictionary, victim: Fighter, percent: int, events: Array[Dictionary], arc_id := "") -> void:
	var key := "%s:%s" % [arc_id, victim.id]
	if not arc_id.is_empty() and _arc_hits.has(key):
		return
	_arc_hits[key] = true
	var caster: Fighter = beacon["lanceur"]
	var outer := _credit
	_open_credit(caster, 1.0)
	var effects: Array[Dictionary] = []
	effects.assign(beacon["effets"])
	for effect in Spell._scaled_effects(effects, percent):
		if victim.is_alive() and Spell.affects(effect, caster, victim):
			_apply_effect(caster, victim, effect, events, false, victim.cell, beacon["sort"])
	_close_credit()
	_credit = outer


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
		if fighter.is_alive() and fighter.master.is_empty():  # Il ne reste que des serviteurs : le camp a perdu.
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
	for fighter in fighters.filter(func(f: Fighter) -> bool: return f.master.is_empty()):
		roster.append({"id": fighter.id, "nom": fighter.display_name, "type": fighter.kind, "palier": fighter.tier,
			"equipe": fighter.team, "vivant": fighter.is_alive()})
	events.append({"type": Protocol.EVT_COMBAT_ENDED, "vainqueur": team, "xp": xp, "tours": maxi(round_number, 1),
		"combattants": roster})


# --- Utilitaires -----------------------------------------------------------------------------

func _command_fighter(command: Dictionary) -> Fighter:
	var fighter_id: Variant = command.get("entite")
	if typeof(fighter_id) != TYPE_STRING:
		return null
	var servant: Variant = command.get("serviteur")  # Démoniste : le joueur fait agir un de ses serviteurs.
	if typeof(servant) == TYPE_STRING:
		var owned := get_fighter(servant)
		return owned if owned != null and owned.master == fighter_id else null
	return get_fighter(fighter_id)


func _plays_before(a: Fighter, b: Fighter) -> bool:
	if a.initiative != b.initiative:
		return a.initiative > b.initiative
	if a.team != b.team:
		return a.team < b.team
	return _arrival[a] < _arrival[b]


## Fonction « cette case bloque-t-elle la vue ? » pour un tir de `shooter`.
func _sight_blocker(shooter: Fighter) -> Callable:
	return _blocks_sight.bind(shooter, true)


func _blocks_sight(cell: Vector2i, shooter: Fighter, fighters_block: bool) -> bool:
	if map.obstacles.has(cell) and map.obstacles[cell] not in SEE_THROUGH_OBSTACLES:
		return true
	var occupant := fighter_at(cell) if fighters_block else null
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
	var own_images: Array = []
	for image in images:
		own_images.append(_ground_snapshot(image))
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
		"images": own_images,
		"auras": auras.map(func(aura: Dictionary) -> Dictionary: return _ground_snapshot(aura)),
		"balises": beacons.map(func(beacon: Dictionary) -> Dictionary: return _ground_snapshot(beacon)),
		"braises": [0, 1].map(func(side: int) -> Array: return embers[side].keys().map(func(cell: Vector2i) -> Dictionary:
			return embers[side][cell].merged({"case": cell}))),
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
			fighter = p_data.create_monster(fighter_state["type"], fighter_id)
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
	for side in 2:
		for ember: Dictionary in saved.get("braises", [[], []])[side]:
			combat.embers[side][ember["case"]] = ember
	var grounds := {"glyphes": combat.glyphs, "pieges": combat.traps, "images": combat.images, "auras": combat.auras, "balises": combat.beacons}
	for kind: String in grounds:
		for ground: Dictionary in saved.get(kind, []):
			var copy := ground.duplicate(true)
			copy["lanceur"] = combat.get_fighter(ground["lanceur"])
			if copy["lanceur"] != null:
				grounds[kind].append(copy)
	return combat
