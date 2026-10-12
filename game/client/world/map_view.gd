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
signal combat_ended(victory: bool, xp: int)
signal exploration_resumed

enum Mode { EXPLORATION, COMBAT }

## Vitesse de marche, en pixels par seconde.
const WALK_SPEED := 170.0

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
## Sort sélectionné par le joueur en combat (id), ou "".
var selected_spell := ""
## Ordre de jeu (ids) et combattant dont c'est le tour.
var turn_order: Array[String] = []
var current_turn := ""

## Ce qui est affiché : id → { pos: Vector2 (grille), kind, team, name, hp, max_hp, pa, pm, alive, count }.
var _actors: Dictionary = {}
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
## Textes flottants : { text, color, pos (Vector2 grille), age }.
var _floating: Array[Dictionary] = []


func setup(p_world: World) -> void:
	world = p_world
	var rect := world.map.screen_rect()
	var rect_polygon := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	_border_polygons.clear()
	for cell in world.map.border_cells():
		_border_polygons.append_array(Geometry2D.intersect_polygons(IsoGrid.diamond(IsoGrid.cell_to_screen(cell)), rect_polygon))
	_load_exploration_actors()
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
			_on_click(cell)
		elif button.button_index == MOUSE_BUTTON_RIGHT and selected_spell != "":
			selected_spell = ""
			_refresh_overlays()


