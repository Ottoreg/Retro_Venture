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
## Ligne de l'historique de combat (BBCode : dégâts, soins et boucliers à la couleur de leur élément),
## au moment où l'événement est joué.
signal combat_logged(line: String)
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
## Un PNJ propose une quête : événement EVT_QUEST_OFFER.
signal quest_offered(event: Dictionary)
## Journal des quêtes changé (voir `QuestBook.sheet`).
signal quests_changed(journal: Dictionary)
## Quête terminée : événement EVT_QUEST_DONE.
signal quest_done(event: Dictionary)
## Progression à sauvegarder sans changement de la fiche : Pierre de Passage découverte, nouveau
## point de résurrection.
signal progress_changed

enum Mode { EXPLORATION, COMBAT }

## Vitesse de marche, en pixels par seconde.
const WALK_SPEED := 170.0
## Les groupes de monstres se promènent plus lentement que le joueur ne marche.
const GROUP_WALK_SPEED := 70.0
## Durée de l'animation d'attaque ou de sort.
const ATTACK_TIME := 0.45
## Durée de vie d'un texte flottant, en secondes (il s'efface pendant les 0,4 dernières).
const FLOATING_LIFE := 1.0
## Celle du message d'un changement de phase, plus long à lire.
const PHASE_FLOATING_LIFE := 2.5
## Temps rattrapé au plus après une absence (fenêtre sans focus ou cachée), en secondes.
const MAX_CATCH_UP := 600.0

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
## Glyphes au sol, selon l'équipe de leur lanceur (alliée, ennemie).
const COLOR_GLYPH := [Color(0.45, 0.75, 1.0, 0.3), Color(0.55, 0.95, 0.3, 0.34)]
const COLOR_GLYPH_EDGE := [Color(0.55, 0.8, 1.0, 0.8), Color(0.65, 0.95, 0.4, 0.8)]
const COLOR_TRAP := Color(0.35, 0.22, 0.12, 0.85)
## Mode tactique : cases claires et foncées en damier, obstacles qui bloquent la vue (blocs) ou
## seulement le passage (eau : à plat), pions des deux camps.
const TACTICAL_BACKGROUND := Color("1d1914")
const TACTICAL_CELLS := [Color("8f8a78"), Color("7f7a69")]
const TACTICAL_BLOCK := Color("4a4038")
const TACTICAL_WATER := Color("3f6f93")
const TACTICAL_EDGE := Color(0, 0, 0, 0.35)
const COLOR_TRAP_FLASH := Color(1.0, 0.45, 0.1, 0.6)
## Noms affichés des caractéristiques modifiées par un bonus ou un malus.
const CARAC_NAMES := {"force": "Force", "intelligence": "Intelligence", "chance": "Chance", "agilite": "Agilité",
	"pa": "PA", "pm": "PM", "portee": "Portée", "dommages": "Dommages", "critique": "% Critique", "resistance": "Rés."}

const NO_CELL := Vector2i(-99999, -99999)
## Haut de l'écran sous le bandeau du haut (pixels) : une bulle de dialogue ne monte pas plus haut.
const DIALOGUE_TOP := 70.0
## Garde-fou de la lecture des événements (voir `_watch_playback`), en secondes.
const STALL_LIMIT := 1.0
## Actions que le joueur peut prévoir pendant une animation de son tour (voir `_plan`).
const PLANNED_LIMIT := 5
const COLOR_PLANNED := Color(1.0, 0.85, 0.3, 0.55)
## Écart (secondes) entre deux textes flottants qui apparaissent au même endroit en même temps.
const FLOATING_STAGGER := 0.2
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
	Protocol.REASON_NOT_IN_LINE: "Lancer en ligne uniquement",
	Protocol.REASON_SPELL_LIMIT: "Déjà lancé ce tour-ci",
	Protocol.REASON_SPELL_COOLDOWN: "Sort en recharge",
	Protocol.REASON_OCCUPIED: "Case occupée",
	Protocol.REASON_BLOCKED: "Case bloquée",
	Protocol.REASON_NOT_PLACEMENT_CELL: "Choisissez un cercle bleu",
	Protocol.REASON_NO_COMBINATION: "Il faut 3 états élémentaires (Composition) pour créer un sort",
	Protocol.REASON_INVALID_COMPOSITION: "Choisissez une combinaison d'états",
}
## Messages affichés pour les objets qu'on ne peut pas équiper.
var _equip_refusals := {
	Protocol.REASON_REQUIREMENTS: "Niveau ou caractéristiques insuffisants pour porter cet objet.",
	Protocol.REASON_ALREADY_WORN: "Vous portez déjà un exemplaire de cet objet.",
	Protocol.REASON_NOT_EQUIPPABLE: "Cet objet ne va pas à cet emplacement.",
}
## Messages affichés pour les voyages refusés (les autres refus : « Le voyage est impossible. »).
var _travel_refusals := {
	Protocol.REASON_NOT_ENOUGH_ECUS: "Pas assez d'écus pour ce voyage.",
	Protocol.REASON_PASSAGE_UNKNOWN: "Pierre de Passage pas encore découverte : allez-y à pied et touchez-la.",
}

var world: World
var mode: Mode = Mode.EXPLORATION
## Vue simplifiée en combat (GDD § 14.3), retenue d'un combat à l'autre dans `Options`.
var tactical: bool:
	get:
		return Options.tactical
	set(value):
		Options.tactical = value
		Options.save_options()
		queue_redraw()
## Carte affichée. Elle peut être en retard sur `world.map` pendant une marche vers le bord :
## le noyau a déjà changé de carte, l'écran pas encore.
var _map: GameMap
## Sort sélectionné par le joueur en combat (id), ou "".
var selected_spell := ""
## Ordre de jeu (ids) et combattant dont c'est le tour.
var turn_order: Array[String] = []
var current_turn := ""

## Ce qui est affiché : id → { pos: Vector2 (grille), kind, team, name, hp, max_hp, pa, pm, alive, count }
## (et pour un groupe en exploration, `members` et `levels` : ses monstres et leurs niveaux).
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
var _stall_time := 0.0
var _paused := false
var _wait := 0.0
var _walk_actor := ""
var _walk_path: Array[Vector2i] = []
## Groupes de monstres en promenade (indépendamment de la file d'événements) : id → cases restantes.
var _group_walks: Dictionary = {}
var _pending_click := NO_CELL
## Actions prévues pendant son tour en combat, envoyées une à une dès que la lecture des événements
## est finie (commandes du noyau : sort, déplacement, fin du tour).
var _planned: Array[Dictionary] = []
## Temps écoulé (respiration des personnages).
var _time := 0.0
## Commande à envoyer quand la marche en cours se termine (attaque d'un groupe, changement de carte).
var _arrival_command: Dictionary = {}
## Textes flottants : { text, color, pos (Vector2 grille), age, life } (`life` : durée de vie).
var _floating: Array[Dictionary] = []
## Glyphes visibles : id → { cases: Array[Vector2i], equipe, sort, lanceur }.
var _glyphs: Dictionary = {}
## Pièges de l'équipe du joueur (les autres sont invisibles) : id → { case, sort, lanceur }.
var _traps: Dictionary = {}
## Explosion d'un piège en cours d'affichage : { cases, age }, ou {}.
var _trap_flash: Dictionary = {}
## Pierre de Passage tout juste découverte (id), pour annoncer en une fois qu'elle devient aussi le
## point de résurrection.
var _discovered_passage := ""

