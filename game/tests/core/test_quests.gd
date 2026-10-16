extends "res://tests/test_case.gd"
## Quêtes : format, conditions, propositions des PNJ, chaque type d'objectif, butin de quête,
## récompenses, objets de quête, sauvegarde.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _world: World


static func _items() -> Array:
	var items := Fixtures.items()
	items.append({"id": "buche", "nom": "Bûche", "type": "ressource", "rarete": "commun"})
	items.append({"id": "pomme", "nom": "Panier de pommes", "type": "quete", "rarete": "commun"})
	return items


static func _jobs() -> Array:
	return [
		{"id": "bucheron", "nom": "Bûcheron", "type": "recolte", "ressources": [
			{"marqueur": "F", "nom": "Frêne", "objet": "buche", "niveau": 1, "quantite": [2, 2], "xp": 10,
				"repousse": [60, 120], "apparence": "arbre"},
		]},
		{"id": "forgeron", "nom": "Forgeron", "type": "artisanat", "recettes": [
			{"objet": "bague", "niveau": 1, "xp": 10, "ingredients": {"buche": 1}},
		]},
	]


static func _quest_list() -> Array:
	return [
		{"id": "tuto", "nom": "Premiers pas", "categorie": "tutoriel", "niveau": 1, "pnj": "berger",
			"donne": [{"objet": "bague", "nombre": 1}],
			"etapes": [
				{"objectifs": [{"type": "equiper", "objet": "bague"}]},
				{"objectifs": [{"type": "vaincre", "monstre": "mannequin", "nombre": 2}]},
				{"objectifs": [{"type": "recolter", "objet": "buche", "nombre": 2}, {"type": "fabriquer", "metier": "forgeron"}]},
				{"objectifs": [{"type": "parler", "pnj": "berger"}]},
			],
			"dialogues": {"berger": {"proposition": ["Aidez-moi !"], "en_cours": ["Alors ?"], "fin": ["Merci !"]}},
			"recompenses": {"xp_cr": 1, "ecus": 10, "objets": [{"objet": "epee", "nombre": 1}]}},
		{"id": "suite", "nom": "Les pommes", "categorie": "principale", "acte": 1, "niveau": 2, "pnj": "berger",
			"conditions": {"camp": "allie", "quetes_terminees": ["tuto"]},
			"etapes": [
				{"objectifs": [{"type": "apporter", "objet": "pomme", "nombre": 2, "pnj": "berger",
					"butin": {"monstres": ["mannequin"], "taux": 1.0}}]},
				{"objectifs": [{"type": "aller", "carte": "b"}]},
				{"objectifs": [{"type": "vaincre_groupe", "monstre": "patron"}]},
			],
			"recompenses": {"xp_cr": 5, "ecus": 50}},
		{"id": "gobeline", "nom": "Réservée aux gobelins", "categorie": "principale", "niveau": 1, "pnj": "berger",
			"conditions": {"camp": "ennemi"}, "etapes": [{"objectifs": [{"type": "parler", "pnj": "berger"}]}]},
		{"id": "rendre", "nom": "À rendre", "categorie": "secondaire", "niveau": 2, "pnj": "berger",
			"conditions": {"quetes_terminees": ["suite"]},
			"etapes": [{"objectifs": [{"type": "vaincre", "monstre": "mannequin", "nombre": 1},
				{"type": "apporter", "objet": "dent", "nombre": 1, "pnj": "berger"}]}],
			"dialogues": {"berger": {"fin": ["Parfait."]}}},
		{"id": "commerce", "nom": "Une affaire", "categorie": "secondaire", "niveau": 1, "pnj": "marchand",
			"conditions": {"une_quete_terminee": ["tuto", "gobeline"]},
			"etapes": [{"objectifs": [{"type": "vaincre", "monstre": "mannequin", "nombre": 1}]}]},
	]


func _data(quests := _quest_list()) -> GameData:
	var base := Fixtures.data()
	var monsters := [Fixtures.monster("mannequin", 30, 0, 0, 10, ["frappe"])]
	var chief := Fixtures.monster("chef", 30, 0, 0, 10, ["frappe"])
	chief["elite"] = true
	chief["famille"] = "mannequin"
	var boss := Fixtures.monster("patron", 30, 0, 0, 10, ["frappe"])
	boss["boss"] = true
	monsters.append_array([chief, boss])
	return GameData.from_dicts(Fixtures.spells(), monsters, base.voies.values(), base.races.values(), _items(), _jobs(), [], [], quests)


