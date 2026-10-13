extends SceneTree
## Capture d'écran du jeu, pour vérifier les graphismes sans éditeur :
##   xvfb-run -s "-screen 0 1280x720x24" godot --path game --rendering-driver opengl3 \
##     -s res://tools/screenshot.gd -- sortie.png [carte] [frames] [action]
## Lance la scène du monde (nouvelle partie), attend quelques images et enregistre la vue.
## Action : « combat » (engage le premier groupe de la carte), « butin » (écran de fin de combat d'exemple), « elite7 » (Loup alpha de rang 7 survolé), « inventaire », « metiers », « sorts » (ouvre la
## fenêtre ; « inventaire » remplit d'abord le sac d'un exemplaire de chaque objet) ou « pierre » (va utiliser
## la Pierre de Passage).
## Si « carte » commence par res://, c'est cette scène qui est capturée (menu, création…).

var _output := "capture.png"
var _frames := 30
var _scene: Node
var _action := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_output = args[0]
	var scene_path := "res://client/world/world.tscn"
	if args.size() > 1 and args[1].begins_with("res://"):
		scene_path = args[1]
	elif args.size() > 1 and not args[1].is_empty():
		Session.start_map = args[1]
	if args.size() > 2:
		_frames = int(args[2])
	_action = args[3] if args.size() > 3 else ""
	_scene = load(scene_path).instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	if not _action.is_empty() and _frames == 20:
		var view: MapView = _scene.get_node("MapView")
		if _action == "inventaire":
			# Un exemplaire de chaque objet du jeu (les ressources par 5), pour voir toutes les icônes.
			var world := view.world
			for item_id: String in world.data.items:
				var template: Dictionary = world.data.items[item_id]
				world.character.inventory.add(template, 1 if Item.is_equipment(template) else 5, Item.roll_bonuses(template, world.rng))
			_scene.get_node("InventoryWindow").toggle()
		elif _action.begins_with("elite"):
			# « elite7 » : le Loup alpha apparaît, vieux de 7 rangs, et on le survole.
			var world := view.world
			world.map_ids = [world.map.id]
			var events: Array[Dictionary] = []
			world.spawn_elite("loup_alpha", events)
			for event in events:
				view._apply_world_change(event)
			world.clock += int(_action.trim_prefix("elite")) * World.ELITE_RANK_SECONDS + 1.0
			var group := world.group(world.elite_location("loup_alpha")["groupe"])
			view._set_hovered(group["case"])
			Input.warp_mouse(view.get_global_transform_with_canvas() * IsoGrid.cell_to_screen(group["case"]))
		elif _action == "butin":
			# Écran de fin de combat avec un butin d'exemple.
			var drops: Array = []
			for item_id: String in ["croc_de_loup", "peau_de_loup", "amulette_croc", "cape_en_peau_de_loup", "lame_cendree"]:
				var template: Dictionary = view.world.data.items[item_id]
				drops.append({"objet": item_id, "nom": template["nom"], "rarete": template["rarete"],
					"quantite": 3 if item_id == "croc_de_loup" else 1})
			_scene.get_node("CombatHud")._on_combat_ended({"vainqueur": Fighter.TEAM_PLAYERS, "xp": 60, "ecus": 12, "butin": drops, "surcharge": true})
		elif _action == "metiers":
			_scene.get_node("JobsWindow").toggle()
		elif _action == "sorts":
			_scene.get_node("SpellsWindow").toggle()
		else:
			var target: Vector2i = view.world.groups()[0]["case"] if _action == "combat" else view.current_map().travel_stone()
			view._on_click(target)
			for i in 200:
				if not view.is_busy():
					break
				view._process(0.3)
		_action = ""
	_frames -= 1
	if _frames > 0:
		return false
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(_output)
	print("Capture : %s (%d × %d)" % [_output, image.get_width(), image.get_height()])
	return true
