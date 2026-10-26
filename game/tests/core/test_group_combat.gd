extends "res://tests/test_case.gd"
## Jalon M2 du multijoueur (GDD § 16.5) : groupes de joueurs, combat rejoint pendant le placement,
## prêt à plusieurs, temps du tour, déconnexion en combat, et parts de chacun (XP, brumes, butin).

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _maps := {}
var _world: World


func before_each() -> void:
	_maps = {"a": Fixtures.map({Fixtures.center(): "1"}, [{"monstres": ["mannequin"]}], {"id": "a"})}
	_world = World.new(_maps["a"], Fixtures.data(), _loader, _character("Frodon"), "p1")
	_world.add_player(_character("Sam"), "p2", "a")
	_world.add_player(_character("Merry"), "p3", "a")
	_world.add_player(_character("Gollum"), "p4", "a")


func _loader(map_id: String) -> GameMap:
	return _maps.get(map_id)


func _character(name: String) -> Character:
	var character := Fixtures.character()
	character.display_name = name
	return character


func _as(player_id: String, type: String, extra := {}) -> Array[Dictionary]:
	var command := {"type": type, "entite": player_id}
	command.merge(extra)
	return _world.execute(command)


## Groupe de Frodon (chef) avec ces joueurs.
func _party(members: Array) -> void:
	for member_id: String in members:
		_as("p1", Protocol.CMD_PARTY_INVITE, {"joueur": member_id})
		_as(member_id, Protocol.CMD_PARTY_ANSWER, {"chef": "p1", "accepte": true})


## Frodon engage le groupe de la carte, les autres le rejoignent.
func _fight(joiners: Array) -> Combat:
	_as("p1", Protocol.CMD_ENGAGE, {"groupe": "groupe_1"})
	for member_id: String in joiners:
		_as(member_id, Protocol.CMD_JOIN_COMBAT, {"groupe": "groupe_1"})
	return _world.player("p1").combat


func _sorted(ids: Array) -> Array:
	var sorted := ids.duplicate()
	sorted.sort()
	return sorted


## Le joueur dont c'est le tour achève le mannequin (1 PV) au contact.
func _finish(combat: Combat) -> Array[Dictionary]:
	var player := combat.current_fighter()
	var monster := combat.get_fighter("groupe_1_1")
	for neighbor in IsoGrid.neighbors_4(monster.cell):
		if combat.is_free(neighbor):
			player.cell = neighbor
			break
	monster.hp = 1
	return _as(player.id, Protocol.CMD_CAST, {"sort": "frappe", "cible": monster.cell})


func test_invitation_et_chef_du_groupe() -> void:
	var invite := _as("p1", Protocol.CMD_PARTY_INVITE, {"joueur": "p2"})
	assert_eq(invite[0]["type"], Protocol.EVT_PARTY_INVITE)
	assert_eq(_world.recipients(invite[0], "p1"), ["p2"] as Array[String], "seul l'invité la reçoit")
	assert_eq(_as("p3", Protocol.CMD_PARTY_ANSWER, {"chef": "p1", "accepte": true})[0]["raison"], Protocol.REASON_NO_INVITATION)
	var joined := _as("p2", Protocol.CMD_PARTY_ANSWER, {"chef": "p1", "accepte": true})
	assert_eq(joined.size(), 2, "chaque membre reçoit le groupe")
	assert_eq(joined[0]["chef"], "p1")
	assert_eq(joined[0]["membres"].size(), 2)
	assert_eq(_world.recipients(joined[1], "p2"), ["p2"] as Array[String])
	assert_eq(_world.recipients(joined[0], "p2"), ["p1"] as Array[String], "adressé au chef par « pour »")
	_as("p1", Protocol.CMD_PARTY_INVITE, {"joueur": "p3"})
	var declined := _as("p3", Protocol.CMD_PARTY_ANSWER, {"chef": "p1", "accepte": false})
	assert_eq(declined[0]["type"], Protocol.EVT_PARTY_DECLINED)
	assert_eq(_world.recipients(declined[0], "p3"), ["p1"] as Array[String])
	# Tout membre invite, dans le groupe de son chef.
	assert_eq(_as("p2", Protocol.CMD_PARTY_INVITE, {"joueur": "p3"})[0]["type"], Protocol.EVT_PARTY_INVITE)
	assert_eq(_as("p3", Protocol.CMD_PARTY_ANSWER, {"chef": "p2", "accepte": true}).size(), 3, "les trois membres le savent")
	assert_eq(_world.parties["p1"], ["p1", "p2", "p3"] as Array[String])
	assert_eq(_world.player("p3").party_leader, "p1")
	# Le chef part : le suivant prend sa place.
	var left := _as("p1", Protocol.CMD_PARTY_LEAVE)
	assert_eq(left[0]["membres"], [], "Frodon n'a plus de groupe")
	assert_eq(_world.player("p2").party_leader, "p2")
	assert_eq(_world.player("p3").party_leader, "p2")
	assert_eq(_world.snapshot("p3")["groupe_joueurs"]["chef"], "p2")
	# À deux, le départ de l'un dissout le groupe.
	_as("p3", Protocol.CMD_PARTY_LEAVE)
	assert_eq(_world.player("p2").party_leader, "", "un groupe d'un seul joueur se dissout")
	assert_true(_world.parties.is_empty())