func before_each() -> void:
	var cells: Array[Vector2i] = [Fixtures.center(), Fixtures.center() + Vector2i(0, 3), Fixtures.center() + Vector2i(3, 0)]
	var npcs := {"pnj": [
		{"marqueur": "b", "id": "berger", "nom": "Le berger", "repliques": ["Bonjour."]},
		{"marqueur": "c", "id": "marchand", "nom": "Le marchand", "marchand": true, "repliques": ["Achetez !"]},
		{"marqueur": "a", "id": "forge", "nom": "La forge", "atelier": "forgeron", "repliques": ["Clang."]},
	]}
	npcs["id"] = "a"
	_maps = {
		"a": Fixtures.map({cells[0]: "1", cells[1]: "2", cells[2]: "F", GameMap.plan_cell(0, 6): "b", GameMap.plan_cell(0, 8): "c",
			GameMap.plan_cell(8, 8): "a"}, [{"monstres": ["mannequin"]}, {"monstres": ["mannequin", "chef"]}], npcs),
		"b": Fixtures.map({cells[0]: "1"}, [{"monstres": ["patron"]}], {"id": "b"}),
	}
	_world = World.new(_maps["a"], _data(), _loader, Fixtures.character())
	_world.map_ids = ["a", "b"]
	_world.rare_harvest_chance = 0.0


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _command(type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": World.PLAYER_ID}
	command.merge(extra, true)
	return _world.execute(command)


func _talk(npc_id: String) -> Array[Dictionary]:
	return _command(Protocol.CMD_TALK, {"pnj": npc_id})


func _win_against(group_id: String) -> Array[Dictionary]:
	_command(Protocol.CMD_ENGAGE, {"groupe": group_id})
	var last: Fighter = null
	for fighter in _world.combat.fighters:
		if fighter.team != Fighter.TEAM_PLAYERS:
			fighter.hp = 0
			last = fighter
	last.hp = 1
	var player := _world.combat.get_fighter(World.PLAYER_ID)
	for neighbor in IsoGrid.neighbors_4(last.cell):
		if _world.combat.is_free(neighbor):
			player.cell = neighbor
			break
	_command(Protocol.CMD_READY)
	var events := _command(Protocol.CMD_CAST, {"sort": "frappe", "cible": last.cell})
	assert_false(_world.in_combat(), "combat gagné")
	return events


func _respawn_all() -> void:
	_world._positions[World.PLAYER_ID] = _maps["a"].spawn
	_world.update(float(GameMap.DEFAULT_RESPAWN[1]) + 1.0)


func _counters(quest_id: String) -> Array:
	return _world.character.quests.counters(quest_id)


func test_format_des_quetes() -> void:
	assert_eq(Quest.validate(_quest_list()[0]), PackedStringArray())
	var bad := {"id": "x", "nom": "X", "categorie": "inconnue", "niveau": 0, "pnj": "",
		"etapes": [{"objectifs": [{"type": "voler"}, {"type": "apporter", "objet": "a"}, {"type": "vaincre", "monstre": "m", "butin": {}}]}],
		"conditions": {"camp": "violet", "age": 3}, "dialogues": {"p": {"blabla": ["?"]}}}
	var errors := " ".join(Quest.validate(bad))
	for expected in ["categorie", "niveau", "pnj", "type", "« pnj » attendu", "butin", "camp", "condition inconnue", "blabla"]:
		assert_true(expected in errors, "erreur attendue : %s" % expected)
	# Liens cassés : la quête est écartée au chargement.
	var broken := _quest_list()
	broken[1]["conditions"]["quetes_terminees"] = ["fantome"]
	broken[0]["etapes"][1]["objectifs"][0]["monstre"] = "inconnu"
	broken[2]["etapes"][0]["objectifs"] = [{"type": "vaincre_groupe", "monstre": "mannequin"}]
	var data := _data(broken)
	assert_false(data.quests.has("tuto"), "monstre inconnu")
	assert_false(data.quests.has("suite"), "quête requise inconnue")
	assert_false(data.quests.has("gobeline"), "« vaincre_groupe » demande un boss")
	assert_true(data.quests.has("commerce"))


func test_recompense_en_combats_de_reference() -> void:
	assert_eq(Quest.reference_xp(1), 14)
	assert_eq(Quest.reference_xp(12), 2 * roundi(7 * 12 + 0.27 * 144))
	assert_eq(Quest.reward_xp({"niveau": 10, "recompenses": {"xp_cr": 3}}), roundi(3 * Quest.reference_xp(10) * Character.XP_RATE))


func test_conditions_et_marques_des_pnj() -> void:
	var book := _world.quest_book
	assert_true(book.is_available("tuto"))
	assert_false(book.is_available("suite"), "quête précédente pas finie")
	assert_false(book.is_available("gobeline"), "réservée à un autre camp")
	assert_false(book.is_available("commerce"), "un des deux tutoriels d'abord")
	assert_eq(book.marker("berger"), QuestBook.MARKER_AVAILABLE)
	assert_eq(book.marker("marchand"), "")
	_world.character.quests.finish("tuto")
	assert_true(book.is_available("suite"))
	assert_true(book.is_available("commerce"), "« une_quete_terminee » : une seule suffit")
	_world.character.level = 1
	var high: Dictionary = _world.data.quests["suite"]
	high["conditions"]["niveau_min"] = 5
	assert_false(book.is_available("suite"), "niveau trop bas")


func test_proposition_acceptation_et_tutoriel_complet() -> void:
	var events := _talk("berger")
	var offer := Fixtures.of_type(events, Protocol.EVT_QUEST_OFFER)
	assert_eq(offer.size(), 1, "le berger propose sa quête")
	assert_eq(offer[0]["quete"], "tuto")
	assert_eq(offer[0]["repliques"], ["Aidez-moi !"])
	assert_eq(offer[0]["objectifs"][0]["texte"], "Équiper : Bague")
	assert_eq(offer[0]["recompenses"]["ecus"], 10)
	events = _command(Protocol.CMD_QUEST_ACCEPT, {"quete": "tuto"})
	assert_true(_world.character.quests.is_active("tuto"))
	assert_eq(_world.character.inventory.quantity_of("bague"), 1, "objet donné à l'acceptation")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_QUESTS).size(), 1, "journal envoyé")
	assert_eq(_command(Protocol.CMD_QUEST_ACCEPT, {"quete": "tuto"})[0]["raison"], Protocol.REASON_REQUIREMENTS, "déjà acceptée")
	assert_eq(_world.quest_book.marker("berger"), QuestBook.MARKER_ACTIVE)
	assert_eq(Fixtures.of_type(_talk("berger"), Protocol.EVT_DIALOGUE)[0]["repliques"], ["Alors ?"], "en cours")

	# Étape 1 : équiper la bague.
	var uid := ""
	for key: String in _world.character.inventory.entries:
		if _world.character.inventory.entries[key]["objet"] == "bague":
			uid = key
	_command(Protocol.CMD_EQUIP, {"objet": uid})
	assert_eq(_world.character.quests.step("tuto"), 1, "étape suivante une fois la bague portée")
	# Étape 2 : deux mannequins (le chef, élite de la famille, compte aussi).
	events = _win_against("groupe_1")
	assert_eq(_counters("tuto"), [1])
	assert_true(Fixtures.of_type(events, Protocol.EVT_QUEST_PROGRESS).any(func(e: Dictionary) -> bool: return e["texte"] == "Vaincre : Mannequin 1 / 2"))
	_win_against("groupe_2")
	assert_eq(_world.character.quests.step("tuto"), 2, "le chef compte pour sa famille")
	# Étape 3 : récolter 2 bûches et fabriquer chez la forge.
	var tree := Fixtures.center() + Vector2i(3, 0)
	var path: Array[Vector2i] = _maps["a"].approach_path(_world.position_of(World.PLAYER_ID), tree)
	_command(Protocol.CMD_MOVE, {"cible": path[-1]})
	_command(Protocol.CMD_HARVEST, {"case": tree})
	assert_eq(_counters("tuto"), [2, 0])
	path = _maps["a"].approach_path(_world.position_of(World.PLAYER_ID), GameMap.plan_cell(8, 8))
	_command(Protocol.CMD_MOVE, {"cible": path[-1]})
	_command(Protocol.CMD_CRAFT, {"pnj": "forge", "recette": "bague"})
	assert_eq(_world.character.quests.step("tuto"), 3)
	assert_eq(_world.quest_book.marker("berger"), QuestBook.MARKER_TURN_IN)
	# Étape 4 : revenir voir le berger ; récompenses.
	var xp := _world.character.xp
	var ecus := _world.character.inventory.ecus
	events = _talk("berger")
	assert_true(_world.character.quests.is_done("tuto"))
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DIALOGUE)[0]["repliques"], ["Merci !"])
	var done := Fixtures.of_type(events, Protocol.EVT_QUEST_DONE)
	assert_eq(done.size(), 1)
	assert_eq(_world.character.xp - xp, Quest.reward_xp(_world.data.quests["tuto"]))
	assert_eq(_world.character.inventory.ecus - ecus, 10)
	assert_eq(_world.character.inventory.quantity_of("epee"), 1, "épée de récompense")
	assert_eq(_world.quest_book.marker("berger"), QuestBook.MARKER_AVAILABLE, "la suite est proposée")


