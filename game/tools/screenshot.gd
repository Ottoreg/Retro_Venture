extends SceneTree
## Capture d'écran du jeu, pour vérifier les graphismes sans éditeur :
##   xvfb-run -s "-screen 0 1280x720x24" godot --path game --rendering-driver opengl3 \
##     -s res://tools/screenshot.gd -- sortie.png [carte] [frames] [action]
## Lance la scène du monde (nouvelle partie), attend quelques images et enregistre la vue.
## Action : « combat » (engage le premier groupe de la carte), « butin » / « defaite » (écran de fin de combat d’exemple : victoire, défaite), « elite7 » (Loup alpha de rang 7 survolé), « cible » (combat, monstre survolé), « sermon » (Théologue en combat, Sermon visé devant lui), « prevision » (comme « sermon », un monstre dans la zone : dégâts prévus), « panoplie » (3 pièces portées), « inventaire », « ressources » (inventaire, onglet Ressources), « assis » (blessé, assis), « metiers », « sorts » (ouvre la
## fenêtre ; « inventaire » remplit d'abord le sac d'un exemplaire de chaque objet), « pierre » (va utiliser
## la Pierre de Passage), « glyphe » (combat contre l'Arbre millénaire, glyphe posée, héros ralenti et
## empoisonné, à lancer sur sylvebrume_0_0), « sortie » (sortie de droite survolée : bulle « Vers : … »), « survol » (le plus grand groupe de la carte survolé :
## bulle avec le niveau tiré de chaque monstre), « phase » (comme « cible » ; le monstre survolé reçoit
## une phase pour l'occasion et passe sous son seuil : message et texte flottant), « reveil » (combat
## perdu contre le premier groupe : réveil près de la Pierre de Passage du point de résurrection, à
## lancer par exemple sur brumerive_1_0), « carte » (ouvre la carte du monde ; « monde » : dézoomée au plus loin, la carte actuelle survolée ; la minicarte, elle,
## est visible sur toute capture en exploration), « tactique »
## (comme « cible », en mode tactique ; « pions » : avec les pions), « pause » (menu pause), « options » (fenêtre des options),
## « quete » (le premier PNJ qui propose une quête : sa proposition), « journal » (cette quête
## acceptée, le journal ouvert ; le suivi est sous la minicarte), « repere » (la même, puis un
## repère posé sur le Moulin de Tournevent : carte du monde ouverte), « suivi » (la même, à l'étape des
## combats : épingle jaune de l'objectif suivi, carte du monde ouverte), « historique » (combat, deux tours
## passés : historique du combat rempli), « arcaniste » (Arcaniste en combat : 3 états, un sort
## créé, une place vide), « composition » (la même, grille de Composition ouverte au-dessus du sort),
## « infobulle » (la même, souris sur le sort Composition : son infobulle, compter ~120 images),
## « objet » (inventaire, bottes portées, souris sur d'autres bottes du sac : infobulle comparée).
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
	if _action in ["sermon", "prevision"]:
		Session.new_character = Character.create("Frère Tuck", "humain", "theologue")
	if _action in ["arcaniste", "composition", "infobulle"]:
		Session.new_character = Character.create("Mirabelle", "humain", "arcaniste")
	# Réglages par défaut (ceux du joueur ne comptent pas), mode tactique si demandé.
	Options.reset()
	if _action == "pions":
		_action = "tactique"
		Options.tactical_pawns = true
	Options.tactical = _action == "tactique"
	_scene = load(scene_path).instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	if not _action.is_empty() and _frames == 20:
		var view: MapView = _scene.get_node("MapView")
		if _action == "panoplie":
			# Trois pièces de la Panoplie du Pyromane Repenti portées, l'amulette choisie.
			var world := view.server
			for slot in ["coiffe", "cape", "amulette"]:
				var template: Dictionary = world.data.items[slot + "_pyromane_repenti"]
				var uid := world.character.inventory.add(template, 1, Item.roll_bonuses(template, world.rng))
				view.refresh_state()
				world.character.inventory.equip(uid, slot)
				view.refresh_state()
			var window: InventoryWindow = _scene.get_node("InventoryWindow")
			window.toggle()
			window._selected = world.character.inventory.equipped["amulette"]
			window.refresh()
		elif _action == "objet":
			# Bottes de marche portées ; d'autres bottes dans le sac, survolées : leur infobulle comparée.
			var world := view.server
			var inventory := world.character.inventory
			inventory.equip(inventory.add(world.data.items["bottes_de_marche"], 1, {"agilite": 3, "initiative": 12}), "bottes")
			view.refresh_state()
			var other := inventory.add(world.data.items["bottes_forgeron_hargneux"], 1, {"force": 5, "initiative": 8})
			view.refresh_state()
			var window: InventoryWindow = _scene.get_node("InventoryWindow")
			window.toggle()
			create_timer(0.2).timeout.connect(func() -> void:
				for index in window._list.item_count:
					if window._list.get_item_metadata(index) == other:
						var motion := InputEventMouseMotion.new()
						motion.position = window._list.get_global_transform() * window._list.get_item_rect(index).get_center()
						motion.global_position = motion.position
						Input.warp_mouse(motion.position)
						root.push_input(motion)
						# L'infobulle native n'apparaît pas toujours dans les captures : on la reproduit
						# (même panneau, même texte) sous le curseur.
						var layer := CanvasLayer.new()
						layer.layer = UiTheme.TOOLTIP_LAYER
						var panel := PanelContainer.new()
						panel.add_theme_stylebox_override("panel", UiTheme.tooltip_style())
						panel.add_child(window._list._make_custom_tooltip(window._list.get_item_tooltip(index)))
						panel.position = motion.position + Vector2(10, 16)
						layer.add_child(panel)
						root.add_child(layer))
		elif _action in ["inventaire", "ressources"]:
			# Un exemplaire de chaque objet du jeu (les ressources par 5), pour voir toutes les icônes.
			var world := view.server
			for item_id: String in world.data.items:
				var template: Dictionary = world.data.items[item_id]
				world.character.inventory.add(template, 1 if Item.is_equipment(template) else 5, Item.roll_bonuses(template, world.rng))
				view.refresh_state()
			_scene.get_node("InventoryWindow").toggle()
			if _action == "ressources":
				_scene.get_node("InventoryWindow").show_bag_tab(InventoryWindow.BagTab.RESOURCES)
		elif _action.begins_with("elite"):
			# « elite7 » : le Loup alpha apparaît, vieux de 7 rangs, et on le survole.
			var world := view.server
			world.map_ids = [world.map.id]
			view.refresh_state()
			var events: Array[Dictionary] = []
			world.spawn_elite("loup_alpha", events)
			view.refresh_state()
			for event in events:
				view._apply_world_change(event)
			world.clock += int(_action.trim_prefix("elite")) * World.ELITE_RANK_SECONDS + 1.0
			view.refresh_state()
			var group := world.group(world.elite_location("loup_alpha")["groupe"])
			Input.warp_mouse(view.get_global_transform_with_canvas() * IsoGrid.cell_to_screen(group["case"]))
		elif _action == "butin" or _action == "defaite":
			# Écran de fin de combat d'exemple : victoire avec butin, ou défaite.
			var drops: Array = []
			for item_id: String in ["croc_de_loup", "peau_de_loup", "amulette_croc", "cape_en_peau_de_loup", "lame_cendree"]:
				var template: Dictionary = view.server.data.items[item_id]
				drops.append({"objet": item_id, "nom": template["nom"], "rarete": template["rarete"],
					"quantite": 3 if item_id == "croc_de_loup" else 1})
			var roster: Array = [{"id": World.PLAYER_ID, "nom": view.server.player_name, "niveau": 4, "equipe": Fighter.TEAM_PLAYERS, "vivant": true}]
			for i in 3:
				roster.append({"id": "loup%d" % i, "nom": "Loup", "niveau": 3 + i, "equipe": Fighter.TEAM_MONSTERS, "vivant": i > 0})
			roster.append({"id": "chef", "nom": "Chef de meute", "niveau": 6, "equipe": Fighter.TEAM_MONSTERS, "vivant": true})
			if _action == "butin":
				for entry: Dictionary in roster.slice(1):
					entry["vivant"] = false
			var victory := _action == "butin"
			view.server.character.level = 5
			view.refresh_state()
			view.server.character.xp = Character.xp_for_level(5) + 260
			view.refresh_state()
			_scene.get_node("CombatHud")._on_combat_ended({"vainqueur": Fighter.TEAM_PLAYERS if victory else Fighter.TEAM_MONSTERS,
				"xp": 260 if victory else 40, "ecus": 12 if victory else 0, "butin": drops if victory else [], "surcharge": victory,
				"niveaux": [5] if victory else [], "tours": 7, "combattants": roster,
				"reveil": {} if victory else {"passage": "x", "nom": "Brumerive", "carte": ""}})
		elif _action == "glyphe":
			# Combat contre l'Arbre millénaire : sa glyphe posée, le héros ralenti et empoisonné, survolé.
			var world := view.server
			world.map_ids = [world.map.id]
			view.refresh_state()
			var spawned: Array[Dictionary] = []
			world.spawn_elite("arbre_millenaire", spawned)
			view.refresh_state()
			for event in spawned:
				view._apply_world_change(event)
			view._on_click(world.group(world.elite_location("arbre_millenaire")["groupe"])["case"])
			_wait_for(view)
			view.request_start_fight()
			_wait_for(view)
			var combat := world.combat
			var hero := view.server.combat.get_fighter(World.PLAYER_ID)
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
			for group: Dictionary in view.server.groups():
				var kinds := {}
				for monster_id: String in group["monstres"]:
					kinds[monster_id] = true
				var score: int = kinds.size() * 10 + group["monstres"].size()
				if score > best_score:
					best_score = score
					biggest = group
			view._set_hovered(biggest["case"])
			Input.warp_mouse(view.get_global_transform_with_canvas() * IsoGrid.cell_to_screen(biggest["case"]))
		elif _action == "sortie":
			# Souris sur la sortie de droite la plus basse : bulle « Vers : … » au bord de la bande droite.
			var exits: Dictionary = view.current_map().exit_cells()
			var side: String = "droite" if exits.has("droite") else str(exits.keys()[0])
			var cell: Vector2i = exits[side][-1]
			view._set_hovered(cell)
			Input.warp_mouse(view.get_global_transform_with_canvas() * IsoGrid.cell_to_screen(cell))
		elif _action == "reveil":
			# Combat perdu (le héros à 1 PV passe ses tours), récap refermé : réveil et message.
			view._on_click(view.server.groups()[0]["case"])
			_wait_for(view)
			view.request_start_fight()
			_wait_for(view)
			view.server.combat.get_fighter(World.PLAYER_ID).hp = 1
			view.refresh_state()
			for i in 100:
				if view.mode == MapView.Mode.EXPLORATION:
					break
				view.request_end_turn()
				_wait_for(view)
			_scene.get_node("CombatHud").close_result()
		elif _action == "fiche":
			# Fiche du personnage avec quelques points investis (bouton « Réinitialiser » actif).
			view.server.character.add_xp(Character.xp_for_level(4))
			view.refresh_state()
			view.server.character.spend_points("force", 6)
			view.refresh_state()
			_scene.get_node("CharacterSheet").toggle()
		elif _action == "joueurs":
			# Multijoueur (M1) : deux autres joueurs sur la carte, dont un assis.
			var here := view.server.position_of(World.PLAYER_ID)
			var others := [["Grizzette", "gobelin", "rodeur", Vector2i(2, 1)], ["Lindëa", "elfe", "arcaniste", Vector2i(-1, 2)]]
			for other: Array in others:
				var cell: Vector2i = here + other[3]
				view.server.add_player(Character.create(other[0], other[1], other[2]), "j:" + other[0], view.server.map.id, cell)
			view.server.player("j:Lindëa").sitting = true
			view.refresh_state()
			view._load_exploration_actors()
		elif _action == "groupe":
			# Multijoueur (M2) : groupe avec Grizzette, qui a engagé un groupe de monstres (ses épées).
			var here := view.server.position_of(World.PLAYER_ID)
			var friend := Character.create("Grizzette", "gobelin", "rodeur")
			view.server.add_player(friend, "j:Grizzette", view.server.map.id, here + Vector2i(2, 1))
			view.server.execute({"type": Protocol.CMD_PARTY_INVITE, "entite": World.PLAYER_ID, "joueur": "j:Grizzette"})
			view.server.execute({"type": Protocol.CMD_PARTY_ANSWER, "entite": "j:Grizzette", "chef": World.PLAYER_ID, "accepte": true})
			var group: Dictionary = view.server.groups()[0]
			view.server.execute({"type": Protocol.CMD_ENGAGE, "entite": "j:Grizzette", "groupe": group["id"]})
			view.refresh_state()
			view._load_exploration_actors()
			view.party_changed.emit()
		elif _action == "chat":
			# Chat (M3) : quelques messages de joueurs dans l'historique, la ligne de saisie ouverte.
			var log: MessageLog = _scene.get_node("CombatHud").message_log
			log.set_chat_enabled(true)
			log.own_name = view.world.player_name
			log.select_channel(MessageLog.CHANNEL_ALL)
			log.add_chat({"canal": Chat.LOCAL, "de": "j:1", "auteur": "Grizzette", "texte": "Quelqu'un pour les Brumes du Nord ?"})
			log.add_chat({"canal": Chat.RECRUIT, "de": "j:2", "auteur": "Lindëa", "texte": "Groupe pour Grondin, il manque un soigneur"})
			log.add_chat({"canal": Chat.TRADE, "de": "j:3", "auteur": "Barlomir", "texte": "Vends 20 bois de frêne, 15 brumes pièce"})
			log.add_chat({"canal": Chat.PRIVATE, "de": "j:1", "auteur": "Grizzette", "texte": "Tu es où ?", "a": view.world.player_name})
			log.add_chat({"canal": Chat.PARTY, "de": "j:1", "auteur": "Grizzette", "texte": "J'arrive par la Pierre"})
			log.toggle_typing()
			log._input.text = "/g deux minutes et je suis là"
		elif _action == "amis":
			# Amis (M3) : un ami en ligne (réciproque), un hors ligne, un ignoré ; la fenêtre ouverte.
			var here := view.server.position_of(World.PLAYER_ID)
			view.server.add_player(Character.create("Grizzette", "gobelin", "rodeur"), "j:Grizzette", view.server.map.id, here + Vector2i(2, 1))
			view.server.player("j:Grizzette").friends.append(view.server.character.display_name)
			view.server.add_player(Character.create("Lindëa", "elfe", "arcaniste"), "j:Lindëa", view.server.map.id, here + Vector2i(-1, 2))
			for entry: Array in [[Relations.ADD, "Grizzette"], [Relations.ADD, "Lindëa"], [Relations.ADD, "Barlomir"],
					[Relations.IGNORE, "Trolldu"]]:
				view.server.execute({"type": Protocol.CMD_RELATIONS, "entite": World.PLAYER_ID, "action": entry[0], "nom": entry[1]})
			view.refresh_state()
			var window: FriendsWindow = _scene.friends_window
			window.enabled = true
			window.open()
		elif _action == "assis":
			view.server.character.hp_lost = 30
			view.refresh_state()
			view.send_command({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": view.server.position_of(World.PLAYER_ID) + Vector2i(2, 2)})
			_wait_for(view)
			view.toggle_sit()
			_wait_for(view)
		elif _action == "boutique":
			# Un achat et une vente (historique du commerce), puis une recherche dans la boutique.
			for npc in view.current_map().npcs:
				if npc["marchand"]:
					view._on_click(npc["case"])
					_wait_for(view)
					break
			var shop: ShopWindow = _scene.get_node("ShopWindow")
			view.server.character.inventory.ecus = 500
			view.refresh_state()
			shop._on_item_selected(0)
			shop._on_action_pressed()
			_wait_for(view)
			shop._on_tab_pressed(ShopWindow.SELL)
			for entry: Dictionary in shop._entries():
				if not shop._is_worn(entry):
					shop._selected = entry["uid"]
					break
			shop.refresh()
			shop._on_action_pressed()
			_wait_for(view)
			shop._on_tab_pressed(ShopWindow.BUY)
			shop._search.text = "botte"
			shop.refresh()
		elif _action == "metiers":
			_scene.get_node("JobsWindow").toggle()
		elif _action == "sorts":
			_scene.get_node("SpellsWindow").toggle()
		elif _action in ["carte", "monde"]:
			if _action == "monde":
				Options.world_map_zoom = 0
			var world_map: WorldMapWindow = _scene.get_node("WorldMapWindow")
			world_map.open()
			if _action == "monde":
				# La carte actuelle survolée : sa zone entourée.
				world_map._grid.size = Vector2(780, 280)
				world_map.hover(world_map._grid.cell_rect(world_map._grid.map_cell(WorldMapWindow.here_map(view.world))).get_center())
		elif _action == "suivi":
			# Quête suivie : l'épingle jaune de son objectif (vaincre, à l'étape 2 du tutoriel) sur la
			# carte du monde et la minicarte.
			for npc in view.current_map().npcs:
				if view.server.quest_book.marker(npc["id"]) == QuestBook.MARKER_AVAILABLE:
					view._on_click(npc["case"])
					_wait_for(view)
					break
			_scene.quest_dialog.accept()
			_wait_for(view)
			var quest_id: String = view.server.character.quests.tracked
			view.server.character.quests.set_step(quest_id, 1, 0)
			view.refresh_state()
			_scene.get_node("Minimap").refresh()
			_scene.get_node("WorldMapWindow").open()
		elif _action in ["quete", "journal", "repere"]:
			for npc in view.current_map().npcs:
				if view.server.quest_book.marker(npc["id"]) == QuestBook.MARKER_AVAILABLE:
					view._on_click(npc["case"])
					_wait_for(view)
					break
			if _action in ["journal", "repere"]:
				_scene.quest_dialog.accept()
				_wait_for(view)
				_scene.quests_window.toggle()
			if _action == "repere":
				_scene._on_pin_requested({"carte": "brumerive_1_1", "nom": "Moulin de Tournevent"})
		elif _action == "pause":
			_scene.pause_menu.open()
		elif _action == "options":
			_scene.pause_menu.open()
			_scene.pause_menu._on_options_pressed()
		else:
			var target: Vector2i = view.server.groups()[0]["case"] if _action in ["combat", "cible", "sermon", "prevision", "phase", "tactique", "historique", "arcaniste", "composition", "infobulle"] else view.current_map().travel_stone()
			if _action == "phase":
				# Aucun monstre n'a encore de phases dans les données : le premier du groupe en reçoit une.
				var monster: Dictionary = view.server.data.monsters[view.server.groups()[0]["monstres"][0]]
				monster["phases"] = [{"pv": 90, "message": "%s entre dans une rage folle !" % monster["nom"], "sorts": [],
					"effets": [{"type": "bonus", "carac": "force", "min": 50, "max": 50, "duree": 2}]}]
			view._on_click(target)
			for i in 200:
				if not view.is_busy():
					break
				view.advance(0.3)
			if _action in ["cible", "sermon", "prevision", "phase", "tactique", "historique", "arcaniste", "composition", "infobulle"] and view.server.combat != null:
				# Placement validé, puis survol du premier monstre.
				view.request_start_fight()
				for i in 200:
					if not view.is_busy():
						break
					view.advance(0.3)
				# Arcaniste : Composition (Flamme, Flamme, Givre), puis Fusion arcanique (une place reste vide).
				if _action in ["arcaniste", "composition", "infobulle"]:
					view.cast_composition("arcaniste_composition", "flamme+flamme+givre")
					for i in 50:
						if not view.is_busy():
							break
						view.advance(0.3)
					view.select_spell("arcaniste_creer_un_sort")
					view._on_click(view.server.combat.get_fighter(World.PLAYER_ID).cell)
					for i in 50:
						if not view.is_busy():
							break
						view.advance(0.3)
				if _action == "composition":
					var hud: CombatHud = _scene.get_node("CombatHud")
					hud._on_spell_pressed("arcaniste_composition")
				if _action == "infobulle":
					# Souris posée sur le sort Composition : son infobulle (prévoir assez d'images).
					# Après la mise en page de la barre.
					create_timer(0.2).timeout.connect(func() -> void:
						var button: Control = _scene.get_node("CombatHud")._spell_buttons["arcaniste_composition"]
						var motion := InputEventMouseMotion.new()
						motion.position = button.get_global_rect().get_center()
						motion.global_position = motion.position
						Input.warp_mouse(motion.position)
						root.push_input(motion))
				# Historique : deux tours passés, le temps que les monstres frappent.
				for turn in 2 if _action == "historique" else 0:
					view.request_end_turn()
					for i in 200:
						if not view.is_busy():
							break
						view.advance(0.3)
				if _action in ["sermon", "prevision"]:
					# Sermon choisi, case visée à 2 cases devant le Théologue, vers les monstres ;
					# « prevision » : un monstre amené dans la zone (dégâts prévus au-dessus de lui).
					var hero := view.server.combat.get_fighter(World.PLAYER_ID)
					var foe := view.server.combat.enemies_of(hero)[0]
					if _action == "prevision":
						foe.cell = hero.cell + Spell.direction(hero.cell, foe.cell) * 2
						view.refresh_state()
						view._actors[foe.id]["pos"] = Vector2(foe.cell)
					view.selected_spell = "theologue_sermon"
					view._refresh_overlays()
					view._set_hovered(hero.cell + Spell.direction(hero.cell, foe.cell))
				for fighter in view.server.combat.fighters if _action in ["cible", "phase", "tactique"] else []:
					if fighter.team != Fighter.TEAM_PLAYERS:
						if _action == "phase":
							# Un tiers de ses PV perdus : le noyau déclenche la phase (seuil à 90 %).
							var events: Array[Dictionary] = []
							view.server.combat._hurt(fighter, ceili(fighter.hp / 3.0), "acier", events)
							view._queue.append_array(events)
							view._playing = true
							view._play_next()
							view.advance(0.3)  # Après les dégâts, le changement de phase.
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
		view.advance(0.3)