func test_trois_joueurs_finissent_un_combat_et_ont_chacun_leur_part() -> void:
	_party(["p2", "p3"])
	var combat := _fight([])
	var joined := _as("p2", Protocol.CMD_JOIN_COMBAT, {"groupe": "groupe_1"})
	var engaged := Fixtures.of_type(joined, Protocol.EVT_GROUP_ENGAGED)
	assert_eq(engaged.size(), 1, "Sam disparaît de la carte chez les autres")
	assert_eq(_sorted(_world.recipients(engaged[0], "p2")), ["p1", "p2", "p3", "p4"])
	var start := Fixtures.of_type(joined, Protocol.EVT_COMBAT_STARTED)[0]
	assert_eq(_world.recipients(start, "p2"), ["p2"] as Array[String], "le combat complet pour qui arrive")
	assert_eq(start["combattants"].size(), 3)
	var arrived := Fixtures.of_type(joined, Protocol.EVT_FIGHTER_JOINED)[0]
	assert_eq(_sorted(_world.recipients(arrived, "p2")), ["p1", "p2"], "les joueurs du combat le voient arriver")
	_as("p3", Protocol.CMD_JOIN_COMBAT, {"groupe": "groupe_1"})
	assert_eq(combat.player_fighters().size(), 3)
	assert_true(_world.player("p3").combat == combat)
	# Gollum, hors du groupe, voit les épées mais ne peut pas entrer ; personne n'est sur la carte pour lui.
	var seen := _world.snapshot("p4")
	assert_eq(seen["joueurs"], [], "les joueurs en combat sont cachés de la carte")
	assert_eq(seen["combats"].size(), 1)
	assert_eq(_sorted(seen["combats"][0]["joueurs"]), ["p1", "p2", "p3"])
	assert_eq(_as("p4", Protocol.CMD_JOIN_COMBAT, {"groupe": "groupe_1"})[0]["raison"], Protocol.REASON_NOT_IN_PARTY)
	# Le combat commence quand les trois sont prêts.
	assert_eq(_as("p1", Protocol.CMD_READY)[0]["type"], Protocol.EVT_READY)
	assert_eq(_as("p2", Protocol.CMD_READY)[0]["type"], Protocol.EVT_READY)
	assert_eq(combat.state, Combat.State.PLACEMENT)
	assert_eq(_as("p3", Protocol.CMD_READY)[0]["type"], Protocol.EVT_FIGHT_BEGINS)
	assert_eq(_world.player("p2").combat == combat, true)
	var ended := _finish(combat)
	var ends := Fixtures.of_type(ended, Protocol.EVT_COMBAT_ENDED)
	assert_eq(ends.size(), 3, "une fin de combat par joueur")
	assert_eq(ends[0]["gains"].size(), 3, "avec les gains de tous, pour le tableau de fin")
	assert_eq(ends[1]["gains"]["p1"]["butin"], ends[0]["butin"], "le butin de Frodon chez Sam aussi")
	var dents := 0
	var coins := 0
	for end in ends:
		var owner: String = end[Protocol.FIELD_FOR]
		assert_eq(_world.recipients(end, "p1"), [owner] as Array[String], "chacun reçoit la sienne")
		assert_eq(end["vainqueur"], Fighter.TEAM_PLAYERS)
		# 10 XP × bonus de groupe 1,5 × un tiers (mêmes niveaux) × XP_RATE × Sagesse +100 %.
		assert_eq(end["xp"], roundi(roundi(10 * 1.5 / 3.0) * Character.XP_RATE * 2.0), "sa part de l'XP")
		coins += int(end["ecus"])
		for drop: Dictionary in end["butin"]:
			if drop["objet"] == "dent":
				dents += int(drop["quantite"])
		assert_true(_world.player(owner).character.xp > 0)
		assert_false(_world.player(owner).in_combat())
	assert_eq(coins, 3, "les brumes du monstre partagées")
	assert_eq(dents, 2, "la limite du butin est partagée entre les joueurs")
	var back := Fixtures.of_type(ended, Protocol.EVT_EXPLORATION)
	assert_eq(back.size(), 3)
	var over := Fixtures.of_type(ended, Protocol.EVT_FIGHT_OVER)
	assert_eq(over.size(), 1, "les épées disparaissent")
	assert_eq(Fixtures.of_type(ended, Protocol.EVT_PLAYER_JOINED).size(), 3, "les joueurs réapparaissent")
	var damage := Fixtures.of_type(ended, Protocol.EVT_DAMAGE)[0]
	assert_eq(_sorted(_world.recipients(damage, "p1")), ["p1", "p2", "p3"], "les coups se voient de tout le combat")
	assert_eq(_world.snapshot("p4")["joueurs"].size(), 3)


