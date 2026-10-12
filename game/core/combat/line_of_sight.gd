class_name LineOfSight
extends RefCounted
## Ligne de vue entre deux cases de la grille.
##
## On parcourt les cases traversées par le segment qui relie les deux centres. La grille isométrique
## n'est qu'une grille carrée tournée, donc le calcul se fait directement en coordonnées de grille.


## Vrai si aucune case entre `from` et `to` (exclues) ne bloque la vue.
## `is_blocking` : Callable(cell: Vector2i) -> bool.
## Quand le segment passe exactement par un coin, la vue n'est bloquée que si les deux cases qui
## se touchent à ce coin bloquent.
static func is_clear(from: Vector2i, to: Vector2i, is_blocking: Callable) -> bool:
	var delta := to - from
	var steps := Vector2i(absi(delta.x), absi(delta.y))
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var cell := from
	var done := Vector2i.ZERO
	while done.x < steps.x or done.y < steps.y:
		var decision := (1 + 2 * done.x) * steps.y - (1 + 2 * done.y) * steps.x
		if decision == 0:
			var side_a := cell + Vector2i(direction.x, 0)
			var side_b := cell + Vector2i(0, direction.y)
			if is_blocking.call(side_a) and is_blocking.call(side_b):
				return false
			cell += direction
			done += Vector2i.ONE
		elif decision < 0:
			cell.x += direction.x
			done.x += 1
		else:
			cell.y += direction.y
			done.y += 1
		if cell == to:
			return true
		if is_blocking.call(cell):
			return false
	return true
