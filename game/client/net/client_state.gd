class_name ClientState
extends RefCounted
## Copie locale de l'état du jeu côté client (GDD § 16.5) : ce que le joueur voit, rechargé d'après
## les instantanés de la connexion (`load_snapshot`, voir `World.snapshot`). Elle offre les lectures
## dont l'interface a besoin, sous les mêmes noms que `World` (personnage, carte, groupes, combat,
## quêtes…), sans jamais modifier le jeu : les commandes passent par la `GameConnection`.
## Les règles partagées (récolte, pierres connues) sont celles du noyau.

var data: GameData
## Id du personnage de ce client (celui de ses commandes et de son combattant).
var player_id := ""
var character: Character
## Carte où se trouve le joueur.
var map: GameMap
## Combat en cours, recréé d'après l'instantané (pour les portées et aperçus), ou `null`.
var combat: Combat = null
## Le joueur regarde le combat `combat` sans y être (spectateur).
var spectating := false
## Joueur qui a engagé le combat du joueur (lui seul le verrouille), ou "".
var fight_leader := ""
var sitting := false
## Toutes les cartes du jeu (carte du monde, liens des quêtes).
var map_ids: Array[String] = []
var all_passages_known := World.ALL_PASSAGES_KNOWN
## Journal et marques des PNJ : la copie tient les rôles du monde et du joueur (lectures seulement).
var quest_book: QuestBook
## Pour `QuestBook` (jamais utilisé côté client : il ne donne rien).
var rng := RandomNumberGenerator.new()
var player_name: String:
	get:
		return character.display_name
var player_voie: String:
	get:
		return character.voie_id
## Case du joueur (rôle de joueur pour `QuestBook`).
var cell: Vector2i:
	get:
		return position_of(player_id)

var _map_loader: Callable
## Temps écoulé côté client (avancé par `advance`), pour l'âge des élites.
var _clock := 0.0
## Case de chaque entité de la carte : le joueur, les autres joueurs, les groupes.
var _positions: Dictionary = {}
## Groupes de monstres de la carte : id → { id, case, monstres, niveaux, age (élite)… }, avec `vu` :
## l'instant (horloge de la copie) où on a reçu leur âge.
var _groups: Dictionary = {}
## Autres joueurs de la carte : id → { id, nom, race, voie, niveau, case, assis }.
var _players: Dictionary = {}
## Ressources épuisées de la carte : case → true.
var _depleted: Dictionary = {}
## Combats des autres joueurs de la carte (leurs épées) : id du groupe combattu → { groupe, case,
## joueurs, placement }.
var _fights: Dictionary = {}
## Groupe de joueurs : { chef, membres: [{ id, nom, niveau, race, voie, absent }] } (voir `World._party_view`).
var party: Dictionary = {"chef": "", "membres": []}
## Amis et ignorés (en ligne, jalon M3) : { amis: Array[{ nom, en_ligne, carte, combat }],
## ignores: Array[String] }.
var relations: Dictionary = {"amis": [], "ignores": []}


## `p_map_loader` : Callable(id: String) -> GameMap (ou null).
func _init(p_data: GameData, p_map_loader: Callable) -> void:
	data = p_data
	_map_loader = p_map_loader
	quest_book = QuestBook.new(self, self)


## Recharge la copie d'après un instantané du monde (voir `World.snapshot`).
func load_snapshot(snapshot: Dictionary) -> void:
	player_id = snapshot["joueur"]
	character = Character.from_dict(snapshot["personnage"], data.items if data != null else {})
	character.inventory.capacity = snapshot["places"]
	sitting = snapshot["assis"]
	all_passages_known = snapshot["pierres_toutes_connues"]
	if map == null or map.id != snapshot["carte"]:
		map = map_by_id(snapshot["carte"])
	_positions = {player_id: snapshot["position"]}
	_groups = {}
	for group_state: Dictionary in snapshot["groupes"]:
		group_state["vu"] = _clock
		_groups[group_state["id"]] = group_state
		_positions[group_state["id"]] = group_state["case"]
	_players = {}
	for other: Dictionary in snapshot["joueurs"]:
		_players[other["id"]] = other
		_positions[other["id"]] = other["case"]
	_depleted = {}
	for depleted_cell: Vector2i in snapshot["epuisees"]:
		_depleted[depleted_cell] = true
	_fights = {}
	for fight: Dictionary in snapshot.get("combats", []):
		_fights[fight["groupe"]] = fight
	party = snapshot.get("groupe_joueurs", {"chef": "", "membres": []})
	relations = snapshot.get("relations", {"amis": [], "ignores": []})
	combat = null
	spectating = snapshot.get("spectateur", false)
	fight_leader = snapshot.get("chef_combat", "")
	if snapshot["combat"] != null and data != null:
		var combat_map := map_by_id(snapshot["combat"]["carte"])
		if combat_map != null:
			combat = Combat.from_snapshot(snapshot["combat"], combat_map, data, {player_id: character})