func _on_click(cell: Vector2i) -> void:
	if mode == Mode.EXPLORATION:
		if _playing:
			_pending_click = cell
			return
		var group := world.group_at(cell)
		if not group.is_empty():
			_send({"type": Protocol.CMD_ENGAGE, "entite": World.PLAYER_ID, "groupe": group["id"]})
		else:
			_send({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": cell})
		return
	if _playing or not world.map.is_inside(cell):
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
	if not world.map.is_inside(cell):
		return ""
	for actor_id: String in _actors:
		var data: Dictionary = _actors[actor_id]
		if data["alive"] and Vector2i(data["pos"].round()) == cell and actor_id != World.PLAYER_ID:
			if mode == Mode.COMBAT:
				return "%s — %d / %d PV" % [data["name"], data["hp"], data["max_hp"]]
			return "%s (groupe de %d)" % [data["name"], data["count"]] if data["count"] > 1 else data["name"]
	return "case (%d, %d)%s" % [cell.x, cell.y, "" if world.map.is_walkable(cell) else " — bloquée"]


func _update_preview() -> void:
	_preview.clear()
	if _playing or not world.map.is_inside(_hovered):
		queue_redraw()
		return
	if mode == Mode.EXPLORATION:
		_preview = world.map.find_path(world.position_of(World.PLAYER_ID), _hovered)
	elif is_player_turn() and selected_spell == "" and _reachable.has(_hovered):
		_preview = _reachable[_hovered]
	queue_redraw()


# --- Lecture des événements --------------------------------------------------------------------

func _process(delta: float) -> void:
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
	if _playing or not _floating.is_empty():
		queue_redraw()


func _advance_walk(delta: float) -> void:
	var data: Dictionary = _actors[_walk_actor]
	var current: Vector2 = data["pos"]
	var next := Vector2(_walk_path[0])
	var distance := IsoGrid.grid_to_screen(current).distance_to(IsoGrid.grid_to_screen(next))
	var step := WALK_SPEED * delta
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
	if type == Protocol.EVT_REFUSED:
		if mode == Mode.COMBAT and _refusals.has(event["raison"]):
			combat_message.emit(_refusals[event["raison"]])
		return 0.0
	if type == Protocol.EVT_COMBAT_STARTED:
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
		combat_ended.emit(event["vainqueur"] == Fighter.TEAM_PLAYERS, event["xp"])
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
	for group: Dictionary in world.groups():
		var monster_ids: Array = group["monstres"]
		var first: String = monster_ids[0]
		var monster_name: String = first
		if world.data != null and world.data.monsters.has(first):
			monster_name = world.data.monsters[first]["nom"]
		var data := _new_actor(Vector2(group["case"]), first, 1, monster_name, 1, 1)
		data["count"] = monster_ids.size()
		_actors[group["id"]] = data


func _load_combat_actors(event: Dictionary) -> void:
	mode = Mode.COMBAT
	_actors.clear()
	for snapshot: Dictionary in event["combattants"]:
		var data := _new_actor(Vector2(snapshot["case"]), snapshot["type"], snapshot["equipe"], snapshot["nom"], snapshot["pv"], snapshot["pv_max"])
		data["pa"] = snapshot["pa"]
		data["pm"] = snapshot["pm"]
		_actors[snapshot["id"]] = data
	_placement.assign(event["placement"])
	current_turn = ""
	turn_order.clear()


func _new_actor(pos: Vector2, kind: String, team: int, actor_name: String, hp: int, max_hp: int) -> Dictionary:
	return {"pos": pos, "kind": kind, "team": team, "name": actor_name, "hp": hp, "max_hp": max_hp,
		"pa": 0, "pm": 0, "alive": true, "count": 1}


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
	var map := world.map
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
	drawables.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for drawable: Array in drawables:
		if drawable[1] == "acteur":
			_draw_actor(drawable[2])
		else:
			_draw_obstacle(drawable[2], map.obstacles[drawable[2]])

	var font := ThemeDB.fallback_font
	for text in _floating:
		var text_pos := IsoGrid.grid_to_screen(text["pos"]) + Vector2(-30, -60 - 30 * text["age"])
		var color: Color = text["color"]
		color.a = 1.0 - maxf(0.0, text["age"] - 0.6) / 0.4
		draw_string_outline(font, text_pos, text["text"], HORIZONTAL_ALIGNMENT_CENTER, 60, 16, 4, Color(0, 0, 0, color.a))
		draw_string(font, text_pos, text["text"], HORIZONTAL_ALIGNMENT_CENTER, 60, 16, color)


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
	for polygon in _border_polygons:
		draw_colored_polygon(polygon, COLOR_BORDER)
		var outline := polygon.duplicate()
		outline.append(polygon[0])
		draw_polyline(outline, COLOR_GRID)
	for cell: Vector2i in map.cells():
		var points := IsoGrid.diamond(IsoGrid.cell_to_screen(cell))
		var color := COLOR_WATER if map.obstacles.get(cell) == "eau" else COLOR_GRASS
		# Légère variation de teinte, stable d'une image à l'autre.
		color = color.darkened(float(posmod(cell.x * 7 + cell.y * 13, 5)) * 0.025)
		draw_colored_polygon(points, color)
		points.append(points[0])
		draw_polyline(points, COLOR_GRID)


func _draw_obstacle(cell: Vector2i, kind: String) -> void:
	var base := IsoGrid.cell_to_screen(cell)
	match kind:
		"arbre":
			draw_colored_polygon(_ellipse(base + Vector2(0, 2), 18, 8), COLOR_SHADOW)
			draw_rect(Rect2(base + Vector2(-4, -24), Vector2(8, 24)), Color("6b4a2b"))
			draw_circle(base + Vector2(0, -40), 22, Color("3f6b34"))
			draw_circle(base + Vector2(-6, -46), 11, Color("4f8040"))
		"rocher":
			var points := PackedVector2Array()
			for offset in [Vector2(-20, 2), Vector2(-15, -14), Vector2(2, -20), Vector2(18, -10), Vector2(21, 4), Vector2(0, 9)]:
				points.append(base + offset)
			draw_colored_polygon(points, Color("8c8c86"))
			draw_colored_polygon(PackedVector2Array([base + Vector2(-15, -14), base + Vector2(2, -20), base + Vector2(4, -8)]), Color("a5a59e"))
		"mur":
			_draw_block(base, 40, Color("b49a74"))
		_:
			_draw_block(base, 20, Color.MAGENTA)  # Type inconnu : bien visible pour le corriger.


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
	if mode == Mode.COMBAT:
		var ring := _ellipse(base, 18, 9)
		ring.append(ring[0])
		draw_polyline(ring, COLOR_TEAM[clampi(data["team"], 0, 1)], 3.0)
		if actor_id == current_turn:
			draw_colored_polygon(_ellipse(base, 18, 9), Color(1, 1, 1, 0.25))
	var kind: String = data["kind"]
	if actor_id == World.PLAYER_ID:
		_draw_player(base)
	elif kind.contains("loup"):
		_draw_wolf(base)
	elif kind.contains("gobelin"):
		_draw_goblin(base)
	else:
		_draw_blob(base)
	if mode == Mode.EXPLORATION and data["count"] > 1:
		draw_string(ThemeDB.fallback_font, base + Vector2(10, -30), "×%d" % data["count"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	if mode == Mode.COMBAT:
		var ratio := clampf(float(data["hp"]) / maxf(1.0, data["max_hp"]), 0.0, 1.0)
		var bar := Rect2(base + Vector2(-17, -66), Vector2(34, 5))
		draw_rect(bar, Color(0, 0, 0, 0.6))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(0.3, 0.85, 0.3) if ratio > 0.3 else Color(0.9, 0.3, 0.2))


func _draw_player(base: Vector2) -> void:
	draw_colored_polygon(_ellipse(base, 14, 7), COLOR_SHADOW)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-11, -2), base + Vector2(11, -2), base + Vector2(7, -30), base + Vector2(-7, -30),
	]), Color("2f5d8a"))
	draw_circle(base + Vector2(0, -38), 8, Color("f0c8a0"))
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-9, -40), base + Vector2(9, -40), base + Vector2(0, -56),
	]), Color("8a3b2f"))


