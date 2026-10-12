extends RefCounted
## Classe de base des tests. Un fichier de test hérite de ce script :
##     extends "res://tests/test_case.gd"
## et déclare des méthodes `test_*`. `before_each()` est appelée avant chaque test.

var failures: PackedStringArray = []


func before_each() -> void:
	pass


func assert_true(condition: bool, message := "") -> void:
	if not condition:
		_fail("attendu : vrai", message)


func assert_false(condition: bool, message := "") -> void:
	if condition:
		_fail("attendu : faux", message)


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if not _equal(actual, expected):
		_fail("obtenu %s, attendu %s" % [var_to_str(actual), var_to_str(expected)], message)


func assert_ne(actual: Variant, unexpected: Variant, message := "") -> void:
	if _equal(actual, unexpected):
		_fail("valeur différente de %s attendue" % var_to_str(unexpected), message)


func assert_almost_eq(actual: float, expected: float, tolerance := 0.0001, message := "") -> void:
	if absf(actual - expected) > tolerance:
		_fail("obtenu %s, attendu %s ± %s" % [actual, expected, tolerance], message)


func _equal(a: Variant, b: Variant) -> bool:
	var numeric := [TYPE_INT, TYPE_FLOAT]
	if typeof(a) in numeric and typeof(b) in numeric:
		return a == b
	# Comparer deux types différents avec `==` lève une erreur en GDScript.
	return typeof(a) == typeof(b) and a == b


func _fail(reason: String, message: String) -> void:
	failures.append(reason if message.is_empty() else "%s — %s" % [message, reason])
