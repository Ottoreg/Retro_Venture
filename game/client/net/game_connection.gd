class_name GameConnection
extends RefCounted
## Connexion du client au jeu (GDD § 16.5) : le client envoie des commandes et reçoit des
## événements, et lit l'état dans sa copie locale (`state`), sans jamais toucher au `World`. Deux
## versions : locale (`LocalConnection`, le monde tourne dans le même processus) et distante
## (`RemoteConnection`, WebSocket vers le serveur, jalon M1). Le reste du client ne sait pas
## laquelle il utilise, sauf pour attendre les réponses (`asynchronous`).

## Copie locale de l'état, tenue à jour par la connexion.
var state: ClientState
## Vrai si les réponses arrivent plus tard (connexion distante) : `send` renvoie alors un tableau
## vide, et les événements de chaque commande arrivent dans l'ordre par `take_replies`.
var asynchronous := false


## Envoie une commande ; renvoie les événements qui en découlent, pour ce joueur (connexion
## synchrone), ou rien (asynchrone : voir `take_replies`).
func send(_command: Dictionary) -> Array[Dictionary]:
	return [] as Array[Dictionary]


## Réponses arrivées depuis le dernier appel (connexion asynchrone) : pour chaque commande envoyée,
## dans l'ordre, ses événements (`Array[Dictionary]`).
func take_replies() -> Array:
	return []


## Fait avancer le temps (connexion locale) ou relève ce qui est arrivé (distante) : événements reçus
## sans commande (réapparitions, promenades, régénération, autres joueurs).
func update(_delta: float) -> Array[Dictionary]:
	return [] as Array[Dictionary]


## Partie à sauvegarder sur ce poste ({} quand la partie vit sur un serveur).
func save_data() -> Dictionary:
	return {}


## Vrai tant que la connexion marche (toujours en local).
func is_open() -> bool:
	return true


## Ferme la connexion (retour au menu).
func close() -> void:
	pass