## Applique un événement fréquent sans instantané (régénération, promenades, réapparitions,
## repousses) ; faux s'il demande de recharger la copie.
func apply_event(event: Dictionary) -> bool:
	match event["type"]:
		Protocol.EVT_REGEN:
			if event["entite"] == player_id:
				character.hp_lost = maxi(0, character.max_hp(data) - int(event["pv"]))
			return true
		Protocol.EVT_GROUP_MOVED:
			if _groups.has(event["groupe"]):
				_groups[event["groupe"]]["case"] = event["case"]
				_positions[event["groupe"]] = event["case"]
			return true
		Protocol.EVT_GROUP_RESPAWNED:
			var respawned: Dictionary = event["groupe"]
			respawned.erase("apparition")
			respawned["vu"] = _clock  # Une élite qui apparaît a 0 s.
			_groups[respawned["id"]] = respawned
			_positions[respawned["id"]] = respawned["case"]
			return true
		Protocol.EVT_RESOURCE_RESPAWNED:
			_depleted.erase(event["case"])
			return true
		# Les autres joueurs de la carte (multijoueur) : ce qu'en voit ce client.
		Protocol.EVT_PLAYER_JOINED:
			var joined: Dictionary = event["joueur"]
			if joined["id"] != player_id:
				_players[joined["id"]] = joined
				_positions[joined["id"]] = joined["case"]
			return joined["id"] != player_id
		Protocol.EVT_PLAYER_LEFT:
			_players.erase(event["entite"])
			if event["entite"] != player_id:
				_positions.erase(event["entite"])
			return event["entite"] != player_id
		Protocol.EVT_MOVED, Protocol.EVT_SAT, Protocol.EVT_HARVESTED:
			return _apply_other_player(event)
		Protocol.EVT_GROUP_ENGAGED:
			if event["entite"] != player_id:
				# Le groupe et le joueur disparaissent ; les épées du combat restent sur la carte.
				_groups.erase(event["groupe"])
				_positions.erase(event["groupe"])
				_players.erase(event["entite"])
				_positions.erase(event["entite"])
				var fight: Dictionary = _fights.get(event["groupe"], {"groupe": event["groupe"], "case": event.get("case",
					Vector2i(-1, -1)), "joueurs": [], "placement": true})
				if event["entite"] not in fight["joueurs"]:
					fight["joueurs"].append(event["entite"])
				_fights[event["groupe"]] = fight
			return true
		Protocol.EVT_FIGHT_OVER:
			_fights.erase(event["groupe"])
			return true
		Protocol.EVT_COMBAT_LOCK:
			if _fights.has(event["groupe"]):
				_fights[event["groupe"]]["ferme"] = event["ferme"]
				_fights[event["groupe"]]["spectateurs"] = event["spectateurs"]
			if combat != null and combat.map.id == event["carte"]:
				combat.locked = event["ferme"]
				combat.spectators_allowed = event["spectateurs"]
			return true
		Protocol.EVT_PARTY:
			party = {"chef": event["chef"], "membres": event["membres"]}
			return true
		Protocol.EVT_RELATIONS:
			relations = {"amis": event["amis"], "ignores": event["ignores"]}
			return true
		Protocol.EVT_PARTY_INVITE, Protocol.EVT_PARTY_DECLINED, Protocol.EVT_CHAT, Protocol.EVT_REPORTED, \
				Protocol.EVT_EXCHANGE_REQUEST, Protocol.EVT_EXCHANGE, Protocol.EVT_EXCHANGE_CLOSED:
			return true
		Protocol.EVT_GROUP_RELEASED:
			var released: Dictionary = event["groupe"]
			released["vu"] = _clock
			_groups[released["id"]] = released
			_positions[released["id"]] = released["case"]
			return true
	return false


## Déplacement, assise ou récolte d'un autre joueur de la carte ; faux pour ceux de ce joueur
## (l'instantané qui suit sa commande les contient déjà).
func _apply_other_player(event: Dictionary) -> bool:
	var other: Dictionary = _players.get(event.get("entite", ""), {})
	if other.is_empty() or not event.has("carte"):
		return false
	match event["type"]:
		Protocol.EVT_MOVED:
			var path: Array = event["chemin"]
			if not path.is_empty():
				other["case"] = path[-1]
				_positions[other["id"]] = path[-1]
			other["assis"] = false
		Protocol.EVT_SAT:
			other["assis"] = event["assis"]
		Protocol.EVT_HARVESTED:
			_depleted[event["case"]] = true
	return true


func in_combat() -> bool:
	return combat != null


func has_entity(entity_id: String) -> bool:
	return _positions.has(entity_id)


