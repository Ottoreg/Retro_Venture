class_name MapView
extends Node2D
## Affichage d'une carte, dessiné avec des formes simples en attendant les graphismes.
##
## La vue envoie les commandes du joueur au noyau (`World`) et rejoue les événements reçus un par
## un, avec des animations (marche, dégâts…). Elle garde une copie de ce qu'elle affiche (`_actors`),
## mise à jour au fil des événements, pour rester cohérente pendant les animations.

signal hovered_cell_changed(cell: Vector2i, description: String)
signal combat_started
signal combat_state_changed
signal combat_message(text: String)
signal combat_ended(result: Dictionary)
signal exploration_resumed
signal map_changed
signal character_changed
signal level_up(level: int)
## Le joueur parle à un marchand : événement EVT_SHOP.
signal shop_opened(event: Dictionary)
## Résultat d'un achat ou d'une vente : EVT_TRADE, ou EVT_REFUSED.
signal trade_result(event: Dictionary)
## Le joueur parle à un artisan : événement EVT_WORKSHOP.
signal workshop_opened(event: Dictionary)
## Résultat d'une fabrication : EVT_CRAFTED, ou EVT_REFUSED.
signal craft_result(event: Dictionary)
## Message court pour le joueur (récolte impossible, niveau de métier…).
signal notice(text: String)
## Coffre ouvert ou modifié : événement EVT_CHEST.
signal chest_changed(event: Dictionary)
## Refus d'un dépôt ou d'un retrait au coffre : EVT_REFUSED.
signal chest_refused(event: Dictionary)
## Pierre de Passage utilisée : événement EVT_TRAVEL_MENU.
signal travel_opened(event: Dictionary)
signal inventory_changed

enum Mode { EXPLORATION, COMBAT }

## Vitesse de marche, en pixels par seconde.
const WALK_SPEED := 170.0
## Durée de l'animation d'attaque ou de sort.
const ATTACK_TIME := 0.45

const COLOR_GRASS := Color("7aa35a")
const COLOR_BORDER := Color("6a8f4e")
const COLOR_WATER := Color("4f8fb8")
const COLOR_GRID := Color(0, 0, 0, 0.12)
const COLOR_HOVER_OK := Color(1, 1, 1, 0.35)
const COLOR_HOVER_KO := Color(0.9, 0.2, 0.2, 0.45)
const COLOR_PATH := Color(1.0, 0.92, 0.55, 0.85)
const COLOR_SHADOW := Color(0, 0, 0, 0.25)
const COLOR_REACHABLE := Color(0.35, 0.85, 0.35, 0.35)
const COLOR_RANGE := Color(0.3, 0.55, 1.0, 0.4)
const COLOR_RANGE_HIDDEN := Color(0.3, 0.55, 1.0, 0.15)
const COLOR_ZONE := Color(1.0, 0.55, 0.15, 0.55)
const COLOR_PLACEMENT := Color(0.25, 0.5, 1.0, 0.9)
const COLOR_TEAM := [Color(0.25, 0.5, 1.0, 0.8), Color(0.9, 0.25, 0.2, 0.8)]

const NO_CELL := Vector2i(-99999, -99999)
## Place de chaque membre d'un groupe de monstres sur sa case (pixels depuis le centre), selon la
## taille du groupe ; le premier est le meneur, devant.
const GROUP_SPOTS := [
	[Vector2(0, 0)],
	[Vector2(12, 5), Vector2(-16, -5)],
	[Vector2(0, 8), Vector2(-26, -5), Vector2(24, -6)],
]

## Messages affichés pour les refus du noyau.
var _refusals := {
	Protocol.REASON_NOT_ENOUGH_PA: "Pas assez de PA",
	Protocol.REASON_NOT_ENOUGH_PM: "Pas assez de PM",
	Protocol.REASON_OUT_OF_RANGE: "Hors de portée",
	Protocol.REASON_NO_LINE_OF_SIGHT: "Pas de ligne de vue",
	Protocol.REASON_SPELL_LIMIT: "Déjà lancé ce tour-ci",
	Protocol.REASON_SPELL_COOLDOWN: "Sort en recharge",
	Protocol.REASON_OCCUPIED: "Case occupée",
	Protocol.REASON_BLOCKED: "Case bloquée",
	Protocol.REASON_NOT_PLACEMENT_CELL: "Choisissez un cercle bleu",
}

var world: World
var mode: Mode = Mode.EXPLORATION
## Carte affichée. Elle peut être en retard sur `world.map` pendant une marche vers le bord :
## le noyau a déjà changé de carte, l'écran pas encore.
var _map: GameMap
## Sort sélectionné par le joueur en combat (id), ou "".
var selected_spell := ""
## Ordre de jeu (ids) et combattant dont c'est le tour.
var turn_order: Array[String] = []
var current_turn := ""

## Ce qui est affiché : id → { pos: Vector2 (grille), kind, team, name, hp, max_hp, pa, pm, alive, count }.
var _actors: Dictionary = {}
## Apparence de chaque espèce de monstre (voir `_monster_look`).
var _monster_looks: Dictionary = {}
var _hovered := NO_CELL
var _preview: Array[Vector2i] = []
var _placement: Array[Vector2i] = []
var _reachable: Dictionary = {}
var _range_visible: Array[Vector2i] = []
var _range_hidden: Array[Vector2i] = []
## Demi-cases du bord, déjà découpées au rectangle de la carte.
var _border_polygons: Array[PackedVector2Array] = []

# Lecture des événements
var _queue: Array[Dictionary] = []
var _playing := false
var _paused := false
var _wait := 0.0
var _walk_actor := ""
var _walk_path: Array[Vector2i] = []
var _pending_click := NO_CELL
## Temps écoulé (respiration des personnages).
var _time := 0.0
## Commande à envoyer quand la marche en cours se termine (attaque d'un groupe, changement de carte).
var _arrival_command: Dictionary = {}
## Textes flottants : { text, color, pos (Vector2 grille), age }.
var _floating: Array[Dictionary] = []

# Dialogue en cours avec un PNJ : { nom, repliques, index, case }, ou {}.
var _dialogue: Dictionary = {}
var _bubble: PanelContainer
var _bubble_name: Label
var _bubble_text: Label


func setup(p_world: World) -> void:
	world = p_world
	if _bubble == null:
		_build_bubble()
	_load_map(world.map)
	_load_exploration_actors()


func current_map() -> GameMap:
	return _map


