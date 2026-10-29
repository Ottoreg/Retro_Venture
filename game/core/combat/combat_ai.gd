class_name CombatAI
extends RefCounted
## IA des monstres. Chaque sort possible est noté sur chaque cible utile (dégâts aux ennemis, soins
## et protections des alliés, bonus, malus, poisons, glyphes, pièges ; moins ce qu'il coûterait à
## son camp), et l'IA lance le meilleur tant qu'il vaut quelque chose. Trois comportements, qui ne
## changent que la façon de se déplacer (`Fighter.ai`) :
## - « basique » : se rapproche par le plus court chemin pour frapper ;
## - « distance » : frappe depuis la case la plus éloignée des ennemis, puis recule avec ses PM ;
## - « soutien » : comme « distance », pour les soigneurs et les poseurs de glyphes.

const BASIC := "basique"
const RANGED := "distance"
const SUPPORT := "soutien"
const BEHAVIOURS := [BASIC, RANGED, SUPPORT]
## Valeur d'un point de PA ou de PM donné ou retiré, en « PV équivalents ».
const PA_PM_VALUE := 5.0
## Valeur d'un point d'autre caractéristique (bonus, malus).
const STAT_VALUE := 0.3
## Les dégâts infligés à son propre camp comptent plus que ceux infligés aux ennemis.
const FRIENDLY_FIRE_WEIGHT := 1.5


## Prochaine commande à jouer pour `fighter`, ou `{}` pour finir son tour.
## L'IA se déplace une fois pour attaquer (`has_moved`) ; les IA « distance » et « soutien »
## reculent ensuite avec les PM qui restent.
static func next_action(combat: Combat, fighter: Fighter, has_moved: bool) -> Dictionary:
	var cast := best_cast(combat, fighter, fighter.cell)
	if not cast.is_empty():
		return cast
	if fighter.pm <= 0:
		return {}
	var keeps_distance := fighter.ai in [RANGED, SUPPORT]
	var reachable := combat.reachable_cells(fighter)
	if not has_moved and _can_still_cast(fighter):
		# Case d'où un sort vaut quelque chose : la plus proche (basique), ou la plus éloignée des
		# ennemis (distance, soutien).
		var best_cell := fighter.cell
		var best_key := [-INF, -INF]
		for cell: Vector2i in reachable:
			var option := best_cast(combat, fighter, cell)
			if option.is_empty():
				continue
			var steps: int = reachable[cell].size()
			var key := [float(_nearest_enemy_distance(combat, fighter, cell)), -float(steps)] if keeps_distance \
				else [-float(steps), float(option["valeur"])]
			if key[0] > best_key[0] or (key[0] == best_key[0] and key[1] > best_key[1]):
				best_cell = cell
				best_key = key
		if best_cell != fighter.cell:
			return _move_to(fighter, best_cell)
		var approach := _approach(combat, fighter, reachable)
		if not approach.is_empty():
			return approach
	if keeps_distance:
		return _retreat(combat, fighter, reachable)
	return {}


## Meilleur sort à lancer depuis `origin`, avec sa note (`valeur`), ou `{}` si aucun ne vaut rien.
static func best_cast(combat: Combat, fighter: Fighter, origin: Vector2i) -> Dictionary:
	var best := {}
	var best_value := 0.0
	for spell in fighter.spells:
		if not fighter.cast_blocker(spell).is_empty() or spell.teleports() or spell.composes():
			continue
		for cell in _candidate_cells(combat, fighter, spell, origin):
			if not combat.targeting_blocker(fighter, spell, cell, origin).is_empty():
				continue
			var value := evaluate(combat, fighter, spell, cell, origin)
			if value > best_value:
				best_value = value
				best = {"type": Protocol.CMD_CAST, "entite": fighter.id, "sort": spell.id, "cible": cell, "valeur": value}
	return best


