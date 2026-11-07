extends "res://tests/test_case.gd"
## Forge personnalisée (`Forge`) : valeurs des ressources, révélation, aperçu, nom, commande « forger »
## à l'enclume, plans, objet forgé (nom, signature, attaque), sauvegarde et échange.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _world: World
var _anvil := GameMap.plan_cell(6, 6)


func before_each() -> void:
	var voies := [{"id": "test", "nom": "Test", "caracteristiques": {"pv": 50, "pa": 6, "pm": 3, "initiative": 100}, "sorts": ["frappe"]}]
	var data := GameData.from_dicts(Fixtures.spells(), [], voies, [], Fixtures.items() + Fixtures.forge_items(),
		[{"id": "forgeron", "nom": "Forgeron", "type": "artisanat"}])
	_world = World.new(Fixtures.map({_anvil: "&"}), data, Callable(), Fixtures.character())
	var path := _world.map.approach_path(_world.position_of(World.PLAYER_ID), _anvil)
	if not path.is_empty():
		_world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": path[-1]})


func _forge(extra: Dictionary) -> Array[Dictionary]:
	var command := {"type": Protocol.CMD_FORGE, "entite": World.PLAYER_ID, "case": _anvil}
	command.merge(extra, true)
	return _world.execute(command)


func _give(item_id: String, quantity := 1) -> void:
	_world.character.inventory.add(_world.data.items[item_id], quantity)


func test_valeur_selon_le_palier() -> void:
	assert_eq(Forge.value("force", 1), 1)
	assert_eq(Forge.value("force", 16), 3)
	assert_eq(Forge.value("force", 30), 5)
	assert_eq(Forge.value("vitalite", 8), 8, "Vitalité : 4 points pour un point de score")
	assert_eq(Forge.value("pa", 50), 1, "PA et PM toujours à 1")
	assert_eq(Forge.value("prospection", 1), 1, "au moins 1")
	assert_eq(Forge.value("dommages_flamme", 1, true), 3, "ressource rare : × 3, même au palier 1")
	assert_eq(Forge.value("portee", 3, true), 1, "PA, PM et Portée restent à 1")
	assert_eq(Forge.line_cap("resistance_givre"), 12, "8 points de score par % : 12 % par ligne")
	var items := _world.data.items.duplicate()
	items["vert_de_gris"] = {"id": "vert_de_gris", "type": "ressource", "rarete": "rare", "matiere": "minerai", "caracteristique": "dommages_flamme"}
	assert_eq(Forge.preview("anneau", {"vert_de_gris": 2}, items, null, false)["bonus"], {"dommages_flamme": [5, 6]}, "2 rares : 2 × 3")


func test_caracteristiques_cachees_sans_reputation_d_artisan() -> void:
	var character := _world.character
	assert_false(Forge.reveals(character, 1), "jamais forgé : tout est caché")
	var hidden := Forge.preview("anneau", {"minerai": 1, "croc": 2}, _world.data.items, character)
	assert_eq(hidden["cachees"], 2)
	assert_eq(hidden["bonus"], {})
	character.add_job_reputation("forgeron", 1300)
	assert_true(Forge.reveals(character, 8), "réputation de niveau équivalent 8 : palier 8 révélé")
	assert_false(Forge.reveals(character, 9))
	assert_eq(Forge.preview("anneau", {"minerai": 1, "croc": 2}, _world.data.items, character)["bonus"], {"force": [3, 4]})
	character.jobs["forgeron"]["competences"]["precision"] = 5
	assert_eq(Forge.preview("anneau", {"minerai": 1, "croc": 2}, _world.data.items, character)["bonus"], {"force": [4, 4]},
		"Précision au rang 5 : jets au maximum")


