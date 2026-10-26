class_name GameConnection
extends RefCounted
## Connexion du client au jeu (GDD § 16.5) : le client envoie des commandes et reçoit des
## événements, et lit l'état dans sa copie locale (`state`), sans jamais toucher au `World`. Deux
## versions : locale (`LocalConnection`, le monde tourne dans le même processus) et, plus tard,
## distante (WebSocket vers le serveur, jalon M1). Le reste du client ne sait pas laquelle il utilise.

## Copie locale de l'état, tenue à jour par la connexion.
var state: ClientState


## Envoie une commande ; renvoie les événements qui en découlent, pour ce joueur.
func send(_command: Dictionary) -> Array[Dictionary]:
	return [] as Array[Dictionary]


## Fait avancer le temps (connexion locale) ou relève ce qui est arrivé (distante) : événements reçus
## sans commande (réapparitions, promenades, régénération, autres joueurs).
func update(_delta: float) -> Array[Dictionary]:
	return [] as Array[Dictionary]


## Partie à sauvegarder sur ce poste ({} quand la partie vit sur un serveur).
func save_data() -> Dictionary:
	return {}
