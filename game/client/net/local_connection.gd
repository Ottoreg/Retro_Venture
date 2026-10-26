class_name LocalConnection
extends GameConnection
## Connexion locale : le `World` tourne dans le même processus (jeu hors ligne, tests, captures,
## GDD § 16.5). Commandes et événements passent quand même par le JSON du protocole, comme en ligne,
## et la copie de l'état est rechargée par instantané (`World.snapshot`) après chaque commande ; les
## événements fréquents du temps qui passe (régénération, promenades…) la mettent à jour eux-mêmes.

## Le monde, côté « serveur ». Le client ne le lit pas : seuls les tests et les outils y touchent
## (puis appellent `refresh`).
var world: World
## Id du personnage de ce client.
var player_id: String
## Faux : sans passer par le JSON (plus rapide, pour la simulation).
var wire := true
var _number := 0


func _init(p_world: World, p_player_id := "", p_wire := true) -> void:
	world = p_world
	player_id = p_player_id if not p_player_id.is_empty() else p_world.player_id
	wire = p_wire
	state = ClientState.new(world.data, world.map_by_id)
	state.map_ids = world.map_ids
	refresh()


func send(command: Dictionary) -> Array[Dictionary]:
	return _received(world.execute(_through_wire(command)), player_id)


func update(delta: float) -> Array[Dictionary]:
	state.advance(delta)
	return _received(world.update(delta), "")


func save_data() -> Dictionary:
	return world.save_data()


## Recharge la copie de l'état d'après le monde.
func refresh() -> void:
	state.map_ids = world.map_ids
	state.load_snapshot(_through_wire(world.snapshot(player_id)))


## Événements qui regardent ce joueur (voir `World.recipients` ; `sender` : qui a envoyé la commande,
## "" pour ceux de `update`), tels qu'ils arriveraient du réseau.
func _received(events: Array[Dictionary], sender: String) -> Array[Dictionary]:
	var mine: Array[Dictionary] = []
	var stale := false
	for event in events:
		if player_id in world.recipients(event, sender):
			mine.append(_through_wire(event))
			stale = stale or not state.apply_event(mine[-1])
	if stale or not sender.is_empty():
		refresh()
	return mine


func _through_wire(message: Dictionary) -> Dictionary:
	if not wire:
		return message
	_number += 1
	return Protocol.decode(Protocol.encode(message, _number))
