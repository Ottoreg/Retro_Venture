class_name Loot
extends RefCounted
## Tirage du butin de fin de combat, pour un ou plusieurs joueurs.
##
## Chaque ligne de la table d'un monstre est tirée par chaque joueur, le plus prospecteur d'abord
## (au hasard entre égaux) : chance = taux × prospection / 100 × (1 + bonus), au plus 100 %.
## Limite par monstre : la quantité maximale de la ligne. Ce qu'un joueur obtient est retiré de ce
## qui reste pour les suivants (un loup à « croc [1, 2] » qui a donné 1 croc au premier joueur ne
## peut plus en donner qu'un seul aux autres). Pas de seuil de prospection.


## Butin de chaque joueur. `monsters` : définitions des monstres vaincus (un élément par monstre,
## même espèce répétée) ; `prospections` : { id du joueur: prospection } ; `bonus` : bonus de
## chance (élites anciennes). Renvoie { id du joueur: [ { objet, quantite } ] }, dans l'ordre
## d'obtention.
static func roll(monsters: Array, prospections: Dictionary, rng: RandomNumberGenerator, bonus := 0.0) -> Dictionary:
	var order := turn_order(prospections, rng)
	var result := {}
	for player_id: Variant in order:
		result[player_id] = []
	for monster: Dictionary in monsters:
		for drop: Dictionary in monster.get("butin", []):
			var amount: Array = drop.get("quantite", [1, 1])
			var remaining := int(amount[1])
			for player_id: Variant in order:
				if remaining <= 0:
					break
				var chance := minf(1.0, float(drop["taux"]) * int(prospections[player_id]) / 100.0 * (1.0 + bonus))
				if rng.randf() >= chance:
					continue
				var quantity := mini(remaining, rng.randi_range(int(amount[0]), int(amount[1])))
				remaining -= quantity
				result[player_id].append({"objet": drop["objet"], "quantite": quantity})
	return result


## Ordre de tirage : prospection décroissante, au hasard entre égaux.
static func turn_order(prospections: Dictionary, rng: RandomNumberGenerator) -> Array:
	if prospections.size() <= 1:
		return prospections.keys()
	var keyed: Array = []
	for player_id: Variant in prospections:
		keyed.append([int(prospections[player_id]), rng.randf(), player_id])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1]))
	return keyed.map(func(entry: Array) -> Variant: return entry[2])