func test_butin_de_quete_apporter_aller_et_boss() -> void:
	_world.character.quests.finish("tuto")
	_talk("berger")
	_command(Protocol.CMD_QUEST_ACCEPT, {"quete": "suite"})
	assert_eq(_world.character.inventory.quantity_of("pomme"), 0)
	var events := _win_against("groupe_1")
	assert_eq(_world.character.inventory.quantity_of("pomme"), 1, "butin de quête du mannequin")
	var ended := Fixtures.of_type(events, Protocol.EVT_COMBAT_ENDED)[0]
	assert_true(ended["butin"].any(func(d: Dictionary) -> bool: return d["objet"] == "pomme"), "affiché avec le butin")
	assert_eq(_world.quest_book.marker("berger"), QuestBook.MARKER_ACTIVE, "pas encore assez de pommes")
	_respawn_all()
	_win_against("groupe_1")
	_respawn_all()
	_win_against("groupe_1")
	assert_eq(_world.character.inventory.quantity_of("pomme"), 2, "pas plus que demandé")
	# Objet de quête : ni jeté ni vendu.
	assert_eq(_command(Protocol.CMD_DROP, {"objet": "pomme", "quantite": 1})[0]["raison"], Protocol.REASON_QUEST_ITEM)
	assert_eq(_world.quest_book.marker("berger"), QuestBook.MARKER_TURN_IN)
	_talk("berger")
	assert_eq(_world.character.inventory.quantity_of("pomme"), 0, "pommes rendues")
	assert_eq(_world.character.quests.step("suite"), 1)
	# Aller sur la carte « b », vaincre le boss.
	_world._set_map(_maps["b"], _maps["b"].spawn)
	_world.quest_book.refresh([] as Array[Dictionary])
	assert_eq(_world.character.quests.step("suite"), 2, "arrivé sur la carte")
	events = _win_against("groupe_1")
	assert_true(_world.character.quests.is_done("suite"))
	assert_eq(Fixtures.of_type(events, Protocol.EVT_QUEST_DONE)[0]["ecus"], 50)


