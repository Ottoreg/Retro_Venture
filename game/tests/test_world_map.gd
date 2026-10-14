extends "res://tests/test_case.gd"
## Carte du monde, sans affichage : coordonnées tirées des ids de cartes, grille d'une zone (cartes
## visitées, voisines en « ? », bornes), nom de la zone, Pierres de Passage.


## Une petite zone « val » : cinq cartes en croix autour de val_0_0, une isolée plus loin, et une
## sortie vers la zone « mont ».
func _maps() -> Dictionary:
	return {
		"val_0_0": {"nom": "Val Joli — La Place", "sorties": ["val_1_0", "val_0_-1", "val_-1_0", "val_0_1"]},
		"val_1_0": {"nom": "Val Joli — Le Moulin", "sorties": ["val_0_0", "val_2_0", "mont_0_0"]},
		"val_2_0": {"nom": "Val Joli — Le Gué", "sorties": ["val_1_0"]},
		"val_0_-1": {"nom": "Val Joli — Les Hauts", "sorties": ["val_0_0"]},
		"val_-1_0": {"nom": "Val Joli — Le Bois", "sorties": ["val_0_0"]},
		"val_0_1": {"nom": "Val Joli — La Mare", "sorties": ["val_0_0"]},
		"val_5_5": {"nom": "Val Joli — Bout du monde", "sorties": []},
		"maison_val": {"nom": "Votre maison", "sorties": []},
		"mont_0_0": {"nom": "Mont Chauve — Le Col", "sorties": ["val_1_0"]},
	}


## Case de la grille par id de carte.
func _cases_by_id(layout: Dictionary) -> Dictionary:
	var cases := {}
	for case: Dictionary in layout["cases"]:
		cases[case["id"]] = case
	return cases


func test_coordonnees_tirees_de_l_id_de_la_carte() -> void:
	assert_eq(WorldMapLayout.map_coordinates("brumerive_1_0"), {"zone": "brumerive", "position": Vector2i(1, 0)})
	assert_eq(WorldMapLayout.map_coordinates("crasse_roc_0_2"), {"zone": "crasse_roc", "position": Vector2i(0, 2)},
		"un nom de zone avec un « _ »")
	assert_eq(WorldMapLayout.map_coordinates("val_-3_-12"), {"zone": "val", "position": Vector2i(-3, -12)}, "coordonnées négatives")
	assert_eq(WorldMapLayout.map_coordinates("maison_joueur"), {}, "une maison n'a pas de coordonnées")
	assert_eq(WorldMapLayout.map_coordinates("maison_crasse_roc"), {})
	assert_eq(WorldMapLayout.map_coordinates("cave_1"), {}, "il faut deux nombres")


func test_nom_court_d_une_carte() -> void:
	assert_eq(WorldMapLayout.short_name("Brumerive — Place du village"), "Place du village")
	assert_eq(WorldMapLayout.short_name("Votre maison"), "Votre maison", "sans tiret : le nom entier")


func test_zones_visitees_dans_l_ordre_des_visites() -> void:
	var zones := WorldMapLayout.visited_zones(["val_0_0", "maison_val", "mont_0_0", "val_1_0"])
	assert_eq(zones, ["val", "mont"] as Array[String], "une fois chacune, sans les maisons")


func test_seulement_les_cartes_visitees_et_leurs_voisines() -> void:
	var layout := WorldMapLayout.zone_layout("val", _maps(), ["val_0_0", "maison_val"], "val_0_0")
	var cases := _cases_by_id(layout)
	assert_eq(cases.size(), 5, "la carte visitée et ses 4 voisines")
	assert_true(cases["val_0_0"]["visitee"] and cases["val_0_0"]["actuelle"])
	assert_eq(cases["val_0_0"]["nom"], "La Place", "nom court")
	assert_eq(cases["val_0_0"]["nom_complet"], "Val Joli — La Place")
	for map_id in ["val_1_0", "val_0_-1", "val_-1_0", "val_0_1"]:
		assert_false(cases[map_id]["visitee"], map_id)
		assert_eq(cases[map_id]["nom"], WorldMapLayout.UNKNOWN_NAME, "voisine pas encore visitée : « ? »")
		assert_eq(cases[map_id]["nom_complet"], "", "son nom reste secret")
	assert_false(cases.has("val_2_0"), "pas voisine d'une carte visitée : cachée")
	assert_false(cases.has("val_5_5"))
	assert_false(cases.has("maison_val"), "pas de coordonnées : jamais sur la carte du monde")
	assert_eq(layout["liens"].size(), 4, "un lien par sortie de la carte visitée")


func test_bornes_de_la_grille_avec_coordonnees_negatives() -> void:
	var layout := WorldMapLayout.zone_layout("val", _maps(), ["val_0_0"], "val_0_0")
	assert_eq(layout["origine"], Vector2i(-1, -1), "coin en haut à gauche")
	assert_eq(layout["colonnes"], 3)
	assert_eq(layout["lignes"], 3)
	var cases := _cases_by_id(layout)
	assert_eq(cases["val_0_0"]["case"], Vector2i(1, 1), "au centre de la grille")
	assert_eq(cases["val_-1_0"]["case"], Vector2i(0, 1), "x vers la droite")
	assert_eq(cases["val_0_-1"]["case"], Vector2i(1, 0), "y vers le bas")
	assert_eq(cases["val_0_1"]["coordonnees"], Vector2i(0, 1))
	assert_eq(layout["cases"][0]["id"], "val_0_-1", "cases dans l'ordre de lecture : d'abord la rangée du haut")


