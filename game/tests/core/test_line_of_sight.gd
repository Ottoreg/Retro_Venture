extends "res://tests/test_case.gd"

var _blocked := {}


func before_each() -> void:
	_blocked = {}


func _clear(from: Vector2i, to: Vector2i) -> bool:
	return LineOfSight.is_clear(from, to, func(cell: Vector2i) -> bool: return _blocked.has(cell))


func test_vue_degagee() -> void:
	assert_true(_clear(Vector2i(0, 0), Vector2i(5, 2)))
	assert_true(_clear(Vector2i(0, 0), Vector2i(0, 0)))
	assert_true(_clear(Vector2i(0, 0), Vector2i(1, 0)))


func test_obstacle_sur_la_ligne() -> void:
	_blocked[Vector2i(2, 0)] = true
	assert_false(_clear(Vector2i(0, 0), Vector2i(4, 0)))
	assert_false(_clear(Vector2i(4, 0), Vector2i(0, 0)), "symétrique")


func test_la_cible_et_le_tireur_ne_bloquent_pas() -> void:
	_blocked[Vector2i(4, 0)] = true
	_blocked[Vector2i(0, 0)] = true
	assert_true(_clear(Vector2i(0, 0), Vector2i(4, 0)))


func test_passage_par_un_coin() -> void:
	# De (0, 0) à (2, 2), la ligne passe par les coins entre (1, 0) et (0, 1), puis par (1, 1).
	_blocked[Vector2i(1, 0)] = true
	assert_true(_clear(Vector2i(0, 0), Vector2i(2, 2)), "un seul côté du coin bloqué")
	_blocked[Vector2i(0, 1)] = true
	assert_false(_clear(Vector2i(0, 0), Vector2i(2, 2)), "les deux côtés du coin bloqués")
	_blocked.clear()
	_blocked[Vector2i(1, 1)] = true
	assert_false(_clear(Vector2i(0, 0), Vector2i(2, 2)), "case centrale bloquée")