func _load_map(map: GameMap) -> void:
	_map = map
	Art.palette = map.palette
	_close_dialogue()
	var rect := _map.screen_rect()
	var rect_polygon := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	_border_polygons.clear()
	for cell in _map.border_cells():
		_border_polygons.append_array(Geometry2D.intersect_polygons(IsoGrid.diamond(IsoGrid.cell_to_screen(cell)), rect_polygon))
	queue_redraw()


func is_busy() -> bool:
	return _playing


func is_player_turn() -> bool:
	return mode == Mode.COMBAT and current_turn == World.PLAYER_ID and not _playing


func is_placement() -> bool:
	return mode == Mode.COMBAT and not _placement.is_empty()


## Valeurs affichées d'un acteur (copie), ou `{}`.
func actor(actor_id: String) -> Dictionary:
	return _actors.get(actor_id, {}).duplicate()


## Combattant du joueur dans le noyau (pour les sorts), ou `null` hors combat.
func player_fighter() -> Fighter:
	if world.combat == null:
		return null
	return world.combat.get_fighter(World.PLAYER_ID)


# --- Actions demandées par l'interface ---------------------------------------------------------

func select_spell(spell_id: String) -> void:
	if not is_player_turn():
		return
	selected_spell = "" if selected_spell == spell_id else spell_id
	_refresh_overlays()


func request_start_fight() -> void:
	if is_placement() and not _playing:
		_send({"type": Protocol.CMD_READY, "entite": World.PLAYER_ID})


func request_end_turn() -> void:
	if is_player_turn():
		selected_spell = ""
		_send({"type": Protocol.CMD_END_TURN, "entite": World.PLAYER_ID})


## Reprend la lecture des événements après l'écran de fin de combat.
func resume() -> void:
	if _paused:
		_paused = false
		_play_next()


# --- Entrées -----------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if world == null:
		return
	if event is InputEventMouseMotion:
		_set_hovered(IsoGrid.screen_to_cell(get_local_mouse_position()))
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if not button.pressed:
			return
		var cell := IsoGrid.screen_to_cell(get_local_mouse_position())
		if button.button_index == MOUSE_BUTTON_LEFT:
			if not _dialogue.is_empty():
				_next_dialogue_line()
			else:
				_on_click(cell)
		elif button.button_index == MOUSE_BUTTON_RIGHT and selected_spell != "":
			selected_spell = ""
			_refresh_overlays()


