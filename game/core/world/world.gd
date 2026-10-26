class_name World
extends RefCounted
## Point d'entrée du noyau de jeu. Le client envoie des commandes à `execute()`, qui les valide,
## met à jour l'état et renvoie les événements produits (voir `Protocol`).
##
## Le monde tient des cartes vivantes (`MapInstance`, partagées) et des joueurs connectés
## (`PlayerState`), chacun désigné par l'id de son personnage : le champ `entite` des commandes dit
## qui agit. En solo, un seul joueur (`PLAYER_ID`) et les raccourcis `character`, `map`, `combat`…
## gardent l'interface d'avant (façade solo). En multijoueur, ce même code tourne sur le serveur
## (GDD § 16.5) ; `recipients` dit à qui envoyer chaque événement.

## Id du personnage en solo (en ligne, chaque personnage a le sien).
const PLAYER_ID := "joueur"
const DEFAULT_VOIE := "guerrier"
const DEFAULT_NAME := "Aventurier"
## Régénération hors combat : un PV toutes les REGEN_SECONDS secondes.
const REGEN_SECONDS := 2.0
## Assis, la régénération va SIT_REGEN_FACTOR fois plus vite.
const SIT_REGEN_FACTOR := 3.0
## Quand un groupe devrait réapparaître sur la case du joueur, il attend encore un peu.
const RESPAWN_RETRY := 5.0
## Promenade des groupes de monstres : délai entre deux déplacements (secondes), nombre de pas au
## plus par déplacement, et distance maximale (en cases) de leur case d'origine.
const GROUP_WANDER_DELAY := [8.0, 20.0]
const GROUP_WANDER_STEPS := 3
const GROUP_WANDER_RANGE := 3
## Monstres élites : chaque espèce tente d'apparaître toutes les 5 à 6 minutes (temps de jeu
## global, quelle que soit la carte du joueur) tant qu'elle n'est pas déjà en vie quelque part. Elle
## gagne un rang d'ancienneté par ELITE_RANK_SECONDS sans être vaincue (10 au plus), chaque rang
## donnant +10 % de chances de butin au combat contre son groupe.
const ELITE_SPAWN_DELAY := [300.0, 360.0]
## Une minute par rang pour les tests (une heure prévue ensuite).
const ELITE_RANK_SECONDS := 60.0
const ELITE_MAX_RANK := 10
const ELITE_LOOT_BONUS_PER_RANK := 0.1
## Au-delà de ce nombre de groupes sur la carte, l'élite prend la place d'un monstre d'un groupe.
const ELITE_MAX_GROUPS := 3
## Id des groupes créés pour une élite (ceux qui ne viennent pas de la carte).
const ELITE_GROUP_PREFIX := "elite_"
## Quantité maximale d'un même objet par achat ou vente.
const MAX_TRADE_QUANTITY := 100
## Phase de test : toutes les Pierres de Passage sont connues dès le début (les zones ne sont pas
## encore reliées à pied). À remettre à false quand elles le seront : il faudra alors toucher une
## pierre pour la découvrir (celle de la zone de départ de la race, et les `toujours_connue`, restent
## connues).
const ALL_PASSAGES_KNOWN := true
## Groupes de joueurs (GDD § 13) : 8 joueurs au plus.
const PARTY_MAX := 8
## Bonus d'XP de groupe selon le nombre de joueurs du combat (1 à 8), comme Dofus : chacun reçoit
## l'XP des monstres × ce bonus × sa part de niveaux (son niveau / somme des niveaux). À régler.
const PARTY_XP_BONUS := [1.0, 1.1, 1.5, 2.3, 3.1, 3.6, 4.2, 4.7]
## Placement en ligne (s), quand le temps des tours est limité (`turn_seconds`).
const PLACEMENT_SECONDS := 45.0

var data: GameData
## Toutes les pierres connues (voir `ALL_PASSAGES_KNOWN` ; les tests de découverte le coupent).
var all_passages_known := ALL_PASSAGES_KNOWN
## Durée d'un tour de joueur en combat (s), 0 : illimitée (solo). Le serveur la règle (GDD § 7.2 :
## 30 s en multi) ; le placement dure alors PLACEMENT_SECONDS.
var turn_seconds := 0.0
## Groupes de joueurs : id du chef → membres (ids, chef en premier).
var parties: Dictionary = {}
## Joueurs absents dont le combat est fini : à sauvegarder puis retirer du monde (`take_departed`).
var _departed: Array[String] = []
## Chance d'une récolte rare (voir `Profession.RARE_CHANCE` ; les tests la fixent à 0 ou 1).
var rare_harvest_chance := Profession.RARE_CHANCE
## Joueurs connectés : id du personnage → PlayerState.
var players: Dictionary = {}
## Id du premier joueur, celui de la façade solo.
var player_id := PLAYER_ID
## Cartes vivantes, une par carte visitée : id de carte → MapInstance.
var instances: Dictionary = {}
## Chargement d'une carte par son id : Callable(id: String) -> GameMap (ou null).
var _map_loader: Callable
var _loaded_maps: Dictionary = {}
## Tirages au hasard hors combat : jets des objets achetés ou fabriqués, récoltes, repousse.
var rng := RandomNumberGenerator.new()
## Temps de jeu écoulé, en secondes (avancé par `update`).
var clock := 0.0
var _combat_count := 0
## Toutes les cartes du jeu (où les élites peuvent apparaître) ; rempli par le client.
var map_ids: Array[String] = []
## Élites en vie : id du monstre élite → { carte, groupe }.
var _elites: Dictionary = {}
## Prochaine tentative d'apparition des élites absentes : id du monstre élite → instant.
var _elite_attempts: Dictionary = {}
## Boss déjà vaincus au moins une fois (id → true) : ils débloquent les groupes `apres_boss` des
## cartes (les variantes corrompues de leur zone).
var defeated_bosses: Dictionary = {}

# --- Façade solo : le premier joueur ----------------------------------------------------------

## Carte du joueur.
var map: GameMap:
	get:
		return _solo().map
## Personnage du joueur (niveau, caractéristiques…).
var character: Character:
	get:
		return _solo().character
## Raccourcis vers le personnage.
var player_voie: String:
	get:
		return character.voie_id
	set(value):
		character.voie_id = value
var player_name: String:
	get:
		return character.display_name
	set(value):
		character.display_name = value
## Combat en cours, ou `null` en exploration.
var combat: Combat:
	get:
		return _solo().combat
## Le joueur est assis (régénération plus rapide).
var sitting: bool:
	get:
		return _solo().sitting
	set(value):
		_solo().sitting = value
## Quêtes du joueur.
var quest_book: QuestBook:
	get:
		return _solo().quest_book
## Groupes et cases de la carte du joueur (pour les tests).
var _groups: Dictionary:
	get:
		return _solo().instance.groups
var _positions: Dictionary:
	get:
		return _solo().instance.positions
## Réapparitions en attente, par carte : id de carte → { id du groupe: instant }.
var _respawns: Dictionary:
	get:
		var timers := {}
		for map_id: String in instances:
			timers[map_id] = instances[map_id].respawns
		return timers


func _init(p_map: GameMap, p_data: GameData = null, p_map_loader: Callable = Callable(), p_character: Character = null,
		p_player_id := PLAYER_ID) -> void:
	data = p_data
	_map_loader = p_map_loader
	rng.randomize()
	player_id = p_player_id
	_loaded_maps[p_map.id] = p_map
	if p_player_id.is_empty():
		return  # Monde du serveur : les joueurs se connectent ensuite (`add_player`).
	add_player(p_character if p_character != null else Character.create(DEFAULT_NAME, "humain", DEFAULT_VOIE), p_player_id,
		p_map.id, p_map.spawn)


## Monde d'un serveur (GDD § 16.5) : aucun joueur au départ, pas de façade solo ; chaque joueur se
## connecte par `add_player` (sur une carte nommée) et chaque commande nomme son joueur (`entite`).
static func for_server(p_map: GameMap, p_data: GameData, p_map_loader: Callable) -> World:
	return World.new(p_map, p_data, p_map_loader, null, "")


## Connecte un personnage sous l'id `id`, sur la carte `map_id` (celle du premier joueur si vide), à
## la case `cell` (l'arrivée de la carte si elle n'est pas praticable). Renvoie son état, ou `null`
## si l'id est pris ou la carte introuvable.
func add_player(p_character: Character, id: String, map_id := "", cell := GameMap.NO_CELL) -> PlayerState:
	if players.has(id):
		return null
	var target := _load_map(map_id if not map_id.is_empty() else map.id)
	if target == null:
		return null
	var p := PlayerState.new(id, p_character)
	p.quest_book = QuestBook.new(self, p)
	players[id] = p
	_init_travel(p)
	_set_map(p, target, cell if target.is_walkable(cell) else target.spawn)
	return p


