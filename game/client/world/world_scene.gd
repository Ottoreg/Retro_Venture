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
@onready var _minimap: Minimap = $Minimap
@onready var _world_map: WorldMapWindow = $WorldMapWindow
## Message d'erreur si le monde ne se charge pas (le nom de la carte est dans la bande gauche).
@onready var _info: Label = %Info

## Menu pause (Échap quand aucune fenêtre n'est ouverte).
var pause_menu: PauseMenu
## Groupes de joueurs (en ligne) : invitations.
var party_ui: PartyUi
## Amis et ignorés (en ligne, touche F).
var friends_window: FriendsWindow
## Quêtes : proposition d'un PNJ, journal (Q), suivi dans la bande gauche.
var quest_dialog: QuestDialog
var quests_window: QuestsWindow
var quest_tracker: QuestTracker
var _hover_text := ""
## Bulle près du curseur : ce qu'on survole (monstres, PNJ, ressources…).
var _hover_bubble: PanelContainer
var _hover_label: Label
var _hover_crown: EliteCrown
## Connexion au serveur perdue : on retourne à l'écran de connexion (une seule fois).
var _lost := false


func _ready() -> void:
	UiTheme.apply(get_tree())
	Options.load_options()
	Session.quest_pin = {}
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.main_menu_requested.connect(_back_to_menu)
	quest_dialog = QuestDialog.new()
	add_child(quest_dialog)
	quests_window = QuestsWindow.new()
	add_child(quests_window)
	quest_tracker = QuestTracker.new()
	add_child(quest_tracker)
	party_ui = PartyUi.new()
	add_child(party_ui)
	friends_window = FriendsWindow.new()
	add_child(friends_window)
	if Session.online_connection != null and Session.online_connection.is_open():
		_map_view.setup(Session.online_connection)  # En ligne : le monde tourne sur le serveur.
	else:
		var world := _create_world()
		if world == null:
			_info.text = "Impossible de charger le monde (carte de départ introuvable)."
			return
		world.map_ids = DataLoader.map_ids()  # Les élites peuvent apparaître sur toutes les cartes.
		_map_view.setup(LocalConnection.new(world))  # Solo : le monde tourne ici (GDD § 16.5).
	_combat_hud.setup(_map_view)
	_sheet.setup(_map_view)
	_inventory.setup(_map_view)
	_shop.setup(_map_view)
	_craft.setup(_map_view)
	_chest.setup(_map_view)
	_jobs.setup(_map_view)
	_travel.setup(_map_view)
	_spells.setup(_map_view)
	_minimap.setup(_map_view, _combat_hud)
	_world_map.setup(_map_view)
	_minimap.pressed.connect(_world_map.open)
	quest_dialog.setup(_map_view)
	party_ui.setup(_map_view)
	# Chat : le nom d'un auteur de l'historique ouvre son menu, « Message privé » la ligne de saisie.
	_combat_hud.message_log.author_clicked.connect(party_ui.on_author_clicked)
	party_ui.whisper_requested.connect(_combat_hud.message_log.whisper_to)
	friends_window.setup(_map_view)
	friends_window.player_menu_requested.connect(party_ui.on_author_clicked)
	_combat_hud.friends_pressed.connect(friends_window.toggle)
	quests_window.setup(_map_view)
	quest_tracker.setup(_map_view, _combat_hud)
	quest_tracker.pressed.connect(quests_window.toggle)
	quest_dialog.pin_requested.connect(_on_pin_requested)
	quests_window.pin_requested.connect(_on_pin_requested)
	_world_map.pin_cleared.connect(_set_pin.bind({}))
	_world_map.flag_requested.connect(_on_flag_requested)
	_world_map.icons_changed.connect(_minimap.refresh)
	_minimap.flag_requested.connect(_on_flag_requested)
	_combat_hud.menu_pressed.connect(_on_menu_pressed)
	_map_view.notice.connect(_combat_hud.show_message)
	_map_view.hovered_cell_changed.connect(_on_hovered_cell_changed)
	_map_view.combat_started.connect(_on_combat_started)
	_map_view.exploration_resumed.connect(_on_exploration_resumed)
	_map_view.map_changed.connect(_on_map_changed)
	_map_view.character_changed.connect(_on_character_changed)
	_map_view.level_up.connect(_on_level_up)
	_map_view.inventory_changed.connect(_on_inventory_changed)
	_map_view.progress_changed.connect(_save)
	get_viewport().size_changed.connect(_center_map)
	_map_view.announce_combat()
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
	if _map_view.connection != null and not _map_view.connection.is_open() and not _lost:
		_lost = true
		var remote := _map_view.connection as RemoteConnection
		var message := remote.error_message if remote != null else ""
		Session.online_connection = null
		# Coupure (réseau, serveur relancé) : l'écran de connexion la rouvre tout seul ; un refus du
		# serveur (version, compte connecté ailleurs…) s'affiche.
		Session.online_resume = remote != null and not remote.refused and not Session.online_login.is_empty()
		Session.online_error = "" if Session.online_resume else message if not message.is_empty() else "Connexion au serveur perdue."
		get_tree().change_scene_to_file(OnlineScreen.SCENE)
		return
	if _hover_bubble != null and _hover_bubble.visible:
		var screen := get_viewport().get_visible_rect().size
		_hover_bubble.position = bubble_position(get_viewport().get_mouse_position(), _hover_bubble.size, screen)


