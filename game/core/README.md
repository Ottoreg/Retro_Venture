# core/ — noyau de jeu

Toute la **logique de jeu** : règles de combat, grille et déplacements, inventaire, butin, quêtes,
métiers. C'est le « serveur local » décrit au [GDD § 16.1](../../docs/GDD.md#161-principe-directeur) :
en solo il tourne dans le client, en multi il tournera sur le serveur (Godot sans affichage).

Règles :

- **Aucun nœud, aucune scène** : les classes héritent de `RefCounted` (ou `Resource` pour les données).
- **Aucune dépendance vers `client/`** : le noyau ne connaît ni l'affichage, ni l'interface, ni l'audio.
- Le client envoie des **commandes** (intentions du joueur) ; le noyau les valide et émet des
  **événements** (ce qui s'est passé), que le client affiche.
- Tout tirage aléatoire passe par un générateur à graine, pour pouvoir rejouer un combat.
- Chaque système est couvert par des tests dans `tests/core/`.

## Monde, cartes vivantes et joueurs (multijoueur, GDD § 16.5)

- `world/world.gd` (`World`) : point d'entrée, `execute(commande)` et `update(delta)`. Il tient des
  **cartes vivantes** (`world/map_instance.gd`, `MapInstance` : groupes, errance, réapparitions,
  ressources épuisées, cases des joueurs et des groupes), partagées par tous ceux qui s'y trouvent,
  et des **joueurs connectés** (`world/player_state.gd`, `PlayerState` : personnage, case, quêtes,
  combat), désignés par l'id de leur personnage (champ `entite` des commandes).
- En solo, un seul joueur (`World.PLAYER_ID`) : `World.character`, `map`, `combat`… gardent
  l'interface d'avant (façade solo). `add_player` et `remove_player` connectent d'autres joueurs.
- Chaque événement a une **portée** (`Protocol.scope_of` : personnel, carte, combat) ;
  `World.recipients(événement, expéditeur)` dit à qui l'envoyer. Un événement de carte a toujours
  son champ `carte`.
- `social/chat.gd` (`Chat`, jalon M3) : canaux du chat, texte nettoyé, anti-flood et journal des
  derniers messages ; `World` y passe la commande `ecrire` et dit qui reçoit chaque canal.
- `social/relations.gd` (`Relations`, jalon M3) : amis et ignorés (par pseudo, dans la sauvegarde),
  motifs et délai des signalements ; `World` applique `relations` et `signaler`.
- `social/exchange.gd` (`Exchange`, jalon M4) : échange entre deux joueurs (offres, validations,
  transfert tout ou rien sur des copies des inventaires) ; `World` applique `echange` et donne les
  échanges conclus au serveur (`take_exchanges`), qui sauvegarde les deux personnages ensemble.
- Le client ne lit jamais le `World` : il en reçoit des instantanés (`World.snapshot`, rien de
  secret : pas de graine, pas de pièges adverses) et des événements, en JSON (`Protocol.encode`,
  `Protocol.decode`, cases en `[x, y]`, version `Protocol.VERSION`).
- Sur un serveur (`World.for_server`), aucun joueur au départ, pas de façade solo ; `player_save`
  donne ce qu'on garde d'un joueur entre deux connexions. Un groupe engagé est annoncé aux autres
  joueurs de la carte (`EVT_GROUP_ENGAGED`) et revient s'il n'est pas vaincu (`EVT_GROUP_RELEASED`).
  Le serveur lui-même (sessions, réseau, comptes) est dans `game/server/`.