## Note d'un sort lancé sur `target` depuis `origin` (positive : bon pour le camp du lanceur).
static func evaluate(combat: Combat, fighter: Fighter, spell: Spell, target: Vector2i, origin: Vector2i) -> float:
	var trap := spell.trap_effect()
	if not trap.is_empty():
		return _trap_value(combat, fighter, trap, target, origin)
	if spell.charges():
		# Une charge ne vaut que si elle arrive au contact de la cible.
		var path := combat.charge_path(fighter, target, origin)
		var landing: Vector2i = path[-1] if not path.is_empty() else origin
		if _fighter_at(combat, fighter, origin, target) == null or IsoGrid.distance(landing, target) != 1:
			return 0.0
	var value := 0.0
	for effect in spell.effects:
		if effect["type"] == Spell.EFFECT_GLYPH:
			# Une glyphe vaut ce qu'elle ferait une fois à ceux qui sont déjà dedans, un peu plus si
			# elle dure.
			for cell in spell.zone_cells(target, origin):
				var inside := _fighter_at(combat, fighter, origin, cell)
				if inside != null:
					for inner: Dictionary in effect["effets"]:
						if Spell.affects(inner, fighter, inside):
							value += _effect_value(combat, fighter, inside, inner) * (1.0 + 0.25 * mini(int(effect["duree"]) - 1, 2))
	for cell in spell.zone_cells(target, origin):
		var hit := _fighter_at(combat, fighter, origin, cell)
		if hit == null or (spell.excludes_caster and hit == fighter):
			continue
		for effect in spell.effects:
			if effect["type"] not in Spell.GROUND_EFFECTS and Spell.affects(effect, fighter, hit):
				value += _effect_value(combat, fighter, hit, effect)
	return value


## Valeur d'un effet sur un combattant (positive si elle sert le camp du lanceur).
static func _effect_value(combat: Combat, caster: Fighter, target: Fighter, effect: Dictionary) -> float:
	var ally := target.team == caster.team
	var average := (int(effect["min"]) + int(effect["max"])) / 2.0
	var element: String = str(effect.get("element", ""))
	match effect["type"]:
		Spell.EFFECT_DAMAGE:
			var damage := average * (100 + caster.power(element)) / 100.0 * (100 - target.resistance(element)) / 100.0 + caster.total_dommages()
			damage = minf(maxf(0.0, damage), target.hp + target.shield)
			if damage >= target.hp + target.shield:
				damage += 10.0  # Achever un combattant compte double.
			return -damage * FRIENDLY_FIRE_WEIGHT if ally else damage
		Spell.EFFECT_HEAL:
			var heal := minf(average * (100 + caster.power(element)) / 100.0, target.max_hp - target.hp)
			return heal if ally else -heal
		Spell.EFFECT_SHIELD:
			var shield := average * (100 + caster.power(element)) / 100.0 * 0.5
			if combat.enemies_of(target).is_empty() or not ally:
				return -shield if not ally else 0.0
			return shield
		Spell.EFFECT_POISON:
			var tick := average * (100 + caster.power(element)) / 100.0 * (100 - target.resistance(element)) / 100.0
			var poison := maxf(0.0, tick) * int(effect["duree"]) * 0.7
			return -poison if ally else poison
		Spell.EFFECT_BONUS, Spell.EFFECT_MALUS:
			var weight := PA_PM_VALUE if effect["carac"] in ["pa", "pm"] else STAT_VALUE
			var change := average * weight * mini(int(effect["duree"]), 3)
			var helps: bool = (effect["type"] == Spell.EFFECT_BONUS) == ally
			return change if helps else -change
		Spell.EFFECT_REMOVE_PM:
			return -average * PA_PM_VALUE if ally else average * PA_PM_VALUE
		Spell.EFFECT_GAIN_PA:
			return average * PA_PM_VALUE * 0.5 if ally and target == caster else 0.0
		Spell.EFFECT_PUSH, Spell.EFFECT_PULL:
			return -2.0 if ally else 2.0
		Spell.EFFECT_CLOCK:
			return 6.0 if not ally and combat.clock_of(target).is_empty() else 0.0
		Spell.EFFECT_CLOCK_SHIFT:
			return 3.0 if not ally and not combat.clock_of(target).is_empty() else 0.0
	return 0.0