func test_plus_tard_chez_un_marchand() -> void:
	_world.character.quests.finish("tuto")
	var events := _talk("marchand")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_QUEST_OFFER).size(), 1, "le marchand propose d'abord sa quête")
	_command(Protocol.CMD_QUEST_DECLINE, {"quete": "commerce"})
	events = _talk("marchand")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_SHOP).size(), 1, "puis ouvre sa boutique")
	assert_eq(_world.quest_book.marker("marchand"), QuestBook.MARKER_AVAILABLE, "la quête reste proposée")


func test_suivi_et_journal() -> void:
	_talk("berger")
	_command(Protocol.CMD_QUEST_ACCEPT, {"quete": "tuto"})
	var journal: Dictionary = _world.quest_book.sheet()
	assert_eq(journal["suivie"], "tuto", "la quête acceptée est suivie")
	assert_eq(journal["en_cours"][0]["donneur"], "Le berger")
	assert_eq(journal["en_cours"][0]["etapes"], 4)
	assert_eq(_command(Protocol.CMD_QUEST_TRACK, {"quete": "inconnue"})[0]["raison"], Protocol.REASON_UNKNOWN_ENTITY)
	_command(Protocol.CMD_QUEST_TRACK, {"quete": ""})
	assert_eq(_world.character.quests.tracked, "")


func test_sauvegarde_des_quetes() -> void:
	_talk("berger")
	_command(Protocol.CMD_QUEST_ACCEPT, {"quete": "tuto"})
	_world.character.quests.finish("gobeline")
	var saved: Variant = JSON.parse_string(JSON.stringify(_world.character.to_dict()))
	var restored := Character.from_dict(saved)
	assert_true(restored.quests.is_active("tuto"))
	assert_true(restored.quests.is_done("gobeline"))
	assert_eq(restored.quests.tracked, "tuto")
	assert_eq(restored.quests.counters("tuto"), [0])
	assert_true(Character.from_dict({"nom": "A", "race": "humain", "voie": "x", "niveau": 1, "xp": 0, "points": 0}).quests.entries.is_empty(),
		"vieille sauvegarde sans quêtes")


func test_rendre_apres_les_autres_objectifs() -> void:
	_world.character.quests.finish("tuto")
	_world.character.quests.finish("suite")
	_talk("berger")
	_command(Protocol.CMD_QUEST_ACCEPT, {"quete": "rendre"})
	_world.character.inventory.add(_world.data.items["dent"], 1)
	assert_eq(_world.quest_book.marker("berger"), QuestBook.MARKER_ACTIVE, "le monstre d'abord")
	_talk("berger")
	assert_eq(_counters("rendre"), [0, 0], "rien n'est rendu avant le combat")
	_win_against("groupe_1")
	assert_eq(_world.quest_book.marker("berger"), QuestBook.MARKER_TURN_IN)
	var events := _talk("berger")
	assert_true(_world.character.quests.is_done("rendre"))
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DIALOGUE)[0]["repliques"], ["Parfait."])