func test_apercu() -> void:
	var items := _world.data.items
	var preview := Forge.preview("bottes", {"peau": 1, "croc": 2, "corne": 2}, items)
	assert_eq(preview["erreur"], "")
	assert_eq(preview["palier"], 8, "moyenne des paliers : (1 + 16 + 24) / 5")
	assert_eq(preview["bonus"]["pa"], [1, 1], "une ligne de PA au plus, à 1")
	assert_eq(preview["bonus"]["force"], [3, 4], "jet : 75 % à 100 % du total")
	assert_eq(Forge.preview("bottes", {"croc": 1}, items)["manquantes"], ["cuir"], "les bottes demandent du cuir")
	assert_eq(Forge.preview("bottes", {"croc": 1}, items)["erreur"], Protocol.REASON_MISSING_INGREDIENTS)
	assert_eq(Forge.preview("epee", {"minerai": 1}, items)["manquantes"], ["bois"])
	var nine := {"peau": 1}
	for i in Forge.MAX_SLOTS:
		nine["ressource_%d" % i] = 1
	assert_eq(Forge.preview("bottes", nine, items)["erreur"], Protocol.REASON_INVALID_COMMAND, "8 ressources différentes au plus")
	assert_eq(Forge.preview("bottes", {"peau": 1, "croc": 60}, items)["bonus"]["force"], [75, 100], "quantité libre, plafond de la ligne")
	assert_eq(Forge.preview("chaussette", {"peau": 1}, items)["erreur"], Protocol.REASON_INVALID_COMMAND)


func test_plafond_par_ligne_et_lignes_par_objet() -> void:
	assert_eq(Forge.line_cap("force"), 100, "100 points de score par ligne")
	assert_eq(Forge.line_cap("vitalite"), 400)
	assert_eq(Forge.line_cap("critique"), 10)
	assert_eq(Forge.line_cap("pa"), 1)
	var items := _world.data.items.duplicate(true)
	items["croc"]["niveau"] = 500  # 64 de Force par croc : 128 pour deux, plafonnés à 100.
	assert_eq(Forge.preview("anneau", {"minerai": 1, "croc": 2}, items)["bonus"]["force"][1], 100)
	# Une ressource de haut palier peut donner plusieurs caractéristiques (Sacré : Flamme et Acier).
	var stats := ["force", "intelligence", "perception", "agilite", "vitalite", "initiative", "prospection", "dommages", "critique"]
	items["croc"]["caracteristique"] = stats.slice(0, 2)
	assert_eq(Forge.preview("anneau", {"minerai": 1, "croc": 1}, items)["bonus"].keys(), ["force", "intelligence"])
	items["croc"]["caracteristique"] = stats
	assert_eq(Forge.preview("anneau", {"minerai": 1, "croc": 1}, items)["erreur"], Protocol.REASON_TOO_MANY_LINES, "9 lignes : 8 au plus")
	assert_eq(Item.validate(items["croc"]).size(), 0, "liste de caractéristiques permise")


func test_nom_fait_de_mots_proposes() -> void:
	assert_eq(Forge.default_words("bottes", {"force": [3, 4], "pa": [1, 1]}), ["Bottes", "rapides"], "accord au féminin pluriel")
	assert_eq(Forge.name_of(["Bague", "costaude"], "anneau", ["force"]), "Bague costaude")
	assert_eq(Forge.name_of(["Anneau", "costaud", "massif"], "anneau", ["force"]), "Anneau costaud massif", "deux mots d'une même ligne")
	assert_eq(Forge.name_of(["Anneau", "costaud", "costaud"], "anneau", ["force"]), "", "pas deux fois le même mot")
	assert_eq(Forge.name_of(["Anneau", "rapide"], "anneau", ["force"]), "", "pas de ligne de PA")
	assert_eq(Forge.name_of(["Chapeau"], "anneau", []), "", "nom d'un autre type")
	assert_eq(Forge.name_of("Anneau", "anneau", []), "")


func test_forger_a_l_enclume() -> void:
	var inventory := _world.character.inventory
	_give("peau")
	var refused := _forge({"type_objet": "bottes", "ressources": {"peau": 1, "croc": 2}, "mots": ["Bottes"]})
	assert_eq(refused[0].get("raison"), Protocol.REASON_MISSING_INGREDIENTS, "pas de crocs dans le sac")
	_give("croc", 2)
	assert_eq(_forge({"type_objet": "bottes", "ressources": {"peau": 1, "croc": 2}, "mots": ["Bottes", "rapides"]})[0].get("raison"),
		Protocol.REASON_INVALID_COMMAND, "nom refusé")
	var events := _forge({"type_objet": "bottes", "ressources": {"peau": 1, "croc": 2}, "mots": ["Souliers", "costauds"]})
	assert_eq(events[0]["type"], Protocol.EVT_CRAFTED)
	assert_eq(events[0]["nom"], "Souliers costauds")
	assert_eq(events[0]["metier"], "forgeron")
	assert_eq(inventory.quantity_of("croc"), 0, "ressources consommées")
	var entry: Dictionary = inventory.entries.values().filter(func(e: Dictionary) -> bool: return e["objet"] == "forge_bottes")[0]
	assert_eq(entry["forge"]["artisan"], "Testeur")
	assert_eq(events[0]["jets"], entry["jets"], "jets obtenus dans l'événement")
	assert_true(int(entry["jets"]["force"]) in [3, 4] and int(entry["jets"]["vitalite"]) in [4, 5], "jets tirés dans leurs plages : %s" % entry["jets"])
	var template := Item.entry_template(entry, _world.data.items)
	assert_eq(template["nom"], "Souliers costauds")
	assert_eq(template["description"], "Créé par Testeur", "signature à la place du texte d'ambiance")
	assert_eq(template["niveau"], 6, "palier : (1 + 8 × 2) / 3")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_JOB)[0]["gain"], Profession.reputation_gain(Forge.REPUTATION_PER_TIER * 6, 6, 0, 0))
	# La sauvegarde garde l'objet forgé.
	var copy := Character.from_dict(_world.character.to_dict(), _world.data.items)
	assert_eq(copy.inventory.entries[entry["uid"]]["forge"], entry["forge"])