func test_la_grille_grandit_avec_les_visites() -> void:
	var layout := WorldMapLayout.zone_layout("val", _maps(), ["val_0_0", "val_1_0"], "val_1_0")
	var cases := _cases_by_id(layout)
	assert_eq(cases.size(), 6, "les 5 cartes de la croix et le gué")
	assert_eq(layout["colonnes"], 4, "de x = -1 à x = 2")
	assert_true(cases["val_1_0"]["actuelle"] and not cases["val_0_0"]["actuelle"])
	assert_false(cases["val_2_0"]["visitee"])
	assert_false(cases.has("mont_0_0"), "une autre zone n'est pas sur cet onglet")
	assert_eq(layout["liens"].size(), 5, "le lien entre la place et le moulin compté une seule fois")


func test_zone_non_visitee_vide() -> void:
	var layout := WorldMapLayout.zone_layout("mont", _maps(), ["val_0_0"], "val_0_0")
	assert_eq(layout["cases"], [])
	assert_eq(layout["colonnes"], 0)


func test_nom_de_la_zone() -> void:
	var passages := {"pierre_val": {"nom": "Val Joli (pierre)", "carte": "val_1_0"}, "autre": {"nom": "Ailleurs", "carte": "mont_0_0"}}
	assert_eq(WorldMapLayout.zone_name("val", _maps(), passages), "Val Joli (pierre)", "le nom de sa Pierre de Passage")
	assert_eq(WorldMapLayout.zone_name("val", _maps()), "Val Joli", "sinon ce qui précède « — »")
	assert_eq(WorldMapLayout.zone_name("lande_grise", {}), "Lande Grise", "sinon son id")
	assert_eq(WorldMapLayout.zone_layout("val", _maps(), ["val_0_0"], "", passages)["nom"], "Val Joli (pierre)")


func test_pierres_de_passage_connues_ou_non() -> void:
	var passages := {
		"place": {"nom": "Place", "carte": "val_0_0"},
		"moulin": {"nom": "Moulin", "carte": "val_1_0"},
		"gue": {"nom": "Gué", "carte": "val_2_0"},
	}
	var layout := WorldMapLayout.zone_layout("val", _maps(), ["val_0_0", "val_1_0"], "val_0_0", passages, ["place"])
	var cases := _cases_by_id(layout)
	assert_eq(cases["val_0_0"]["pierre"], WorldMapLayout.STONE_KNOWN)
	assert_eq(cases["val_1_0"]["pierre"], WorldMapLayout.STONE_UNKNOWN, "visitée, mais pierre pas encore touchée")
	assert_eq(cases["val_2_0"]["pierre"], WorldMapLayout.STONE_NONE, "rien n'est dévoilé d'une carte inconnue")
	assert_eq(cases["val_-1_0"]["pierre"], WorldMapLayout.STONE_NONE)


func test_grande_zone_dans_la_fenetre() -> void:
	# 15 cartes en 5 × 3, toutes visitées : chaque case tient dans la zone de dessin, sans chevauchement.
	var maps := {}
	var visited: Array[String] = []
	for y in 3:
		for x in 5:
			var exits: Array = []
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var other := Vector2i(x, y) + offset
				if other.x >= 0 and other.x < 5 and other.y >= 0 and other.y < 3:
					exits.append("large_%d_%d" % [other.x, other.y])
			maps["large_%d_%d" % [x, y]] = {"nom": "Large — Carte %d" % (y * 5 + x), "sorties": exits}
			visited.append("large_%d_%d" % [x, y])
	var layout := WorldMapLayout.zone_layout("large", maps, visited, "large_2_1")
	assert_eq([layout["colonnes"], layout["lignes"]], [5, 3])
	var grid := WorldMapWindow.ZoneGrid.new()
	grid.size = Vector2(500, 260)
	grid.layout = layout
	var area := Rect2(Vector2.ZERO, grid.size)
	var rects: Array[Rect2] = []
	for case: Dictionary in layout["cases"]:
		var rect := grid.cell_rect(case["case"])
		assert_true(area.encloses(rect), "%s dans la fenêtre : %s" % [case["id"], rect])
		for other in rects:
			assert_false(other.intersects(rect), "%s ne chevauche pas une autre case" % case["id"])
		rects.append(rect)
	assert_eq(grid.case_at(grid.cell_rect(Vector2i(2, 1)).get_center())["id"], "large_2_1", "case sous la souris")
	grid.free()


func test_zones_du_jeu() -> void:
	# Avec les vraies cartes : à Brumerive, la place du village visitée, les champs de l'est en « ? ».
	var maps := {}
	for map_id in DataLoader.map_ids():
		var map := DataLoader.load_map(DataLoader.map_path(map_id))
		maps[map_id] = {"nom": map.display_name, "sorties": map.exits.values()}
	var data := GameData.load_all()
	var layout := WorldMapLayout.zone_layout("brumerive", maps, ["brumerive_0_0", "maison_joueur"], "maison_joueur",
		data.passages, ["brumerive"])
	assert_eq(layout["nom"], "Brumerive")
	var cases := _cases_by_id(layout)
	assert_eq(cases.size(), 2)
	assert_eq(cases["brumerive_0_0"]["nom"], "Place du village")
	assert_eq(cases["brumerive_0_0"]["pierre"], WorldMapLayout.STONE_KNOWN)
	assert_false(cases["brumerive_0_0"]["actuelle"], "dans la maison : aucune carte de la zone n'est actuelle")
	assert_eq(cases["brumerive_1_0"]["nom"], WorldMapLayout.UNKNOWN_NAME)
	assert_eq(WorldMapLayout.zone_name("cendre", maps, data.passages), "Trône de Cendre (élite)")
	assert_eq(WorldMapLayout.zone_name("crasse_roc", maps, data.passages), "Crasse-Roc")
