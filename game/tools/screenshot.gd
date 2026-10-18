extends SceneTree
## Capture d'écran du jeu, pour vérifier les graphismes sans éditeur :
##   xvfb-run -s "-screen 0 1280x720x24" godot --path game --rendering-driver opengl3 \
##     -s res://tools/screenshot.gd -- sortie.png [carte] [frames] [action]
## Lance la scène du monde (nouvelle partie), attend quelques images et enregistre la vue.
## Action : « combat » (engage le premier groupe de la carte), « butin » (écran de fin de combat d'exemple), « elite7 » (Loup alpha de rang 7 survolé), « cible » (combat, monstre survolé), « sermon » (Théologue en combat, Sermon visé devant lui), « panoplie » (3 pièces portées), « inventaire », « metiers », « sorts » (ouvre la
## fenêtre ; « inventaire » remplit d'abord le sac d'un exemplaire de chaque objet), « pierre » (va utiliser
## la Pierre de Passage), « glyphe » (combat contre l'Arbre millénaire, glyphe posée, héros ralenti et
## empoisonné, à lancer sur sylvebrume_0_0), « survol » (le plus grand groupe de la carte survolé :
## bulle avec le niveau tiré de chaque monstre), « phase » (comme « cible » ; le monstre survolé reçoit
## une phase pour l'occasion et passe sous son seuil : message et texte flottant), « reveil » (combat
## perdu contre le premier groupe : réveil près de la Pierre de Passage du point de résurrection, à
## lancer par exemple sur brumerive_1_0), « carte » (ouvre la carte du monde ; la minicarte, elle,
## est visible sur toute capture en exploration), « repliee » (minicarte repliée), « tactique »
## (comme « cible », en mode tactique), « pause » (menu pause), « options » (fenêtre des options),
## « quete » (le premier PNJ qui propose une quête : sa proposition), « journal » (cette quête
## acceptée, le journal ouvert ; le suivi est sous la minicarte), « historique » (combat, deux tours
## passés : historique du combat rempli).
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
	if _action == "sermon":
		Session.new_character = Character.create("Frère Tuck", "humain", "theologue")
	Session.minimap_folded = _action == "repliee"
	# Réglages par défaut (ceux du joueur ne comptent pas), mode tactique si demandé.
	Options.reset()
	Options.tactical = _action == "tactique"
	_scene = load(scene_path).instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	if not _action.is_empty() and _frames == 20:
		var view: MapView = _scene.get_node("MapView")
		if _action == "panoplie":
			# Trois pièces de la Panoplie du Pyromane Repenti portées, l'amulette choisie.
			var world := view.world
			for slot in ["coiffe", "cape", "amulette"]:
				var template: Dictionary = world.data.items[slot + "_pyromane_repenti"]
				var uid := world.character.inventory.add(template, 1, Item.roll_bonuses(template, world.rng))
				world.character.inventory.equip(uid, slot)
			var window: InventoryWindow = _scene.get_node("InventoryWindow")
			window.toggle()
			window._selected = world.character.inventory.equipped["amulette"]
			window.refresh()
		elif _action == "inventaire":
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
		elif _action == "glyphe":
			# Combat contre l'Arbre millénaire : sa glyphe posée, le héros ralenti et empoisonné, survolé.
			var world := view.world
			world.map_ids = [world.map.id]
			var spawned: Array[Dictionary] = []
			world.spawn_elite("arbre_millenaire", spawned)
			for event in spawned:
				view._apply_world_change(event)
			view._on_click(world.group(world.elite_location("arbre_millenaire")["groupe"])["case"])
			_wait_for(view)
			view.request_start_fight()
			_wait_for(view)
			var combat := world.combat
			var hero := view.player_fighter()
			var tree: Fighter = null
			for fighter in combat.fighters:
				if fighter.kind == "arbre_millenaire":
					tree = fighter
			var events := combat._cast(tree, {"type": Protocol.CMD_CAST, "entite": tree.id, "sort": "millenaire_cercle_de_seve", "cible": tree.cell})
			combat._add_state(hero, {"type": Spell.EFFECT_MALUS, "carac": "pm", "element": "", "valeur": 2, "tours": 1, "sort": "Cercle de sève", "lanceur": tree.id}, events)
			combat._add_state(hero, {"type": Spell.EFFECT_POISON, "element": "givre", "valeur": 6, "tours": 3, "sort": "Test", "lanceur": tree.id}, events)
			view._queue.append_array(events)
			view._playing = true
			view._play_next()
			_wait_for(view)
			view._set_hovered(hero.cell)
		elif _action == "survol":
			# Le groupe le plus varié (puis le plus nombreux), survolé : un monstre par ligne, avec son
			# niveau tiré.
			var biggest: Dictionary = {}
			var best_score := -1
			for group: Dictionary in view.world.groups():
				var kinds := {}
				for monster_id: String in group["monstres"]:
					kinds[monster_id] = true
				var score: int = kinds.size() * 10 + group["monstres"].size()
				if score > best_score:
					best_score = score
					biggest = group
			view._set_hovered(biggest["case"])
			Input.warp_mouse(view.get_global_transform_with_canvas() * IsoGrid.cell_to_screen(biggest["case"]))
		elif _action == "reveil":
			# Combat perdu (le héros à 1 PV passe ses tours), puis « Continuer » : réveil et message.
			view._on_click(view.world.groups()[0]["case"])
			_wait_for(view)
			view.request_start_fight()
			_wait_for(view)
			view.world.combat.get_fighter(World.PLAYER_ID).hp = 1
			for i in 100:
				if view._paused:
					break
				view.request_end_turn()
				_wait_for(view)
			_scene.get_node("CombatHud")._on_continue_pressed()
			_wait_for(view)
		elif _action == "metiers":
			_scene.get_node("JobsWindow").toggle()
		elif _action == "sorts":
			_scene.get_node("SpellsWindow").toggle()
		elif _action == "carte":
			_scene.get_node("WorldMapWindow").open()
		elif _action == "repliee":
			pass  # Minicarte repliée dès le départ (voir `_initialize`).
		elif _action in ["quete", "journal"]:
			for npc in view.current_map().npcs:
				if view.world.quest_book.marker(npc["id"]) == QuestBook.MARKER_AVAILABLE:
					view._on_click(npc["case"])
					_wait_for(view)
					break
			if _action == "journal":
				_scene.quest_dialog.accept()
				_wait_for(view)
				_scene.quests_window.toggle()
		elif _action == "pause":
			_scene.pause_menu.open()
		elif _action == "options":
			_scene.pause_menu.open()
			_scene.pause_menu._on_options_pressed()
		else:
			var target: Vector2i = view.world.groups()[0]["case"] if _action in ["combat", "cible", "sermon", "phase", "tactique", "historique"] else view.current_map().travel_stone()
			if _action == "phase":
				# Aucun monstre n'a encore de phases dans les données : le premier du groupe en reçoit une.
				var monster: Dictionary = view.world.data.monsters[view.world.groups()[0]["monstres"][0]]
				monster["phases"] = [{"pv": 90, "message": "%s entre dans une rage folle !" % monster["nom"], "sorts": [],
					"effets": [{"type": "bonus", "carac": "force", "min": 50, "max": 50, "duree": 2}]}]
			view._on_click(target)
			for i in 200:
				if not view.is_busy():
					break
				view._process(0.3)
			if _action in ["cible", "sermon", "phase", "tactique", "historique"] and view.world.combat != null:
				# Placement validé, puis survol du premier monstre.
				view.request_start_fight()
				for i in 200:
					if not view.is_busy():
						break
					view._process(0.3)
				# Historique : deux tours passés, le temps que les monstres frappent.
				for turn in 2 if _action == "historique" else 0:
					view.request_end_turn()
					for i in 200:
						if not view.is_busy() or view._paused:
							break
						view._process(0.3)
				if _action == "sermon":
					# Sermon choisi, case visée à 2 cases devant le Théologue, vers les monstres.
					var hero := view.player_fighter()
					var foe := view.world.combat.enemies_of(hero)[0]
					view.selected_spell = "theologue_sermon"
					view._refresh_overlays()
					view._set_hovered(hero.cell + Spell.direction(hero.cell, foe.cell))
				for fighter in view.world.combat.fighters if _action in ["cible", "phase", "tactique"] else []:
					if fighter.team != Fighter.TEAM_PLAYERS:
						if _action == "phase":
							# Un tiers de ses PV perdus : le noyau déclenche la phase (seuil à 90 %).
							var events: Array[Dictionary] = []
							view.world.combat._hurt(fighter, ceili(fighter.hp / 3.0), "acier", events)
							view._queue.append_array(events)
							view._playing = true
							view._play_next()
							view._process(0.3)  # Après les dégâts, le changement de phase.
						view._set_hovered(fighter.cell)
						break
		_action = ""
	_frames -= 1
	if _frames > 0:
		return false
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(_output)
	print("Capture : %s (%d × %d)" % [_output, image.get_width(), image.get_height()])
	return true


func _wait_for(view: MapView) -> void:
	for i in 200:
		if not view.is_busy():
			return
		view._process(0.3)
