extends Node2D
## Scène du monde : crée (ou reprend) la partie, branche la carte, l'interface de combat et la fiche
## du personnage, et sauvegarde automatiquement.

const DEFAULT_START_MAP := "brumerive_0_0"
const MENU_SCENE := "res://client/main/main.tscn"

@onready var _map_view: MapView = $MapView
@onready var _combat_hud: CombatHud = $CombatHud
@onready var _sheet: CharacterSheet = $CharacterSheet
@onready var _inventory: InventoryWindow = $InventoryWindow
@onready var _shop: ShopWindow = $ShopWindow
@onready var _craft: CraftWindow = $CraftWindow
@onready var _chest: ChestWindow = $ChestWindow
@onready var _jobs: JobsWindow = $JobsWindow
@onready var _travel: TravelWindow = $TravelWindow
@onready var _spells: SpellsWindow = $SpellsWindow
@onready var _info: Label = %Info

var _hover_text := ""
## Bulle près du curseur : ce qu'on survole (monstres, PNJ, ressources…).
var _hover_bubble: PanelContainer
var _hover_label: Label


func _ready() -> void:
	UiTheme.apply(get_tree())
	var world := _create_world()
	if world == null:
		_info.text = "Impossible de charger le monde (carte de départ introuvable)."
		return
	_map_view.setup(world)
	_combat_hud.setup(_map_view)
	_sheet.setup(_map_view)
	_inventory.setup(_map_view)
	_shop.setup(_map_view)
	_craft.setup(_map_view)
	_chest.setup(_map_view)
	_jobs.setup(_map_view)
	_travel.setup(_map_view)
	_spells.setup(_map_view)
	_combat_hud.menu_pressed.connect(_on_menu_pressed)
	_combat_hud.spell_info_requested.connect(_spells.show_spell)
	_map_view.notice.connect(_combat_hud.show_message)
	_map_view.hovered_cell_changed.connect(_on_hovered_cell_changed)
	_map_view.combat_started.connect(_on_combat_started)
	_map_view.exploration_resumed.connect(_on_exploration_resumed)
	_map_view.map_changed.connect(_on_map_changed)
	_map_view.character_changed.connect(_on_character_changed)
	_map_view.level_up.connect(_on_level_up)
	_map_view.inventory_changed.connect(_on_inventory_changed)
	get_viewport().size_changed.connect(_center_map)
	_center_map()
	_update_info()
	_save()


func _create_world() -> World:
	var game_data := GameData.load_all()
	var load_map := func(map_id: String) -> GameMap: return DataLoader.load_map(DataLoader.map_path(map_id))
	if Session.continue_game and SaveGame.exists():
		var restored := World.from_save(SaveGame.read(), game_data, load_map)
		if restored != null:
			return restored
	var character: Character = Session.new_character
	if character == null:
		character = Character.create(World.DEFAULT_NAME, "humain", World.DEFAULT_VOIE)
	# Nouveau personnage : équipement de départ de sa Voie (une seule fois).
	Session.new_character = null
	game_data.give_starting_kit(character)
	var start_id := str(game_data.races.get(character.race_id, {}).get("carte_depart", DEFAULT_START_MAP))
	if not Session.start_map.is_empty():
		start_id = Session.start_map
	var start_map: GameMap = load_map.call(start_id)
	if start_map == null:
		start_map = load_map.call(DEFAULT_START_MAP)
	if start_map == null:
		return null
	return World.new(start_map, game_data, load_map, character)


func _process(_delta: float) -> void:
	if _hover_bubble != null and _hover_bubble.visible:
		var viewport_size := get_viewport().get_visible_rect().size
		var spot := get_viewport().get_mouse_position() + Vector2(18, 22)
		spot.x = minf(spot.x, viewport_size.x - _hover_bubble.size.x - 4)
		spot.y = minf(spot.y, viewport_size.y - _hover_bubble.size.y - CombatHud.BAR_HEIGHT - 4)
		_hover_bubble.position = spot


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _map_view.mode == MapView.Mode.EXPLORATION:
		if _shop.is_open():
			_shop.close()
			return
		if _craft.is_open():
			_craft.close()
			return
		if _chest.is_open():
			_chest.close()
			return
		if _travel.is_open():
			_travel.close()
			return
		if _jobs.is_open():
			_jobs.toggle()
			return
		if _spells.is_open():
			_spells.toggle()
			return
		if _sheet.is_open():
			_sheet.toggle()
			return
		if _inventory.is_open():
			_inventory.toggle()
			return
		_save()
		get_tree().change_scene_to_file(MENU_SCENE)


## Sauvegarde automatique (jamais pendant un combat).
func _save() -> void:
	if _map_view.world != null and not _map_view.world.in_combat():
		SaveGame.write(_map_view.world.save_data())


func _center_map() -> void:
	var map_size := _map_view.current_map().screen_rect().size
	var free_space := get_viewport_rect().size - map_size
	# Un peu plus de place en bas, pour la barre d'interface.
	_map_view.position = Vector2(free_space.x / 2.0, maxf(free_space.y / 2.0 - 8.0, 0.0)).round()


## Boutons de menu de la barre du bas.
func _on_menu_pressed(menu: String) -> void:
	if menu == "personnage":
		_sheet.toggle()
	elif menu == "inventaire":
		_inventory.toggle()
	elif menu == "sorts":
		_spells.toggle()
	elif menu == "metiers":
		_jobs.toggle()


func _on_combat_started() -> void:
	_update_info()


func _on_exploration_resumed() -> void:
	_update_info()
	_save()


func _on_map_changed() -> void:
	_hover_text = ""
	_center_map()
	_update_info()
	_save()


func _on_character_changed() -> void:
	_update_info()
	_sheet.refresh()
	_save()


func _on_inventory_changed() -> void:
	_sheet.refresh()
	_save()


func _on_level_up(level: int) -> void:
	_combat_hud.show_message("Niveau %d ! Ouvrez la fiche (C) pour répartir vos points." % level)


func _on_hovered_cell_changed(_cell: Vector2i, description: String) -> void:
	_hover_text = description
	_update_info()


## En haut de l'écran : seulement le nom de la carte. Ce qu'on survole s'affiche près du curseur
## (sauf une simple case du sol).
func _update_info() -> void:
	_info.text = _map_view.current_map().display_name
	if _hover_bubble == null:
		_build_hover_bubble()
	_hover_label.text = _hover_text
	_hover_bubble.visible = not _hover_text.is_empty() and not _hover_text.begins_with("case (")
	_hover_bubble.reset_size()


func _build_hover_bubble() -> void:
	_hover_bubble = PanelContainer.new()
	_hover_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.05, 0.88)
	style.border_color = Color(0.55, 0.42, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	_hover_bubble.add_theme_stylebox_override("panel", style)
	_hover_label = Label.new()
	_hover_label.add_theme_font_size_override("font_size", 14)
	_hover_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	_hover_bubble.add_child(_hover_label)
	_info.get_parent().add_child(_hover_bubble)
