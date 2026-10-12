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
