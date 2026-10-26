# client/ — affichage et interface

Scènes, rendu isométrique, interface, audio et entrées du joueur. Le client lit l'état du
[noyau](../core/README.md), lui envoie des commandes et réagit à ses événements. Il ne contient
**aucune règle de jeu**.

## Connexion et copie de l'état (GDD § 16.5)

- Le client parle au jeu par une **connexion** (`net/game_connection.gd`) : `send(commande)` renvoie
  les événements, `update(delta)` ceux du temps qui passe. En solo, `net/local_connection.gd` fait
  tourner le `World` dans le même processus, en passant quand même par le JSON du protocole.
- Il **lit tout dans la copie locale** de l'état (`net/client_state.gd`, `MapView.world`) : mêmes
  lectures que `World` (personnage, carte, groupes, combat recréé, quêtes), rechargée d'après les
  instantanés du monde. Jamais de lecture ni d'écriture directe du `World` dans le client ; seuls
  les tests et les outils y touchent (`MapView.server`, puis `MapView.refresh_state()`).
- L'id du joueur est `world.player_id` (pas `World.PLAYER_ID`, qui n'existe qu'en solo).
