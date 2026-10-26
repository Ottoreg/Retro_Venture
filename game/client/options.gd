class_name Options
extends RefCounted
## Réglages du joueur, gardés d'une partie à l'autre dans `user://options.cfg` (hors sauvegarde) :
## volume, plein écran, taille de la fenêtre (hors navigateur), mode tactique en combat et adresse
## du serveur de jeu (développement).

## Tailles de fenêtre proposées (sur ordinateur ; le navigateur garde la taille de sa page).
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

## Fichier des réglages (les tests en changent).
static var path := "user://options.cfg"
## Volume général, de 0 à 100.
static var volume := 80
static var fullscreen := false
## Indice dans WINDOW_SIZES.
static var window_size := 0
## Mode tactique en combat (GDD § 14.3) : retenu d'un combat à l'autre.
static var tactical := false
## En mode tactique, combattants en pions (cercle de la couleur du camp, initiale) plutôt qu'en
## personnages.
static var tactical_pawns := false
## Adresse du serveur de jeu (ws:// ou wss://) pour le développement ; vide : celle que publie le
## serveur de test dans Supabase (GDD § 16.5).
static var server_address := ""
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
	fullscreen = bool(file.get_value("affichage", "plein_ecran", fullscreen))
	window_size = clampi(int(file.get_value("affichage", "taille", window_size)), 0, WINDOW_SIZES.size() - 1)
	tactical = bool(file.get_value("combat", "tactique", tactical))
	tactical_pawns = bool(file.get_value("combat", "pions", tactical_pawns))
	server_address = str(file.get_value("en_ligne", "serveur", server_address))


static func save_options() -> void:
	var file := ConfigFile.new()
	file.set_value("son", "volume", volume)
	file.set_value("affichage", "plein_ecran", fullscreen)
	file.set_value("affichage", "taille", window_size)
	file.set_value("combat", "tactique", tactical)
	file.set_value("combat", "pions", tactical_pawns)
	file.set_value("en_ligne", "serveur", server_address)
	file.save(path)


## Remet les réglages par défaut (tests).
static func reset() -> void:
	volume = 80
	fullscreen = false
	window_size = 0
	tactical = false
	tactical_pawns = false
	server_address = ""
	_loaded = true


## Applique le volume et l'affichage (rien sur la fenêtre sans affichage, ni dans un navigateur
## pour la taille).
static func apply() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(volume / 100.0))
	AudioServer.set_bus_mute(bus, volume == 0)
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
