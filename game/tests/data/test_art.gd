extends "res://tests/test_case.gd"
## Vérifie les images de `res://art/` : chaque SVG se dessine, et tout ce qui y fait référence
## (personnages, PNJ, monstres, ressources, décors des cartes) pointe vers des images existantes.


func test_toutes_les_images_se_dessinent() -> void:
	var images: Dictionary = Art.manifest()["images"]
	assert_true(images.size() > 20, "des images dans art.json")
	for image_name: String in images:
		assert_true(FileAccess.file_exists(Art.ROOT.path_join(images[image_name]["fichier"])), "fichier de « %s »" % image_name)
		assert_true(Art.texture(image_name) != null, "« %s » se dessine" % image_name)


func test_personnages_et_accessoires() -> void:
	var manifest := Art.manifest()
	for rig_name: String in manifest["personnages"]:
		for back in [false, true]:
			var parts := Rig.parts(rig_name, back)
			assert_true(parts.size() >= 6, "%s : jambes, torse, tête, bras" % rig_name)
			for part: Dictionary in parts:
				assert_true(Art.has_image(part["image"]), "%s : image « %s »" % [rig_name, part["image"]])
	for weapon: String in manifest["armes"]:
		assert_true(Art.has_image(weapon), "arme « %s »" % weapon)
	for accessory: String in manifest["accessoires"]:
		assert_true(Art.has_image(manifest["accessoires"][accessory].get("image", accessory)), "accessoire « %s »" % accessory)
	for group: String in ["tenues", "pnj", "monstres"]:
		for entry_name: String in manifest[group]:
			var spec: Dictionary = manifest[group][entry_name]
			if spec.has("rig"):
				assert_true(Rig.exists(spec["rig"]), "%s « %s » : assemblage « %s »" % [group, entry_name, spec["rig"]])
			if spec.has("image"):
				assert_true(Art.has_image(spec["image"]), "%s « %s » : image" % [group, entry_name])
			if not str(spec.get("arme", "")).is_empty():
				assert_true(manifest["armes"].has(spec["arme"]), "%s « %s » : arme" % [group, entry_name])
			for accessory: String in spec.get("accessoires", []):
				assert_true(manifest["accessoires"].has(accessory), "%s « %s » : accessoire" % [group, entry_name])
	var data := GameData.load_all()
	for voie_id: String in data.voies:
		assert_true(manifest["tenues"].has(voie_id), "tenue de la Voie « %s »" % voie_id)
	for race_id: String in data.races:
		assert_true(manifest["races"].has(race_id), "apparence de la race « %s »" % race_id)
	for monster_id: String in data.monsters:
		assert_true(manifest["monstres"].has(monster_id), "dessin du monstre « %s »" % monster_id)
	for marker: String in data.nodes:
		assert_true(Art.has_image(manifest["ressources"].get(marker, "")), "dessin de la ressource « %s »" % marker)


func test_decors_des_cartes() -> void:
	for path in DataLoader.list_json("res://data/cartes"):
		var map := DataLoader.load_map(path)
		if map == null:
			continue
		for decor: Dictionary in map.decors:
			assert_true(Art.has_image(decor["image"]), "%s : image « %s »" % [path, decor["image"]])
			assert_true(map.is_inside(decor["case"]), "%s : décor « %s » hors de la carte" % [path, decor["image"]])
			assert_eq(map.obstacles.get(decor["case"]), "bloc", "%s : le décor « %s » doit être posé sur des cases « # »" % [path, decor["image"]])
		for npc: Dictionary in map.npcs:
			assert_true(Art.manifest()["pnj"].has(npc["id"]), "%s : dessin du PNJ « %s »" % [path, npc["id"]])


func test_icones_des_sorts_et_des_armes() -> void:
	var data := GameData.load_all()
	for voie_id: String in data.voies:
		for spell_id: String in data.voies[voie_id]["sorts"]:
			assert_true(Art.has_image("sort_" + spell_id), "icône du sort %s" % spell_id)
	for race_id: String in data.races:
		assert_true(Art.has_image("sort_" + str(data.races[race_id]["sort"])), "icône du sort racial de %s" % race_id)
	var weapon_icons: Dictionary = Art.manifest()["icones_armes"]
	for item_id: String in data.items:
		if data.items[item_id]["type"] == "arme":
			assert_true(weapon_icons.has(item_id), "icône de l'attaque de %s" % item_id)
	for icon: String in weapon_icons.values():
		assert_true(Art.has_image(icon), icon)
	for image in ["coeur_vide", "coeur_plein", "etoile_pa", "case_pm", "case_sort", "sort_inconnu"]:
		assert_true(Art.has_image(image), image)
