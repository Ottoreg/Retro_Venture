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
- `run_tests.gd` active `Protocol.verify_json` : chaque commande et chaque événement du noyau doit
  survivre à l'aller-retour en JSON (réseau), sinon le lanceur compte un échec « protocole JSON ».
- Les tests du client lisent l'état dans `view.server` (le `World`) ; après l'avoir modifié
  directement, appeler `view.refresh_state()` pour que l'interface (qui lit sa copie) le voie.
