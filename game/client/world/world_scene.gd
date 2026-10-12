extends Node2D
## Scène du monde : charge le contenu et la carte de départ, crée le noyau de jeu et branche
## l'affichage (carte + interface de combat).

const START_MAP := "res://data/cartes/brumerive_0_0.json"
const HELP_EXPLORATION := "Clic : se déplacer · Monstre : attaquer · PNJ : parler · Flèches au bord : changer de carte · Échap : menu"
const HELP_COMBAT := "Clic : se déplacer (cases vertes) · 1-4 : choisir un sort, clic : le lancer · Clic droit : annuler"

@onready var _map_view: MapView = $MapView
@onready var _combat_hud: CombatHud = $CombatHud
@onready var _info: Label = %Info

var _hover_text := ""


func _ready() -> void:
	var map := DataLoader.load_map(START_MAP)
	if map == null:
		_info.text = "Impossible de charger la carte %s" % START_MAP
		return
	var load_neighbor := func(map_id: String) -> GameMap: return DataLoader.load_map(DataLoader.map_path(map_id))
	_map_view.setup(World.new(map, GameData.load_all(), load_neighbor))
	_combat_hud.setup(_map_view)
	_map_view.hovered_cell_changed.connect(_on_hovered_cell_changed)
	_map_view.combat_started.connect(_update_info)
	_map_view.exploration_resumed.connect(_update_info)
	_map_view.map_changed.connect(_on_map_changed)
	get_viewport().size_changed.connect(_center_map)
	_center_map()
	_update_info()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _map_view.mode == MapView.Mode.EXPLORATION:
		get_tree().change_scene_to_file("res://client/main/main.tscn")


func _center_map() -> void:
	var map_size := _map_view.current_map().screen_rect().size
	var free_space := get_viewport_rect().size - map_size
	# Un peu plus de place en bas, pour la barre d'interface.
	_map_view.position = Vector2(free_space.x / 2.0, maxf(free_space.y / 2.0 - 8.0, 0.0)).round()


func _on_map_changed() -> void:
	_hover_text = ""
	_center_map()
	_update_info()


func _on_hovered_cell_changed(_cell: Vector2i, description: String) -> void:
	_hover_text = description
	_update_info()


func _update_info() -> void:
	var map := _map_view.current_map()
	var help := HELP_COMBAT if _map_view.mode == MapView.Mode.COMBAT else HELP_EXPLORATION
	var detail := "   ·   %s" % _hover_text if not _hover_text.is_empty() else ""
	_info.text = "%s%s\n%s" % [map.display_name, detail, help]