func test_rejoindre_seulement_pendant_le_placement() -> void:
	_party(["p2", "p3"])
	var combat := _fight(["p2"])
	_as("p1", Protocol.CMD_READY)
	_as("p2", Protocol.CMD_READY)
	assert_eq(combat.state, Combat.State.FIGHTING)
	assert_eq(_as("p3", Protocol.CMD_JOIN_COMBAT, {"groupe": "groupe_1"})[0]["raison"], Protocol.REASON_COMBAT_STARTED)
	assert_eq(_as("p3", Protocol.CMD_JOIN_COMBAT, {"groupe": "inconnu"})[0]["raison"], Protocol.REASON_UNKNOWN_ENTITY)


func test_les_allies_sont_recrees_dans_la_copie_du_client() -> void:
	_party(["p2"])
	_world.player("p1").character.inventory.ecus = 0
	var combat := _fight(["p2"])
	var copy := ClientState.new(_world.data, _loader)
	copy.load_snapshot(Protocol.decode(Protocol.encode(_world.snapshot("p2"))))
	assert_true(copy.combat != null, "le combat se recrée chez Sam")
	var ally := copy.combat.get_fighter("p1")
	assert_true(ally != null, "Frodon, d'après son profil")
	assert_eq(ally.display_name, "Frodon")
	assert_eq(ally.max_hp, combat.get_fighter("p1").max_hp)
	assert_eq(ally.spells.size(), combat.get_fighter("p1").spells.size(), "avec ses sorts et son arme")
	assert_eq(ally.spells[0].id, combat.get_fighter("p1").spells[0].id)


func test_temps_du_placement_et_du_tour_en_ligne() -> void:
	_world.turn_seconds = 30.0
	_party(["p2"])
	var combat := _fight(["p2"])
	assert_eq(combat.turn_limit, 30.0)
	assert_eq(_world.update(World.PLACEMENT_SECONDS - 1.0).filter(func(e: Dictionary) -> bool: return e["type"] == Protocol.EVT_FIGHT_BEGINS), [])
	var begins := _world.update(1.0)
	var started := Fixtures.of_type(begins, Protocol.EVT_TURN_STARTED)
	assert_eq(combat.state, Combat.State.FIGHTING, "le placement a une fin")
	assert_eq(started[0]["duree"], 30.0)
	var playing := combat.current_fighter().id
	assert_eq(_sorted(_world.recipients(started[0])), ["p1", "p2"], "sans commande, envoyé au combat")
	var passed := Fixtures.of_type(_world.update(30.0), Protocol.EVT_TURN_ENDED)
	assert_eq(passed[0]["entite"], playing)
	assert_true(passed[0]["temps_ecoule"], "tour passé faute de temps")
	assert_true(combat.current_fighter().id != playing)


func test_deconnexion_en_combat_et_reprise() -> void:
	_party(["p2"])
	var combat := _fight(["p2"])
	_as("p1", Protocol.CMD_READY)
	var away := _world.disconnect_player("p2")
	assert_eq(Fixtures.of_type(away, Protocol.EVT_FIGHTER_AWAY).size(), 1)
	assert_eq(combat.state, Combat.State.FIGHTING, "un absent compte comme prêt")
	assert_true(_world.is_away("p2"), "Sam reste dans le monde")
	# Ses tours passent tout seuls : c'est toujours à Frodon de jouer.
	_as("p1", Protocol.CMD_END_TURN)
	assert_eq(combat.current_fighter().id, "p1")
	_world.reconnect("p2")
	assert_false(_world.is_away("p2"))
	assert_true(_world.snapshot("p2")["combat"] != null, "il retrouve son combat")
	_world.disconnect_player("p2")
	_finish(combat)
	assert_eq(_world.take_departed(), ["p2"] as Array[String], "parti à la fin du combat, avec sa part")
	assert_true(_world.player("p2").character.xp > 0)
	_world.remove_player("p2")
	assert_eq(_world.parties, {}, "plus de groupe à un")


func test_le_dernier_connecte_part_et_le_combat_est_abandonne() -> void:
	_party(["p2"])
	_fight(["p2"])
	_world.disconnect_player("p1")
	var events := _world.disconnect_player("p2")
	assert_eq(Fixtures.of_type(events, Protocol.EVT_GROUP_RELEASED).size(), 1, "le groupe revient pour les autres")
	assert_true(_world.player("p2") == null)
	assert_eq(_world.take_departed(), ["p1"] as Array[String])
	assert_false(_world.player("p1").in_combat())