## Place d'une bulle de survol près du curseur, entièrement dans l'écran : à droite et en dessous,
## sinon de l'autre côté du curseur, et toujours recalée au bord s'il le faut.
static func bubble_position(mouse: Vector2, bubble: Vector2, screen: Vector2) -> Vector2:
	const MARGIN := 4.0
	var spot := mouse + Vector2(18, 22)
	if spot.x + bubble.x > screen.x - MARGIN:
		spot.x = mouse.x - bubble.x - 8.0
	if spot.y + bubble.y > screen.y - MARGIN:
		spot.y = mouse.y - bubble.y - 8.0
	spot.x = clampf(spot.x, MARGIN, maxf(MARGIN, screen.x - bubble.x - MARGIN))
	spot.y = clampf(spot.y, MARGIN, maxf(MARGIN, screen.y - bubble.y - MARGIN))
	return spot



func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _map_view.mode != MapView.Mode.EXPLORATION:
		if _inventory.is_open():  # Consultable en combat.
			_inventory.toggle()
			return
		pause_menu.open(true)  # En combat : Échap désélectionne d'abord le sort choisi (barre du bas).
		return
	# La carte du monde d'abord : elle est au-dessus des autres fenêtres (calque 3), même de la
	# proposition de quête (ouverte par un nom cliqué).
	if _world_map.is_open():
		_world_map.close()
		return
	if quest_dialog.is_open():
		quest_dialog.later()
		return
	if _combat_hud.is_result_open():
		_combat_hud.close_result()
		return
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
	if quests_window.is_open():
		quests_window.toggle()
		return
	pause_menu.open()


func _back_to_menu() -> void:
	_save()
	if _map_view.connection != null and _map_view.connection == Session.online_connection:
		Session.online_connection.close()
		Session.online_connection = null
	get_tree().change_scene_to_file(MENU_SCENE)


## Sauvegarde automatique (jamais pendant un combat) ; en ligne, le serveur s'en charge.
func _save() -> void:
	if _map_view.world == null or _map_view.world.in_combat():
		return
	var save := _map_view.connection.save_data()
	if not save.is_empty():
		SaveGame.write(save)


## La carte à l'échelle de la zone de jeu, centrée entre les bordures d'interface (`ScreenLayout`).
func _center_map() -> void:
	var screen := get_viewport_rect().size
	var map_scale := ScreenLayout.map_scale(screen)
	_map_view.scale = Vector2(map_scale, map_scale)
	_map_view.position = ScreenLayout.map_position(screen, _map_view.current_map().screen_rect().size)


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
	elif menu == "carte":
		_world_map.toggle()
	elif menu == "quetes":
		quests_window.toggle()


func _on_combat_started() -> void:
	_update_info()


func _on_exploration_resumed() -> void:
	_update_info()
	_save()


## Nom cliqué dans un texte de quête : pose le repère et ouvre la carte du monde sur sa zone ; le
## même nom une seconde fois le retire.
func _on_pin_requested(pin: Dictionary) -> void:
	if pin == Session.quest_pin:
		_set_pin({})
		_combat_hud.show_message("Repère retiré.")
		return
	_set_pin(pin)
	_combat_hud.show_message("Repère posé : %s." % pin["nom"])
	_world_map.show_pin()


## Drapeau (clic droit sur la minicarte ou la carte du monde) : le repère, montré au groupe avec Maj ;
## le même une seconde fois le retire.
func _on_flag_requested(pin: Dictionary, shared: bool) -> void:
	if pin.get("carte") == Session.quest_pin.get("carte") and pin.get("nom") == Session.quest_pin.get("nom"):
		_set_pin({})
		_combat_hud.show_message("Drapeau retiré.")
		return
	_set_pin(pin, shared)
	_combat_hud.show_message("Drapeau posé%s : %s." % [" pour le groupe" if shared else "", pin["nom"]])


## Pose le repère (`share` : montré aux membres du groupe, GDD § 16.5, M2 ; sinon, celui qu'ils
## voyaient est retiré).
func _set_pin(pin: Dictionary, share := true) -> void:
	Session.quest_pin = pin
	_map_view.share_pin(pin if share else {})
	_minimap.refresh()
	_world_map.refresh()


func _on_map_changed() -> void:
	# Arrivé à la carte du repère : il a servi.
	if not Session.quest_pin.is_empty() and Session.quest_pin["carte"] == WorldMapWindow.here_map(_map_view.world):
		_combat_hud.show_message("Vous y êtes : %s." % Session.quest_pin["nom"])
		_set_pin({})
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
	_combat_hud.map_title.text = _map_view.current_map().display_name
	if _hover_bubble == null:
		_build_hover_bubble()
	_hover_label.text = _hover_text
	_hover_crown.rank = _map_view.elite_rank_at(_map_view.hovered_cell())
	_hover_bubble.visible = not _hover_text.is_empty() and not _hover_text.begins_with("case (") \
			and get_viewport().gui_get_hovered_control() == null
	_hover_bubble.reset_size()


func _build_hover_bubble() -> void:
	_hover_bubble = PanelContainer.new()
	_hover_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_bubble.add_theme_stylebox_override("panel", UiTheme.tooltip_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	_hover_bubble.add_child(column)
	_hover_crown = EliteCrown.new()
	_hover_crown.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hover_crown.rank = 0
	column.add_child(_hover_crown)
	_hover_label = Label.new()
	_hover_label.add_theme_font_size_override("font_size", 14)
	_hover_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	column.add_child(_hover_label)
	# Au premier plan, au-dessus des bandes, de la barre et des fenêtres (voir `TOOLTIP_LAYER`).
	var layer := CanvasLayer.new()
	layer.name = "Infobulles"
	layer.layer = UiTheme.TOOLTIP_LAYER
	add_child(layer)
	layer.add_child(_hover_bubble)
