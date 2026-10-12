extends Node2D
## Scène d'exploration : charge la carte de départ, crée le noyau de jeu et branche l'affichage.

const START_MAP := "res://data/cartes/brumerive_0_0.json"
const HELP := "Clic gauche : se déplacer   ·   Échap : retour au menu"

@onready var _map_view: MapView = $MapView
@onready var _info: Label = %Info


func _ready() -> void:
	var map := DataLoader.load_map(START_MAP)
	if map == null:
		_info.text = "Impossible de charger la carte %s" % START_MAP
		return
	_map_view.setup(World.new(map))
	_map_view.hovered_cell_changed.connect(_on_hovered_cell_changed)
	get_viewport().size_changed.connect(_center_map)
	_center_map()
	_info.text = "%s\n%s" % [map.display_name, HELP]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://client/main/main.tscn")


func _center_map() -> void:
	# Décalage vers le bas pour laisser de la place au relief (arbres, murs).
	_map_view.position = (get_viewport_rect().size / 2.0 - _map_view.get_map_center() + Vector2(0, 20)).round()


func _on_hovered_cell_changed(cell: Vector2i, walkable: bool) -> void:
	var map := _map_view.world.map
	var detail := ""
	if map.is_inside(cell):
		detail = "   ·   case (%d, %d)%s" % [cell.x, cell.y, "" if walkable else " — bloquée"]
	_info.text = "%s%s\n%s" % [map.display_name, detail, HELP]