## Un piège vaut la moitié de ce qu'il ferait à l'ennemi le plus proche s'il marchait dessus, s'il est
## posé sur une case libre juste à côté d'un ennemi (un peu moins à deux cases).
static func _trap_value(combat: Combat, fighter: Fighter, trap: Dictionary, target: Vector2i, origin: Vector2i) -> float:
	if not combat.is_free(target) or not combat.trap_at(target).is_empty() or target == origin:
		return 0.0
	var best := 0.0
	for enemy in combat.enemies_of(fighter):
		var distance := IsoGrid.distance(enemy.cell, target)
		if distance < 1 or distance > 2:
			continue
		var value := 0.0
		for effect: Dictionary in trap["effets"]:
			if Spell.affects(effect, fighter, enemy):
				value += _effect_value(combat, fighter, enemy, effect)
		best = maxf(best, value * (0.5 if distance == 1 else 0.35))
	return best


## Cases où viser : celles des combattants et autour (zones, glyphes), ou près des ennemis (pièges).
static func _candidate_cells(combat: Combat, fighter: Fighter, spell: Spell, origin: Vector2i) -> Array[Vector2i]:
	var reach := combat.max_range(fighter, spell)
	var spread := 0
	if spell.zone_type == Spell.ZONE_CIRCLE:
		spread = spell.zone_size
	elif spell.zone_type == Spell.ZONE_LATIN_CROSS:
		spread = 4
	if not spell.trap_effect().is_empty():
		spread = 2
	var seen := {}
	var cells: Array[Vector2i] = []
	for other in combat.fighters:
		if not other.is_alive():
			continue
		var center := origin if other == fighter else other.cell
		for cell in Spell.circle_cells(center, spread):
			if not seen.has(cell) and IsoGrid.distance(origin, cell) <= reach:
				seen[cell] = true
				cells.append(cell)
	return cells


## Combattant sur `cell` si `fighter` se tenait sur `origin`.
static func _fighter_at(combat: Combat, fighter: Fighter, origin: Vector2i, cell: Vector2i) -> Fighter:
	if cell == origin:
		return fighter
	var occupant := combat.fighter_at(cell)
	return null if occupant == fighter else occupant


static func _can_still_cast(fighter: Fighter) -> bool:
	for spell in fighter.spells:
		if fighter.cast_blocker(spell).is_empty():
			return true
	return false


static func _nearest_enemy_distance(combat: Combat, fighter: Fighter, cell: Vector2i) -> int:
	var nearest := 1 << 30
	for enemy in combat.enemies_of(fighter):
		nearest = mini(nearest, IsoGrid.distance(cell, enemy.cell))
	return nearest


## Se rapprocher autant que possible de l'ennemi le plus proche.
static func _approach(combat: Combat, fighter: Fighter, reachable: Dictionary) -> Dictionary:
	var enemy_cells: Array[Vector2i] = []
	for enemy in combat.enemies_of(fighter):
		enemy_cells.append(enemy.cell)
	var distances := combat.distances_from(enemy_cells, fighter)
	var best_cell := fighter.cell
	var best_distance: int = distances.get(fighter.cell, 1 << 30)
	var best_steps := 1 << 30
	for cell: Vector2i in reachable:
		var distance: int = distances.get(cell, 1 << 30)
		var steps: int = reachable[cell].size()
		if distance < best_distance or (distance == best_distance and best_cell != fighter.cell and steps < best_steps):
			best_cell = cell
			best_distance = distance
			best_steps = steps
	return _move_to(fighter, best_cell) if best_cell != fighter.cell else {}


## S'éloigner de l'ennemi le plus proche, si une case accessible l'éloigne vraiment.
static func _retreat(combat: Combat, fighter: Fighter, reachable: Dictionary) -> Dictionary:
	var best_cell := fighter.cell
	var best_distance := _nearest_enemy_distance(combat, fighter, fighter.cell)
	for cell: Vector2i in reachable:
		var distance := _nearest_enemy_distance(combat, fighter, cell)
		if distance > best_distance:
			best_cell = cell
			best_distance = distance
	return _move_to(fighter, best_cell) if best_cell != fighter.cell else {}


static func _move_to(fighter: Fighter, cell: Vector2i) -> Dictionary:
	return {"type": Protocol.CMD_MOVE, "entite": fighter.id, "cible": cell}
