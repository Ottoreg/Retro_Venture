class_name CombatAI
extends RefCounted
## IA des monstres. Un seul comportement pour l'instant (« basique »), qui convient aux monstres
## de mêlée comme à distance :
## 1. lancer le sort le plus fort possible sur un ennemi à portée ;
## 2. sinon, se déplacer vers la case la plus proche d'où un sort peut toucher ;
## 3. sinon, se rapprocher de l'ennemi le plus proche ;
## 4. sinon, finir son tour.


## Prochaine commande à jouer pour `fighter`, ou `{}` pour finir son tour.
## L'IA ne se déplace qu'une fois par tour (`has_moved`).
static func next_action(combat: Combat, fighter: Fighter, has_moved: bool) -> Dictionary:
	var cast := _best_cast(combat, fighter, fighter.cell)
	if not cast.is_empty():
		return cast
	if has_moved or fighter.pm <= 0:
		return {}
	var reachable := combat.reachable_cells(fighter)

	# Case la plus proche d'où un sort peut toucher un ennemi.
	var best_cell := fighter.cell
	var best_steps := 1 << 30
	for cell: Vector2i in reachable:
		var steps: int = reachable[cell].size()
		if steps < best_steps and not _best_cast(combat, fighter, cell).is_empty():
			best_cell = cell
			best_steps = steps
	if best_cell != fighter.cell:
		return _move_to(fighter, best_cell)

	# Sinon, se rapprocher autant que possible de l'ennemi le plus proche.
	var enemy_cells: Array[Vector2i] = []
	for enemy in combat.enemies_of(fighter):
		enemy_cells.append(enemy.cell)
	var distances := combat.distances_from(enemy_cells, fighter)
	var best_distance: int = distances.get(fighter.cell, 1 << 30)
	best_steps = 1 << 30
	for cell: Vector2i in reachable:
		var distance: int = distances.get(cell, 1 << 30)
		var steps: int = reachable[cell].size()
		if distance < best_distance or (distance == best_distance and best_cell != fighter.cell and steps < best_steps):
			best_cell = cell
			best_distance = distance
			best_steps = steps
	if best_cell != fighter.cell:
		return _move_to(fighter, best_cell)
	return {}


## Meilleur sort à lancer depuis `origin` sur un ennemi (le plus de dégâts), ou `{}`.
static func _best_cast(combat: Combat, fighter: Fighter, origin: Vector2i) -> Dictionary:
	var best := {}
	var best_damage := -1
	for spell in fighter.spells:
		if not spell.deals_damage() or not fighter.cast_blocker(spell).is_empty():
			continue
		if spell.max_damage() <= best_damage:
			continue
		for enemy in combat.enemies_of(fighter):
			if combat.targeting_blocker(fighter, spell, enemy.cell, origin).is_empty():
				best = {"type": Protocol.CMD_CAST, "entite": fighter.id, "sort": spell.id, "cible": enemy.cell}
				best_damage = spell.max_damage()
				break
	return best


static func _move_to(fighter: Fighter, cell: Vector2i) -> Dictionary:
	return {"type": Protocol.CMD_MOVE, "entite": fighter.id, "cible": cell}
