class_name Options
extends RefCounted
## Réglages du joueur, gardés d'une partie à l'autre dans `user://options.cfg` (hors sauvegarde) :
## volume général et de la musique, plein écran, taille de la fenêtre (hors navigateur), thème de couleurs, mode tactique en combat, adresse
## du serveur de jeu (développement), zoom de la minicarte et icônes masquées.

## Tailles de fenêtre proposées (sur ordinateur ; le navigateur garde la taille de sa page).
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

## Fichier des réglages (les tests en changent).
static var path := "user://options.cfg"
## Volume général, de 0 à 100.
static var volume := 80
## Musique de fond (en boucle, `MUSIC`) : volume de 0 à 100, et coupée ou non.
const MUSIC := "res://art/musique/cobblestone_afternoon.mp3"
static var music_volume := 60
static var music_on := true
static var _music: AudioStreamPlayer
static var fullscreen := false
## Indice dans WINDOW_SIZES.
static var window_size := 0
## Mode tactique en combat (GDD § 14.3) : retenu d'un combat à l'autre.
static var tactical := false
## En mode tactique, combattants en pions (cercle de la couleur du camp, initiale) plutôt qu'en
## personnages.
static var tactical_pawns := false
## Thème de couleurs de l'interface (clé de `UiTheme.THEMES`).
static var ui_theme := UiTheme.DEFAULT_THEME
## Adresse du serveur de jeu (ws:// ou wss://) pour le développement ; vide : celle que publie le
## serveur de test dans Supabase (GDD § 16.5).
static var server_address := ""
## Minicarte : cartes montrées de chaque côté (1 à 4 : de 3 × 3 à 9 × 9, molette) et icônes masquées
## (sortes de `MapIcons.KINDS`, légende de la carte du monde).
static var minimap_radius := 2
## Carte du monde : niveau de zoom (molette), d'une case par carte de `WorldMapWindow.ZOOM_WIDTHS`.
static var world_map_zoom := WorldMapWindow.DEFAULT_ZOOM
static var hidden_icons: Array = []
static var _loaded := false


## Relit les réglages (une fois par lancement, sauf `force`).
static func load_options(force := false) -> void:
	if _loaded and not force:
		return
	_loaded = true
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	volume = clampi(int(file.get_value("son", "volume", volume)), 0, 100)
	music_volume = clampi(int(file.get_value("son", "musique", music_volume)), 0, 100)
	music_on = bool(file.get_value("son", "musique_active", music_on))
	fullscreen = bool(file.get_value("affichage", "plein_ecran", fullscreen))
	window_size = clampi(int(file.get_value("affichage", "taille", window_size)), 0, WINDOW_SIZES.size() - 1)
	tactical = bool(file.get_value("combat", "tactique", tactical))
	tactical_pawns = bool(file.get_value("combat", "pions", tactical_pawns))
	ui_theme = str(file.get_value("affichage", "theme", ui_theme))
	if not UiTheme.THEMES.has(ui_theme):
		ui_theme = UiTheme.DEFAULT_THEME
	server_address = str(file.get_value("en_ligne", "serveur", server_address))
	minimap_radius = clampi(int(file.get_value("carte", "minicarte", minimap_radius)), 1, 4)
	world_map_zoom = clampi(int(file.get_value("carte", "zoom_monde", world_map_zoom)), 0, WorldMapWindow.ZOOM_WIDTHS.size() - 1)
	var hidden: Variant = file.get_value("carte", "icones_masquees", hidden_icons)
	hidden_icons = hidden if typeof(hidden) == TYPE_ARRAY else []


static func save_options() -> void:
	var file := ConfigFile.new()
	file.set_value("son", "volume", volume)
	file.set_value("son", "musique", music_volume)
	file.set_value("son", "musique_active", music_on)
	file.set_value("affichage", "plein_ecran", fullscreen)
	file.set_value("affichage", "taille", window_size)
	file.set_value("combat", "tactique", tactical)
	file.set_value("combat", "pions", tactical_pawns)
	file.set_value("affichage", "theme", ui_theme)
	file.set_value("en_ligne", "serveur", server_address)
	file.set_value("carte", "minicarte", minimap_radius)
	file.set_value("carte", "zoom_monde", world_map_zoom)
	file.set_value("carte", "icones_masquees", hidden_icons)
	file.save(path)


## Remet les réglages par défaut (tests).
static func reset() -> void:
	volume = 80
	music_volume = 60
	music_on = true
	fullscreen = false
	window_size = 0
	tactical = false
	tactical_pawns = false
	ui_theme = UiTheme.DEFAULT_THEME
	server_address = ""
	minimap_radius = 2
	world_map_zoom = WorldMapWindow.DEFAULT_ZOOM
	hidden_icons = []
	_loaded = true


## Applique le volume, la musique (lancée au premier appel, elle continue d'une scène à l'autre) et l'affichage (rien sur la fenêtre sans affichage, ni dans un navigateur
## pour la taille).
static func apply() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(volume / 100.0))
	AudioServer.set_bus_mute(bus, volume == 0)
	if _music == null:
		_music = AudioStreamPlayer.new()
		_music.stream = load(MUSIC)
		_music.stream.loop = true
		_music.process_mode = Node.PROCESS_MODE_ALWAYS  # Elle continue pendant la pause.
		_music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM  # Dans le navigateur, le mode « échantillon » ignore la boucle.
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_music)
		_music.play.call_deferred()
	_music.volume_db = linear_to_db(music_volume / 100.0 if music_on else 0.0)
	if DisplayServer.get_name() == "headless":
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if not OS.has_feature("web"):
			DisplayServer.window_set_size(WINDOW_SIZES[window_size])


## Vrai si le jeu peut changer la taille de sa fenêtre (pas dans un navigateur).
static func can_resize() -> bool:
	return not OS.has_feature("web")