# Dialogue en cours avec un PNJ : { nom, repliques, index, case }, ou {}.
var _dialogue: Dictionary = {}
var _bubble: PanelContainer
var _bubble_name: Label
var _bubble_text: Label
## Cases de sortie praticables de la carte, par direction (voir `GameMap.exit_cells`).
var _exit_cells: Dictionary = {}
## Instant de l'image précédente (µs), pour rattraper le temps réel (voir `_real_delta`).
var _last_tick_usec := -1


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
	_exit_cells = _map.exit_cells()
	queue_redraw()


func is_busy() -> bool:
	return _playing


func is_player_turn() -> bool:
	return mode == Mode.COMBAT and current_turn == World.PLAYER_ID and not _playing


## C'est le tour du joueur à l'écran : il peut choisir un sort et prévoir ses actions, même pendant
## l'animation des précédentes (elles partiront dans l'ordre, voir `_plan`).
func can_plan() -> bool:
	return mode == Mode.COMBAT and current_turn == World.PLAYER_ID and not _paused


## Actions prévues (copie), pour l'interface et les tests.
func planned_actions() -> Array[Dictionary]:
	return _planned.duplicate()


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
	if not can_plan():
		return
	selected_spell = "" if selected_spell == spell_id else spell_id
	_refresh_overlays()


## Lance un sort de composition des états (`Spell.state_choices`) avec la combinaison `states`
## (« flamme+flamme+givre ») choisie dans la grille : sur la case du joueur, tout de suite ou après
## l'animation en cours.
func cast_composition(spell_id: String, states: String) -> void:
	if not can_plan() or player_fighter() == null:
		return
	selected_spell = ""
	var command := {"type": Protocol.CMD_CAST, "entite": World.PLAYER_ID, "sort": spell_id, "etats": states}
	if _playing:
		_plan(command)  # Case visée à l'envoi : le joueur a pu se déplacer d'ici là.
	else:
		command["cible"] = player_fighter().cell
		_send(command)
	_refresh_overlays()


func request_start_fight() -> void:
	if is_placement() and not _playing:
		_send({"type": Protocol.CMD_READY, "entite": World.PLAYER_ID})


func request_end_turn() -> void:
	if is_player_turn():
		selected_spell = ""
		_send({"type": Protocol.CMD_END_TURN, "entite": World.PLAYER_ID})
	elif can_plan() and _playing:
		selected_spell = ""
		_plan({"type": Protocol.CMD_END_TURN, "entite": World.PLAYER_ID})
		_refresh_overlays()


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
		elif button.button_index == MOUSE_BUTTON_RIGHT and not _planned.is_empty():
			_planned.clear()
			combat_message.emit("Actions prévues annulées")
			queue_redraw()