func test_forger_avec_un_plan_et_une_arme() -> void:
	assert_eq(_forge({"recette": "plan_bague"})[0].get("raison"), Protocol.REASON_UNKNOWN_ITEM, "plan absent du sac")
	_give("plan_bague")
	_give("minerai")
	_give("croc", 2)
	var events := _forge({"recette": "plan_bague"})
	assert_eq(events[0]["nom"], "Bague du test", "le plan donne son nom")
	assert_eq(_world.character.inventory.quantity_of("plan_bague"), 1, "le plan reste dans le sac")
	_give("minerai")
	_give("bois")
	_give("croc", 4)
	_forge({"type_objet": "epee", "ressources": {"minerai": 1, "bois": 1, "croc": 4}, "mots": ["Glaive"]})
	var weapon: Dictionary = _world.character.inventory.entries.values().filter(func(e: Dictionary) -> bool: return e["objet"] == "forge_epee")[0]
	assert_eq(weapon["forge"]["palier"], 6)
	assert_eq(Item.entry_template(weapon, _world.data.items)["attaque"]["effets"][0]["min"], 13, "dégâts × (1 + 5 / 20)")
	_world.character.inventory.equip(weapon["uid"], "arme")
	var fighter := _world.data.create_character_fighter(_world.character, "j")
	assert_eq(fighter.weapon_tier, 6)
	var copy := _world.data.create_profile_fighter(fighter.profile(), "j")
	assert_eq(copy.spells[0].effects[0]["min"], 13, "la copie du combat garde l'attaque forgée")


func test_element_d_attaque_selon_les_ressources() -> void:
	var attack: Dictionary = _world.data.items["forge_epee"]["attaque"]
	var element := func(bonus: Dictionary) -> String: return Forge.scaled_attack(attack, 1, bonus)["effets"][0]["element"]
	assert_eq(element.call({}), "acier", "élément de l'arme sans ligne élémentaire")
	assert_eq(element.call({"force": [3, 4], "perception": [6, 8], "vitalite": [40, 50]}), "givre", "beaucoup de Perception : Givre")
	assert_eq(element.call({"force": [6, 8], "agilite": [6, 8]}), "acier", "à égalité : l'élément de l'arme")
	assert_eq(element.call({"agilite": [1, 2], "intelligence": [1, 3]}), "flamme")
	assert_eq(element.call({"force": [60, 100], "intelligence": [70, 91]}), "sacre", "Force et Intelligence à 10 % près : Sacré")
	assert_eq(element.call({"force": [60, 100], "intelligence": [70, 89]}), "acier", "au-delà de 10 % : l'élément le plus fort")
	assert_eq(element.call({"agilite": [30, 40], "perception": [30, 38], "force": [5, 5]}), "impie", "Agilité et Perception : Impie")


func test_enclume_a_cote() -> void:
	assert_eq(_world.execute({"type": Protocol.CMD_USE, "entite": World.PLAYER_ID, "case": _anvil})[0]["type"], Protocol.EVT_ANVIL)
	_world.execute({"type": Protocol.CMD_MOVE, "entite": World.PLAYER_ID, "cible": GameMap.plan_cell(1, 1)})
	_give("minerai")
	assert_eq(_forge({"type_objet": "anneau", "ressources": {"minerai": 1}, "mots": ["Anneau"]})[0].get("raison"), Protocol.REASON_TOO_FAR)