func position_of(entity_id: String) -> Vector2i:
	return _positions.get(entity_id, Vector2i(-1, -1))


## Groupes de monstres présents sur la carte.
func groups() -> Array:
	return _groups.values()


## Groupe de monstres de la carte, par son id ({} s'il n'y est pas).
func group(group_id: String) -> Dictionary:
	return _groups.get(group_id, {})


## Groupe de monstres sur la case, ou `{}`.
func group_at(at: Vector2i) -> Dictionary:
	for group_state: Dictionary in _groups.values():
		if group_state["case"] == at:
			return group_state
	return {}


## Autres joueurs présents sur la carte (multijoueur).
func other_players() -> Array:
	return _players.values()


## Combats des autres joueurs de la carte : { groupe, case, joueurs: Array[String], placement, ferme,
## spectateurs }.
func fights() -> Array:
	return _fights.values()


## Combat d'un autre joueur sur cette case (ses épées), ou {}.
func fight_at(at: Vector2i) -> Dictionary:
	for fight: Dictionary in _fights.values():
		if fight["case"] == at:
			return fight
	return {}


## Autre joueur de la carte sur cette case, ou {}.
func player_at(at: Vector2i) -> Dictionary:
	for other: Dictionary in _players.values():
		if other["case"] == at:
			return other
	return {}


## Vrai si ce pseudo est dans la liste d'amis (`amis`) ou d'ignorés (`ignores`).
func has_relation(list: String, player_name: String) -> bool:
	for entry: Variant in relations.get(list, []):
		var entry_name := str(entry["nom"]) if typeof(entry) == TYPE_DICTIONARY else str(entry)
		if entry_name.to_lower() == player_name.to_lower():
			return true
	return false


## Autre joueur de la carte, ou membre du groupe, de ce pseudo ({} si on ne le voit pas : un auteur
## de chat peut être n'importe où sur le serveur).
func player_named(player_name: String) -> Dictionary:
	for other: Dictionary in _players.values():
		if other["nom"] == player_name:
			return other
	for member: Dictionary in party.get("membres", []):
		if member["nom"] == player_name:
			return member
	return {}


## Membre du groupe (id) : { id, nom, niveau, race, voie, absent, carte, repere }, ou {}.
func party_member(other_id: String) -> Dictionary:
	for member: Dictionary in party.get("membres", []):
		if member["id"] == other_id:
			return member
	return {}


## Vrai si ce joueur (id) est du groupe du joueur.
func is_party_member(other_id: String) -> bool:
	for member: Dictionary in party.get("membres", []):
		if member["id"] == other_id:
			return true
	return false


## Fait passer le temps de la copie (âge des élites).
func advance(delta: float) -> void:
	_clock += delta


## Rang d'ancienneté de l'élite d'un groupe (0 sans élite), d'après son âge.
func elite_rank(group_state: Dictionary) -> int:
	if not group_state.has("elite"):
		return 0
	return World.rank_for_age(float(group_state.get("age", 0.0)) + _clock - float(group_state.get("vu", _clock)))


## Carte d'après son id, ou `null` si elle est introuvable.
func map_by_id(map_id: String) -> GameMap:
	return _map_loader.call(map_id) if _map_loader.is_valid() else null


## Nom d'une carte d'après son id ("" si elle est introuvable).
func map_name(map_id: String) -> String:
	var found := map_by_id(map_id)
	return found.display_name if found != null else ""


## Nom de la carte voisine dans cette direction, ou "" s'il n'y en a pas.
func neighbor_name(direction: String) -> String:
	return map_name(map.exits[direction]) if map.exits.has(direction) else ""


## Cartes où le joueur est déjà allé (ids, dans l'ordre des visites).
func visited_maps() -> Array[String]:
	return character.visited_maps.duplicate()


func is_passage_known(passage_id: String) -> bool:
	return World.passage_known_for(passage_id, character, data, all_passages_known)


## Ressource de la carte sur cette case (voir `GameData.nodes`), ou {}.
func resource_node(at: Vector2i) -> Dictionary:
	if data == null or not map.resource_nodes.has(at):
		return {}
	return data.nodes.get(map.resource_nodes[at], {})


func is_depleted(at: Vector2i) -> bool:
	return _depleted.has(at)


## Raison de ne pas pouvoir récolter la ressource de cette case, distance mise à part ("" si on peut).
func harvest_refusal(at: Vector2i) -> String:
	return World.harvest_refusal_for(resource_node(at), is_depleted(at), character)


## Pour `QuestBook` : le client ne reçoit pas d'événements d'inventaire de lui-même.
func _inventory_events(_player: Variant) -> Array[Dictionary]:
	return [] as Array[Dictionary]


func _inventory_event(_player: Variant) -> Dictionary:
	return {}