func _on_click(cell: Vector2i) -> void:
	if mode == Mode.EXPLORATION:
		if not _playing:
			_explore(cell)
		elif _can_interrupt_walk():
			_explore(cell, _walk_path[0])
		else:
			_pending_click = cell
		return
	if _playing or not _map.is_inside(cell):
		return
	if is_placement():
		_send({"type": Protocol.CMD_PLACE, "entite": World.PLAYER_ID, "cible": cell})
	elif is_player_turn():
		if selected_spell != "":
			var spell_id := selected_spell
			selected_spell = ""
			_send({"type": Protocol.CMD_CAST, "entite": World.PLAYER_ID, "sort": spell_id, "cible": cell})
		elif _reachable.has(cell):
			_send({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": cell})


## Commandes d'exploration pour un clic sur `cell` : la marche (ou la discussion avec un PNJ), puis
## éventuellement l'action à faire en arrivant (attaquer un groupe, changer de carte). Cette action
## n'est envoyée qu'à l'arrivée, pour que la marche reste interruptible jusqu'au bout.
func _exploration_commands(cell: Vector2i, from: Vector2i) -> Array[Dictionary]:
	if _map.resource_nodes.has(cell):
		return _harvest_commands(cell, from)
	if _map.obstacles.get(cell, "") in GameMap.FURNITURE:
		return _approach_commands(cell, from, {"type": Protocol.CMD_USE, "entite": World.PLAYER_ID, "case": cell})
	if _map.doors.has(cell):
		var through: Array[Dictionary] = [
			{"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": cell},
			{"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": cell, "porte": true},
		]
		return through
	var npc := _map.npc_at(cell)
	var group := world.group_at(cell)
	var exit := _exit_at(cell)
	var commands: Array[Dictionary] = []
	if not npc.is_empty():
		commands.append({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": npc["id"]})
		return commands
	var target := cell
	if not group.is_empty():
		target = group["case"]
	elif not exit.is_empty():
		target = exit["case"]
	commands.append({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": target})
	if not group.is_empty():
		commands.append({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": group["id"]})
	elif not exit.is_empty():
		commands.append({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": target, "sortie": exit["direction"]})
	return commands


## Récolte : marcher jusqu'à une case qui touche la ressource (ou rester sur place), puis récolter.
## Si la récolte est impossible (niveau de métier, ressource épuisée…), un message l'explique.
func _harvest_commands(cell: Vector2i, from: Vector2i) -> Array[Dictionary]:
	var refusal := world.harvest_refusal(cell)
	if not refusal.is_empty():
		notice.emit(_harvest_refusal_text(refusal, cell))
		var none: Array[Dictionary] = []
		return none
	return _approach_commands(cell, from, {"type": Protocol.CMD_HARVEST, "entite": World.PLAYER_ID, "case": cell})


## Marcher jusqu'à une case qui touche `cell` (ou rester sur place si on y est), puis `action`.
func _approach_commands(cell: Vector2i, from: Vector2i, action: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var target := from
	if not GameMap.is_adjacent(from, cell):
		var path := _map.approach_path(from, cell)
		if path.is_empty():
			notice.emit("Impossible d'y accéder.")
			return commands
		target = path[-1]
	commands.append({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": target})
	commands.append(action)
	return commands


func _harvest_refusal_text(reason: String, cell: Vector2i) -> String:
	var node := world.resource_node(cell)
	if reason == Protocol.REASON_DEPLETED:
		return "%s : déjà récolté, ça repousse." % node.get("nom", "Ressource")
	if reason == Protocol.REASON_JOB_LEVEL:
		var job: Dictionary = world.data.jobs.get(node.get("metier", ""), {})
		return "%s : il faut être %s niveau %d." % [node.get("nom", "Ressource"), job.get("nom", "?"), int(node.get("niveau", 1))]
	if reason == Protocol.REASON_INVENTORY_FULL:
		return "Inventaire plein."
	return "Impossible d'y accéder."


## Clic en exploration. Pendant une marche, `stop` est la case où le joueur termine son pas : il
## repart de là vers la nouvelle cible, et le reste de l'ancien trajet (avec le dialogue, le combat
## ou le changement de carte qui l'attendait) est abandonné.
func _explore(cell: Vector2i, stop := NO_CELL) -> void:
	var commands := _exploration_commands(cell, stop if stop != NO_CELL else world.position_of(World.PLAYER_ID))
	if commands.is_empty():
		return
	var arrival: Dictionary = commands[1] if commands.size() > 1 else {}
	var walk := commands[0]
	if stop != NO_CELL:
		walk["interrompre_a"] = stop
	var events := world.execute(walk)
	if events[0]["type"] == Protocol.EVT_REFUSED:
		if arrival.is_empty() or events[0]["raison"] != Protocol.REASON_ALREADY_THERE:
			return  # Destination impossible : on garde l'éventuelle marche en cours.
		events = world.execute(arrival)  # Déjà sur place : on agit tout de suite.
		arrival = {}
	_arrival_command = arrival
	_preview.clear()
	if stop == NO_CELL:
		_queue.append_array(events)
		_playing = true
		_play_next()
		return
	_walk_path.clear()
	_walk_path.append(stop)
	_queue = events
	_pending_click = NO_CELL


## Vrai si le joueur est en train de marcher en exploration et que rien d'autre n'attend derrière
## sa marche (sinon un dialogue tout au plus) : il peut alors changer de destination en chemin.
func _can_interrupt_walk() -> bool:
	if mode != Mode.EXPLORATION or _walk_actor != World.PLAYER_ID or _walk_path.is_empty():
		return false
	if world.in_combat() or world.map != _map:
		return false
	for event in _queue:
		if event["type"] not in [Protocol.EVT_DIALOGUE, Protocol.EVT_SHOP, Protocol.EVT_WORKSHOP]:
			return false
	return true


## Sortie de carte visée par un clic sur `cell` : { direction, case } ou {}. Un clic sur une case
## du bord ou sur la demi-case juste derrière fait changer de carte.
func _exit_at(cell: Vector2i) -> Dictionary:
	if _map.is_inside(cell):
		var directions := _map.exit_directions(cell)
		if not directions.is_empty() and _map.is_walkable(cell):
			return {"direction": directions[0], "case": cell}
		return {}
	var row := cell.x + cell.y
	var half_column := cell.x - cell.y
	var direction := ""
	if row <= 0:
		direction = "haut"
	elif row >= _map.rows:
		direction = "bas"
	elif half_column <= 0:
		direction = "gauche"
	elif half_column >= 2 * _map.columns:
		direction = "droite"
	if direction.is_empty() or not _map.exits.has(direction):
		return {}
	var target := _map.arrival_cell(GameMap.OPPOSITE_DIRECTION[direction], cell)
	if direction not in _map.exit_directions(target):
		return {}
	return {"direction": direction, "case": target}


## Envoie une commande au noyau et rejoue les événements (pour l'interface : fiche, etc.).
func send_command(command: Dictionary) -> void:
	if not _playing:
		_send(command)


func _send(command: Dictionary) -> void:
	_preview.clear()
	_queue.append_array(world.execute(command))
	if not _playing:
		_playing = true
		_play_next()


func _set_hovered(cell: Vector2i) -> void:
	if cell == _hovered:
		return
	_hovered = cell
	_update_preview()
	hovered_cell_changed.emit(cell, _describe(cell))


func _describe(cell: Vector2i) -> String:
	if mode == Mode.EXPLORATION:
		var exit := _exit_at(cell)
		if not exit.is_empty():
			return "Vers : %s" % world.neighbor_name(exit["direction"])
		if _map.doors.has(cell):
			return "Porte : %s (cliquer pour entrer)" % world.map_name(_map.doors[cell])
		var furniture: String = _map.obstacles.get(cell, "")
		if furniture == "coffre":
			return "Coffre (cliquer pour l'ouvrir)"
		if furniture == "lit":
			return "Lit (cliquer pour dormir : PV au maximum)"
		if furniture == GameMap.TRAVEL_STONE:
			return "Pierre de Passage (cliquer pour voyager)"
		var npc := _map.npc_at(cell)
		if not npc.is_empty():
			var action: String = "commercer" if npc.get("marchand", false) else "fabriquer" if not str(npc.get("atelier", "")).is_empty() else "parler"
			return "%s (cliquer pour %s)" % [npc["nom"], action]
		var node: Dictionary = world.resource_node(cell) if world.map == _map else {}
		if not node.is_empty():
			var job: Dictionary = world.data.jobs.get(node["metier"], {})
			var state: String = "déjà récolté, repousse bientôt" if world.is_depleted(cell) else "cliquer pour récolter"
			return "%s — %s niv. %d (%s)" % [node["nom"], job.get("nom", "?"), int(node.get("niveau", 1)), state]
	if not _map.is_inside(cell):
		return ""
	for actor_id: String in _actors:
		var data: Dictionary = _actors[actor_id]
		if data["alive"] and Vector2i(data["pos"].round()) == cell and actor_id != World.PLAYER_ID:
			if mode == Mode.COMBAT:
				return "%s — %d / %d PV" % [data["name"], data["hp"], data["max_hp"]]
			return data["name"]
	return "case (%d, %d)%s" % [cell.x, cell.y, "" if _map.is_walkable(cell) else " — bloquée"]


func _update_preview() -> void:
	_preview.clear()
	if _playing or not _map.is_inside(_hovered):
		queue_redraw()
		return
	if mode == Mode.EXPLORATION:
		var exit := _exit_at(_hovered)
		var target: Vector2i = exit["case"] if not exit.is_empty() else _hovered
		_preview = _map.find_path(world.position_of(World.PLAYER_ID), target)
	elif is_player_turn() and selected_spell == "" and _reachable.has(_hovered):
		_preview = _reachable[_hovered]
	queue_redraw()


# --- Lecture des événements --------------------------------------------------------------------

func _process(delta: float) -> void:
	# Le temps passe pour le monde : les ressources récoltées repoussent.
	if world != null:
		for event in world.update(delta):
			_apply_world_change(event)
	_time += delta
	for data: Dictionary in _actors.values():
		if data.get("attaque", 0.0) > 0.0:
			data["attaque"] = maxf(0.0, data["attaque"] - delta)
	var kept: Array[Dictionary] = []
	for text in _floating:
		text["age"] += delta
		if text["age"] < 1.0:
			kept.append(text)
	_floating = kept
	if _walk_actor != "":
		_advance_walk(delta)
	elif _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_play_next()
	queue_redraw()  # Les personnages respirent, même à l'arrêt.


## Changements du monde qui ne viennent pas d'une commande (repousse, réapparition) : appliqués
## tout de suite, sans attendre la file d'événements.
func _apply_world_change(event: Dictionary) -> void:
	if event["type"] == Protocol.EVT_GROUP_RESPAWNED and mode == Mode.EXPLORATION and world.map == _map:
		_add_group_actor(event["groupe"])
	queue_redraw()


func _advance_walk(delta: float) -> void:
	var data: Dictionary = _actors[_walk_actor]
	var current: Vector2 = data["pos"]
	var next := Vector2(_walk_path[0])
	var screen_delta := IsoGrid.grid_to_screen(next) - IsoGrid.grid_to_screen(current)
	var distance := screen_delta.length()
	var step := WALK_SPEED * delta
	if absf(screen_delta.x) > 0.5:
		data["facing"] = 1.0 if screen_delta.x > 0.0 else -1.0
	if absf(screen_delta.y) > 0.5:
		data["dos"] = screen_delta.y < 0.0
	data["phase"] += delta * 14.0
	if distance <= step:
		data["pos"] = next
		_walk_path.remove_at(0)
		if _walk_path.is_empty():
			_walk_actor = ""
			_play_next()
	else:
		data["pos"] = current.lerp(next, step / distance)


func _play_next() -> void:
	while not _queue.is_empty() and not _paused:
		var duration := _apply(_queue.pop_front())
		if duration < 0.0 or _paused:
			return  # Marche en cours, ou écran de fin de combat.
		if duration > 0.0:
			_wait = duration
			return
	if _paused:
		return
	_playing = false
	if not _arrival_command.is_empty():
		var command := _arrival_command
		_arrival_command = {}
		_send(command)
		return
	_refresh_overlays()
	if _pending_click != NO_CELL:
		var cell := _pending_click
		_pending_click = NO_CELL
		_on_click(cell)


## Applique un événement à l'affichage ; renvoie la durée d'attente avant le suivant
## (négative pendant une marche).
func _apply(event: Dictionary) -> float:
	var type: String = event["type"]
	if type == Protocol.EVT_MOVED:
		var actor_id: String = event["entite"]
		if event.has("pm") and _actors.has(actor_id):
			_actors[actor_id]["pm"] = event["pm"]
		var path: Array[Vector2i] = event["chemin"]
		if not _actors.has(actor_id) or path.is_empty():
			return 0.0
		_walk_actor = actor_id
		_walk_path = path.duplicate()
		combat_state_changed.emit()
		return -1.0
	if type == Protocol.EVT_DIALOGUE:
		_open_dialogue(event)
		return 0.0
	if type == Protocol.EVT_SHOP:
		shop_opened.emit(event)
		return 0.0
	if type == Protocol.EVT_TRADE:
		trade_result.emit(event)
		return 0.0
	if type == Protocol.EVT_WORKSHOP:
		workshop_opened.emit(event)
		return 0.0
	if type == Protocol.EVT_CRAFTED:
		craft_result.emit(event)
		return 0.0
	if type == Protocol.EVT_HARVESTED:
		var player: Dictionary = _actors[World.PLAYER_ID]
		var toward: float = IsoGrid.cell_to_screen(event["case"]).x - IsoGrid.grid_to_screen(player["pos"]).x
		if absf(toward) > 0.5:
			player["facing"] = signf(toward)
		_add_floating("+%d %s" % [event["quantite"], event["nom"]], Color(0.6, 0.95, 0.5), player["pos"])
		queue_redraw()
		return 0.6
	if type == Protocol.EVT_CHEST:
		chest_changed.emit(event)
		return 0.0
	if type == Protocol.EVT_TRAVEL_MENU:
		travel_opened.emit(event)
		return 0.0
	if type == Protocol.EVT_RESTED:
		if int(event["gain"]) > 0:
			_add_floating("+%d PV" % event["gain"], Color(0.45, 1, 0.45), _actors[World.PLAYER_ID]["pos"])
		notice.emit("Une bonne nuit de sommeil : %d / %d PV." % [event["pv"], event["pv_max"]])
		return 0.6
	if type == Protocol.EVT_JOB:
		for level_reached: int in event["niveaux"]:
			_add_floating("%s niv. %d !" % [event["nom"], level_reached], Color(1, 0.85, 0.3), _actors[World.PLAYER_ID]["pos"] + Vector2(0, -0.6))
			notice.emit("%s niveau %d !" % [event["nom"], level_reached])
		return 0.0
	if type == Protocol.EVT_MAP_CHANGED:
		_load_map(world.map)
		_load_exploration_actors()
		_actors[World.PLAYER_ID]["pos"] = Vector2(event["position"])
		map_changed.emit()
		return 0.15
	if type == Protocol.EVT_TELEPORTED:
		_actors[event["entite"]]["pos"] = Vector2(event["case"])
		return 0.25
	if type == Protocol.EVT_STATUS:
		var affected: Dictionary = _actors[event["entite"]]
		affected["pa"] = event["pa"]
		affected["pm"] = event["pm"]
		var label := "+%d PA" % event["valeur"] if event["effet"] == Spell.EFFECT_GAIN_PA else "-%d PM" % event["valeur"]
		_add_floating(label, Color(0.55, 0.8, 1.0), affected["pos"])
		combat_state_changed.emit()
		return 0.25
	if type == Protocol.EVT_XP:
		return 0.0
	if type == Protocol.EVT_LEVEL_UP:
		if _actors.has(World.PLAYER_ID):
			_add_floating("Niveau %d !" % event["niveau"], Color(1, 0.85, 0.3), _actors[World.PLAYER_ID]["pos"])
		level_up.emit(event["niveau"])
		return 0.6
	if type == Protocol.EVT_CHARACTER:
		character_changed.emit()
		return 0.0
	if type == Protocol.EVT_INVENTORY:
		inventory_changed.emit()
		return 0.0
	if type == Protocol.EVT_REFUSED:
		if event["commande"] == Protocol.CMD_BUY or event["commande"] == Protocol.CMD_SELL:
			trade_result.emit(event)
		if event["commande"] == Protocol.CMD_CRAFT:
			craft_result.emit(event)
		if event["commande"] == Protocol.CMD_DEPOSIT or event["commande"] == Protocol.CMD_WITHDRAW:
			chest_refused.emit(event)
		if event["commande"] == Protocol.CMD_USE:
			notice.emit("Impossible d'utiliser ce meuble d'ici.")
		if event["commande"] == Protocol.CMD_TRAVEL:
			notice.emit("Le voyage est impossible.")
		if event["commande"] == Protocol.CMD_HARVEST:
			notice.emit(_harvest_refusal_text(event["raison"], NO_CELL))
		if mode == Mode.COMBAT and _refusals.has(event["raison"]):
			combat_message.emit(_refusals[event["raison"]])
		return 0.0
	if type == Protocol.EVT_COMBAT_STARTED:
		_close_dialogue()
		_load_combat_actors(event)
		combat_started.emit()
		return 0.3
	if type == Protocol.EVT_PLACED:
		_actors[event["entite"]]["pos"] = Vector2(event["case"])
		return 0.0
	if type == Protocol.EVT_FIGHT_BEGINS:
		_placement.clear()
		turn_order.assign(event["ordre"])
		combat_message.emit("Le combat commence !")
		return 0.4
	if type == Protocol.EVT_TURN_STARTED:
		current_turn = event["entite"]
		var playing: Dictionary = _actors[current_turn]
		playing["pa"] = event["pa"]
		playing["pm"] = event["pm"]
		combat_state_changed.emit()
		if current_turn == World.PLAYER_ID:
			combat_message.emit("À vous de jouer !")
			return 0.0
		return 0.35
	if type == Protocol.EVT_SPELL_CAST:
		var caster: Dictionary = _actors[event["entite"]]
		caster["pa"] = event["pa"]
		combat_state_changed.emit()
		caster["attaque"] = ATTACK_TIME
		_face_toward(caster, Vector2(event["cible"]))
		var spell: Spell = world.data.spells.get(event["sort"])
		if spell != null:
			_add_floating(spell.display_name, Color(1, 0.95, 0.7), caster["pos"])
		return 0.35
	if type == Protocol.EVT_DAMAGE:
		var target: Dictionary = _actors[event["entite"]]
		target["hp"] = event["pv"]
		_add_floating("-%d" % event["valeur"], Color(1, 0.35, 0.3), target["pos"])
		combat_state_changed.emit()
		return 0.25
	if type == Protocol.EVT_HEAL:
		var healed: Dictionary = _actors[event["entite"]]
		healed["hp"] = event["pv"]
		_add_floating("+%d" % event["valeur"], Color(0.45, 1, 0.45), healed["pos"])
		combat_state_changed.emit()
		return 0.25
	if type == Protocol.EVT_DIED:
		_actors[event["entite"]]["alive"] = false
		return 0.3
	if type == Protocol.EVT_COMBAT_ENDED:
		current_turn = ""
		_paused = true
		combat_ended.emit(event)
		return 0.0
	if type == Protocol.EVT_EXPLORATION:
		mode = Mode.EXPLORATION
		selected_spell = ""
		turn_order.clear()
		_load_exploration_actors()
		exploration_resumed.emit()
	return 0.0


func _add_floating(text: String, color: Color, grid_pos: Vector2) -> void:
	_floating.append({"text": text, "color": color, "pos": grid_pos, "age": 0.0})


func _load_exploration_actors() -> void:
	_actors.clear()
	_actors[World.PLAYER_ID] = _new_actor(Vector2(world.position_of(World.PLAYER_ID)), world.player_voie, 0, world.player_name, 1, 1)
	_actors[World.PLAYER_ID]["race"] = world.character.race_id
	for group: Dictionary in world.groups():
		_add_group_actor(group)


func _add_group_actor(group: Dictionary) -> void:
	var monster_ids: Array = group["monstres"]
	var data := _new_actor(Vector2(group["case"]), monster_ids[0], 1, group_label(monster_ids, world.data), 1, 1)
	data["count"] = monster_ids.size()
	data["members"] = monster_ids.duplicate()
	_actors[group["id"]] = data


## Nom affiché d'un groupe : « Loup des collines », ou « Groupe : 2 × Rat des galeries, Grouilleur ».
static func group_label(monster_ids: Array, data: GameData) -> String:
	var counts := {}
	for monster_id: String in monster_ids:
		counts[monster_id] = int(counts.get(monster_id, 0)) + 1
	var parts: PackedStringArray = []
	for monster_id: String in counts:
		var monster_name: String = data.monsters[monster_id]["nom"] if data != null and data.monsters.has(monster_id) else monster_id
		parts.append(monster_name if counts[monster_id] == 1 else "%d × %s" % [counts[monster_id], monster_name])
	if monster_ids.size() == 1:
		return parts[0]
	return "Groupe : %s" % ", ".join(parts)


func _load_combat_actors(event: Dictionary) -> void:
	mode = Mode.COMBAT
	_actors.clear()
	for snapshot: Dictionary in event["combattants"]:
		var data := _new_actor(Vector2(snapshot["case"]), snapshot["type"], snapshot["equipe"], snapshot["nom"], snapshot["pv"], snapshot["pv_max"])
		data["pa"] = snapshot["pa"]
		data["pm"] = snapshot["pm"]
		data["race"] = snapshot.get("race", "")
		_actors[snapshot["id"]] = data
	_placement.assign(event["placement"])
	current_turn = ""
	turn_order.clear()


func _new_actor(pos: Vector2, kind: String, team: int, actor_name: String, hp: int, max_hp: int) -> Dictionary:
	return {"pos": pos, "kind": kind, "team": team, "name": actor_name, "hp": hp, "max_hp": max_hp,
		"pa": 0, "pm": 0, "alive": true, "count": 1, "facing": 1.0, "phase": 0.0, "race": ""}


## Tourne un personnage vers une case (pour attaquer, lancer un sort…).
func _face_toward(data: Dictionary, target: Vector2) -> void:
	var delta := IsoGrid.grid_to_screen(target) - IsoGrid.grid_to_screen(data["pos"])
	if absf(delta.x) > 0.5:
		data["facing"] = signf(delta.x)
	if absf(delta.y) > 0.5:
		data["dos"] = delta.y < 0.0


## Recalcule les zones affichées en combat (déplacement, portée du sort).
func _refresh_overlays() -> void:
	_reachable.clear()
	_range_visible.clear()
	_range_hidden.clear()
	var fighter := player_fighter()
	if is_player_turn() and fighter != null:
		var spell: Spell = fighter.get_spell(selected_spell)
		if spell != null:
			var spell_range := world.combat.spell_range(fighter, spell)
			_range_visible.assign(spell_range["visibles"])
			_range_hidden.assign(spell_range["masquees"])
		else:
			_reachable = world.combat.reachable_cells(fighter)
	combat_state_changed.emit()
	_update_preview()


# --- Dessin ------------------------------------------------------------------------------------

func _draw() -> void:
	if world == null:
		return
	var map := _map
	_draw_ground(map)

	if mode == Mode.COMBAT:
		_draw_placement_markers()
		_draw_cells(_reachable.keys(), COLOR_REACHABLE)
		_draw_cells(_range_hidden, COLOR_RANGE_HIDDEN)
		_draw_cells(_range_visible, COLOR_RANGE)
		var fighter := player_fighter()
		if selected_spell != "" and _hovered in _range_visible and fighter != null:
			var spell: Spell = fighter.get_spell(selected_spell)
			if spell != null:
				_draw_cells(spell.zone_cells(_hovered).filter(func(c: Vector2i) -> bool: return map.is_inside(c)), COLOR_ZONE)
	for cell in _preview:
		draw_colored_polygon(_scaled_diamond(IsoGrid.cell_to_screen(cell), 0.35), COLOR_PATH)
	if map.is_inside(_hovered):
		var color := COLOR_HOVER_OK if map.is_walkable(_hovered) else COLOR_HOVER_KO
		draw_colored_polygon(IsoGrid.diamond(IsoGrid.cell_to_screen(_hovered)), color)

	# Objets en relief et personnages, du fond vers l'avant.
	var drawables: Array = []
	for cell: Vector2i in map.obstacles:
		if map.obstacles[cell] not in GameMap.FLAT_OBSTACLES:
			drawables.append([IsoGrid.depth(Vector2(cell)), "obstacle", cell])
	for actor_id: String in _actors:
		var data: Dictionary = _actors[actor_id]
		if data["alive"]:
			drawables.append([IsoGrid.depth(data["pos"]) + 0.01, "acteur", actor_id])
	if mode == Mode.EXPLORATION:
		for npc in map.npcs:
			drawables.append([IsoGrid.depth(Vector2(npc["case"])) + 0.01, "pnj", npc])
	for decor: Dictionary in map.decors:
		# Un bâtiment passe derrière ce qui se tient devant ses faces visibles.
		var footprint: Array = Art.manifest()["images"].get(decor["image"], {}).get("emprise", [1, 1])
		drawables.append([IsoGrid.depth(Vector2(decor["case"])) - (minf(float(footprint[0]), float(footprint[1])) - 1.0), "decor", decor])
	drawables.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for drawable: Array in drawables:
		if drawable[1] == "acteur":
			_draw_actor(drawable[2])
		elif drawable[1] == "pnj":
			_draw_npc(drawable[2])
		elif drawable[1] == "decor":
			Art.draw(self, drawable[2]["image"], IsoGrid.cell_to_screen(drawable[2]["case"]))
		else:
			_draw_obstacle(drawable[2], map.obstacles[drawable[2]])
	if mode == Mode.EXPLORATION:
		_draw_exit_arrows(map)

	var font := ThemeDB.fallback_font
	for text in _floating:
		var text_pos := IsoGrid.grid_to_screen(text["pos"]) + Vector2(-100, -60 - 30 * text["age"])
		var color: Color = text["color"]
		color.a = 1.0 - maxf(0.0, text["age"] - 0.6) / 0.4
		draw_string_outline(font, text_pos, text["text"], HORIZONTAL_ALIGNMENT_CENTER, 200, 16, 4, Color(0, 0, 0, color.a))
		draw_string(font, text_pos, text["text"], HORIZONTAL_ALIGNMENT_CENTER, 200, 16, color)


## Cases de placement : des cercles bleus (pour ne pas les confondre avec l'eau).
func _draw_placement_markers() -> void:
	for cell in _placement:
		var center := IsoGrid.cell_to_screen(cell)
		draw_colored_polygon(_ellipse(center, 15, 7.5), Color(COLOR_PLACEMENT, 0.3))
		var ring := _ellipse(center, 15, 7.5)
		ring.append(ring[0])
		draw_polyline(ring, COLOR_PLACEMENT, 2.5)


func _draw_cells(cells: Array, color: Color) -> void:
	for cell: Vector2i in cells:
		draw_colored_polygon(IsoGrid.diamond(IsoGrid.cell_to_screen(cell)), color)


func _draw_ground(map: GameMap) -> void:
	var indoor := map.floor_kind == "parquet"
	# Un fond uni (herbe ou plancher) : pas de liseré entre les cases.
	draw_rect(map.screen_rect(), Art.color("bois") if indoor else Art.color("herbe"))
	for polygon in _border_polygons:
		draw_colored_polygon(polygon, Color("2b2118") if indoor else Color(0, 0, 0, 0.12))
	var water: Array[Vector2i] = []
	for cell: Vector2i in map.cells():
		var center := IsoGrid.cell_to_screen(cell)
		if map.obstacles.get(cell) == "eau":
			water.append(cell)
		if indoor:
			Art.draw(self, "parquet", center)
	if not indoor:
		# Taches, touffes, fleurs et cailloux : toujours aux mêmes endroits, décalés des cases.
		for cell: Vector2i in map.cells():
			var pick := posmod(cell.x * 31 + cell.y * 17, 23)
			var offset := Vector2(posmod(cell.x * 13 + cell.y * 7, 21) - 10, posmod(cell.x * 5 + cell.y * 11, 9) - 4)
			var spot := IsoGrid.cell_to_screen(cell) + offset
			if pick < 5:
				Art.draw(self, "tache_claire" if pick % 2 == 0 else "tache_sombre", spot)
			elif pick < 9 and not map.ground.has(cell):
				Art.draw(self, Art.substitute("touffes"), spot)
			elif (pick == 11 or pick == 17) and map.is_walkable(cell) and not map.ground.has(cell):
				Art.draw(self, Art.substitute("fleurs" if pick == 11 else "cailloux"), spot)
	else:
		for cell: Vector2i in map.doors:
			Art.draw(self, "paillasson", IsoGrid.cell_to_screen(cell))
	# Chemins et eau : d'abord les bords, puis l'intérieur (les bords ne restent qu'au contour).
	for cell: Vector2i in map.ground:
		Art.draw(self, "chemin_bord", IsoGrid.cell_to_screen(cell))
	for cell: Vector2i in map.ground:
		Art.draw(self, "chemin", IsoGrid.cell_to_screen(cell))
	for cell in water:
		Art.draw(self, "eau_rive", IsoGrid.cell_to_screen(cell))
	for cell in water:
		Art.draw(self, "eau", IsoGrid.cell_to_screen(cell))
	# La grille n'apparaît qu'en combat, comme dans Dofus.
	if mode == Mode.COMBAT or indoor:
		for cell: Vector2i in map.cells():
			var outline := IsoGrid.diamond(IsoGrid.cell_to_screen(cell))
			outline.append(outline[0])
			draw_polyline(outline, COLOR_GRID)


func _draw_obstacle(cell: Vector2i, kind: String) -> void:
	var base := IsoGrid.cell_to_screen(cell)
	if kind in GameMap.HIDDEN_OBSTACLES:
		return
	if kind == "mur" and _map.floor_kind == "parquet":
		# Dans une maison, les murs du devant sont bas, pour voir l'intérieur.
		var front := not _map.is_walkable(cell + Vector2i(1, 0)) and not _map.is_walkable(cell + Vector2i(0, 1))
		Art.draw(self, "mur_maison_bas" if front else "mur_maison", base)
		return
	if Art.has_image(kind):
		Art.draw(self, kind, base)
		return
	var variants: Array = Art.manifest().get("decor", {}).get(kind, [])
	if not variants.is_empty():
		Art.draw(self, Art.substitute(variants[posmod(cell.x * 5 + cell.y * 3, variants.size())]), base, {}, false, _fade_if_hiding(cell))
		return
	if kind == GameMap.RESOURCE_OBSTACLE:
		_draw_resource(cell, base)
		return
	_draw_block(base, 20, Color.MAGENTA)  # Pas de dessin pour ce type : bien visible pour le corriger.


## Ressource récoltable : arbre ou rocher à minerai, ou ce qu'il en reste en attendant la repousse.
func _draw_resource(cell: Vector2i, base: Vector2) -> void:
	var node: Dictionary = world.resource_node(cell) if world.map == _map else {}
	var manifest := Art.manifest()
	var image: String = manifest.get("ressources", {}).get(_map.resource_nodes.get(cell, ""), "rocher")
	if world.map == _map and world.is_depleted(cell):
		image = manifest.get("epuisees", {}).get(node.get("apparence", "rocher"), "minerai_vide")
	Art.draw(self, image, base, {}, false, _fade_if_hiding(cell))


## Un arbre (ou une ressource) devient transparent quand un personnage se tient juste derrière.
func _fade_if_hiding(cell: Vector2i) -> Color:
	var base := IsoGrid.cell_to_screen(cell)
	for data: Dictionary in _actors.values():
		if not data["alive"]:
			continue
		var feet := IsoGrid.grid_to_screen(data["pos"])
		var reach := 36.0 if data.get("members", []).size() < 2 else 62.0  # Un groupe s'étale sur sa case.
		if IsoGrid.depth(data["pos"]) < IsoGrid.depth(Vector2(cell)) and absf(feet.x - base.x) < reach and feet.y > base.y - 100.0:
			return Color(1, 1, 1, 0.45)
	return Color.WHITE


## Bloc isométrique de hauteur `height` posé sur la case : faces gauche, droite et dessus.
func _draw_block(base: Vector2, height: float, color: Color) -> void:
	var ground := IsoGrid.diamond(base)  # haut, droite, bas, gauche
	var up := Vector2(0, -height)
	draw_colored_polygon(PackedVector2Array([ground[3], ground[2], ground[2] + up, ground[3] + up]), color.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([ground[2], ground[1], ground[1] + up, ground[2] + up]), color.darkened(0.4))
	draw_colored_polygon(PackedVector2Array([ground[0] + up, ground[1] + up, ground[2] + up, ground[3] + up]), color)


func _draw_actor(actor_id: String) -> void:
	var data: Dictionary = _actors[actor_id]
	var base := IsoGrid.grid_to_screen(data["pos"])
	var walking := actor_id == _walk_actor
	var phase: float = data["phase"]
	var facing: float = data["facing"]
	if mode == Mode.COMBAT:
		var ring := _ellipse(base, 18, 9)
		ring.append(ring[0])
		draw_polyline(ring, COLOR_TEAM[clampi(data["team"], 0, 1)], 3.0)
		if actor_id == current_turn:
			draw_colored_polygon(_ellipse(base, 18, 9), Color(1, 1, 1, 0.25))
	var members: Array = data.get("members", [])
	if mode == Mode.EXPLORATION and members.size() > 1:
		# Tout le groupe est visible, serré sur sa case : les plus éloignés d'abord.
		var spots: Array = GROUP_SPOTS[mini(members.size(), GROUP_SPOTS.size()) - 1]
		var order: Array[int] = []
		for i in mini(members.size(), spots.size()):
			order.append(i)
		order.sort_custom(func(a: int, b: int) -> bool: return spots[a].y < spots[b].y)
		for i in order:
			var member_id := "%s_%d" % [actor_id, i]
			var member_facing := facing if i == 0 else (1.0 if posmod(hash(member_id), 2) == 0 else -1.0)
			_draw_figure(member_id, _monster_look(members[i]), members[i], base + spots[i], member_facing, false, 0.0, data)
	else:
		_draw_figure(actor_id, _look_of(actor_id, data), data["kind"], base, facing, walking, phase, data)
	if mode == Mode.COMBAT:
		var ratio := clampf(float(data["hp"]) / maxf(1.0, data["max_hp"]), 0.0, 1.0)
		var bar := Rect2(base + Vector2(-17, -80), Vector2(34, 5))
		draw_rect(bar, Color(0, 0, 0, 0.6))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(0.3, 0.85, 0.3) if ratio > 0.3 else Color(0.9, 0.3, 0.2))


## Dessine un personnage ou un monstre, les pieds en `base`.
func _draw_figure(seed_id: String, look: Dictionary, kind: String, base: Vector2, facing: float, walking: bool, phase: float, data: Dictionary) -> void:
	var offset := float(posmod(hash(seed_id), 100))
	if look.has("rig"):
		var progress := 1.0 - float(data.get("attaque", 0.0)) / ATTACK_TIME if data.get("attaque", 0.0) > 0.0 else -1.0
		Rig.draw(self, look, base, {"facing": facing, "dos": data.get("dos", false), "marche": walking, "phase": phase,
			"temps": _time + offset * 0.1, "attaque": progress})
	elif look.has("image"):
		var hop := -absf(sin(phase)) * 2.0 if walking else sin(_time * 2.0 + offset) * 0.4
		Art.draw(self, look["image"], base + Vector2(0, hop), {}, facing < 0.0, Color.WHITE, look["echelle"])
	else:
		# Pas de dessin pour ce personnage : l'ancienne silhouette.
		var swing := sin(phase) * 3.0 if walking else 0.0
		var body := base + Vector2(0, -absf(sin(phase)) * 2.5 if walking else 0.0)
		if kind.contains("loup"):
			Figures.wolf(self, base, body, facing, swing)
		elif kind.contains("gobelin"):
			Figures.goblin(self, base, body, facing, swing)
		else:
			Figures.blob(self, base, body)


func _draw_npc(npc: Dictionary) -> void:
	var base := IsoGrid.cell_to_screen(npc["case"])
	var npc_id: String = npc["id"]
	var spec: Dictionary = Art.manifest().get("pnj", {}).get(npc_id, {})
	if spec.has("rig"):
		# Le PNJ regarde le joueur.
		var player: Dictionary = _actors.get(World.PLAYER_ID, {})
		var facing := -1.0
		if not player.is_empty():
			facing = 1.0 if IsoGrid.grid_to_screen(player["pos"]).x > base.x else -1.0
		var look := Rig.look(spec["rig"], spec.get("couleurs", {}), spec.get("arme", ""), spec.get("accessoires", []))
		Rig.draw(self, look, base, {"facing": facing, "temps": _time + float(posmod(hash(npc_id), 100)) * 0.1})
	elif npc_id.contains("gobelin"):
		Figures.goblin(self, base, base, -1.0, 0.0)
	else:
		Figures.humanoid(self, base, base, -1.0, 0.0, Color("6b7d3a"), Color("e8c09a"), Color("c9a64a"), "chapeau")
	# Petite bulle « … » : ce personnage a quelque chose à dire.
	var mark := base + Vector2(14, -76)
	draw_circle(mark, 8, Color(1, 1, 1, 0.9))
	draw_arc(mark, 8, 0, TAU, 20, Color(0.23, 0.15, 0.09), 1.2)
	draw_string(ThemeDB.fallback_font, mark + Vector2(-6, 4), "…", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.2, 0.2, 0.2))


## Apparence d'un acteur (joueur ou monstre) d'après `art.json`, gardée dans ses données :
## { rig, couleurs, arme } pour un personnage articulé, { image } pour un monstre dessiné d'un bloc,
## {} s'il n'a pas de dessin.
func _look_of(actor_id: String, data: Dictionary) -> Dictionary:
	if data.has("look"):
		return data["look"]
	var manifest := Art.manifest()
	var look := {}
	var kind: String = data["kind"]
	if actor_id == World.PLAYER_ID or manifest.get("tenues", {}).has(kind) and data["team"] == 0:
		look = Rig.player_look(data.get("race", "humain"), kind, world.data)
	else:
		look = _monster_look(kind)
	data["look"] = look
	return look


## Apparence d'un monstre d'après `art.json` (gardée pour les fois suivantes).
func _monster_look(kind: String) -> Dictionary:
	if _monster_looks.has(kind):
		return _monster_looks[kind]
	var spec: Dictionary = Art.manifest().get("monstres", {}).get(kind, {})
	var look := {}
	if spec.has("image"):
		look = {"image": spec["image"], "echelle": float(spec.get("echelle", 1.0))}
	elif spec.has("rig"):
		look = Rig.look(spec["rig"], spec.get("couleurs", {}), spec.get("arme", ""), spec.get("accessoires", []))
	_monster_looks[kind] = look
	return look


## Flèches au milieu des bords qui mènent à une autre carte.
func _draw_exit_arrows(map: GameMap) -> void:
	var rect := map.screen_rect()
	var center := rect.get_center()
	var arrows := {
		"haut": [Vector2(center.x, 10), Vector2(0, -1)],
		"bas": [Vector2(center.x, rect.end.y - 10), Vector2(0, 1)],
		"gauche": [Vector2(14, center.y), Vector2(-1, 0)],
		"droite": [Vector2(rect.end.x - 14, center.y), Vector2(1, 0)],
	}
	for direction: String in map.exits:
		if not arrows.has(direction):
			continue
		var tip: Vector2 = arrows[direction][0]
		var forward: Vector2 = arrows[direction][1]
		var side := Vector2(-forward.y, forward.x)
		var points := PackedVector2Array([tip + forward * 9, tip - forward * 7 + side * 10, tip - forward * 7 - side * 10])
		draw_colored_polygon(points, Color(1, 0.85, 0.3, 0.9))
		points.append(points[0])
		draw_polyline(points, Color(0.3, 0.2, 0.05), 2.0)


# --- Bulle de dialogue -------------------------------------------------------------------------

func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.98, 0.92, 0.96)
	style.border_color = Color(0.35, 0.25, 0.12)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	_bubble.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(box)
	_bubble_name = Label.new()
	_bubble_name.add_theme_color_override("font_color", Color(0.55, 0.3, 0.05))
	_bubble_name.add_theme_font_size_override("font_size", 15)
	_bubble_text = Label.new()
	_bubble_text.custom_minimum_size = Vector2(300, 0)
	_bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_text.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1))
	_bubble_text.add_theme_font_size_override("font_size", 15)
	var hint := Label.new()
	hint.text = "(cliquez pour continuer)"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35))
	hint.add_theme_font_size_override("font_size", 12)
	for label: Label in [_bubble_name, _bubble_text, hint]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
	_bubble.visible = false
	add_child(_bubble)


func _open_dialogue(event: Dictionary) -> void:
	_dialogue = {"nom": event["nom"], "repliques": event["repliques"], "index": 0, "case": event["case"]}
	_show_dialogue_line()


func _next_dialogue_line() -> void:
	_dialogue["index"] += 1
	if _dialogue["index"] >= _dialogue["repliques"].size():
		_close_dialogue()
	else:
		_show_dialogue_line()


func _show_dialogue_line() -> void:
	_bubble_name.text = _dialogue["nom"]
	_bubble_text.text = _dialogue["repliques"][_dialogue["index"]]
	_bubble.visible = true
	_bubble.reset_size()
	var bubble_size := _bubble.get_combined_minimum_size()
	var anchor := IsoGrid.cell_to_screen(_dialogue["case"]) + Vector2(0, -68)
	var top_left := anchor - Vector2(bubble_size.x / 2.0, bubble_size.y)
	var max_x := _map.screen_rect().size.x - bubble_size.x
	_bubble.position = Vector2(clampf(top_left.x, 0.0, maxf(max_x, 0.0)), maxf(top_left.y, -60.0))


func _close_dialogue() -> void:
	_dialogue = {}
	if _bubble != null:
		_bubble.visible = false


func _scaled_diamond(center: Vector2, scale_factor: float) -> PackedVector2Array:
	var points := IsoGrid.diamond(Vector2.ZERO)
	for i in points.size():
		points[i] = center + points[i] * scale_factor
	return points


func _ellipse(center: Vector2, radius_x: float, radius_y: float) -> PackedVector2Array:
	return Figures.ellipse(center, radius_x, radius_y)
