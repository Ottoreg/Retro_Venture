extends "res://tests/test_case.gd"
## Marchands : boutique, prix selon la rareté, achat, vente à prix réduit.

const Fixtures := preload("res://tests/helpers/fixtures.gd")
const MERCHANT := "marchand"

var _world: World


func before_each() -> void:
	var map := Fixtures.map({Fixtures.center(): "a", GameMap.plan_cell(8, 8): "b"}, [], {"pnj": [
		{"marqueur": "a", "id": MERCHANT, "nom": "Marchand", "marchand": true, "repliques": ["Bonjour !"]},
		{"marqueur": "b", "id": "badaud", "nom": "Badaud", "repliques": ["Hm ?"]},
	]})
	_world = World.new(map, Fixtures.data(), Callable(), Fixtures.character())
	_world.character.inventory.ecus = 1000


func _talk() -> Array[Dictionary]:
	return _world.execute({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": MERCHANT})


func _trade(type: String, item: String, quantity := 1, npc := MERCHANT) -> Array[Dictionary]:
	return _world.execute({"type": type, "entite": World.PLAYER_ID, "pnj": npc, "objet": item, "quantite": quantity})


func _assert_refused(events: Array[Dictionary], reason: String, message := "") -> void:
	assert_eq(events.size(), 1, message)
	assert_eq(events[0]["type"], Protocol.EVT_REFUSED, message)
	assert_eq(events[0].get("raison"), reason, message)


func _uid_of(item_id: String) -> String:
	for entry: Dictionary in _world.character.inventory.entries.values():
		if entry["objet"] == item_id:
			return entry["uid"]
	return ""


func test_prix_selon_la_rarete() -> void:
	var previous := 0
	for rarity: String in Item.RARITIES:
		var price := Item.buy_price({"type": "anneau", "rarete": rarity})
		assert_true(price > previous, "équipement %s plus cher que la rareté d'avant" % rarity)
		previous = price
		var resource := {"type": "ressource", "rarete": rarity}
		assert_true(Item.buy_price(resource) < price, "une ressource coûte moins qu'un équipement")
		assert_true(Item.sell_price(resource) >= 1, "revente d'au moins 1 écu")
		assert_true(Item.sell_price({"type": "anneau", "rarete": rarity}) < price, "revente moins chère que l'achat")


func test_parler_au_marchand_ouvre_la_boutique() -> void:
	var events := _talk()
	assert_eq(Fixtures.of_type(events, Protocol.EVT_DIALOGUE).size(), 0, "pas de simple dialogue")
	var shops := Fixtures.of_type(events, Protocol.EVT_SHOP)
	assert_eq(shops.size(), 1)
	var articles: Array = shops[0]["articles"]
	assert_eq(articles.size(), _world.data.items.size(), "tous les objets sont en vente")
	for article: Dictionary in articles:
		assert_eq(article["prix"], Item.buy_price(_world.data.items[article["objet"]]))
	assert_true(articles[0]["type"] != Item.TYPE_RESOURCE and articles[-1]["type"] == Item.TYPE_RESOURCE, "équipements d'abord")
	var other := _world.execute({"type": Protocol.CMD_TALK, "entite": World.PLAYER_ID, "pnj": "badaud"})
	assert_eq(Fixtures.of_type(other, Protocol.EVT_SHOP).size(), 0, "un PNJ ordinaire ne vend rien")


func test_objets_hors_boutique() -> void:
	# « boutique » : false (trophée de boss) : ni en vente, ni achetable ; il se revend quand même.
	_world.data.items["trophee"] = {"id": "trophee", "nom": "Trophée", "type": "anneau", "rarete": "epique",
		"niveau": 1, "boutique": false}
	assert_eq(Item.validate(_world.data.items["trophee"]).size(), 0)
	assert_false(Item.is_sold(_world.data.items["trophee"]))
	assert_true(Item.is_sold(_world.data.items["bague"]), "en vente par défaut")
	var articles: Array = Fixtures.of_type(_talk(), Protocol.EVT_SHOP)[0]["articles"]
	for article: Dictionary in articles:
		assert_ne(article["objet"], "trophee", "pas dans la boutique")
	_assert_refused(_trade(Protocol.CMD_BUY, "trophee"), Protocol.REASON_UNKNOWN_ITEM)
	assert_true(Item.validate({"id": "x", "nom": "X", "type": "ressource", "rarete": "commun", "boutique": "non"}).size() > 0,
		"« boutique » booléen")


func test_il_faut_etre_a_cote_du_marchand() -> void:
	_assert_refused(_trade(Protocol.CMD_BUY, "dent"), Protocol.REASON_TOO_FAR)
	_talk()
	assert_eq(_trade(Protocol.CMD_BUY, "dent")[0]["type"], Protocol.EVT_TRADE)
	_assert_refused(_trade(Protocol.CMD_BUY, "dent", 1, "badaud"), Protocol.REASON_UNKNOWN_ENTITY, "pas un marchand")
	_assert_refused(_trade(Protocol.CMD_BUY, "dent", 1, "personne"), Protocol.REASON_UNKNOWN_ENTITY)


func test_acheter() -> void:
	_talk()
	var events := _trade(Protocol.CMD_BUY, "bague")
	assert_eq(events[0]["type"], Protocol.EVT_TRADE)
	assert_eq(events[0]["operation"], "achat")
	assert_eq(events[0]["prix"], Item.EQUIPMENT_PRICES["commun"])
	assert_eq(events[0]["ecus"], 1000 - Item.EQUIPMENT_PRICES["commun"])
	assert_eq(Fixtures.of_type(events, Protocol.EVT_INVENTORY).size(), 1, "inventaire mis à jour")
	var inventory := _world.character.inventory
	assert_eq(inventory.ecus, 1000 - Item.EQUIPMENT_PRICES["commun"])
	assert_eq(inventory.entries[_uid_of("bague")]["jets"], {"force": 5}, "jets tirés à l'achat")

	_trade(Protocol.CMD_BUY, "dent", 10)
	_trade(Protocol.CMD_BUY, "dent", 5)
	assert_eq(inventory.quantity_of("dent"), 15, "les ressources s'empilent")
	assert_eq(inventory.ecus, 1000 - Item.EQUIPMENT_PRICES["commun"] - 15 * Item.RESOURCE_PRICES["commun"])


func test_achats_refuses() -> void:
	_talk()
	var inventory := _world.character.inventory
	_assert_refused(_trade(Protocol.CMD_BUY, "tresor", 100), Protocol.REASON_NOT_ENOUGH_ECUS)
	_assert_refused(_trade(Protocol.CMD_BUY, "inconnu"), Protocol.REASON_UNKNOWN_ITEM)
	_assert_refused(_trade(Protocol.CMD_BUY, "dent", 0), Protocol.REASON_INVALID_COMMAND)
	_assert_refused(_trade(Protocol.CMD_BUY, "dent", World.MAX_TRADE_QUANTITY + 1), Protocol.REASON_INVALID_COMMAND)
	assert_eq(inventory.ecus, 1000, "rien n'a été payé")
	assert_true(inventory.entries.is_empty(), "rien n'a été ajouté")

	_trade(Protocol.CMD_BUY, "dent")
	while not inventory.is_full():
		inventory.add(_world.data.items["bague"], 1, {})
	_assert_refused(_trade(Protocol.CMD_BUY, "bague"), Protocol.REASON_INVENTORY_FULL)
	assert_eq(_trade(Protocol.CMD_BUY, "dent")[0]["type"], Protocol.EVT_TRADE, "une pile déjà là ne prend pas de place")


func test_vendre_a_prix_reduit() -> void:
	_talk()
	_trade(Protocol.CMD_BUY, "dent", 12)
	_trade(Protocol.CMD_BUY, "heaume")
	var inventory := _world.character.inventory
	var ecus := inventory.ecus

	var events := _trade(Protocol.CMD_SELL, _uid_of("dent"), 4)
	assert_eq(events[0]["type"], Protocol.EVT_TRADE)
	assert_eq(events[0]["operation"], "vente")
	assert_eq(events[0]["prix"], 4 * Item.sell_price(_world.data.items["dent"]))
	assert_eq(inventory.quantity_of("dent"), 8)
	_trade(Protocol.CMD_SELL, _uid_of("heaume"))
	assert_eq(inventory.quantity_of("heaume"), 0, "équipement vendu")
	var expected := ecus + 4 * Item.sell_price(_world.data.items["dent"]) + Item.sell_price(_world.data.items["heaume"])
	assert_eq(inventory.ecus, expected)
	assert_true(Item.sell_price(_world.data.items["heaume"]) < Item.buy_price(_world.data.items["heaume"]), "à perte")


func test_ventes_refusees() -> void:
	_talk()
	_trade(Protocol.CMD_BUY, "dent", 2)
	_trade(Protocol.CMD_BUY, "bague")
	var inventory := _world.character.inventory
	var ecus := inventory.ecus
	_assert_refused(_trade(Protocol.CMD_SELL, _uid_of("dent"), 3), Protocol.REASON_INVALID_COMMAND, "plus qu'on n'en a")
	_assert_refused(_trade(Protocol.CMD_SELL, "o999"), Protocol.REASON_UNKNOWN_ITEM)
	_world.execute({"type": Protocol.CMD_EQUIP, "entite": World.PLAYER_ID, "objet": _uid_of("bague")})
	_assert_refused(_trade(Protocol.CMD_SELL, _uid_of("bague")), Protocol.REASON_ITEM_WORN, "objet porté")
	assert_eq(inventory.ecus, ecus, "rien n'a été payé")
	assert_eq(inventory.quantity_of("dent"), 2)


func test_marchand_invalide_dans_une_carte() -> void:
	var data := {"id": "test", "plan": Fixtures.plan_with({Fixtures.center(): "a"}), "pnj": [
		{"marqueur": "a", "id": "m", "nom": "M", "marchand": "oui", "repliques": ["…"]},
	]}
	assert_false(GameMap.validate(data).is_empty(), "« marchand » doit être un booléen")
