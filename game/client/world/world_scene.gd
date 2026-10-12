extends Node2D
## Scène du monde : crée (ou reprend) la partie, branche la carte, l'interface de combat et la fiche
## du personnage, et sauvegarde automatiquement.

const DEFAULT_START_MAP := "brumerive_0_0"
const MENU_SCENE := "res://client/main/main.tscn"
const HELP_EXPLORATION := "Clic : se déplacer · Monstre : attaquer · PNJ : parler, commercer, fabriquer · Arbre, minerai : récolter · Flèches au bord : changer de carte · C : personnage · I : inventaire · Échap : menu"
const HELP_COMBAT := "Clic : se déplacer (cases vertes) · 1-5 : choisir un sort, clic : le lancer · Clic droit : annuler"

@onready var _map_view: MapView = $MapView
@onready var _combat_hud: CombatHud = $CombatHud
@onready var _sheet: CharacterSheet = $CharacterSheet
@onready var _inventory: InventoryWindow = $InventoryWindow
@onready var _shop: ShopWindow = $ShopWindow
@onready var _craft: CraftWindow = $CraftWindow
@onready var _inventory_button: Button = %InventoryButton
@onready var _info: Label = %Info
@onready var _sheet_button: Button = %SheetButton

var _hover_text := ""


func _ready() -> void:
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
	_map_view.notice.connect(_combat_hud.show_message)
	_map_view.hovered_cell_changed.connect(_on_hovered_cell_changed)
	_map_view.combat_started.connect(_on_combat_started)
	_map_view.exploration_resumed.connect(_on_exploration_resumed)
	_map_view.map_changed.connect(_on_map_changed)
	_map_view.character_changed.connect(_on_character_changed)
	_map_view.level_up.connect(_on_level_up)
	_sheet_button.pressed.connect(_sheet.toggle)
	_inventory_button.pressed.connect(_inventory.toggle)
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
	var start_map: GameMap = load_map.call(start_id)
	if start_map == null:
		start_map = load_map.call(DEFAULT_START_MAP)
	if start_map == null:
		return null
	return World.new(start_map, game_data, load_map, character)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _map_view.mode == MapView.Mode.EXPLORATION:
		if _shop.is_open():
			_shop.close()
			return
		if _craft.is_open():
			_craft.close()
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


func _on_combat_started() -> void:
	_sheet_button.visible = false
	_inventory_button.visible = false
	_update_info()


func _on_exploration_resumed() -> void:
	_sheet_button.visible = true
	_inventory_button.visible = true
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


func _update_info() -> void:
	var world := _map_view.world
	var sheet := world.character.sheet(world.data)
	var help := HELP_COMBAT if _map_view.mode == MapView.Mode.COMBAT else HELP_EXPLORATION
	var detail := "   ·   %s" % _hover_text if not _hover_text.is_empty() else ""
	var hero := "%s — niv. %d %s %s" % [sheet["nom"], sheet["niveau"], sheet["race_nom"], sheet["voie_nom"]]
	if int(sheet["points"]) > 0:
		hero += " (%d points à répartir)" % sheet["points"]
	_info.text = "%s   ·   %s%s\n%s" % [hero, _map_view.current_map().display_name, detail, help]
