# tests/

Tests automatisés, lancés en local et par la CI :

```sh
godot --headless --path game --import                     # première fois : importe le projet
godot --headless --path game -s res://tests/run_tests.gd  # lance tous les tests
```

- Un fichier de test s'appelle `test_*.gd` et commence par `extends "res://tests/test_case.gd"`.
- Chaque méthode `test_*` est un test ; `before_each()` est appelée avant chacun.
- Assertions : `assert_true`, `assert_false`, `assert_eq`, `assert_ne`, `assert_almost_eq`.
- Les tests du noyau vont dans `tests/core/`, en miroir de `core/`.