func test_dommages_et_resistances_par_element() -> void:
	var inventory := _world.character.inventory
	inventory.equip(inventory.add(_world.data.items["forge_bottes"], 1, {"dommages_flamme": 10, "dommages_acier": 4, "resistance_givre": 5}), "bottes")
	var fighter := _world.data.create_character_fighter(_world.character, "j")
	assert_eq(fighter.resistances.get("givre"), 5, "résistance de l'équipement")
	assert_eq(fighter.element_damage("sacre"), 7, "élément composé : moyenne de ses deux éléments")
	var target := Fighter.new()
	target.resistances = {"flamme": 50}
	assert_eq(Combat.damage_value(fighter, target, "flamme", 20), 20, "20 × 50 % + 10 dommages Flamme")
	assert_eq(_world.data.create_profile_fighter(fighter.profile(), "j").element_damage("flamme"), 10, "gardés dans la copie du combat")
	inventory.equip(inventory.add(_world.data.items["forge_anneau"], 1, {"resistance_givre": 70}), "anneau_1")
	fighter = _world.data.create_character_fighter(_world.character, "j")
	assert_eq(fighter.resistance("givre"), 60.0, "équipement : 60 % au plus")
	fighter.states.append({"type": Spell.EFFECT_BONUS, "carac": "resistance", "element": "givre", "valeur": 20})
	assert_eq(fighter.resistance("givre"), 80.0, "les effets de combat dépassent le plafond")
	target.resistances["givre"] = 90
	assert_eq(target.resistance("givre"), 90.0, "les monstres aussi")


func test_patron_sur_une_feuille_de_papier() -> void:
	var inventory := _world.character.inventory
	_give("peau", 2)
	_give("croc", 4)
	var command := {"type_objet": "bottes", "ressources": {"peau": 1, "croc": 2}, "mots": ["Bottes"], "papier": true}
	assert_eq(_forge(command)[0].get("raison"), Protocol.REASON_MISSING_INGREDIENTS, "pas de feuille de papier")
	_give("feuille_de_papier", 2)
	for i in 2:
		assert_true(_forge(command)[0]["patron"])
	assert_eq(inventory.quantity_of("feuille_de_papier"), 0, "feuilles consommées")
	var patterns: Array = inventory.entries.values().filter(func(e: Dictionary) -> bool: return e["objet"] == Forge.PATTERN)
	assert_eq(patterns.size(), 2, "un patron par objet, sans empilement")
	var template := Item.entry_template(patterns[0], _world.data.items)
	assert_eq(template["nom"], "Patron de Bottes")
	assert_eq(template["patron"]["ressources"], {"peau": 1, "croc": 2}, "les ressources")
	var boots: Dictionary = inventory.entries.values().filter(func(e: Dictionary) -> bool: return e["objet"] == "forge_bottes")[0]
	assert_eq(template["patron"]["jets"], boots["jets"], "les jets de l'objet forgé")
	assert_eq(Inventory.from_dict(inventory.to_dict(), _world.data.items).quantity_of(Forge.PATTERN), 2, "gardés à la sauvegarde")


func test_plafonds_selon_le_palier_de_forge() -> void:
	var character := _world.character
	assert_eq(Forge.tier(character), 1, "Inconnu : palier 1")
	assert_eq([Forge.line_cap("force", 1), Forge.line_cap("vitalite", 3), Forge.line_cap("resistance_givre", 4)], [20, 240, 10])
	assert_eq([Forge.line_cap("portee", 2), Forge.line_cap("portee", 3), Forge.line_cap("pm", 3), Forge.line_cap("pm", 4),
		Forge.line_cap("pa", 4), Forge.line_cap("pa", 5)], [0, 1, 0, 1, 0, 1], "Portée au palier 3, PM au 4, PA au 5")
	var items := _world.data.items
	var preview := Forge.preview("bottes", {"peau": 1, "croc": 60, "corne": 2}, items, character, false)
	assert_eq(preview["bonus"]["force"][1], 20, "20 points de score par ligne au palier 1")
	assert_false(preview["bonus"].has("pa"), "PA perdu avant le palier 5")
	assert_eq(preview["indisponibles"], ["pa"])
	character.add_job_reputation("forgeron", 100000)
	assert_eq(Forge.tier(character), 5, "Légende : palier 5")
	assert_eq(Forge.preview("bottes", {"peau": 1, "croc": 60, "corne": 2}, items, character, false)["bonus"]["pa"], [1, 1])