func _draw_wolf(base: Vector2) -> void:
	draw_colored_polygon(_ellipse(base, 18, 7), COLOR_SHADOW)
	draw_colored_polygon(_ellipse(base + Vector2(0, -14), 16, 9), Color("7d7f86"))
	draw_circle(base + Vector2(13, -22), 7, Color("8e9097"))
	draw_colored_polygon(PackedVector2Array([base + Vector2(10, -27), base + Vector2(13, -36), base + Vector2(16, -27)]), Color("6b6d73"))
	draw_colored_polygon(PackedVector2Array([base + Vector2(17, -21), base + Vector2(25, -19), base + Vector2(17, -17)]), Color("6b6d73"))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-15, -16), base + Vector2(-26, -24), base + Vector2(-14, -11)]), Color("6b6d73"))
	draw_circle(base + Vector2(15, -23), 1.5, Color(0.9, 0.8, 0.2))


func _draw_goblin(base: Vector2) -> void:
	draw_colored_polygon(_ellipse(base, 12, 6), COLOR_SHADOW)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-9, -2), base + Vector2(9, -2), base + Vector2(6, -22), base + Vector2(-6, -22),
	]), Color("5a4630"))
	draw_circle(base + Vector2(0, -29), 8, Color("6f9a3e"))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-6, -31), base + Vector2(-17, -36), base + Vector2(-7, -26)]), Color("6f9a3e"))
	draw_colored_polygon(PackedVector2Array([base + Vector2(6, -31), base + Vector2(17, -36), base + Vector2(7, -26)]), Color("6f9a3e"))
	draw_circle(base + Vector2(-3, -30), 1.5, Color(1, 0.3, 0.2))
	draw_circle(base + Vector2(3, -30), 1.5, Color(1, 0.3, 0.2))


func _draw_blob(base: Vector2) -> void:
	draw_colored_polygon(_ellipse(base, 14, 7), COLOR_SHADOW)
	draw_colored_polygon(_ellipse(base + Vector2(0, -12), 13, 12), Color("9a5fb0"))


func _scaled_diamond(center: Vector2, scale_factor: float) -> PackedVector2Array:
	var points := IsoGrid.diamond(Vector2.ZERO)
	for i in points.size():
		points[i] = center + points[i] * scale_factor
	return points


func _ellipse(center: Vector2, radius_x: float, radius_y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