## Déconnecte un joueur : il quitte sa carte et son combat, abandonné (le personnage reste tel
## qu'avant le combat, et le groupe redevient libre). Renvoie les événements pour les autres joueurs
## de la carte.
func remove_player(id: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var p: PlayerState = players.get(id)
	if p == null or id == player_id:
		return events
	if p.combat != null:
		var mates := _team_of(p.combat)
		if not _present_mates(p).is_empty() and p.combat.state != Combat.State.FINISHED:
			# D'autres joueurs restent dans le combat : il continue sans lui (ses tours passent).
			var mate := _present_mates(p)[0]
			events.append_array(_tag_combat(p.combat.set_absent(id, true), mates, p))
			_quit_combat(p)
			if mate.combat.state == Combat.State.FINISHED:
				_end_combat(mate, events)
		else:
			# Plus personne de connecté : le combat est abandonné, les absents partent aussi.
			p.instance.fighting.erase(p.combat_group)
			_release_group(p.instance, p.combat_group, events)
			for member in mates:
				if member != p:
					member.combat = null
					member.combat_group = ""
					_departed.append(member.id)
			p.combat = null
			p.combat_group = ""
	_leave_party(p, events)
	_leave_instance(p, events)
	players.erase(id)
	_departed.erase(id)
	return events


## Un joueur se déconnecte (serveur). En plein combat avec d'autres joueurs connectés, il reste
## dans le monde, absent (ses tours passent) : il retrouve son combat s'il revient avant la fin
## (`reconnect`), sinon il part à la fin (`take_departed`). Sinon il est retiré (`remove_player`).
## Renvoie les événements pour les autres joueurs.
func disconnect_player(id: String) -> Array[Dictionary]:
	var p: PlayerState = players.get(id)
	if p == null:
		return [] as Array[Dictionary]
	if p.combat == null or p.combat.state == Combat.State.FINISHED or _present_mates(p).is_empty():
		return remove_player(id)
	p.away = true
	var events := _tag_combat(p.combat.set_absent(id, true), _team_of(p.combat), p)
	events.append_array(_party_events(p.party_leader))
	if p.combat.state == Combat.State.FINISHED:
		_end_combat(p, events)
	return events


## Un joueur absent revient (serveur) : il retrouve son combat. Renvoie les événements pour les
## autres joueurs, ou rien s'il n'était pas absent.
func reconnect(id: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var p: PlayerState = players.get(id)
	if p == null or not p.away:
		return events
	p.away = false
	_departed.erase(id)
	if p.combat != null:
		events.append_array(_tag_combat(p.combat.set_absent(id, false), _team_of(p.combat), p))
	events.append_array(_party_events(p.party_leader))
	return events


## Vrai si le joueur est absent (déconnecté pendant un combat de groupe).
func is_away(id: String) -> bool:
	return players.has(id) and (players[id] as PlayerState).away


## Joueurs absents dont le combat est fini, à sauvegarder puis retirer (`remove_player`) ; la liste
## est vidée.
func take_departed() -> Array[String]:
	var departed := _departed.duplicate()
	_departed.clear()
	return departed


## État d'un joueur connecté, ou `null`.
func player(id: String) -> PlayerState:
	return players.get(id)


func _solo() -> PlayerState:
	return players[player_id]


## Joueur qui envoie la commande (`entite`) ; le premier joueur si elle n'en nomme aucun de connu
## (en ligne, le serveur remplit `entite` d'après la session : il désigne toujours un joueur).
func _player_of(command: Dictionary) -> PlayerState:
	var entity_id: Variant = command.get("entite")
	if typeof(entity_id) == TYPE_STRING and players.has(entity_id):
		return players[entity_id]
	return players.get(player_id)  # `null` sur un serveur.


## Nom d'une carte d'après son id ("" si elle est introuvable).
func map_name(map_id: String) -> String:
	var found := _load_map(map_id)
	return found.display_name if found != null else ""


## Carte d'après son id, chargée au besoin (pour la carte du monde), ou `null` si elle est introuvable.
func map_by_id(map_id: String) -> GameMap:
	return _load_map(map_id)


## Nom de la carte voisine dans cette direction, ou "" s'il n'y en a pas.
func neighbor_name(direction: String) -> String:
	if not map.exits.has(direction):
		return ""
	var neighbor := _load_map(map.exits[direction])
	return neighbor.display_name if neighbor != null else ""


func has_entity(entity_id: String) -> bool:
	return _solo().instance.has_entity(entity_id)


func position_of(entity_id: String) -> Vector2i:
	return _solo().instance.position_of(entity_id)


## Groupes de monstres présents sur la carte.
func groups() -> Array:
	return _groups.values()


## Groupe de monstres de la carte actuelle, par son id ({} s'il n'y est pas).
func group(group_id: String) -> Dictionary:
	return _groups.get(group_id, {})


## Groupe de monstres sur la case, ou `{}`.
func group_at(cell: Vector2i) -> Dictionary:
	return _solo().instance.group_at(cell)


func in_combat() -> bool:
	return combat != null


func execute(command: Dictionary) -> Array[Dictionary]:
	Protocol.check_round_trip(command)
	var events := _execute(command)
	for event in events:
		Protocol.check_round_trip(event)
	return events


func _execute(command: Dictionary) -> Array[Dictionary]:
	var p := _player_of(command)
	if p == null:
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if p.in_combat():
		var events := p.combat.execute(command)
		if p.combat.state == Combat.State.FINISHED:
			_end_combat(p, events)
			p.quest_book.observe(events)
		return events
	var events := _execute_exploration(p, command)
	_stand_up_if_leaving(p, events)
	p.quest_book.observe(events)
	return events


## Instantané de ce que voit le joueur `id`, pour la copie de l'état de son client
## (`ClientState`) : son personnage, sa carte et ce qui s'y trouve (groupes avec l'âge de leur élite,
## autres joueurs, ressources épuisées), son combat vu de son équipe. En ligne, le serveur l'envoie à
## l'entrée d'une carte et à la reconnexion (GDD § 16.5).
func snapshot(id := player_id) -> Dictionary:
	var p: PlayerState = players[id]
	var groups: Array = []
	for group_state: Dictionary in p.instance.groups.values():
		if p.instance.fighting.get(group_state["id"], id) == id:  # Pas ceux que combat un autre joueur.
			groups.append(group_view(group_state))
	var others: Array = []
	for other_id: String in p.instance.player_ids():
		if other_id != id and not players[other_id].in_combat():  # En combat : caché de la carte.
			others.append(player_view(players[other_id]))
	var fights: Array = []
	for group_id: String in p.instance.fighting:
		var starter: PlayerState = players.get(p.instance.fighting[group_id])
		if starter != null and starter.combat != null and starter.combat != p.combat:
			fights.append(_fight_view(p.instance, group_id, starter.combat))
	var fighter: Fighter = p.combat.get_fighter(id) if p.combat != null else null
	return {
		"type": Protocol.EVT_SNAPSHOT,
		"joueur": id,
		"personnage": p.character.to_dict(),
		"places": p.character.inventory.capacity,
		"assis": p.sitting,
		"carte": p.map.id,
		"position": p.cell,
		"groupes": groups,
		"joueurs": others,
		"combats": fights,
		"groupe_joueurs": _party_view(p.party_leader),
		"epuisees": p.instance.depleted.keys(),
		"pierres_toutes_connues": all_passages_known,
		"combat": p.combat.snapshot(fighter.team if fighter != null else Fighter.TEAM_PLAYERS) if p.combat != null else null,
	}


## Ce que les clients voient d'un groupe : une copie, avec l'âge de son élite plutôt que l'instant
## de son apparition (l'horloge du monde ne sort pas du serveur).
func group_view(group_state: Dictionary) -> Dictionary:
	var copy := group_state.duplicate(true)
	if copy.has("apparition"):
		copy["age"] = clock - float(copy["apparition"])
		copy.erase("apparition")
	return copy


## État d'un joueur à garder entre deux connexions (serveur, GDD § 16.5) : son personnage, sa carte
## et sa case. Un combat en cours n'y est pas : le personnage est gardé tel qu'avant le combat.
func player_save(id: String) -> Dictionary:
	var p: PlayerState = players.get(id)
	if p == null:
		return {}
	var cell := p.cell
	return {"personnage": p.character.to_dict(), "carte": p.map.id, "position": [cell.x, cell.y]}


## Joueurs à qui envoyer un événement produit par la commande de `sender_id` (ou par `update` si
## `sender_id` est vide), selon sa portée (`Protocol.scope_of`) : lui seul (personnel, ou l'événement
## nomme son joueur dans `entite`), les joueurs de la carte `carte` (carte), ou ceux de son combat.
func recipients(event: Dictionary, sender_id := "") -> Array[String]:
	var ids: Array[String] = []
	match Protocol.scope_of(event):
		Protocol.SCOPE_MAP:
			var instance: MapInstance = instances.get(str(event.get("carte", "")))
			if instance != null:
				ids = instance.player_ids()
			if not sender_id.is_empty() and sender_id not in ids:
				ids.append(sender_id)
		Protocol.SCOPE_COMBAT:
			var p: PlayerState = players.get(sender_id if not sender_id.is_empty() else str(event.get(Protocol.FIELD_COMBAT_OF, "")))
			if p != null:
				for mate_id in p.fight_mates:
					if players.has(mate_id):
						ids.append(mate_id)
				if p.id not in ids:
					ids.append(p.id)
		_:
			var target: String = str(event[Protocol.FIELD_FOR]) if event.has(Protocol.FIELD_FOR) \
				else sender_id if not sender_id.is_empty() else str(event.get("entite", ""))
			if players.has(target):
				ids.append(target)
	return ids


func _execute_exploration(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var type: Variant = command.get("type")
	if typeof(type) == TYPE_STRING:
		if type == Protocol.CMD_MOVE:
			return _move(p, command)
		if type == Protocol.CMD_ENGAGE:
			return _engage(p, command)
		if type == Protocol.CMD_JOIN_COMBAT:
			return _join_combat(p, command)
		if type == Protocol.CMD_PARTY_INVITE:
			return _party_invite(p, command)
		if type == Protocol.CMD_PARTY_ANSWER:
			return _party_answer(p, command)
		if type == Protocol.CMD_PARTY_LEAVE:
			var left: Array[Dictionary] = []
			if p.party_leader.is_empty():
				return _refused(command, Protocol.REASON_NOT_IN_PARTY)
			_leave_party(p, left)
			return left
		if type == Protocol.CMD_TALK:
			return _talk(p, command)
		if type == Protocol.CMD_SIT:
			return _sit(p, command)
		if type == Protocol.CMD_SPEND_POINTS:
			return _spend_points(p, command)
		if type == Protocol.CMD_RESET_POINTS:
			return _reset_points(p, command)
		if type == Protocol.CMD_EQUIP:
			return _equip(p, command)
		if type == Protocol.CMD_UNEQUIP:
			return _unequip(p, command)
		if type == Protocol.CMD_DROP:
			return _drop(p, command)
		if type == Protocol.CMD_BUY:
			return _buy(p, command)
		if type == Protocol.CMD_SELL:
			return _sell(p, command)
		if type == Protocol.CMD_HARVEST:
			return _harvest(p, command)
		if type == Protocol.CMD_CRAFT:
			return _craft(p, command)
		if type == Protocol.CMD_USE:
			return _use(p, command)
		if type == Protocol.CMD_DEPOSIT:
			return _transfer(p, command, p.character.inventory, p.character.chest)
		if type == Protocol.CMD_WITHDRAW:
			return _transfer(p, command, p.character.chest, p.character.inventory)
		if type == Protocol.CMD_TRAVEL:
			return _travel(p, command)
		if type in [Protocol.CMD_QUEST_ACCEPT, Protocol.CMD_QUEST_DECLINE, Protocol.CMD_QUEST_TRACK]:
			return _quest_command(p, command)
	return _refused(command, Protocol.REASON_UNKNOWN_COMMAND)


func _quest_command(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var quest_id: Variant = command.get("quete")
	if not _is_player_command(p, command) or typeof(quest_id) != TYPE_STRING or data == null:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var events: Array[Dictionary] = []
	var reason := ""
	if command["type"] == Protocol.CMD_QUEST_ACCEPT:
		reason = p.quest_book.accept(quest_id, events)
	elif command["type"] == Protocol.CMD_QUEST_DECLINE:
		p.quest_book.decline(quest_id)
	else:
		reason = p.quest_book.track(quest_id, events)
	return _refused(command, reason) if not reason.is_empty() else events


func _move(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var entity_id: Variant = command.get("entite")
	var target: Variant = command.get("cible")
	var exit: Variant = command.get("sortie", "")
	var door: Variant = command.get("porte", false)
	if typeof(entity_id) != TYPE_STRING or typeof(target) != TYPE_VECTOR2I or typeof(exit) != TYPE_STRING or typeof(door) != TYPE_BOOL:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if entity_id != p.id:
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if not p.map.is_inside(target):
		return _refused(command, Protocol.REASON_OUT_OF_MAP)
	if not p.map.is_walkable(target):
		return _refused(command, Protocol.REASON_BLOCKED)
	var next_map: GameMap = null
	if not exit.is_empty():
		if exit not in p.map.exit_directions(target):
			return _refused(command, Protocol.REASON_NO_EXIT)
		next_map = _load_map(p.map.exits[exit])
		if next_map == null:
			return _refused(command, Protocol.REASON_UNKNOWN_MAP)
	elif door:
		if not p.map.doors.has(target):
			return _refused(command, Protocol.REASON_NO_EXIT)
		next_map = _load_map(p.map.doors[target])
		if next_map == null:
			return _refused(command, Protocol.REASON_UNKNOWN_MAP)
	var start: Variant = _start_cell(p, command)
	if start == null:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var from: Vector2i = start
	var interrupted := command.has("interrompre_a")
	var path := p.map.find_path(from, target)
	if from == target and next_map == null and not interrupted:
		return _refused(command, Protocol.REASON_ALREADY_THERE)
	if path.is_empty() and from != target:
		return _refused(command, Protocol.REASON_NO_PATH)

	var events: Array[Dictionary] = []
	if not path.is_empty() or interrupted:
		events.append(_moved_event(p, from, path))
	p.cell = target
	_remember_walk(p, from, path)
	if next_map != null:
		var previous_map := p.map.id
		var arrival := next_map.door_to(previous_map) if door else next_map.arrival_cell(exit, target)
		var others: Array[Dictionary] = []
		_set_map(p, next_map, arrival, others)
		_append_map_change(events, others, {
			"type": Protocol.EVT_MAP_CHANGED,
			"carte": p.map.id,
			"nom": p.map.display_name,
			"position": p.cell,
		})
	return events


## Ajoute un changement de carte entre le départ (EVT_PLAYER_LEFT, pour les joueurs de l'ancienne
## carte) et l'arrivée (EVT_PLAYER_JOINED, pour ceux de la nouvelle).
static func _append_map_change(events: Array[Dictionary], others: Array[Dictionary], changed: Dictionary) -> void:
	for event in others:
		if event["type"] == Protocol.EVT_PLAYER_LEFT:
			events.append(event)
	events.append(changed)
	for event in others:
		if event["type"] != Protocol.EVT_PLAYER_LEFT:
			events.append(event)


## Le joueur marche à côté du PNJ, qui lui parle.
func _talk(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var entity_id: Variant = command.get("entite")
	var npc_id: Variant = command.get("pnj")
	if typeof(entity_id) != TYPE_STRING or entity_id != p.id or typeof(npc_id) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var npc := p.map.get_npc(npc_id)
	if npc.is_empty():
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	var npc_cell: Vector2i = npc["case"]
	var start: Variant = _start_cell(p, command)
	if start == null:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var from: Vector2i = start
	var events: Array[Dictionary] = []
	if not GameMap.is_adjacent(from, npc_cell):
		var best := p.map.approach_path(from, npc_cell)
		if best.is_empty():
			return _refused(command, Protocol.REASON_NO_PATH)
		events.append(_moved_event(p, from, best))
		p.cell = best[-1]
		_remember_walk(p, from, best)
	elif from != p.cell:
		# Arrêté en chemin juste à côté du PNJ.
		events.append(_moved_event(p, from, [] as Array[Vector2i]))
		p.cell = from
		_remember_walk(p, from, [] as Array[Vector2i])
	if data != null and p.quest_book.talk(npc, events):
		return events
	var workshop: String = npc.get("atelier", "")
	if not workshop.is_empty() and data != null and data.jobs.has(workshop):
		events.append({
			"type": Protocol.EVT_WORKSHOP,
			"pnj": npc["id"],
			"nom": npc["nom"],
			"case": npc_cell,
			"repliques": npc["repliques"].duplicate(),
			"metier": workshop,
			"nom_metier": data.jobs[workshop]["nom"],
			"recettes": _workshop_recipes(workshop),
		})
		return events
	if npc.get("marchand", false) and data != null:
		events.append({
			"type": Protocol.EVT_SHOP,
			"pnj": npc["id"],
			"nom": npc["nom"],
			"case": npc_cell,
			"repliques": npc["repliques"].duplicate(),
			"articles": _shop_articles(),
			"taux_revente": Item.RESALE_RATE,
		})
		return events
	events.append({
		"type": Protocol.EVT_DIALOGUE,
		"pnj": npc["id"],
		"nom": npc["nom"],
		"case": npc_cell,
		"repliques": npc["repliques"].duplicate(),
	})
	return events


## Case de départ d'une commande d'exploration : la position du joueur, ou la case du trajet en
## cours où il s'arrête (`interrompre_a`). `null` si cette case n'est pas sur le trajet.
func _start_cell(p: PlayerState, command: Dictionary) -> Variant:
	if not command.has("interrompre_a"):
		return p.cell
	var stop: Variant = command["interrompre_a"]
	if typeof(stop) != TYPE_VECTOR2I or (stop not in p.last_walk and stop != p.cell):
		return null
	return stop


func _remember_walk(p: PlayerState, from: Vector2i, path: Array[Vector2i]) -> void:
	p.last_walk = [from]
	p.last_walk.append_array(path)


## Change de carte : le joueur quitte la carte vivante de l'ancienne (qui garde ses groupes) et
## entre dans celle de la nouvelle, créée à la première visite. La carte rejoint les cartes visitées
## du personnage. Les autres joueurs des deux cartes l'apprennent par `events` (EVT_PLAYER_LEFT et
## EVT_PLAYER_JOINED, seulement s'il y en a : jamais en solo).
func _set_map(p: PlayerState, next_map: GameMap, player_cell: Vector2i, events: Array[Dictionary] = []) -> void:
	_leave_instance(p, events)
	_loaded_maps[next_map.id] = next_map
	p.instance = _instance(next_map.id)
	if not p.instance.has_players():
		p.instance.wander_times.clear()  # Une carte qui se réveille : pas de promenade tout de suite.
	var others := p.instance.player_ids()
	p.instance.add_player(p.id, player_cell)
	p.character.visit_map(next_map.id)
	p.last_walk.clear()
	if not others.is_empty():
		events.append(_player_joined_event(p))


## Un groupe qui n'est plus combattu (joueur vaincu ou parti) redevient visible pour les autres
## joueurs de la carte.
func _release_group(instance: MapInstance, group_id: String, events: Array[Dictionary]) -> void:
	if instance.groups.has(group_id) and instance.player_ids().size() > 1:
		events.append({"type": Protocol.EVT_GROUP_RELEASED, "carte": instance.map.id, "groupe": group_view(instance.groups[group_id])})


func _leave_instance(p: PlayerState, events: Array[Dictionary]) -> void:
	if p.instance == null:
		return
	p.instance.remove_player(p.id)
	if p.instance.has_players():
		events.append({"type": Protocol.EVT_PLAYER_LEFT, "carte": p.map.id, "entite": p.id})
	p.instance = null


## Un joueur arrive sur une carte où il y a déjà du monde : ce que les autres en voient.
func _player_joined_event(p: PlayerState) -> Dictionary:
	return {"type": Protocol.EVT_PLAYER_JOINED, "carte": p.map.id, "joueur": player_view(p)}


## Ce que les autres joueurs voient d'un joueur : { id, nom, race, voie, niveau, case, assis }.
func player_view(p: PlayerState) -> Dictionary:
	return {"id": p.id, "nom": p.character.display_name, "race": p.character.race_id, "voie": p.character.voie_id,
		"niveau": p.character.level, "case": p.cell, "assis": p.sitting}


## Carte vivante d'une carte, créée (avec ses groupes, comme à une première visite) au besoin ;
## `null` si la carte est introuvable.
func _instance(map_id: String) -> MapInstance:
	if instances.has(map_id):
		return instances[map_id]
	var source := _load_map(map_id)
	if source == null:
		return null
	var groups := {}
	for group in available_groups(source):
		groups[group["id"]] = GameMap.compose_group(group, rng, data)
	var instance := MapInstance.new(source, groups)
	instances[map_id] = instance
	return instance


func _load_map(map_id: String) -> GameMap:
	if _loaded_maps.has(map_id):
		return _loaded_maps[map_id]
	if not _map_loader.is_valid():
		return null
	var loaded: GameMap = _map_loader.call(map_id)
	if loaded != null:
		_loaded_maps[map_id] = loaded
	return loaded


## Le joueur marche jusqu'au groupe de monstres, puis le combat commence.
func _engage(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var group_id: Variant = command.get("groupe")
	var entity_id: Variant = command.get("entite")
	if typeof(entity_id) != TYPE_STRING or entity_id != p.id or typeof(group_id) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if not p.instance.groups.has(group_id):
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if p.instance.fighting.has(group_id):
		return _refused(command, Protocol.REASON_GROUP_IN_COMBAT)
	if data == null or not data.voies.has(p.character.voie_id):
		return _refused(command, Protocol.REASON_WRONG_PHASE)
	if p.character.inventory.is_overloaded():
		return _refused(command, Protocol.REASON_INVENTORY_OVERLOADED)
	var group: Dictionary = p.instance.groups[group_id]
	var start: Variant = _start_cell(p, command)
	if start == null:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var from: Vector2i = start
	var target: Vector2i = group["case"]
	var path := p.map.find_path(from, target)
	if path.is_empty() and from != target:
		return _refused(command, Protocol.REASON_NO_PATH)

	var events: Array[Dictionary] = []
	if not path.is_empty() or command.has("interrompre_a"):
		events.append(_moved_event(p, from, path))
	p.cell = target
	p.last_walk.clear()
	p.combat = _create_combat(p, group)
	p.combat_group = group_id
	p.fight_mates.assign([p.id])
	p.instance.fighting[group_id] = p.id
	if p.instance.player_ids().size() > 1:
		# Le groupe et le joueur disparaissent pour les autres joueurs de la carte, qui voient les
		# épées du combat (GDD § 16.5, M2).
		events.append({"type": Protocol.EVT_GROUP_ENGAGED, "carte": p.map.id, "groupe": group_id, "entite": p.id, "case": target})
	var start_events := p.combat.start()
	start_events[0]["groupe"] = group_id
	events.append_array(start_events)
	return events


## Rejoint, pendant le placement, le combat d'un membre de son groupe sur la même carte (GDD § 16.5,
## M2) : le joueur arrive sur une case de placement libre, et disparaît de la carte chez les autres.
func _join_combat(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var group_id: Variant = command.get("groupe")
	if command.get("entite") != p.id or typeof(group_id) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var starter: PlayerState = players.get(p.instance.fighting.get(group_id, ""))
	if starter == null or starter.combat == null or starter.instance != p.instance:
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	var combat := starter.combat
	var team := _team_of(combat)
	var party_mate := false
	for member in team:
		party_mate = party_mate or (not p.party_leader.is_empty() and member.party_leader == p.party_leader)
	if not party_mate:
		return _refused(command, Protocol.REASON_NOT_IN_PARTY)
	if combat.state != Combat.State.PLACEMENT:
		return _refused(command, Protocol.REASON_COMBAT_STARTED)
	if data == null or not data.voies.has(p.character.voie_id):
		return _refused(command, Protocol.REASON_WRONG_PHASE)
	if p.character.inventory.is_overloaded():
		return _refused(command, Protocol.REASON_INVENTORY_OVERLOADED)
	var joined := combat.add_player_fighter(data.create_character_fighter(p.character, p.id))
	if joined[0]["type"] == Protocol.EVT_REFUSED:
		joined[0]["commande"] = Protocol.CMD_JOIN_COMBAT
		return joined
	var events: Array[Dictionary] = []
	if p.sitting:
		p.sitting = false
		events.append(_sat_event(p))
	p.cell = starter.cell
	p.last_walk.clear()
	p.combat = combat
	p.combat_group = starter.combat_group
	p.combat_loot_bonus = starter.combat_loot_bonus
	team.append(p)
	var mates: Array[String] = []
	for member in team:
		mates.append(member.id)
	for member in team:
		member.fight_mates.assign(mates)
	events.append({"type": Protocol.EVT_GROUP_ENGAGED, "carte": p.map.id, "groupe": p.combat_group, "entite": p.id, "case": p.cell})
	var start := combat.start()[0]
	start["groupe"] = p.combat_group
	start["prets"] = combat.ready.keys()
	start[Protocol.FIELD_FOR] = p.id
	events.append(start)
	events.append_array(joined)
	return events


## Joueurs (connectés ou absents) d'un combat.
func _team_of(combat: Combat) -> Array[PlayerState]:
	var team: Array[PlayerState] = []
	if combat == null:
		return team
	for fighter in combat.player_fighters():
		var member: PlayerState = players.get(fighter.id)
		if member != null and member.combat == combat:
			team.append(member)
	return team


## Autres joueurs connectés du combat de `p`.
func _present_mates(p: PlayerState) -> Array[PlayerState]:
	var mates: Array[PlayerState] = []
	for member in _team_of(p.combat):
		if member != p and not member.away:
			mates.append(member)
	return mates


## Le joueur quitte son combat, qui continue sans lui (déconnexion définitive) : son combattant reste,
## absent, et le combat passe à un autre joueur s'il l'avait engagé.
func _quit_combat(p: PlayerState) -> void:
	if p.instance != null and p.instance.fighting.get(p.combat_group) == p.id:
		for member in _team_of(p.combat):
			if member != p:
				p.instance.fighting[p.combat_group] = member.id
				break
	p.combat = null
	p.combat_group = ""


## Événements de combat produits sans commande d'un joueur : ils nomment un joueur du combat
## (`Protocol.FIELD_COMBAT_OF`, autre que `avoid` si possible) pour trouver leurs destinataires.
func _tag_combat(events: Array[Dictionary], team: Array[PlayerState], avoid: PlayerState = null) -> Array[Dictionary]:
	if team.is_empty():
		return events
	var owner := team[0]
	for member in team:
		if member != avoid:
			owner = member
			break
	for event in events:
		if Protocol.scope_of(event) == Protocol.SCOPE_COMBAT:
			event[Protocol.FIELD_COMBAT_OF] = owner.id
	return events


## Les épées d'un combat sur la carte, pour les autres joueurs : { groupe, case, joueurs, placement }.
func _fight_view(instance: MapInstance, group_id: String, combat: Combat) -> Dictionary:
	var ids: Array = []
	for member in _team_of(combat):
		ids.append(member.id)
	var group: Dictionary = instance.groups.get(group_id, {})
	return {"groupe": group_id, "case": group.get("case", Vector2i(-1, -1)), "joueurs": ids,
		"placement": combat.state == Combat.State.PLACEMENT}


# --- Groupes de joueurs ------------------------------------------------------------------------

## Le groupe d'un chef, tel que le voient ses membres : { chef, membres: [{ id, nom, niveau, race,
## voie, absent }] } ({ chef: "", membres: [] } sans groupe).
func _party_view(leader_id: String) -> Dictionary:
	var members: Array = []
	for member_id: String in parties.get(leader_id, []):
		var member: PlayerState = players[member_id]
		members.append({"id": member_id, "nom": member.character.display_name, "niveau": member.character.level,
			"race": member.character.race_id, "voie": member.character.voie_id, "absent": member.away})
	return {"chef": leader_id if not members.is_empty() else "", "membres": members}


## EVT_PARTY pour chaque membre du groupe de ce chef.
func _party_events(leader_id: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var view := _party_view(leader_id)
	for member_id: String in parties.get(leader_id, []):
		var event := {"type": Protocol.EVT_PARTY, Protocol.FIELD_FOR: member_id}
		event.merge(view)
		events.append(event)
	return events


func _party_invite(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var target: PlayerState = players.get(command.get("joueur", ""))
	if target == null or target == p or target.away:
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if not p.party_leader.is_empty() and p.party_leader != p.id:
		return _refused(command, Protocol.REASON_NOT_PARTY_LEADER)
	if not target.party_leader.is_empty():
		return _refused(command, Protocol.REASON_ALREADY_IN_PARTY)
	if parties.get(p.id, []).size() >= PARTY_MAX:
		return _refused(command, Protocol.REASON_PARTY_FULL)
	target.invitations[p.id] = true
	var events: Array[Dictionary] = [{"type": Protocol.EVT_PARTY_INVITE, "chef": p.id, "nom": p.character.display_name,
		Protocol.FIELD_FOR: target.id}]
	return events


func _party_answer(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var leader_id: Variant = command.get("chef")
	if typeof(leader_id) != TYPE_STRING or not p.invitations.has(leader_id):
		return _refused(command, Protocol.REASON_NO_INVITATION)
	p.invitations.erase(leader_id)
	var leader: PlayerState = players.get(leader_id)
	if leader == null:
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if not command.get("accepte", false):
		var declined: Array[Dictionary] = [{"type": Protocol.EVT_PARTY_DECLINED, "nom": p.character.display_name,
			Protocol.FIELD_FOR: leader.id}]
		return declined
	if not p.party_leader.is_empty():
		return _refused(command, Protocol.REASON_ALREADY_IN_PARTY)
	if not leader.party_leader.is_empty() and leader.party_leader != leader.id:
		return _refused(command, Protocol.REASON_NOT_PARTY_LEADER)  # Il a rejoint un autre groupe entre-temps.
	if parties.get(leader.id, []).size() >= PARTY_MAX:
		return _refused(command, Protocol.REASON_PARTY_FULL)
	if not parties.has(leader.id):
		parties[leader.id] = [leader.id] as Array[String]
		leader.party_leader = leader.id
	(parties[leader.id] as Array[String]).append(p.id)
	p.party_leader = leader.id
	p.invitations.clear()
	return _party_events(leader.id)


## Le joueur quitte son groupe : le suivant devient chef, et un groupe d'un seul joueur se dissout.
func _leave_party(p: PlayerState, events: Array[Dictionary]) -> void:
	for invited: PlayerState in players.values():
		invited.invitations.erase(p.id)
	if p.party_leader.is_empty():
		return
	var leader_id := p.party_leader
	var members: Array[String] = parties[leader_id]
	members.erase(p.id)
	parties.erase(leader_id)
	p.party_leader = ""
	events.append({"type": Protocol.EVT_PARTY, "chef": "", "membres": [], Protocol.FIELD_FOR: p.id})
	if members.size() < 2:
		for member_id in members:
			players[member_id].party_leader = ""
			events.append({"type": Protocol.EVT_PARTY, "chef": "", "membres": [], Protocol.FIELD_FOR: member_id})
		return
	parties[members[0]] = members
	for member_id in members:
		players[member_id].party_leader = members[0]
	events.append_array(_party_events(members[0]))


## Combat sur les cases de placement de la carte, comme dans Dofus (`GameMap.placement_players`,
## `placement_monsters`), où que le groupe ait été engagé : les monstres sur des cases « m » tirées
## au hasard, le joueur sur la première case « j », libre d'en changer pendant le placement. Les
## côtés sont tirés au sort à chaque combat : une fois sur deux, les camps échangent leurs cases
## (si les cases « j » suffisent au plus grand groupe).
func _create_combat(p: PlayerState, group: Dictionary) -> Combat:
	var fighters: Array[Fighter] = []
	var seed_value := hash(p.map.id) + _combat_count + 1
	var shuffle := RandomNumberGenerator.new()
	shuffle.seed = seed_value
	var monster_cells: Array[Vector2i] = p.map.placement_monsters.duplicate()
	var placement: Array[Vector2i] = p.map.placement_players.duplicate()
	if shuffle.randi_range(0, 1) == 1 and placement.size() >= GameMap.MAX_GROUP_SIZE:
		var swap_sides := monster_cells
		monster_cells = placement
		placement = swap_sides
	for i in range(monster_cells.size() - 1, 0, -1):
		var k := shuffle.randi_range(0, i)
		var swap := monster_cells[i]
		monster_cells[i] = monster_cells[k]
		monster_cells[k] = swap
	var levels: Array = group.get("niveaux", [])
	var index := 0
	for i in group["monstres"].size():
		# Chaque monstre à son niveau tiré à l'apparition (niveau de base s'il manque).
		var level := int(levels[i]) if i < levels.size() else -1
		var monster := data.create_monster(group["monstres"][i], "%s_%d" % [group["id"], index + 1], level)
		if monster == null or index >= monster_cells.size():
			continue
		monster.cell = monster_cells[index]
		fighters.append(monster)
		index += 1

	var player := data.create_character_fighter(p.character, p.id)
	player.cell = placement[0]
	fighters.append(player)
	_combat_count += 1
	var combat := Combat.new(p.map, fighters, placement, seed_value)
	combat.turn_limit = turn_seconds
	combat.placement_limit = PLACEMENT_SECONDS if turn_seconds > 0.0 else 0.0
	return combat


func _end_combat(p: PlayerState, events: Array[Dictionary]) -> void:
	var combat := p.combat
	var group_id := p.combat_group
	var combat_instance := p.instance
	var combat_map := p.map.id
	var team := _team_of(combat)
	var won := combat.winner_team == Fighter.TEAM_PLAYERS
	var loot_bonus := p.combat_loot_bonus
	combat_instance.fighting.erase(group_id)
	var map_events: Array[Dictionary] = []
	var defeated_group := ""
	if won:
		defeated_group = group_id
		var defeated: Dictionary = combat_instance.groups[group_id]
		loot_bonus = ELITE_LOOT_BONUS_PER_RANK * elite_rank(defeated)
		if defeated.has("elite"):
			_elite_defeated(defeated["elite"])
		for monster_id: String in defeated["monstres"]:
			if data != null and data.monsters.get(monster_id, {}).get("boss", false):
				_boss_defeated(monster_id)
		if not group_id.begins_with(ELITE_GROUP_PREFIX):
			_schedule_respawn(combat_map, defeated)
		combat_instance.groups.erase(group_id)
		combat_instance.positions.erase(group_id)
	else:
		_release_group(combat_instance, group_id, map_events)
	var ended: Dictionary = {}
	for i in range(events.size() - 1, -1, -1):
		if events[i]["type"] == Protocol.EVT_COMBAT_ENDED:
			ended = events[i]
			events.remove_at(i)
			break
	# Butin et brumes de victoire (`Loot` : limite par monstre partagée, tirage du plus prospecteur
	# au moins prospecteur), XP de chacun selon sa part (GDD § 7.1).
	var kinds: Array = []
	var monsters: Array = []
	var coins := 0
	for fighter in combat.fighters:
		if fighter.team == Fighter.TEAM_PLAYERS:
			continue
		kinds.append(fighter.kind)
		if won and data.monsters.has(fighter.kind):
			var monster: Dictionary = data.monsters[fighter.kind]
			monsters.append(monster)
			var coin_range: Array = monster.get("ecus", [0, 0])
			coins += combat.rng.randi_range(int(coin_range[0]), int(coin_range[1]))
	var prospections := {}
	var levels := 0
	for member in team:
		var fighter := combat.get_fighter(member.id)
		prospections[member.id] = fighter.prospection if fighter != null else Character.BASE_PROSPECTION
		levels += member.character.level
	var drops: Dictionary = Loot.roll(monsters, prospections, combat.rng, loot_bonus) if won else {}
	for i in team.size():
		var member := team[i]
		var block: Array[Dictionary] = []
		var own: Dictionary = ended.duplicate(true)
		block.append(own)
		var fighter := combat.get_fighter(member.id)
		var moved: Array[Dictionary] = []
		var wake_up := {}
		if won:
			member.character.set_hp(maxi(1, fighter.hp) if fighter != null else 1, data)
		else:
			member.character.set_hp(1, data)  # Vaincu : on se relève avec 1 PV.
			wake_up = _wake_up(member, moved)
			own["reveil"] = wake_up
		var share := float(ended.get("xp", 0))
		if team.size() > 1:
			share *= PARTY_XP_BONUS[mini(team.size(), PARTY_XP_BONUS.size()) - 1] * member.character.level / float(maxi(1, levels))
		_reward(member, own, roundi(share), block)
		if won:
			# Brumes partagées à parts égales (le reste au premier), puis le passif de race de chacun.
			var part := coins / team.size() + (coins % team.size() if i == 0 else 0)
			_loot(member, own, drops.get(member.id, []), part, combat.rng, block)
			member.quest_book.combat_won(kinds, combat.rng, own, block)
		var back := {"type": Protocol.EVT_EXPLORATION, "position": member.cell, "groupe_vaincu": defeated_group}
		if not wake_up.is_empty():
			back["reveil"] = wake_up
		block.append(back)
		if member.map.id != combat_map:
			_append_map_change(block, moved, {"type": Protocol.EVT_MAP_CHANGED, "carte": member.map.id,
				"nom": member.map.display_name, "position": member.cell})
		else:
			block.append_array(moved)
		for event in block:
			if Protocol.scope_of(event) != Protocol.SCOPE_MAP:
				event[Protocol.FIELD_FOR] = member.id
		events.append_array(block)
		member.combat = null
		member.combat_group = ""
		member.combat_loot_bonus = 0.0
		if member.away:
			_departed.append(member.id)
	# Les joueurs du combat réapparaissent pour les autres joueurs de la carte, et ses épées disparaissent.
	if combat_instance.player_ids().size() > 1:
		for member in team:
			if member.instance == combat_instance:
				map_events.append(_player_joined_event(member))
		map_events.append({"type": Protocol.EVT_FIGHT_OVER, "carte": combat_map, "groupe": group_id})
	events.append_array(map_events)


## Après une défaite, le joueur se réveille à côté de la Pierre de Passage de son point de
## résurrection, en changeant de carte s'il le faut ; sans point de résurrection (ou si sa carte est
## introuvable), au départ de la carte du combat. Renvoie où : { passage, nom, carte }.
func _wake_up(p: PlayerState, events: Array[Dictionary]) -> Dictionary:
	var passage: Dictionary = data.passages.get(p.character.respawn_passage, {}) if data != null else {}
	var target: GameMap = _load_map(passage["carte"]) if not passage.is_empty() else null
	if target == null or target.travel_stone() == Vector2i(-1, -1):
		p.cell = p.map.spawn
		return {"passage": "", "nom": p.map.display_name, "carte": p.map.id}
	_set_map(p, target, target.beside(target.travel_stone()), events)
	return {"passage": passage["id"], "nom": passage["nom"], "carte": p.map.id}


## XP des monstres vaincus, même en cas de défaite : `base` (la part du joueur) × `Character.XP_RATE`,
## bonus de Sagesse (+1 % par point) ; montées de niveau. `ended` : son EVT_COMBAT_ENDED.
func _reward(p: PlayerState, ended: Dictionary, base: int, events: Array[Dictionary]) -> void:
	ended["xp"] = 0
	if base <= 0:
		return
	var gain := roundi(base * Character.XP_RATE * (100 + p.character.stat("sagesse", data)) / 100.0)
	ended["xp"] = gain
	var levels := p.character.add_xp(gain)
	ended["niveaux"] = levels
	events.append({"type": Protocol.EVT_XP, "gain": gain, "xp": p.character.xp, "niveau": p.character.level})
	for reached in levels:
		events.append({"type": Protocol.EVT_LEVEL_UP, "niveau": reached, "points": p.character.unspent_points})
	events.append(_character_event(p))


## Butin de victoire du joueur (`drops`, tiré par `Loot.roll`) et ses brumes (`coins`, +X % avec le
## passif de race « ecus »). Rien ne se perd : si le sac est plein, le butin y entre en surplus
## (`surcharge` dans l'événement) et les combats sont refusés tant qu'on n'a pas fait de la place.
func _loot(p: PlayerState, ended: Dictionary, drops: Array, coins: int, rng: RandomNumberGenerator, events: Array[Dictionary]) -> void:
	coins = roundi(coins * (100 + data.passive_value(p.character.race_id, "ecus")) / 100.0)
	var found: Array[Dictionary] = []
	for drop: Dictionary in drops:
		var template: Dictionary = data.items[drop["objet"]]
		var quantity: int = drop["quantite"]
		for _unit in (quantity if Item.is_equipment(template) else 1):
			p.character.inventory.add(template, 1 if Item.is_equipment(template) else quantity, Item.roll_bonuses(template, rng), true)
			found.append({"objet": template["id"], "nom": template["nom"], "rarete": template["rarete"],
				"quantite": 1 if Item.is_equipment(template) else quantity})
	p.character.inventory.ecus += coins
	ended["butin"] = _merged_loot(found)
	ended["surcharge"] = p.character.inventory.is_overloaded()
	ended["ecus"] = coins
	events.append(_inventory_event(p))


func _equip(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var uid: Variant = command.get("objet")
	var wanted_slot: Variant = command.get("emplacement", "")
	if not _is_player_command(p, command) or typeof(uid) != TYPE_STRING or typeof(wanted_slot) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var inventory := p.character.inventory
	if not inventory.entries.has(uid) or not data.items.has(inventory.entries[uid]["objet"]):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	var template: Dictionary = data.items[inventory.entries[uid]["objet"]]
	if not Item.is_equipment(template):
		return _refused(command, Protocol.REASON_NOT_EQUIPPABLE)
	var slots: Array = Item.SLOTS_BY_TYPE[template["type"]]
	var slot: String = wanted_slot
	if slot.is_empty():
		# Un exemplaire identique déjà porté est remplacé ; sinon le premier emplacement libre.
		slot = slots[0]
		for candidate: String in slots:
			if not inventory.equipped.has(candidate):
				slot = candidate
				break
		for candidate: String in slots:
			var worn := inventory.equipped_entry(candidate)
			if not worn.is_empty() and worn["uid"] != uid and worn["objet"] == template["id"]:
				slot = candidate
				break
	if slot not in slots:
		return _refused(command, Protocol.REASON_NOT_EQUIPPABLE)
	if p.character.level < int(template.get("niveau", 1)):
		return _refused(command, Protocol.REASON_REQUIREMENTS)
	var conditions: Dictionary = template.get("conditions", {})
	for stat_name: String in conditions:
		if p.character.stat(stat_name, data) < int(conditions[stat_name]):
			return _refused(command, Protocol.REASON_REQUIREMENTS)
	# Deux exemplaires du même objet (deux anneaux identiques…) ne se portent pas ensemble.
	for other_slot: String in slots:
		var other := inventory.equipped_entry(other_slot)
		if other_slot != slot and not other.is_empty() and other["uid"] != uid and other["objet"] == template["id"]:
			return _refused(command, Protocol.REASON_ALREADY_WORN)
	inventory.equip(uid, slot)
	return _inventory_events(p)


func _unequip(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var slot: Variant = command.get("emplacement")
	if not _is_player_command(p, command) or typeof(slot) != TYPE_STRING or slot not in Inventory.SLOTS:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if not p.character.inventory.equipped.has(slot):
		return _refused(command, Protocol.REASON_EMPTY_SLOT)
	p.character.inventory.unequip(slot)
	return _inventory_events(p)


func _drop(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var uid: Variant = command.get("objet")
	var quantity: Variant = command.get("quantite", 1)
	if not _is_player_command(p, command) or typeof(uid) != TYPE_STRING or typeof(quantity) != TYPE_INT:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if _is_quest_item(p, uid):
		return _refused(command, Protocol.REASON_QUEST_ITEM)
	if not p.character.inventory.remove(uid, quantity):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	return _inventory_events(p)


# --- Marchands ----------------------------------------------------------------------------------

## Tous les objets du jeu en vente (voir `Item.is_sold`), avec leur prix d'achat.
func _shop_articles() -> Array:
	var articles: Array = []
	for template: Dictionary in data.items.values():
		if not Item.is_sold(template):
			continue
		articles.append({
			"objet": template["id"],
			"nom": template["nom"],
			"type": template["type"],
			"rarete": template["rarete"],
			"niveau": int(template.get("niveau", 1)),
			"description": template.get("description", ""),
			"bonus": template.get("bonus", {}).duplicate(true),
			"conditions": template.get("conditions", {}).duplicate(),
			"prix": Item.buy_price(template),
		})
	articles.sort_custom(_article_order)
	return articles


## Tri de la boutique : équipements puis ressources, par rareté, niveau et nom.
static func _article_order(a: Dictionary, b: Dictionary) -> bool:
	var resource_a: bool = a["type"] == Item.TYPE_RESOURCE
	var resource_b: bool = b["type"] == Item.TYPE_RESOURCE
	if resource_a != resource_b:
		return resource_b
	var rarity_a := Item.RARITIES.find(a["rarete"])
	var rarity_b := Item.RARITIES.find(b["rarete"])
	if rarity_a != rarity_b:
		return rarity_a < rarity_b
	if a["niveau"] != b["niveau"]:
		return int(a["niveau"]) < int(b["niveau"])
	return str(a["nom"]) < str(b["nom"])


## Raison de refuser un achat, une vente ou une fabrication auprès du PNJ `pnj` de la commande
## ("" si tout va bien) : il doit être sur la carte et offrir ce service (`marchand`, ou `atelier`
## du métier `job_id`), et le joueur doit se tenir à côté de lui.
func _service_refusal(p: PlayerState, command: Dictionary, job_id := "") -> String:
	var npc_id: Variant = command.get("pnj")
	if typeof(npc_id) != TYPE_STRING:
		return Protocol.REASON_INVALID_COMMAND
	if data == null:
		return Protocol.REASON_WRONG_PHASE
	var npc := p.map.get_npc(npc_id)
	var offered: bool = npc.get("atelier", "") == job_id if not job_id.is_empty() else npc.get("marchand", false)
	if npc.is_empty() or not offered:
		return Protocol.REASON_UNKNOWN_ENTITY
	if not GameMap.is_adjacent(p.cell, npc["case"]):
		return Protocol.REASON_TOO_FAR
	return ""


func _trade_quantity(command: Dictionary) -> int:
	var quantity: Variant = command.get("quantite", 1)
	if typeof(quantity) != TYPE_INT or quantity < 1 or quantity > MAX_TRADE_QUANTITY:
		return 0
	return quantity


func _buy(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var item_id: Variant = command.get("objet")
	var quantity := _trade_quantity(command)
	if not _is_player_command(p, command) or typeof(item_id) != TYPE_STRING or quantity == 0:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := _service_refusal(p, command)
	if not reason.is_empty():
		return _refused(command, reason)
	if not data.items.has(item_id) or not Item.is_sold(data.items[item_id]):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	var template: Dictionary = data.items[item_id]
	var inventory := p.character.inventory
	var price := Item.buy_price(template) * quantity
	if price > inventory.ecus:
		return _refused(command, Protocol.REASON_NOT_ENOUGH_ECUS)
	# Chaque équipement prend une place ; une ressource s'ajoute à sa pile si on en a déjà.
	var equipment := Item.is_equipment(template)
	if not inventory.has_room_for(template, quantity):
		return _refused(command, Protocol.REASON_INVENTORY_FULL)
	inventory.ecus -= price
	if equipment:
		for _unit in quantity:
			inventory.add(template, 1, Item.roll_bonuses(template, rng))
	else:
		inventory.add(template, quantity)
	return _trade_events(p, "achat", template, quantity, price)


func _sell(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var uid: Variant = command.get("objet")
	var quantity := _trade_quantity(command)
	if not _is_player_command(p, command) or typeof(uid) != TYPE_STRING or quantity == 0:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := _service_refusal(p, command)
	if not reason.is_empty():
		return _refused(command, reason)
	var inventory := p.character.inventory
	if not inventory.entries.has(uid) or not data.items.has(inventory.entries[uid]["objet"]):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	if not inventory.slot_of(uid).is_empty():
		return _refused(command, Protocol.REASON_ITEM_WORN)
	if _is_quest_item(p, uid):
		return _refused(command, Protocol.REASON_QUEST_ITEM)
	if quantity > int(inventory.entries[uid]["quantite"]):
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var template: Dictionary = data.items[inventory.entries[uid]["objet"]]
	var price := Item.sell_price(template) * quantity
	inventory.remove(uid, quantity)
	inventory.ecus += price
	return _trade_events(p, "vente", template, quantity, price)


func _trade_events(p: PlayerState, operation: String, template: Dictionary, quantity: int, price: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_TRADE,
		"operation": operation,
		"objet": template["id"],
		"nom": template["nom"],
		"quantite": quantity,
		"prix": price,
		"ecus": p.character.inventory.ecus,
	}]
	events.append_array(_inventory_events(p))
	return events


# --- Métiers : récolte et artisanat ------------------------------------------------------------

## Fait avancer le temps : les PV se régénèrent hors combat, les ressources récoltées repoussent
## et les groupes de monstres vaincus réapparaissent. Renvoie un événement par ressource
## (EVT_RESOURCE_RESPAWNED) ou groupe (EVT_GROUP_RESPAWNED) revenu sur une carte où il y a des
## joueurs, et par PV régénéré (EVT_REGEN, pour le joueur concerné).
func update(delta: float) -> Array[Dictionary]:
	clock += delta
	var events: Array[Dictionary] = []
	for p: PlayerState in players.values():
		_regenerate(p, delta, events)
	_respawn_groups(events)
	_update_elites(events)
	_wander_groups(events)
	_advance_combats(delta, events)
	for map_id: String in instances:
		var instance: MapInstance = instances[map_id]
		for cell: Vector2i in instance.depleted.keys():
			if instance.depleted[cell] <= clock:
				instance.depleted.erase(cell)
				if instance.has_players():
					events.append({"type": Protocol.EVT_RESOURCE_RESPAWNED, "carte": map_id, "case": cell})
	for event in events:
		Protocol.check_round_trip(event)
	return events


## Les groupes des cartes où il y a des joueurs se promènent de temps en temps, sans trop
## s'éloigner de leur case d'origine ; pas pendant le combat d'un joueur de la carte.
func _wander_groups(events: Array[Dictionary]) -> void:
	for map_id: String in instances:
		var instance: MapInstance = instances[map_id]
		if not instance.has_players() or _anyone_fighting(instance):
			continue
		for group_id: String in instance.groups:
			if not instance.wander_times.has(group_id):
				instance.wander_times[group_id] = clock + rng.randf_range(GROUP_WANDER_DELAY[0], GROUP_WANDER_DELAY[1])
				continue
			if instance.wander_times[group_id] > clock:
				continue
			instance.wander_times[group_id] = clock + rng.randf_range(GROUP_WANDER_DELAY[0], GROUP_WANDER_DELAY[1])
			var path := _wander_path(instance, instance.groups[group_id])
			if path.is_empty():
				continue
			instance.groups[group_id]["case"] = path[-1]
			instance.positions[group_id] = path[-1]
			events.append({"type": Protocol.EVT_GROUP_MOVED, "carte": map_id, "groupe": group_id, "chemin": path, "case": path[-1]})


## Temps limité des combats en ligne (`turn_seconds`) : placement et tours de joueur.
func _advance_combats(delta: float, events: Array[Dictionary]) -> void:
	if turn_seconds <= 0.0:
		return
	var seen := {}
	for p: PlayerState in players.values():
		if p.combat == null or seen.has(p.combat):
			continue
		seen[p.combat] = true
		var produced := p.combat.advance(delta)
		if produced.is_empty():
			continue
		_tag_combat(produced, _team_of(p.combat))
		if p.combat.state == Combat.State.FINISHED:
			_end_combat(p, produced)
		events.append_array(produced)


func _anyone_fighting(instance: MapInstance) -> bool:
	for player_id: String in instance.player_ids():
		if players[player_id].in_combat():
			return true
	return false


## Petit trajet au hasard pour un groupe (sans sa case de départ), vide s'il reste sur place :
## des pas droits, sur des cases libres (ni joueur, ni autre groupe, ni porte, ni bord de sortie,
## ni derrière un bâtiment),
## à GROUP_WANDER_RANGE cases au plus de son origine.
func _wander_path(instance: MapInstance, group: Dictionary) -> Array[Vector2i]:
	var source := instance.map
	var start: Vector2i = group["case"]
	var home: Vector2i = group.get("foyer", start)
	var taken := instance.taken_cells()
	var parents := {start: start}
	var frontier: Array[Vector2i] = [start]
	var choices: Array[Vector2i] = []
	for _step in GROUP_WANDER_STEPS:
		var next_frontier: Array[Vector2i] = []
		for cell in frontier:
			for neighbor in IsoGrid.neighbors_4(cell):
				if parents.has(neighbor) or taken.has(neighbor) or not source.is_walkable(neighbor) or source.doors.has(neighbor) \
						or source.is_behind_building(neighbor) \
						or not source.exit_directions(neighbor).is_empty() \
						or maxi(absi(neighbor.x - home.x), absi(neighbor.y - home.y)) > GROUP_WANDER_RANGE:
					continue
				parents[neighbor] = cell
				next_frontier.append(neighbor)
				choices.append(neighbor)
		frontier = next_frontier
	var path: Array[Vector2i] = []
	if choices.is_empty():
		return path
	var cell: Vector2i = choices[rng.randi_range(0, choices.size() - 1)]
	while cell != start:
		path.push_front(cell)
		cell = parents[cell]
	return path


## Rang d'ancienneté de l'élite d'un groupe (0 sans élite) : un par ELITE_RANK_SECONDS en vie.
func elite_rank(group: Dictionary) -> int:
	if not group.has("elite"):
		return 0
	return rank_for_age(clock - float(group["apparition"]))


## Rang d'une élite en vie depuis `age` secondes (règle partagée avec `ClientState`).
static func rank_for_age(age: float) -> int:
	return clampi(floori(age / ELITE_RANK_SECONDS), 0, ELITE_MAX_RANK)


## Où est l'élite de cette espèce : { carte, groupe }, ou {} si elle n'est pas en vie.
func elite_location(elite_id: String) -> Dictionary:
	return _elites.get(elite_id, {})


## Ids des monstres élites du jeu.
func elite_ids() -> Array[String]:
	var ids: Array[String] = []
	if data != null:
		for monster_id: String in data.monsters:
			if data.monsters[monster_id].get("elite", false):
				ids.append(monster_id)
	return ids


## Chaque élite absente tente d'apparaître toutes les 5 à 6 minutes de jeu.
func _update_elites(events: Array[Dictionary]) -> void:
	for elite_id in elite_ids():
		if _elites.has(elite_id):
			continue
		if not _elite_attempts.has(elite_id):
			_elite_attempts[elite_id] = clock + rng.randf_range(ELITE_SPAWN_DELAY[0], ELITE_SPAWN_DELAY[1])
		elif _elite_attempts[elite_id] <= clock:
			_elite_attempts[elite_id] = clock + rng.randf_range(ELITE_SPAWN_DELAY[0], ELITE_SPAWN_DELAY[1])
			if spawn_elite(elite_id, events):
				_elite_attempts.erase(elite_id)


## Fait apparaître l'élite sur une carte (au hasard) où vit sa famille : dans un nouveau groupe s'il
## y a moins de ELITE_MAX_GROUPS groupes, sinon à la place d'un monstre d'un groupe (de sa famille
## de préférence). Faux si c'est impossible pour l'instant (aucune carte, aucune place).
func spawn_elite(elite_id: String, events: Array[Dictionary] = []) -> bool:
	if data == null or not data.monsters.has(elite_id) or _elites.has(elite_id):
		return false
	var family: String = data.monsters[elite_id].get("famille", "")
	var candidates: Array[String] = []
	var ids := map_ids.duplicate()
	if ids.is_empty():
		for p: PlayerState in players.values():
			if p.map.id not in ids:
				ids.append(p.map.id)  # Liste des cartes inconnue : au moins celles des joueurs.
	for map_id in ids:
		var candidate := _load_map(map_id)
		if candidate == null:
			continue
		for group in candidate.groups:
			if family in GameMap.possible_monsters(group):
				candidates.append(map_id)
				break
	if candidates.is_empty():
		return false
	var target_id: String = candidates[rng.randi_range(0, candidates.size() - 1)]
	var target := _load_map(target_id)
	var instance := _instance(target_id)
	var here := instance.has_players()
	var states := instance.groups
	var group := {}
	if states.size() < ELITE_MAX_GROUPS:
		var cell := _free_cell(instance)
		if cell == GameMap.NO_CELL:
			return false
		var monsters: Array = [elite_id]
		if rng.randf() < 0.5:
			monsters.append(family)  # Parfois avec un monstre de sa famille.
		group = {"id": ELITE_GROUP_PREFIX + elite_id, "case": cell, "foyer": cell, "monstres": monsters,
			"niveaux": data.roll_group_levels(monsters, rng), "reapparition": GameMap.DEFAULT_RESPAWN.duplicate()}
		states[group["id"]] = group
		instance.positions[group["id"]] = cell
	else:
		var choices: Array = []
		var family_choices: Array = []
		for candidate: Dictionary in states.values():
			if candidate.has("elite") or instance.fighting.has(candidate["id"]):
				continue
			choices.append(candidate)
			if family in candidate["monstres"]:
				family_choices.append(candidate)
		if not family_choices.is_empty():
			choices = family_choices
		if choices.is_empty():
			return false
		group = choices[rng.randi_range(0, choices.size() - 1)]
		var slot: int = group["monstres"].find(family)
		group["monstres"][maxi(0, slot)] = elite_id
		# Les autres gardent leur niveau ; l'élite prend son niveau fixe.
		group["niveaux"] = _checked_levels(group["monstres"], group.get("niveaux"))
	group["elite"] = elite_id
	group["apparition"] = clock
	_elites[elite_id] = {"carte": target_id, "groupe": group["id"]}
	if here:
		events.append({"type": Protocol.EVT_GROUP_RESPAWNED, "carte": target_id, "groupe": group.duplicate(true)})
	return true


## Groupes d'une carte qui peuvent y paraître : tous, sauf les `apres_boss` d'un boss pas encore vaincu.
func available_groups(source: GameMap) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for group in source.groups:
		if not group.has("apres_boss") or defeated_bosses.has(group["apres_boss"]):
			available.append(group)
	return available


## Un boss vaincu pour la première fois débloque ses groupes `apres_boss` : ils paraissent tout de
## suite sur les cartes déjà visitées (les autres les auront à la première visite).
func _boss_defeated(boss_id: String) -> void:
	if defeated_bosses.has(boss_id):
		return
	defeated_bosses[boss_id] = true
	for map_id: String in instances:
		var instance: MapInstance = instances[map_id]
		for group in instance.map.groups:
			if group.get("apres_boss", "") == boss_id and not instance.groups.has(group["id"]):
				instance.respawns[group["id"]] = clock


## L'élite a été vaincue : elle pourra réapparaître (5 à 6 minutes plus tard, au plus tôt).
func _elite_defeated(elite_id: String) -> void:
	_elites.erase(elite_id)
	_elite_attempts[elite_id] = clock + rng.randf_range(ELITE_SPAWN_DELAY[0], ELITE_SPAWN_DELAY[1])


## Groupes présents sur une carte (créés comme à une première visite si on n'y est jamais allé).
func _groups_of(map_id: String) -> Dictionary:
	var instance := _instance(map_id)
	return instance.groups if instance != null else {}


## Case libre au hasard pour un nouveau groupe : praticable, ni occupée, ni porte, ni bord de
## sortie, ni derrière un bâtiment. GameMap.NO_CELL s'il n'y en a pas.
func _free_cell(instance: MapInstance) -> Vector2i:
	var target := instance.map
	var taken := instance.taken_cells()
	var cells: Array[Vector2i] = []
	for cell: Vector2i in target.cells():
		if target.is_walkable(cell) and not taken.has(cell) and not target.doors.has(cell) and cell != target.spawn \
				and target.exit_directions(cell).is_empty() and not target.is_behind_building(cell):
			cells.append(cell)
	if cells.is_empty():
		return GameMap.NO_CELL
	return cells[rng.randi_range(0, cells.size() - 1)]


## Un PV toutes les REGEN_SECONDS secondes hors combat, SIT_REGEN_FACTOR fois plus vite assis.
func _regenerate(p: PlayerState, delta: float, events: Array[Dictionary]) -> void:
	if p.in_combat() or p.character.hp_lost <= 0:
		p.regen_time = 0.0
		return
	p.regen_time += delta * (SIT_REGEN_FACTOR if p.sitting else 1.0)
	var healed := floori(p.regen_time / REGEN_SECONDS)
	if healed > 0:
		p.regen_time -= healed * REGEN_SECONDS
		p.character.hp_lost = maxi(0, p.character.hp_lost - healed)
		events.append({"type": Protocol.EVT_REGEN, "entite": p.id, "pv": p.character.hp(data)})


func _sit(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var wanted: Variant = command.get("assis", true)
	if not _is_player_command(p, command) or typeof(wanted) != TYPE_BOOL:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if wanted == p.sitting:
		return _refused(command, Protocol.REASON_ALREADY_THERE)
	p.sitting = wanted
	var events: Array[Dictionary] = [_sat_event(p)]
	return events


## Un joueur assis se relève avant de marcher, de changer de carte ou d'entrer en combat.
func _stand_up_if_leaving(p: PlayerState, events: Array[Dictionary]) -> void:
	if not p.sitting:
		return
	for event in events:
		if event["type"] in [Protocol.EVT_MOVED, Protocol.EVT_MAP_CHANGED, Protocol.EVT_COMBAT_STARTED]:
			p.sitting = false
			events.push_front(_sat_event(p))
			return


func _sat_event(p: PlayerState) -> Dictionary:
	return {"type": Protocol.EVT_SAT, "carte": p.map.id, "entite": p.id, "assis": p.sitting}


func _schedule_respawn(map_id: String, group: Dictionary) -> void:
	var delay: Array = group.get("reapparition", GameMap.DEFAULT_RESPAWN)
	_instance(map_id).respawns[group["id"]] = clock + rng.randf_range(float(delay[0]), float(delay[1]))


## Remet en place les groupes dont l'heure est venue (sur toutes les cartes visitées).
func _respawn_groups(events: Array[Dictionary]) -> void:
	for map_id: String in instances:
		var instance: MapInstance = instances[map_id]
		var waiting := instance.respawns
		for group_id: String in waiting.keys():
			if waiting[group_id] > clock:
				continue
			var original: Dictionary = {}
			for group in instance.map.groups:
				if group["id"] == group_id:
					original = group
			var here := instance.has_players()
			if here and not original.is_empty() and original["case"] in instance.positions.values():
				waiting[group_id] = clock + RESPAWN_RETRY  # Un joueur (ou un groupe) est dessus : un peu plus tard.
				continue
			waiting.erase(group_id)
			if original.is_empty():
				continue
			var composed := GameMap.compose_group(original, rng, data)
			instance.groups[group_id] = composed
			instance.positions[group_id] = original["case"]
			instance.wander_times.erase(group_id)
			if here:
				events.append({"type": Protocol.EVT_GROUP_RESPAWNED, "carte": map_id, "groupe": composed.duplicate(true)})


## Ressource de la carte du joueur sur cette case (voir `GameData.nodes`), ou {}.
func resource_node(cell: Vector2i) -> Dictionary:
	return _resource_node(_solo().instance, cell)


func _resource_node(instance: MapInstance, cell: Vector2i) -> Dictionary:
	if data == null or not instance.map.resource_nodes.has(cell):
		return {}
	return data.nodes.get(instance.map.resource_nodes[cell], {})


## Vrai si la ressource de cette case (carte du joueur) a été récoltée et n'a pas encore repoussé.
func is_depleted(cell: Vector2i) -> bool:
	return _solo().instance.depleted.has(cell)


## Raison de ne pas pouvoir récolter la ressource de cette case, distance mise à part ("" si on peut).
func harvest_refusal(cell: Vector2i) -> String:
	return _harvest_refusal(_solo(), cell)


func _harvest_refusal(p: PlayerState, cell: Vector2i) -> String:
	var node := _resource_node(p.instance, cell)
	return harvest_refusal_for(node, p.instance.depleted.has(cell), p.character)


## Règle de récolte, partagée avec la copie de l'état du client (`ClientState`).
static func harvest_refusal_for(node: Dictionary, depleted: bool, p_character: Character) -> String:
	if node.is_empty():
		return Protocol.REASON_UNKNOWN_ENTITY
	if depleted:
		return Protocol.REASON_DEPLETED
	if p_character.job_level(node["metier"]) < int(node.get("niveau", 1)):
		return Protocol.REASON_JOB_LEVEL
	if p_character.inventory.is_full() and not p_character.inventory.entries.has(node["objet"]):
		return Protocol.REASON_INVENTORY_FULL
	return ""


func _harvest(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var cell: Variant = command.get("case")
	if not _is_player_command(p, command) or typeof(cell) != TYPE_VECTOR2I:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := _harvest_refusal(p, cell)
	if not reason.is_empty():
		return _refused(command, reason)
	if not GameMap.is_adjacent(p.cell, cell):
		return _refused(command, Protocol.REASON_TOO_FAR)
	var node := _resource_node(p.instance, cell)
	var template: Dictionary = data.items[node["objet"]]
	var amount: Array = node.get("quantite", [1, 1])
	var quantity := rng.randi_range(int(amount[0]), int(amount[1]))
	# Parfois, une ressource rare à la place de la récolte normale : un seul exemplaire.
	var rare: bool = node.has("rare") and data.items.has(node["rare"]) and rng.randf() < rare_harvest_chance
	if rare:
		template = data.items[node["rare"]]
		quantity = 1
	p.character.inventory.add(template, quantity)
	var regrowth: Array = node["repousse"]
	p.instance.depleted[cell] = clock + rng.randf_range(float(regrowth[0]), float(regrowth[1]))
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_HARVESTED,
		"carte": p.map.id,
		"entite": p.id,
		"case": cell,
		"ressource": node["nom"],
		"objet": template["id"],
		"nom": template["nom"],
		"quantite": quantity,
		"metier": node["metier"],
		"rare": rare,
	}]
	events.append(_job_event(p, node["metier"], int(node.get("xp", 0))))
	events.append_array(_inventory_events(p))
	return events


## Recettes d'un métier d'artisanat, par niveau puis par nom.
func _workshop_recipes(job_id: String) -> Array:
	var listed: Array = []
	for recipe: Dictionary in data.jobs[job_id].get("recettes", []):
		var template: Dictionary = data.items[recipe["objet"]]
		var ingredients: Array = []
		for item_id: String in recipe["ingredients"]:
			ingredients.append({"objet": item_id, "nom": data.items[item_id]["nom"], "quantite": int(recipe["ingredients"][item_id])})
		listed.append({
			"objet": template["id"],
			"nom": template["nom"],
			"type": template["type"],
			"rarete": template["rarete"],
			"niveau": int(recipe.get("niveau", 1)),
			"niveau_objet": int(template.get("niveau", 1)),
			"description": template.get("description", ""),
			"bonus": template.get("bonus", {}).duplicate(true),
			"conditions": template.get("conditions", {}).duplicate(),
			"ingredients": ingredients,
			"xp": int(recipe.get("xp", 0)),
		})
	listed.sort_custom(_recipe_order)
	return listed


static func _recipe_order(a: Dictionary, b: Dictionary) -> bool:
	if a["niveau"] != b["niveau"]:
		return int(a["niveau"]) < int(b["niveau"])
	return str(a["nom"]) < str(b["nom"])


func _craft(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var recipe_id: Variant = command.get("recette")
	var quantity := _trade_quantity(command)
	if not _is_player_command(p, command) or typeof(recipe_id) != TYPE_STRING or quantity == 0:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if data == null or not data.recipes.has(recipe_id):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	var recipe: Dictionary = data.recipes[recipe_id]
	var job_id: String = recipe["metier"]
	var reason := _service_refusal(p, command, job_id)
	if not reason.is_empty():
		return _refused(command, reason)
	if p.character.job_level(job_id) < int(recipe.get("niveau", 1)):
		return _refused(command, Protocol.REASON_JOB_LEVEL)
	var inventory := p.character.inventory
	var ingredients: Dictionary = recipe["ingredients"]
	var freed := 0
	for item_id: String in ingredients:
		var needed := int(ingredients[item_id]) * quantity
		var owned := inventory.quantity_of(item_id)
		if owned < needed:
			return _refused(command, Protocol.REASON_MISSING_INGREDIENTS)
		if owned == needed:
			freed += 1
	var template: Dictionary = data.items[recipe_id]
	var equipment := Item.is_equipment(template)
	var places := quantity if equipment else (0 if inventory.entries.has(recipe_id) else 1)
	if inventory.entries.size() - freed + places > inventory.capacity:
		return _refused(command, Protocol.REASON_INVENTORY_FULL)
	# Les ingrédients sont des ressources : leur uid est leur id.
	for item_id: String in ingredients:
		inventory.remove(item_id, int(ingredients[item_id]) * quantity)
	if equipment:
		for _unit in quantity:
			inventory.add(template, 1, Item.roll_bonuses(template, rng))
	else:
		inventory.add(template, quantity)
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_CRAFTED,
		"objet": recipe_id,
		"nom": template["nom"],
		"quantite": quantity,
		"metier": job_id,
	}]
	events.append(_job_event(p, job_id, int(recipe.get("xp", 0)) * quantity))
	events.append_array(_inventory_events(p))
	return events


# --- Maison : coffre et lit ----------------------------------------------------------------------

## Raison de refuser d'utiliser le meuble de la case `case` ("" si on peut) : ce doit être un meuble
## du type voulu (tous si `kind` est vide) et le joueur doit se tenir à côté.
func _furniture_refusal(p: PlayerState, command: Dictionary, kind := "") -> String:
	var cell: Variant = command.get("case")
	if not _is_player_command(p, command) or typeof(cell) != TYPE_VECTOR2I:
		return Protocol.REASON_INVALID_COMMAND
	var found: String = p.map.obstacles.get(cell, "")
	if found not in GameMap.FURNITURE or (not kind.is_empty() and found != kind):
		return Protocol.REASON_UNKNOWN_ENTITY
	if not GameMap.is_adjacent(p.cell, cell):
		return Protocol.REASON_TOO_FAR
	return ""


func _use(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var reason := _furniture_refusal(p, command)
	if not reason.is_empty():
		return _refused(command, reason)
	var cell: Vector2i = command["case"]
	if p.map.obstacles[cell] == GameMap.TRAVEL_STONE:
		var touched: Array[Dictionary] = []
		_activate_passage(p, touched)
		touched.append(_travel_menu(p, cell))
		return touched
	if p.map.obstacles[cell] == "coffre":
		var opened: Array[Dictionary] = [_chest_event(p, cell)]
		return opened
	# Le lit : une bonne nuit, et tous les PV reviennent.
	var gain := p.character.hp_lost
	p.character.hp_lost = 0
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_RESTED,
		"gain": gain,
		"pv": p.character.hp(data),
		"pv_max": p.character.max_hp(data),
	}]
	events.append(_character_event(p))
	return events


## Déplace un objet entre l'inventaire et le coffre (dans un sens ou dans l'autre).
func _transfer(p: PlayerState, command: Dictionary, source: Inventory, destination: Inventory) -> Array[Dictionary]:
	var uid: Variant = command.get("objet")
	var quantity := _trade_quantity(command)
	if typeof(uid) != TYPE_STRING or quantity == 0:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := _furniture_refusal(p, command, "coffre")
	if not reason.is_empty():
		return _refused(command, reason)
	if data == null or not source.entries.has(uid) or not data.items.has(source.entries[uid]["objet"]):
		return _refused(command, Protocol.REASON_UNKNOWN_ITEM)
	if not source.slot_of(uid).is_empty():
		return _refused(command, Protocol.REASON_ITEM_WORN)
	var entry: Dictionary = source.entries[uid]
	if quantity > int(entry["quantite"]):
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var template: Dictionary = data.items[entry["objet"]]
	if not destination.has_room_for(template, 1 if Item.is_equipment(template) else quantity):
		return _refused(command, Protocol.REASON_INVENTORY_FULL)
	var rolled: Dictionary = entry["jets"].duplicate()
	source.remove(uid, quantity)
	destination.add(template, quantity, rolled)
	var events: Array[Dictionary] = [_chest_event(p, command["case"])]
	events.append_array(_inventory_events(p))
	return events


# --- Pierres de Passage --------------------------------------------------------------------------

## Pierre de Passage de la carte actuelle (id), ou "".
func _here_passage(p: PlayerState) -> String:
	if data == null:
		return ""
	for passage_id: String in data.passages:
		if data.passages[passage_id]["carte"] == p.map.id:
			return passage_id
	return ""


## Vrai si le joueur peut voyager jusqu'à cette pierre : il l'a découverte, elle est
## `toujours_connue`, ou toutes le sont (`all_passages_known`, phase de test).
func is_passage_known(passage_id: String) -> bool:
	return _passage_known(_solo(), passage_id)


func _passage_known(p: PlayerState, passage_id: String) -> bool:
	return passage_known_for(passage_id, p.character, data, all_passages_known)


## Règle de connaissance des pierres, partagée avec la copie de l'état du client (`ClientState`).
static func passage_known_for(passage_id: String, p_character: Character, p_data: GameData, all_known: bool) -> bool:
	if all_known and p_data != null and p_data.passages.has(passage_id):
		return true
	return passage_id in p_character.known_passages or (p_data != null and p_data.passage_always_known(passage_id))


## Cartes où le joueur est déjà allé (ids, dans l'ordre des visites), pour l'interface.
func visited_maps() -> Array[String]:
	return character.visited_maps.duplicate()


## La pierre de la zone de départ de la race est toujours connue ; elle sert de point de résurrection
## tant qu'il n'y en a pas d'autre (nouveau personnage, vieille sauvegarde, pierre disparue).
func _init_travel(p: PlayerState) -> void:
	if data == null:
		return
	var start := data.start_passage(p.character.race_id)
	if start.is_empty():
		return
	p.character.discover_passage(start)
	if not data.passages.has(p.character.respawn_passage):
		p.character.respawn_passage = start


## Utiliser la pierre de la carte la découvre (si besoin) et en fait le point de résurrection.
func _activate_passage(p: PlayerState, events: Array[Dictionary]) -> void:
	var passage_id := _here_passage(p)
	if passage_id.is_empty():
		return
	var passage_name: String = data.passages[passage_id]["nom"]
	if not _passage_known(p, passage_id):
		p.character.discover_passage(passage_id)
		events.append({"type": Protocol.EVT_PASSAGE_DISCOVERED, "passage": passage_id, "nom": passage_name})
	if p.character.respawn_passage != passage_id:
		p.character.respawn_passage = passage_id
		events.append({"type": Protocol.EVT_RESPAWN_POINT, "passage": passage_id, "nom": passage_name})


func _travel_menu(p: PlayerState, cell: Vector2i) -> Dictionary:
	var destinations: Array = []
	for passage_id: String in data.passages:
		var passage: Dictionary = data.passages[passage_id]
		destinations.append({"id": passage_id, "nom": passage["nom"], "carte": passage["carte"],
			"prix": data.passage_price(passage_id), "connue": _passage_known(p, passage_id)})
	return {"type": Protocol.EVT_TRAVEL_MENU, "case": cell, "ici": _here_passage(p), "destinations": destinations,
		"ecus": p.character.inventory.ecus, "resurrection": p.character.respawn_passage}


## Voyage d'une Pierre de Passage à une autre, déjà découverte (ou `toujours_connue`), contre son prix
## en brumes : on arrive à côté de la pierre de destination. Arriver ainsi ne la découvre pas et n'en
## fait pas le point de résurrection : il faut l'utiliser.
func _travel(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var destination: Variant = command.get("destination")
	if typeof(destination) != TYPE_STRING:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := _furniture_refusal(p, command, GameMap.TRAVEL_STONE)
	if not reason.is_empty():
		return _refused(command, reason)
	if data == null or not data.passages.has(destination):
		return _refused(command, Protocol.REASON_UNKNOWN_ENTITY)
	if destination == _here_passage(p):
		return _refused(command, Protocol.REASON_ALREADY_THERE)
	if not _passage_known(p, destination):
		return _refused(command, Protocol.REASON_PASSAGE_UNKNOWN)
	var next_map := _load_map(data.passages[destination]["carte"])
	if next_map == null or next_map.travel_stone() == Vector2i(-1, -1):
		return _refused(command, Protocol.REASON_UNKNOWN_MAP)
	var price := data.passage_price(destination)
	if price > p.character.inventory.ecus:
		return _refused(command, Protocol.REASON_NOT_ENOUGH_ECUS)
	p.character.inventory.ecus -= price
	var others: Array[Dictionary] = []
	_set_map(p, next_map, next_map.beside(next_map.travel_stone()), others)
	var events: Array[Dictionary] = []
	_append_map_change(events, others, {
		"type": Protocol.EVT_MAP_CHANGED,
		"carte": p.map.id,
		"nom": p.map.display_name,
		"position": p.cell,
		"prix": price,
	})
	if price > 0:
		events.append_array(_inventory_events(p))
	return events


func _chest_event(p: PlayerState, cell: Vector2i) -> Dictionary:
	return {"type": Protocol.EVT_CHEST, "case": cell, "coffre": p.character.chest_sheet(data)}


## Ajoute de l'XP de métier (avec le bonus de race) et décrit le résultat.
func _job_event(p: PlayerState, job_id: String, base_gain: int) -> Dictionary:
	var gain := floori(base_gain * (100 + p.character.job_xp_bonus(data)) / 100.0)
	var reached := p.character.add_job_xp(job_id, gain)
	var level := p.character.job_level(job_id)
	return {
		"type": Protocol.EVT_JOB,
		"metier": job_id,
		"nom": data.jobs[job_id]["nom"],
		"gain": gain,
		"niveau": level,
		"xp": p.character.job_xp(job_id),
		"xp_niveau": Profession.xp_for_level(level),
		"xp_suivant": Profession.xp_for_level(level + 1) if level < Profession.MAX_LEVEL else p.character.job_xp(job_id),
		"niveaux": reached,
	}


func _is_quest_item(p: PlayerState, uid: String) -> bool:
	var entry: Dictionary = p.character.inventory.entries.get(uid, {})
	return not entry.is_empty() and data != null and data.items.get(entry["objet"], {}).get("type") == Item.TYPE_QUEST


func _is_player_command(p: PlayerState, command: Dictionary) -> bool:
	var entity_id: Variant = command.get("entite")
	return typeof(entity_id) == TYPE_STRING and entity_id == p.id


func _inventory_events(p: PlayerState) -> Array[Dictionary]:
	var events: Array[Dictionary] = [_inventory_event(p), _character_event(p)]
	return events


func _inventory_event(p: PlayerState) -> Dictionary:
	return {"type": Protocol.EVT_INVENTORY, "inventaire": p.character.inventory_sheet(data)}


func _spend_points(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	var entity_id: Variant = command.get("entite")
	var stat_name: Variant = command.get("carac")
	var points: Variant = command.get("points", 1)
	if typeof(entity_id) != TYPE_STRING or entity_id != p.id or typeof(stat_name) != TYPE_STRING or typeof(points) != TYPE_INT:
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	var reason := p.character.spend_points(stat_name, points)
	if not reason.is_empty():
		return _refused(command, reason)
	var events: Array[Dictionary] = [_character_event(p)]
	return events


func _reset_points(p: PlayerState, command: Dictionary) -> Array[Dictionary]:
	if not _is_player_command(p, command):
		return _refused(command, Protocol.REASON_INVALID_COMMAND)
	if p.character.reset_points() == 0:
		return _refused(command, Protocol.REASON_NOTHING_TO_RESET)
	var events: Array[Dictionary] = [_character_event(p)]
	return events


func _character_event(p: PlayerState) -> Dictionary:
	return {"type": Protocol.EVT_CHARACTER, "personnage": p.character.sheet(data)}


# --- Sauvegarde ---------------------------------------------------------------------------------

const SAVE_VERSION := 1


## État à sauvegarder (solo) : personnage, carte et position, groupes restants des cartes visitées.
func save_data() -> Dictionary:
	var p := _solo()
	var remaining := {}
	var respawns := {}
	var depleted := {}
	for map_id: String in instances:
		var instance: MapInstance = instances[map_id]
		respawns[map_id] = instance.respawns
		depleted[map_id] = instance.depleted
		var groups: Array = []
		for group: Dictionary in instance.groups.values():
			var cell: Vector2i = group["case"]
			var saved_group := {"id": group["id"], "case": [cell.x, cell.y], "monstres": group["monstres"].duplicate(),
				"niveaux": group.get("niveaux", []).duplicate()}
			if group.has("elite"):
				var home: Vector2i = group.get("foyer", cell)
				saved_group["elite"] = group["elite"]
				saved_group["age"] = clock - float(group["apparition"])
				saved_group["foyer"] = [home.x, home.y]
			groups.append(saved_group)
		remaining[map_id] = groups
	var attempts := {}
	for elite_id: String in _elite_attempts:
		attempts[elite_id] = maxf(0.0, float(_elite_attempts[elite_id]) - clock)
	var position := p.cell
	return {
		"version": SAVE_VERSION,
		"personnage": p.character.to_dict(),
		"carte": p.map.id,
		"position": [position.x, position.y],
		"groupes_restants": remaining,
		"reapparitions": _saved_timers(respawns),
		"repousses": _saved_timers(depleted),
		"elites": attempts,
		"boss_vaincus": defeated_bosses.keys(),
	}


## Butin regroupé par objet (une ligne par objet, quantités additionnées), dans l'ordre d'obtention.
static func _merged_loot(found: Array) -> Array:
	var merged: Array = []
	var index_of := {}
	for drop: Dictionary in found:
		var key: String = drop["objet"]
		if index_of.has(key):
			merged[index_of[key]]["quantite"] += int(drop["quantite"])
		else:
			index_of[key] = merged.size()
			merged.append(drop.duplicate())
	return merged


## Groupe d'une carte tel qu'il a été sauvegardé (monstres, niveaux et case), si la sauvegarde est
## cohérente ; sinon tel qu'il apparaît d'habitude.
func _restored_group(saved_map: GameMap, group: Dictionary, saved: Dictionary) -> Dictionary:
	var restored := GameMap.compose_group(group, rng, data)
	var monsters: Variant = saved.get("monstres")
	if typeof(monsters) == TYPE_ARRAY and not monsters.is_empty() and monsters.size() <= GameMap.MAX_GROUP_SIZE:
		var known := true
		for monster_id: Variant in monsters:
			known = known and typeof(monster_id) == TYPE_STRING and (data == null or data.monsters.has(monster_id))
		if known:
			restored["monstres"] = monsters.duplicate()
			restored["niveaux"] = _checked_levels(restored["monstres"], saved.get("niveaux"))
	var cell: Variant = saved.get("case")
	if typeof(cell) == TYPE_ARRAY and cell.size() == 2:
		var saved_cell := Vector2i(int(cell[0]), int(cell[1]))
		if saved_map.is_walkable(saved_cell):
			restored["case"] = saved_cell
	_restore_elite_fields(restored, saved)
	return restored


## Groupe d'élite apparu en plus des groupes de la carte, tel qu'il a été sauvegardé ({} si la
## sauvegarde est incohérente).
func _restored_elite_group(saved_map: GameMap, group_id: String, saved: Dictionary) -> Dictionary:
	var cell: Variant = saved.get("case")
	var monsters: Variant = saved.get("monstres")
	if not group_id.begins_with(ELITE_GROUP_PREFIX) or typeof(cell) != TYPE_ARRAY or cell.size() != 2 \
			or typeof(monsters) != TYPE_ARRAY or monsters.is_empty() or monsters.size() > GameMap.MAX_GROUP_SIZE:
		return {}
	for monster_id: Variant in monsters:
		if typeof(monster_id) != TYPE_STRING or (data != null and not data.monsters.has(monster_id)):
			return {}
	var saved_cell := Vector2i(int(cell[0]), int(cell[1]))
	if not saved_map.is_walkable(saved_cell):
		return {}
	var group := {"id": group_id, "case": saved_cell, "foyer": saved_cell, "monstres": monsters.duplicate(),
		"niveaux": _checked_levels(monsters, saved.get("niveaux")), "reapparition": GameMap.DEFAULT_RESPAWN.duplicate()}
	var home: Variant = saved.get("foyer")
	if typeof(home) == TYPE_ARRAY and home.size() == 2 and saved_map.is_walkable(Vector2i(int(home[0]), int(home[1]))):
		group["foyer"] = Vector2i(int(home[0]), int(home[1]))
	_restore_elite_fields(group, saved)
	return group if group.has("elite") else {}


## Niveaux d'un groupe, un par monstre : ceux de `saved` quand chaque monstre peut encore les avoir
## (dans sa tranche, de poids non nul : voir `GameData.is_monster_level`), sinon tirés à nouveau
## (vieille sauvegarde sans niveaux, données changées depuis).
func _checked_levels(monsters: Array, saved: Variant) -> Array:
	var levels: Array = []
	for i in monsters.size():
		var level: Variant = saved[i] if typeof(saved) == TYPE_ARRAY and i < saved.size() else null
		if data == null:
			levels.append(int(level) if Spell._is_int_at_least(level, 1) else 1)
		elif data.is_monster_level(monsters[i], level):
			levels.append(int(level))
		else:
			levels.append(data.roll_monster_level(monsters[i], rng))
	return levels


## Reprend l'élite d'un groupe sauvegardé (et son ancienneté) si elle est cohérente.
func _restore_elite_fields(group: Dictionary, saved: Dictionary) -> void:
	var elite_id: Variant = saved.get("elite")
	if typeof(elite_id) != TYPE_STRING or elite_id not in group["monstres"]:
		return
	group["elite"] = elite_id
	group["apparition"] = clock - maxf(0.0, float(saved.get("age", 0.0)))


## Minuteries (réapparitions, repousses) en secondes restantes : id de carte → [[clé, secondes]…],
## la clé étant un id de groupe ou une case [x, y].
func _saved_timers(timers: Dictionary) -> Dictionary:
	var saved := {}
	for map_id: String in timers:
		var entries: Array = []
		for key: Variant in timers[map_id]:
			var left := maxf(0.0, float(timers[map_id][key]) - clock)
			entries.append([[key.x, key.y] if typeof(key) == TYPE_VECTOR2I else key, left])
		saved[map_id] = entries
	return saved


## Relit des minuteries sauvegardées (voir `_saved_timers`) ; `cells` : clés en cases.
func _load_timers(saved: Variant, cells: bool) -> Dictionary:
	var timers := {}
	if typeof(saved) != TYPE_DICTIONARY:
		return timers
	for map_id: Variant in saved:
		if typeof(map_id) != TYPE_STRING or typeof(saved[map_id]) != TYPE_ARRAY:
			continue
		var entries := {}
		for pair: Variant in saved[map_id]:
			if typeof(pair) != TYPE_ARRAY or pair.size() != 2 or typeof(pair[1]) not in [TYPE_INT, TYPE_FLOAT]:
				continue
			var key: Variant = pair[0]
			if cells:
				if typeof(key) != TYPE_ARRAY or key.size() != 2:
					continue
				key = Vector2i(int(key[0]), int(key[1]))
			elif typeof(key) != TYPE_STRING:
				continue
			entries[key] = clock + float(pair[1])
		timers[map_id] = entries
	return timers


## Monde reconstruit depuis une sauvegarde, ou `null` si elle est inutilisable.
static func from_save(save: Dictionary, p_data: GameData, p_map_loader: Callable) -> World:
	if int(save.get("version", 0)) != SAVE_VERSION or typeof(save.get("personnage")) != TYPE_DICTIONARY:
		return null
	var saved_character := Character.from_dict(save["personnage"], p_data.items if p_data != null else {})
	if saved_character == null or typeof(save.get("carte")) != TYPE_STRING or not p_map_loader.is_valid():
		return null
	var start_map: GameMap = p_map_loader.call(save["carte"])
	if start_map == null:
		return null
	var world := World.new(start_map, p_data, p_map_loader, saved_character)
	var bosses: Variant = save.get("boss_vaincus", [])
	if typeof(bosses) == TYPE_ARRAY:
		for boss_id: Variant in bosses:
			if typeof(boss_id) == TYPE_STRING:
				world.defeated_bosses[boss_id] = true
	var remaining: Variant = save.get("groupes_restants", {})
	if typeof(remaining) == TYPE_DICTIONARY:
		for map_id: Variant in remaining:
			if typeof(map_id) != TYPE_STRING or typeof(remaining[map_id]) != TYPE_ARRAY:
				continue
			var saved_map := world._load_map(map_id)
			if saved_map == null:
				continue
			var saved_groups := {}
			for entry: Variant in remaining[map_id]:
				if typeof(entry) == TYPE_STRING:
					saved_groups[entry] = {}  # Ancienne sauvegarde : seulement l'id du groupe.
				elif typeof(entry) == TYPE_DICTIONARY and typeof(entry.get("id")) == TYPE_STRING:
					saved_groups[entry["id"]] = entry
			var groups := {}
			for group in saved_map.groups:
				if saved_groups.has(group["id"]):
					groups[group["id"]] = world._restored_group(saved_map, group, saved_groups[group["id"]])
					saved_groups.erase(group["id"])
			# Groupes d'élites apparus en plus de ceux de la carte.
			for group_id: String in saved_groups:
				var extra := world._restored_elite_group(saved_map, group_id, saved_groups[group_id])
				if not extra.is_empty():
					groups[group_id] = extra
			for group: Dictionary in groups.values():
				if group.has("elite"):
					world._elites[group["elite"]] = {"carte": map_id, "groupe": group["id"]}
			world._instance(map_id).set_groups(groups)
	var saved_position: Variant = save.get("position")
	var position := start_map.spawn
	if typeof(saved_position) == TYPE_ARRAY and saved_position.size() == 2:
		var cell := Vector2i(int(saved_position[0]), int(saved_position[1]))
		if start_map.is_walkable(cell):
			position = cell
	var respawns := world._load_timers(save.get("reapparitions"), false)
	var depleted := world._load_timers(save.get("repousses"), true)
	for map_id: String in respawns:
		var instance := world._instance(map_id)
		if instance != null:
			instance.respawns = respawns[map_id]
	for map_id: String in depleted:
		var instance := world._instance(map_id)
		if instance != null:
			instance.depleted = depleted[map_id]
	var attempts: Variant = save.get("elites", {})
	if typeof(attempts) == TYPE_DICTIONARY:
		for elite_id: Variant in attempts:
			if typeof(elite_id) == TYPE_STRING and typeof(attempts[elite_id]) in [TYPE_INT, TYPE_FLOAT] and not world._elites.has(elite_id):
				world._elite_attempts[elite_id] = world.clock + float(attempts[elite_id])
	world._solo().cell = position
	return world


func _moved_event(p: PlayerState, from: Vector2i, path: Array[Vector2i]) -> Dictionary:
	return {"type": Protocol.EVT_MOVED, "carte": p.map.id, "entite": p.id, "depuis": from, "chemin": path}


func _refused(command: Dictionary, reason: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = [{
		"type": Protocol.EVT_REFUSED,
		"commande": str(command.get("type", "")),
		"raison": reason,
	}]
	return events