func _on_click(cell: Vector2i) -> void:
	if mode == Mode.EXPLORATION:
		if not _playing:
			_explore(cell)
		elif _can_interrupt_walk():
			_explore(cell, _walk_path[0])
		else:
			_pending_click = cell
		return
	if not _map.is_inside(cell):
		return
	if _playing:
		# Pendant l'animation de son tour : l'action est gardée pour plus tard.
		if can_plan() and selected_spell != "":
			var planned_spell := selected_spell
			selected_spell = ""
			_plan({"type": Protocol.CMD_CAST, "entite": World.PLAYER_ID, "sort": planned_spell, "cible": cell})
			_refresh_overlays()
		elif can_plan():
			_plan({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": cell})
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


## Garde une action du joueur pour la fin de la lecture des événements (sorts enchaînés). Le noyau
## la juge à son envoi : un sort devenu impossible est refusé avec son message. Rien après une fin
## du tour.
func _plan(command: Dictionary) -> void:
	if _planned.size() >= PLANNED_LIMIT:
		combat_message.emit("Trop d'actions prévues")
		return
	if not _planned.is_empty() and _planned.back()["type"] == Protocol.CMD_END_TURN:
		return
	_planned.append(command)
	queue_redraw()


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
	if not group.is_empty() and world.character.inventory.is_overloaded():
		notice.emit(CombatHud.OVERLOAD_TEXT)
		return commands
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
		if event["type"] not in [Protocol.EVT_DIALOGUE, Protocol.EVT_SHOP, Protocol.EVT_WORKSHOP, Protocol.EVT_QUEST_OFFER, Protocol.EVT_QUESTS]:
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


## Rang d'ancienneté de l'élite du groupe sur cette case (0 s'il n'y en a pas), en exploration.
func hovered_cell() -> Vector2i:
	return _hovered


func elite_rank_at(cell: Vector2i) -> int:
	if mode != Mode.EXPLORATION:
		return 0
	for actor_id: String in _actors:
		var data: Dictionary = _actors[actor_id]
		if data["alive"] and actor_id != World.PLAYER_ID and Vector2i(data["pos"].round()) == cell:
			return world.elite_rank(world.group(actor_id))
	return 0


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
	var ground := ground_description(cell) if mode == Mode.COMBAT else ""
	for actor_id: String in _actors:
		var data: Dictionary = _actors[actor_id]
		if data["alive"] and Vector2i(data["pos"].round()) == cell and actor_id != World.PLAYER_ID:
			if mode == Mode.COMBAT:
				return "%s — %d / %d PV%s" % [data["name"], data["hp"], data["max_hp"], "\n" + ground if ground != "" else ""]
			var text := group_lines(data.get("members", [data["kind"]]), world.data, data.get("levels", []))
			var rank := world.elite_rank(world.group(actor_id))
			if rank > 0:
				text += "\nButin : +%d %%" % roundi(rank * World.ELITE_LOOT_BONUS_PER_RANK * 100.0)
			return text
	if ground != "":
		return ground
	var walkable := _map.is_walkable_in_combat(cell) if mode == Mode.COMBAT else _map.is_walkable(cell)
	return "case (%d, %d)%s" % [cell.x, cell.y, "" if walkable else " — bloquée"]


## Glyphes et pièges visibles sur la case : nom du sort, qui l'a lancé et dans quel camp (une ligne
## chacun ; "" s'il n'y en a pas). Les pièges ennemis restent invisibles.
func ground_description(cell: Vector2i) -> String:
	var lines: PackedStringArray = []
	for glyph_id: int in _glyphs:
		var glyph: Dictionary = _glyphs[glyph_id]
		if cell in glyph["cases"]:
			var turns := ""
			if world.combat != null:
				for state: Dictionary in world.combat.glyphs:
					if state["id"] == glyph_id:
						turns = ", encore %d tour%s" % [state["tours"], "s" if int(state["tours"]) > 1 else ""]
			lines.append("Glyphe %s : %s, lancée par %s%s" % [_camp_word(int(glyph["equipe"]), true), glyph["sort"],
				_actor_name(glyph["lanceur"]), turns])
	for trap: Dictionary in _traps.values():
		if trap["case"] == cell:
			lines.append("Piège allié : %s, posé par %s" % [trap["sort"], _actor_name(trap["lanceur"])])
	return "\n".join(lines)


func _camp_word(team: int, feminine := false) -> String:
	if team == Fighter.TEAM_PLAYERS:
		return "alliée" if feminine else "allié"
	return "ennemie" if feminine else "ennemi"


func _actor_name(actor_id: String) -> String:
	return str(_actors[actor_id]["name"]) if _actors.has(actor_id) else "?"


# --- Historique de combat --------------------------------------------------------------------------

const LOG_GREY := "a89c86"
const LOG_SPELL := "ffe9a0"
const LOG_BONUS := "8cd9ff"
const LOG_MALUS := "d99cff"
const LOG_DEATH := "ff6a5a"


## Ligne d'historique d'un événement de combat, en BBCode ("" : rien à noter). Dégâts, soins,
## boucliers et poisons prennent la couleur de leur élément.
func _log_line(event: Dictionary) -> String:
	var type: String = event["type"]
	var who := _actor_name(str(event.get("entite", "")))
	match type:
		Protocol.EVT_FIGHT_BEGINS:
			return "[b]Le combat commence ![/b]"
		Protocol.EVT_TURN_STARTED:
			return "[color=#%s]— Tour de %s —[/color]" % [LOG_GREY, who]
		Protocol.EVT_SPELL_CAST:
			var spell: Spell = world.data.spells.get(event["sort"])
			var spell_name: String = spell.display_name if spell != null else str(event["sort"])
			return "%s lance [color=#%s]%s[/color]%s" % [who, LOG_SPELL, spell_name,
				" — [color=#ff9a3c]coup critique ![/color]" if event.get("critique", false) else ""]
		Protocol.EVT_DAMAGE:
			var element: String = event.get("element", "")
			var text := "%s perd %s" % [who, _colored("%d PV" % event["valeur"], element)]
			if not element.is_empty():
				text += " " + _colored("(%s)" % SpellsWindow.ELEMENT_LABELS.get(element, element), element)
			if int(event.get("absorbe", 0)) > 0:
				text += ", %d absorbés par le bouclier" % event["absorbe"]
			if event.get("source", "") == "poison":
				text += " — poison"
			elif event.get("source", "") == "choc":
				text += " — choc contre un obstacle"
			return text
		Protocol.EVT_HEAL:
			return "%s récupère %s" % [who, _colored("%d PV" % event["valeur"], event.get("element", ""))]
		Protocol.EVT_STATUS:
			if event["effet"] == Spell.EFFECT_SHIELD:
				return "%s gagne %s" % [who, _colored("%d de bouclier" % event["valeur"], event.get("element", ""))]
			if event["effet"] == Spell.EFFECT_GAIN_PA:
				return "%s gagne [color=#%s]%d PA[/color]" % [who, LOG_BONUS, event["valeur"]]
			return "%s perd [color=#%s]%d PM[/color] au prochain tour" % [who, LOG_MALUS, event["valeur"]]
		Protocol.EVT_STATES:
			if event.has("retires"):
				return "%s : [color=#%s]%d état%s retiré%s[/color]" % [who, LOG_SPELL, event["retires"],
					"s" if int(event["retires"]) > 1 else "", "s" if int(event["retires"]) > 1 else ""]
			if not event.has("nouveau"):
				return ""
			var state: Dictionary = event["nouveau"]
			var color: String = LOG_BONUS if state["type"] == Spell.EFFECT_BONUS else LOG_MALUS
			if state["type"] == Spell.EFFECT_POISON:
				color = _element_hex(state["element"])
			var origin := " (%s)" % state["sort"] if str(state.get("sort", "")) != "" else ""
			return "%s : [color=#%s]%s[/color]%s" % [who, color, state_text(state), origin]
		Protocol.EVT_PUSHED:
			return "%s est déplacé de force" % who
		Protocol.EVT_CHARGED:
			return "%s charge%s" % [who, " jusqu'au contact !" if event["contact"] else ", mais s'arrête avant le contact"]
		Protocol.EVT_ELEMENT_STATES:
			if event.get("composition", false):
				var colored: PackedStringArray = []
				for element: String in event["etats"]:
					colored.append(_colored(SpellsWindow.ELEMENT_LABELS.get(element, element), element))
				return "%s compose ses états : %s" % [who, " · ".join(colored)]
			return "%s prend l'état %s (%s)" % [who, _colored(SpellsWindow.ELEMENT_LABELS.get(event["element"], event["element"]),
				event["element"]), element_states_text(event["etats"])]
		Protocol.EVT_SPELL_CREATED:
			var created: Spell = world.data.spells.get(event["sort"])
			var text := "%s crée le sort [color=#%s]%s[/color]" % [who, LOG_SPELL, created.display_name if created != null else event["sort"]]
			var removed: Spell = world.data.spells.get(str(event.get("ancien", "")))
			if removed != null:
				text += ", qui remplace %s" % removed.display_name
			return text
		Protocol.EVT_TELEPORTED:
			return "%s se téléporte" % who
		Protocol.EVT_GLYPH:
			return "%s pose la glyphe [color=#%s]%s[/color] (%d tours)" % [_actor_name(event["lanceur"]), LOG_SPELL,
				event["sort"], event["tours"]]
		Protocol.EVT_TRAP:
			if event["equipe"] != Fighter.TEAM_PLAYERS:
				return ""  # Un piège ennemi reste secret.
			return "%s pose le piège [color=#%s]%s[/color]" % [_actor_name(event["lanceur"]), LOG_SPELL, event["sort"]]
		Protocol.EVT_TRAP_TRIGGERED:
			return "%s déclenche le piège [color=#%s]%s[/color] !" % [who, LOG_SPELL, event["sort"]]
		Protocol.EVT_PHASE:
			return "[color=#ff73d9]%s[/color]" % event["message"]
		Protocol.EVT_DIED:
			return "[color=#%s]%s est vaincu.[/color]" % [LOG_DEATH, who]
		Protocol.EVT_COMBAT_ENDED:
			return "[b]%s[/b]" % ("Victoire !" if event["vainqueur"] == Fighter.TEAM_PLAYERS else "Défaite…")
	return ""


## Couleur d'un élément (celle de la fenêtre des sorts), ou `fallback` sans élément (choc).
static func element_color(element: String, fallback := Color.WHITE) -> Color:
	return SpellsWindow.ELEMENT_COLORS.get(element, fallback)


static func _element_hex(element: String) -> String:
	return element_color(element).to_html(false)


static func _colored(text: String, element: String) -> String:
	return "[color=#%s]%s[/color]" % [_element_hex(element), text]


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
	advance(_real_delta(delta))


## Temps réel écoulé depuis l'image précédente. Godot plafonne le `delta` d'une image (~0,13 s) et
## le navigateur ralentit ou suspend le jeu quand sa fenêtre perd le focus ou est cachée : sans ce
## rattrapage, le monde (marches, combats, repousse, régénération) s'arrêtait avec lui. Au retour,
## le temps perdu est rattrapé (au plus MAX_CATCH_UP secondes). Le menu pause, lui, arrête le temps.
func _real_delta(delta: float) -> float:
	var now := Time.get_ticks_usec()
	var elapsed := delta
	if _last_tick_usec != -1:
		elapsed = clampf((now - _last_tick_usec) / 1000000.0, delta, MAX_CATCH_UP)
	_last_tick_usec = now
	return elapsed


func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED:
		_last_tick_usec = -1  # Le temps passé dans le menu pause ne compte pas.


## Fait avancer le monde et l'affichage de `delta` secondes.
func advance(delta: float) -> void:
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
		if text["age"] < text["life"]:
			kept.append(text)
	_floating = kept
	if not _trap_flash.is_empty():
		_trap_flash["age"] += delta
		if _trap_flash["age"] > 0.6:
			_trap_flash = {}
	for group_id: String in _group_walks.keys():
		if not _actors.has(group_id) or _step_along(_actors[group_id], _group_walks[group_id], delta, GROUP_WALK_SPEED):
			_group_walks.erase(group_id)
	if _walk_actor != "" and (not _actors.has(_walk_actor) or _walk_path.is_empty()):
		push_error("Marche sans chemin (%s) : on passe à l'événement suivant." % _walk_actor)
		_walk_actor = ""
		_play_next()
	if _walk_actor != "":
		_advance_walk(delta)
	elif _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_play_next()
	_watch_playback(delta)
	queue_redraw()  # Les personnages respirent, même à l'arrêt.


## Garde-fou : la lecture des événements ne doit jamais rester « en cours » sans rien attendre
## (ni marche, ni délai, ni écran de fin). Si c'est le cas (une erreur l'a interrompue en route),
## elle repart au bout de STALL_LIMIT secondes, avec un message dans la console du navigateur.
func _watch_playback(delta: float) -> void:
	if _playing and not _paused and _walk_actor == "" and _wait <= 0.0:
		_stall_time += delta
		if _stall_time >= STALL_LIMIT:
			push_error("Lecture des événements bloquée (%d en attente) : reprise." % _queue.size())
			_stall_time = 0.0
			_play_next()
	else:
		_stall_time = 0.0


## Changements du monde qui ne viennent pas d'une commande (repousse, réapparition) : appliqués
## tout de suite, sans attendre la file d'événements.
func _apply_world_change(event: Dictionary) -> void:
	if event["type"] == Protocol.EVT_GROUP_RESPAWNED and mode == Mode.EXPLORATION and world.map == _map:
		_add_group_actor(event["groupe"])
	elif event["type"] == Protocol.EVT_GROUP_MOVED and mode == Mode.EXPLORATION and world.map == _map and _actors.has(event["groupe"]):
		var path: Array[Vector2i] = event["chemin"]
		_group_walks[event["groupe"]] = path.duplicate()
	queue_redraw()


func _advance_walk(delta: float) -> void:
	if _step_along(_actors[_walk_actor], _walk_path, delta, WALK_SPEED):
		_walk_actor = ""
		_play_next()


## Avance un personnage le long de `path` (les cases atteintes en sont retirées) ; vrai à l'arrivée.
## Un long `delta` (temps rattrapé) fait franchir plusieurs cases d'un coup.
func _step_along(data: Dictionary, path: Array[Vector2i], delta: float, speed: float) -> bool:
	var step := speed * delta
	data["phase"] += delta * 14.0 * speed / WALK_SPEED
	while true:
		var current: Vector2 = data["pos"]
		var next := Vector2(path[0])
		var screen_delta := IsoGrid.grid_to_screen(next) - IsoGrid.grid_to_screen(current)
		var distance := screen_delta.length()
		if absf(screen_delta.x) > 0.5:
			data["facing"] = 1.0 if screen_delta.x > 0.0 else -1.0
		if absf(screen_delta.y) > 0.5:
			data["dos"] = screen_delta.y < 0.0
		if distance > step:
			data["pos"] = current.lerp(next, step / distance)
			return false
		step -= distance
		data["pos"] = next
		path.remove_at(0)
		if path.is_empty():
			return true
	return true


func _play_next() -> void:
	while not _queue.is_empty() and not _paused:
		var duration := _apply(_queue.pop_front())
		if duration < 0.0 or _paused:
			return  # Marche en cours, ou écran de fin de combat.
		# Pendant son tour, le joueur n'attend pas la fin des textes et des animations de ses sorts :
		# ils continuent pendant qu'il joue (seules ses marches se lisent jusqu'au bout).
		if duration > 0.0 and not (mode == Mode.COMBAT and current_turn == World.PLAYER_ID):
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
	if not _planned.is_empty():
		if is_player_turn():
			var command: Dictionary = _planned.pop_front()
			if command["type"] == Protocol.CMD_CAST and not command.has("cible"):
				command["cible"] = player_fighter().cell
			_send(command)
			return
		_planned.clear()
	if _pending_click != NO_CELL:
		var cell := _pending_click
		_pending_click = NO_CELL
		_on_click(cell)


## Applique un événement à l'affichage ; renvoie la durée d'attente avant le suivant
## (négative pendant une marche).
func _apply(event: Dictionary) -> float:
	var type: String = event["type"]
	if mode == Mode.COMBAT:
		var line := _log_line(event)
		if not line.is_empty():
			combat_logged.emit(line)
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
	if type == Protocol.EVT_QUEST_OFFER:
		_close_dialogue()
		quest_offered.emit(event)
		return 0.0
	if type == Protocol.EVT_QUESTS:
		quests_changed.emit(event["journal"])
		progress_changed.emit()
		queue_redraw()  # Les marques des PNJ changent.
		return 0.0
	if type == Protocol.EVT_QUEST_PROGRESS:
		notice.emit(event["texte"])
		return 0.0
	if type == Protocol.EVT_QUEST_DONE:
		if _actors.has(World.PLAYER_ID):
			_add_floating("Quête terminée !", Color(1, 0.85, 0.3), _actors[World.PLAYER_ID]["pos"] + Vector2(0, -0.6), PHASE_FLOATING_LIFE)
		notice.emit("Quête terminée : %s — %s" % [event["nom"], QuestsWindow.rewards_text({"xp": event["xp"], "ecus": event["ecus"],
			"objets": event["objets"]})])
		quest_done.emit(event)
		return 0.6
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
		if event.get("rare", false):
			_add_floating("Rare ! +1 %s" % event["nom"], Color(1.0, 0.82, 0.3), player["pos"])
		else:
			_add_floating("+%d %s" % [event["quantite"], event["nom"]], Color(0.6, 0.95, 0.5), player["pos"])
		queue_redraw()
		return 0.6
	if type == Protocol.EVT_CHEST:
		chest_changed.emit(event)
		return 0.0
	if type == Protocol.EVT_TRAVEL_MENU:
		travel_opened.emit(event)
		return 0.0
	if type == Protocol.EVT_PASSAGE_DISCOVERED:
		_discovered_passage = event["passage"]
		if _actors.has(World.PLAYER_ID):
			_add_floating("Pierre découverte !", Color(0.55, 0.8, 1.0), _actors[World.PLAYER_ID]["pos"])
		notice.emit("Pierre de Passage découverte : %s ! Vous pourrez y revenir en voyage." % event["nom"])
		progress_changed.emit()
		return 0.0
	if type == Protocol.EVT_RESPAWN_POINT:
		if _discovered_passage == event["passage"]:
			notice.emit("Pierre de Passage découverte : %s ! C'est votre nouveau point de résurrection." % event["nom"])
		else:
			notice.emit("Nouveau point de résurrection : %s." % event["nom"])
		_discovered_passage = ""
		progress_changed.emit()
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
		if int(event.get("prix", 0)) > 0:
			notice.emit("Voyage payé : %d écus." % event["prix"])
		return 0.15
	if type == Protocol.EVT_TELEPORTED:
		_actors[event["entite"]]["pos"] = Vector2(event["case"])
		return 0.25
	if type == Protocol.EVT_STATUS:
		var affected: Dictionary = _actors[event["entite"]]
		affected["pa"] = event["pa"]
		affected["pm"] = event["pm"]
		var label := "+%d PA" % event["valeur"] if event["effet"] == Spell.EFFECT_GAIN_PA else "-%d PM" % event["valeur"]
		var color := Color(0.55, 0.8, 1.0)
		if event["effet"] == Spell.EFFECT_SHIELD:
			affected["bouclier"] = event["bouclier"]
			label = "+%d bouclier" % event["valeur"]
			color = element_color(event.get("element", ""), Color(1.0, 0.88, 0.45))
		_add_floating(label, color, affected["pos"])
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
		if event["commande"] == Protocol.CMD_EQUIP and _equip_refusals.has(event["raison"]):
			notice.emit(_equip_refusals[event["raison"]])
		if event["commande"] == Protocol.CMD_TRAVEL:
			notice.emit(_travel_refusals.get(event["raison"], "Le voyage est impossible."))
		if event.get("raison") == Protocol.REASON_QUEST_ITEM:
			notice.emit("Un objet de quête ne se jette ni ne se vend.")
		if event.get("raison") == Protocol.REASON_INVENTORY_OVERLOADED:
			notice.emit(CombatHud.OVERLOAD_TEXT)
		if event["commande"] == Protocol.CMD_HARVEST:
			notice.emit(_harvest_refusal_text(event["raison"], NO_CELL))
		if mode == Mode.COMBAT and _refusals.has(event["raison"]):
			combat_message.emit(_refusals[event["raison"]])
		return 0.0
	if type == Protocol.EVT_COMBAT_STARTED:
		_close_dialogue()
		_planned.clear()
		_glyphs.clear()
		_traps.clear()
		_trap_flash = {}
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
		if current_turn != World.PLAYER_ID:
			_planned.clear()  # Mort pendant son tour : rien ne part au tour suivant.
		var playing: Dictionary = _actors[current_turn]
		playing["pa"] = event["pa"]
		playing["pm"] = event["pm"]
		playing["bouclier"] = 0  # Le bouclier tombe au début de son tour.
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
		# La case d'un piège ennemi reste secrète.
		if not event.get("cache", false) or caster["team"] == Fighter.TEAM_PLAYERS:
			_face_toward(caster, Vector2(event["cible"]))
		var spell: Spell = world.data.spells.get(event["sort"])
		if spell != null:
			_add_floating(spell.display_name, Color(1, 0.95, 0.7), caster["pos"])
		if event.get("critique", false):
			_add_floating("Coup critique !", Color(1.0, 0.6, 0.15), caster["pos"] + Vector2(0, -0.5))
		return 0.35
	if type == Protocol.EVT_STATES:
		var bearer: Dictionary = _actors[event["entite"]]
		bearer["pa"] = event["pa"]
		bearer["pm"] = event["pm"]
		bearer["etats"] = event["etats"]
		if event.has("retires"):
			_add_floating("États retirés", Color(1.0, 0.92, 0.6), bearer["pos"])
		if event.has("nouveau"):
			var label := state_text(event["nouveau"])
			var good: bool = event["nouveau"]["type"] == Spell.EFFECT_BONUS
			var color := Color(0.55, 0.85, 1.0) if good else Color(0.85, 0.6, 1.0)
			if event["nouveau"]["type"] == Spell.EFFECT_POISON:
				color = element_color(event["nouveau"]["element"], color)
			_add_floating(label, color, bearer["pos"])
		combat_state_changed.emit()
		return 0.25 if event.has("nouveau") or event.has("retires") else 0.0
	if type == Protocol.EVT_PUSHED:
		_actors[event["entite"]]["pos"] = Vector2(event["case"])
		return 0.25
	if type == Protocol.EVT_CHARGED:
		var charger: Dictionary = _actors[event["entite"]]
		charger["pos"] = Vector2(event["case"])
		_add_floating("Charge !", Color(1.0, 0.85, 0.45), charger["pos"] + Vector2(0, -0.5))
		combat_state_changed.emit()
		return 0.3
	if type == Protocol.EVT_ELEMENT_STATES:
		var bearer: Dictionary = _actors[event["entite"]]
		bearer["etats_elementaires"] = event["etats"]
		if event.has("element"):
			_add_floating(SpellsWindow.ELEMENT_LABELS.get(event["element"], event["element"]),
				element_color(event["element"]), bearer["pos"] + Vector2(0, -0.3))
		else:
			_add_floating(element_states_text(event["etats"]), Color(0.8, 0.68, 1.0), bearer["pos"] + Vector2(0, -0.3))
		combat_state_changed.emit()
		return 0.15
	if type == Protocol.EVT_SPELL_CREATED:
		var created: Spell = world.data.spells.get(event["sort"])
		if created != null:
			_add_floating("Sort créé : %s" % created.display_name, Color(0.8, 0.65, 1.0), _actors[event["entite"]]["pos"] + Vector2(0, -0.5))
		combat_state_changed.emit()
		return 0.3
	if type == Protocol.EVT_GLYPH:
		_glyphs[event["id"]] = {"cases": event["cases"], "equipe": event["equipe"], "sort": event["sort"],
			"lanceur": event["lanceur"]}
		return 0.2
	if type == Protocol.EVT_GLYPH_ENDED:
		_glyphs.erase(event["id"])
		return 0.0
	if type == Protocol.EVT_TRAP:
		if event["equipe"] == Fighter.TEAM_PLAYERS:
			_traps[event["id"]] = {"case": event["case"], "sort": event["sort"], "lanceur": event["lanceur"]}
		return 0.0
	if type == Protocol.EVT_TRAP_ENDED:
		_traps.erase(event["id"])
		return 0.0
	if type == Protocol.EVT_TRAP_TRIGGERED:
		_traps.erase(event["id"])
		_trap_flash = {"cases": event["cases"], "age": 0.0}
		_add_floating("Piège : %s !" % event["sort"], Color(1.0, 0.55, 0.2), Vector2(event["case"]) + Vector2(0, -0.4))
		return 0.4
	if type == Protocol.EVT_PHASE:
		# Changement de phase d'un monstre : message de combat, et texte flottant qui dure assez pour
		# être lu.
		combat_message.emit(event["message"])
		_add_floating(event["message"], Color(1.0, 0.45, 0.85), _actors[event["entite"]]["pos"] + Vector2(0, -0.6),
			PHASE_FLOATING_LIFE)
		return 0.8
	if type == Protocol.EVT_DAMAGE:
		var target: Dictionary = _actors[event["entite"]]
		target["hp"] = event["pv"]
		target["bouclier"] = event.get("bouclier", 0)
		var text := "-%d" % event["valeur"]
		if int(event.get("absorbe", 0)) > 0:
			text += "  (%d absorbés)" % event["absorbe"]
		if event.get("source", "") == "poison":
			text += " (poison)"
		elif event.get("source", "") == "choc":
			text += " (choc)"
		_add_floating(text, element_color(event.get("element", ""), Color(1, 0.35, 0.3)), target["pos"])
		combat_state_changed.emit()
		return 0.25
	if type == Protocol.EVT_HEAL:
		var healed: Dictionary = _actors[event["entite"]]
		healed["hp"] = event["pv"]
		_add_floating("+%d" % event["valeur"], element_color(event.get("element", ""), Color(0.45, 1, 0.45)), healed["pos"])
		combat_state_changed.emit()
		return 0.25
	if type == Protocol.EVT_DIED:
		_actors[event["entite"]]["alive"] = false
		return 0.3
	if type == Protocol.EVT_COMBAT_ENDED:
		current_turn = ""
		_planned.clear()
		_paused = true
		combat_ended.emit(event)
		return 0.0
	if type == Protocol.EVT_EXPLORATION:
		mode = Mode.EXPLORATION
		selected_spell = ""
		turn_order.clear()
		_load_exploration_actors()
		exploration_resumed.emit()
		if event.has("reveil"):
			notice.emit(wake_up_text(event["reveil"]))
	return 0.0


## Où l'on se réveille après une défaite (`reveil` de EVT_COMBAT_ENDED et EVT_EXPLORATION).
static func wake_up_text(wake_up: Dictionary) -> String:
	if str(wake_up.get("passage", "")).is_empty():
		return "Vous vous réveillez au point de départ, un peu groggy."
	return "Vous vous réveillez près de la Pierre de Passage « %s », un peu groggy." % wake_up["nom"]


## « +100 Force (2 tours) », « −2 PM (1 tour) », « Poison 5 Givre (3 tours) ».
## « Flamme · Flamme · Givre » (états élémentaires, du plus ancien au plus récent).
static func element_states_text(states: Array) -> String:
	var names: PackedStringArray = []
	for element: String in states:
		names.append(SpellsWindow.ELEMENT_LABELS.get(element, element))
	return " · ".join(names)


static func state_text(state: Dictionary) -> String:
	var turns := int(state["tours"])
	var duration := "%d tour%s" % [turns, "s" if turns > 1 else ""]
	if state["type"] == Spell.EFFECT_POISON:
		return "Poison %d %s (%s)" % [state["valeur"], SpellsWindow.ELEMENT_LABELS.get(state["element"], state["element"]), duration]
	var carac: String = CARAC_NAMES.get(state["carac"], state["carac"])
	if state["carac"] == "resistance":
		carac = "Rés. %s %%" % SpellsWindow.ELEMENT_LABELS.get(state["element"], state["element"])
	return "%s%d %s (%s)" % ["+" if state["type"] == Spell.EFFECT_BONUS else "−", state["valeur"], carac, duration]


## Un texte au même endroit qu'un autre tout juste apparu attend son tour (âge négatif), pour ne pas
## s'y superposer : les sorts enchaînés affichent tout à la fois.
func _add_floating(text: String, color: Color, grid_pos: Vector2, life := FLOATING_LIFE) -> void:
	var delay := 0.0
	for other in _floating:
		if other["age"] < FLOATING_STAGGER and (other["pos"] as Vector2).distance_to(grid_pos) < 0.3:
			delay = maxf(delay, FLOATING_STAGGER - other["age"])
	_floating.append({"text": text, "color": color, "pos": grid_pos, "age": -delay, "life": life})


func _load_exploration_actors() -> void:
	_actors.clear()
	_group_walks.clear()
	_actors[World.PLAYER_ID] = _new_actor(Vector2(world.position_of(World.PLAYER_ID)), world.player_voie, 0, world.player_name, 1, 1)
	_actors[World.PLAYER_ID]["race"] = world.character.race_id
	for group: Dictionary in world.groups():
		_add_group_actor(group)


func _add_group_actor(group: Dictionary) -> void:
	var monster_ids: Array = group["monstres"]
	var data := _new_actor(Vector2(group["case"]), monster_ids[0], 1, group_label(monster_ids, world.data), 1, 1)
	data["count"] = monster_ids.size()
	data["members"] = monster_ids.duplicate()
	data["levels"] = group.get("niveaux", []).duplicate()
	_actors[group["id"]] = data


## Bulle d'un groupe : chaque monstre sur sa ligne, son niveau devant (« Niv. 3 Loup des collines »).
## `levels` : le niveau tiré de chaque monstre (voir `GameMap.compose_group`) ; à défaut, le niveau
## de base de ses données.
static func group_lines(monster_ids: Array, data: GameData, levels: Array = []) -> String:
	var lines: PackedStringArray = []
	for i in monster_ids.size():
		var monster_id: String = monster_ids[i]
		var monster: Dictionary = data.monsters.get(monster_id, {}) if data != null else {}
		var level := int(levels[i]) if i < levels.size() else int(monster.get("niveau", 1))
		lines.append("Niv. %d %s%s" % [level, monster.get("nom", monster_id), " (élite)" if monster.get("elite", false) else ""])
	return "\n".join(lines)


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
	_group_walks.clear()
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
	if can_plan() and fighter != null:
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
	var tactical_view := mode == Mode.COMBAT and tactical
	if tactical_view:
		_draw_tactical_ground(map)
	else:
		_draw_ground(map)

	if mode == Mode.COMBAT:
		_draw_ground_marks()
		_draw_placement_markers()
		_draw_cells(_reachable.keys(), COLOR_REACHABLE)
		_draw_cells(_range_hidden, COLOR_RANGE_HIDDEN)
		_draw_cells(_range_visible, COLOR_RANGE)
		var fighter := player_fighter()
		if selected_spell != "" and _hovered in _range_visible and fighter != null:
			var spell: Spell = fighter.get_spell(selected_spell)
			if spell != null:
				_draw_cells(spell.zone_cells(_hovered, fighter.cell).filter(func(c: Vector2i) -> bool: return map.is_inside(c)), COLOR_ZONE)
		for command in _planned:
			if command.has("cible"):
				draw_colored_polygon(_scaled_diamond(IsoGrid.cell_to_screen(command["cible"]), 0.6), COLOR_PLANNED)
	else:
		_draw_exit_halos()
	for cell in _preview:
		draw_colored_polygon(_scaled_diamond(IsoGrid.cell_to_screen(cell), 0.35), COLOR_PATH)
	if map.is_inside(_hovered):
		var walkable := map.is_walkable_in_combat(_hovered) if mode == Mode.COMBAT else map.is_walkable(_hovered)
		var color := COLOR_HOVER_OK if walkable else COLOR_HOVER_KO
		draw_colored_polygon(IsoGrid.diamond(IsoGrid.cell_to_screen(_hovered)), color)

	# Objets en relief et personnages, du fond vers l'avant.
	var drawables: Array = []
	if tactical_view:
		_draw_tactical_pieces(map)
		_draw_floating_texts()
		return
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
		_draw_door_marks(map)
	_draw_floating_texts()


func _draw_floating_texts() -> void:
	var font := ThemeDB.fallback_font
	for text in _floating:
		if text["age"] < 0.0:
			continue  # Pas encore apparu (voir `_add_floating`).
		# Centré au-dessus de la case, assez large pour un long message (changement de phase).
		var width := maxf(200.0, font.get_string_size(text["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 8.0)
		# Monte pendant une seconde, puis reste en place (texte qui dure plus longtemps).
		var text_pos := IsoGrid.grid_to_screen(text["pos"]) + Vector2(-width / 2.0, -60 - 30 * minf(text["age"], FLOATING_LIFE))
		var color: Color = text["color"]
		color.a = 1.0 - maxf(0.0, text["age"] - (text["life"] - 0.4)) / 0.4
		draw_string_outline(font, text_pos, text["text"], HORIZONTAL_ALIGNMENT_CENTER, width, 16, 4, Color(0, 0, 0, color.a))
		draw_string(font, text_pos, text["text"], HORIZONTAL_ALIGNMENT_CENTER, width, 16, color)


## Mode tactique : fond uni, cases à plat en damier, eau à plat, sans décor ni touffes.
func _draw_tactical_ground(map: GameMap) -> void:
	draw_rect(map.screen_rect(), TACTICAL_BACKGROUND)
	for cell: Vector2i in map.cells():
		var center := IsoGrid.cell_to_screen(cell)
		var diamond := IsoGrid.diamond(center)
		if not map.obstacles.has(cell):
			draw_colored_polygon(diamond, TACTICAL_CELLS[posmod(cell.x + cell.y, 2)])
		elif map.obstacles[cell] in Combat.SEE_THROUGH_OBSTACLES:
			draw_colored_polygon(diamond, TACTICAL_WATER)
		else:
			continue
		diamond.append(diamond[0])
		draw_polyline(diamond, TACTICAL_EDGE)


## Mode tactique : obstacles qui bloquent la vue en blocs bas, combattants en pions (couleur du camp,
## initiale, barre de PV), du fond vers l'avant.
func _draw_tactical_pieces(map: GameMap) -> void:
	var drawables: Array = []
	for cell: Vector2i in map.obstacles:
		if map.obstacles[cell] not in Combat.SEE_THROUGH_OBSTACLES:
			drawables.append([IsoGrid.depth(Vector2(cell)), "", cell])
	for actor_id: String in _actors:
		if _actors[actor_id]["alive"]:
			drawables.append([IsoGrid.depth(_actors[actor_id]["pos"]) + 0.01, actor_id, NO_CELL])
	drawables.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var font := ThemeDB.fallback_font
	for drawable: Array in drawables:
		if drawable[1] == "":
			_draw_block(IsoGrid.cell_to_screen(drawable[2]), 14, TACTICAL_BLOCK)
			continue
		var data: Dictionary = _actors[drawable[1]]
		var base := IsoGrid.grid_to_screen(data["pos"])
		var color: Color = COLOR_TEAM[clampi(data["team"], 0, 1)]
		color.a = 1.0
		if drawable[1] == current_turn:
			draw_colored_polygon(_ellipse(base, 22, 11), Color(1, 1, 1, 0.35))
		draw_colored_polygon(_ellipse(base, 15, 7.5), color.darkened(0.45))
		var head := base + Vector2(0, -16)
		draw_circle(head, 12, color)
		draw_arc(head, 12, 0, TAU, 24, Color(0, 0, 0, 0.7), 2.0)
		var initial := str(data.get("name", "?")).left(1).to_upper()
		draw_string(font, head + Vector2(-12, 6), initial, HORIZONTAL_ALIGNMENT_CENTER, 24, 16, Color.WHITE)
		var ratio := clampf(float(data["hp"]) / maxf(1.0, data["max_hp"]), 0.0, 1.0)
		var bar := Rect2(base + Vector2(-15, -36), Vector2(30, 4))
		draw_rect(bar, Color(0, 0, 0, 0.7))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(0.3, 0.85, 0.3) if ratio > 0.3 else Color(0.9, 0.3, 0.2))


## Glyphes (cases teintées et liserés), pièges de l'équipe du joueur, explosion d'un piège.
func _draw_ground_marks() -> void:
	for glyph: Dictionary in _glyphs.values():
		var team := clampi(int(glyph["equipe"]), 0, 1)
		for cell: Vector2i in glyph["cases"]:
			var diamond := _scaled_diamond(IsoGrid.cell_to_screen(cell), 0.92)
			draw_colored_polygon(diamond, COLOR_GLYPH[team])
			diamond.append(diamond[0])
			draw_polyline(diamond, COLOR_GLYPH_EDGE[team], 2.0)
	for trap: Dictionary in _traps.values():
		var center := IsoGrid.cell_to_screen(trap["case"])
		for i in 5:
			var angle := TAU * i / 5.0
			var tip := center + Vector2(cos(angle) * 11.0, sin(angle) * 5.5)
			draw_line(center, tip, COLOR_TRAP, 2.0)
		draw_colored_polygon(_ellipse(center, 4, 2), COLOR_TRAP)
	if not _trap_flash.is_empty():
		var flash := COLOR_TRAP_FLASH
		flash.a *= 1.0 - _trap_flash["age"] / 0.6
		_draw_cells(_trap_flash["cases"], flash)


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
	var walking := actor_id == _walk_actor or _group_walks.has(actor_id)
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
			var member_facing := facing if i == 0 or walking else (1.0 if posmod(hash(member_id), 2) == 0 else -1.0)
			_draw_figure(member_id, _monster_look(members[i]), members[i], base + spots[i], member_facing, walking, phase + i * 1.3, data)
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
	if look.get("elite", false):
		_draw_elite_aura(base, offset)
	if look.has("rig"):
		var progress := 1.0 - float(data.get("attaque", 0.0)) / ATTACK_TIME if data.get("attaque", 0.0) > 0.0 else -1.0
		Rig.draw(self, look, base, {"facing": facing, "dos": data.get("dos", false), "marche": walking, "phase": phase,
			"temps": _time + offset * 0.1, "attaque": progress})
	elif look.has("image"):
		var hop := -absf(sin(phase)) * 2.0 if walking else sin(_time * 2.0 + offset) * 0.4
		Art.draw(self, look["image"], base + Vector2(0, hop), look.get("couleurs", {}), facing < 0.0, look.get("teinte", Color.WHITE), look["echelle"])
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


## Halo doré sous les pieds d'un monstre élite, qui pulse doucement.
func _draw_elite_aura(base: Vector2, offset: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.0 + offset)
	draw_colored_polygon(_ellipse(base, 24, 12), Color(1.0, 0.78, 0.25, 0.18 + 0.12 * pulse))
	var ring := _ellipse(base, 24, 12)
	ring.append(ring[0])
	draw_polyline(ring, Color(1.0, 0.82, 0.3, 0.55 + 0.3 * pulse), 2.0)


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
	_draw_npc_mark(base, world.quest_book.marker(npc_id) if world.map == _map else "")


## Au-dessus d'un PNJ : « ! » jaune (quête à prendre), « ? » jaune (à rendre, ou objectif à remplir
## en lui parlant), « ? » gris (quête en cours), sinon une petite bulle « … » (il a quelque chose à dire).
func _draw_npc_mark(base: Vector2, quest_mark: String) -> void:
	var font := ThemeDB.fallback_font
	if quest_mark.is_empty():
		var mark := base + Vector2(14, -76)
		draw_circle(mark, 8, Color(1, 1, 1, 0.9))
		draw_arc(mark, 8, 0, TAU, 20, Color(0.23, 0.15, 0.09), 1.2)
		draw_string(font, mark + Vector2(-6, 4), "…", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.2, 0.2, 0.2))
		return
	var text := "!" if quest_mark == QuestBook.MARKER_AVAILABLE else "?"
	var color := Color(1.0, 0.82, 0.2) if quest_mark != QuestBook.MARKER_ACTIVE else Color(0.72, 0.72, 0.72)
	var bounce := sin(_time * 3.0) * 2.0 if quest_mark != QuestBook.MARKER_ACTIVE else 0.0
	var spot := base + Vector2(-10, -84 + bounce)
	draw_string_outline(font, spot, text, HORIZONTAL_ALIGNMENT_CENTER, 20, 28, 6, Color(0.2, 0.12, 0.05))
	draw_string(font, spot, text, HORIZONTAL_ALIGNMENT_CENTER, 20, 28, color)


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
		look = {"image": spec["image"], "echelle": float(spec.get("echelle", 1.0)), "couleurs": spec.get("couleurs", {}),
			"teinte": Color(str(spec.get("teinte", "ffffff")))}
	elif spec.has("rig"):
		look = Rig.look(spec["rig"], spec.get("couleurs", {}), spec.get("arme", ""), spec.get("accessoires", []))
	if world != null and world.data != null and world.data.monsters.get(kind, {}).get("elite", false):
		look["elite"] = true
	_monster_looks[kind] = look
	return look


## Devant chaque porte d'un bâtiment où l'on peut entrer (hors intérieur, où le paillasson suffit) :
## un losange doré qui pulse doucement au sol et un double chevron « entrer ». Dessiné par-dessus
## le décor, pour rester visible au pied du bâtiment.
func _draw_door_marks(map: GameMap) -> void:
	if map.floor_kind == "parquet":
		return
	var pulse := 0.5 + 0.5 * sin(_time * 2.5)
	for cell: Vector2i in map.doors:
		var center := IsoGrid.cell_to_screen(cell)
		var diamond := _scaled_diamond(center, 0.78)
		draw_colored_polygon(diamond, Color(1.0, 0.82, 0.3, 0.16 + 0.12 * pulse))
		diamond.append(diamond[0])
		draw_polyline(diamond, Color(1.0, 0.85, 0.35, 0.65 + 0.3 * pulse), 2.0)
		for k in 2:
			var tip := center + Vector2(0, -3.0 - 5.0 * k - 2.0 * pulse)
			var chevron := PackedVector2Array([tip + Vector2(-7, 4), tip, tip + Vector2(7, 4)])
			draw_polyline(chevron, Color(0.25, 0.16, 0.05, 0.9), 4.0)
			draw_polyline(chevron, Color(1.0, 0.9, 0.5), 2.0)


## Halo blanc léger, qui respire doucement, sur les cases praticables du bord qui mènent à la
## carte voisine : le joueur voit où cliquer pour changer de carte (dessiné sous les personnages).
func _draw_exit_halos() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	for direction: String in _exit_cells:
		for cell: Vector2i in _exit_cells[direction]:
			var diamond := _scaled_diamond(IsoGrid.cell_to_screen(cell), 0.86)
			draw_colored_polygon(diamond, Color(1, 1, 1, 0.1 + 0.06 * pulse))
			diamond.append(diamond[0])
			draw_polyline(diamond, Color(1, 1, 1, 0.35 + 0.15 * pulse), 1.5)


## Flèche au bord de l'écran pour chaque sortie, en face de la case de sortie praticable la plus
## proche du milieu du bord (jamais devant une case bloquée).
func _draw_exit_arrows(map: GameMap) -> void:
	var rect := map.screen_rect()
	var center := rect.get_center()
	var forwards := {"haut": Vector2(0, -1), "bas": Vector2(0, 1), "gauche": Vector2(-1, 0), "droite": Vector2(1, 0)}
	for direction: String in _exit_cells:
		if not forwards.has(direction):
			continue
		var forward: Vector2 = forwards[direction]
		var along := Vector2(absf(forward.y), absf(forward.x))  # Axe du bord.
		var best := Vector2.ZERO
		var best_gap := INF
		for cell: Vector2i in _exit_cells[direction]:
			var spot := IsoGrid.cell_to_screen(cell)
			var gap := absf((spot - center).dot(along))
			if gap < best_gap:
				best_gap = gap
				best = spot
		var tip := Vector2(best.x, 10) if direction == "haut" else Vector2(best.x, rect.end.y - 10) if direction == "bas" \
			else Vector2(14, best.y) if direction == "gauche" else Vector2(rect.end.x - 14, best.y)
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
	# Au-dessus du PNJ, sauf si la bulle passerait sous le bandeau du haut : alors sous ses pieds.
	var highest := DIALOGUE_TOP - global_position.y
	if top_left.y < highest:
		top_left.y = IsoGrid.cell_to_screen(_dialogue["case"]).y + 18.0
	_bubble.position = Vector2(clampf(top_left.x, 0.0, maxf(max_x, 0.0)), top_left.y)


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
