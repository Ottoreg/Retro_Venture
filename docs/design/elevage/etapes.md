# Ampas, élevage et montures : étapes pour les coder

Préparé le 24/11/2026 à la demande de l'auteur, d'après le GDD § 10.3 (Éleveur, ampas, monture) et le code
actuel. Rien n'est codé. Chaque lot se code, se teste et se pousse sur `main` à part, et l'auteur valide
avant le suivant (même méthode que les sous-zones).

## Ce qui existe déjà et servira

| Besoin | Déjà dans le jeu |
|---|---|
| Ampas dans le monde | 17 cartes des Grandes Plaines, Courses d'Ampas avec 2 enclos (`docs/design/grandes_plaines/plaines.py`) |
| Monstres de monture | `loup_des_collines`, `cerf_enchante`, `grouilleur`, `olifant_de_guerre` (données et dessins) |
| Groupes rares | `reapparition` des groupes (délai en secondes) : Onyx et Cristal auront un délai plus long |
| Enclos | instances de métier (`core/jobs/plots.gd`, temps réel `World.wall_clock`, copie privée par joueur) |
| Métier | réputation, points de maîtrise et compétences par métier (`Character.jobs`, `Profession`) |
| Équipement | `Inventory.SLOTS` (pas encore d'emplacement monture), entrées d'inventaire à champs libres (comme `forge`, `exo`) |
| Bonus de monture | caractéristiques, résistances, spectraux %, réduction %, dévastateurs %, épines % : toutes existent déjà en combat |
| Course | `MapView.RUN_FACTOR` (1,4) |

## Décisions à prendre avant de coder

Le GDD laisse ces points « à définir ». Je proposerai des valeurs provisoires dans chaque lot si l'auteur
préfère trancher plus tard.

1. **Palier des ampas** (zone commune, palier « à définir » au § 3.5) : je propose palier 2 pour les 6
   couleurs, 3 pour Onyx et Cristal.
2. **Bonus total** au palier 5 de la monture (ex. 40 points de chaque carac du duo, ou 10 % de chaque
   résistance ; Onyx et Cristal : +1 PM / +1 PA et 10 %).
3. **Points de maîtrise** de la monture : barème par monstre combattu et seuils des 5 paliers.
4. **Apprivoisement** : chance de base, effet du palier d'éleveur et du palier du monstre.
5. **Licol** : le Costumier n'existe pas encore. En attendant, je propose un licol vendu par un PNJ
   éleveur aux Courses d'Ampas.
6. **Dressage** : durée à l'enclos (temps réel), effet de la brosse, de la mangeoire et de l'épouvantail.
7. **Énergie** : réserve, perte par combat, recharge à la mangeoire.
8. **Palier d'éleveur requis** pour chaque ampa (le loup, le cerf et le grouilleur sont à Inconnu, l'olifant à Vétéran).

## Lots

### Lot 1 : les ampas dans les Grandes Plaines (fait le 24/11/2026, `docs/design/grandes_plaines/ampas.py`)
- Dessin SVG d'un ampa (bipède ailé, tête d'aigle), recolorié par ses plumes pour les 8 types.
- 8 monstres `ampa_<couleur>` : sorts aux éléments de leur couleur, une famille, une élite (règle des tests).
- Groupes et calque `placement` sur les cartes des plaines. Onyx et Cristal sont rares (moins de
  groupes, `reapparition` plus longue).
- Butin : plumes (ressources de forge) et viande.
- Tests : données, `tools/simulation.gd` sur `grandesplaines`, catalogue regénéré.

### Lot 2 : le métier d'Éleveur (fait le 24/11/2026)
- `data/metiers/eleveur.json` : réputation, points de maîtrise, compétences (apprivoisement, dressage).
- PNJ maître éleveur aux Courses d'Ampas, qui vend les licols (provisoire, voir la décision 5).
- Objet `licol`.

### Lot 3 : apprivoiser en combat
- Sort *Apprivoiser* (3 PA, au contact), donné à tous quand on porte un licol. Il marche seulement si
  la cible est le dernier ennemi, sous 25 % de ses PV, d'une espèce apprivoisable (champ `monture` des
  monstres), et n'est ni élite ni mini-boss.
- Réussite : le licol est consommé, le monstre quitte le combat (victoire sans son butin), et une
  **monture sauvage** entre dans l'inventaire avec son espèce, sa robe, son sexe et sa docilité.
- Réputation d'éleveur gagnée. Commande et événement nouveaux, protocole v27. Tests du noyau.

### Lot 4 : l'enclos
- Instance `enclos` sur le modèle des instances de métier, ouverte depuis la porte des enclos des
  Courses d'Ampas.
- On y pose une monture sauvage, qui se dresse en temps réel. Les objets d'élevage (mangeoire,
  abreuvoir, brosse, épouvantail) accélèrent le dressage. Ils seront vendus par le PNJ tant que les
  métiers qui les fabriquent n'existent pas.
- Une monture dressée ressort dans l'inventaire, prête à monter.
- Fumier produit à l'enclos ; posé sur un emplacement d'instance, il divise la pousse par 2 (engrais, § 10.3).

### Lot 5 : la monture équipée
- Emplacement `monture` dans `Inventory.SLOTS`, et fenêtre de monture : espèce, robe, nature,
  palier, points, énergie.
- Choix de la nature (offensive ou défensive) au palier 0, une fois pour toutes.
- Bonus ajouté au cavalier en combat : 20/40/60/80/100 % selon le palier, rien si l'énergie est à 0.
- Points gagnés seulement si la monture est équipée pendant un combat gagné, et plus rien au palier 5.
- Hors combat : course × 1,8 au lieu de × 1,4. Le cavalier affiché sur sa monture demande des dessins,
  ce sera un lot d'art à part (pour commencer, une petite icône près du personnage).
- Protocole v28, tests du noyau, captures de la fenêtre.

### Lot 6 : les 4 montures-monstres
- Champ `monture` sur le loup des collines, le cerf enchanté, le grouilleur et l'olifant de guerre
  (Vétéran), avec l'élément unique de chacun (Tempête, Givre, Flamme, Acier).

### Lot 7, plus tard : robes, reproduction et chef-d'œuvre
- Robes rares, reproduction à l'enclos (mâle et femelle, héritage d'une partie des bonus, portées limitées).
- Lignée de maître (chef-d'œuvre au palier Maître).
- Plus tard encore : licols et selles fabriqués par le Costumier, objets d'élevage fabriqués par les métiers.

## Ordre conseillé

Lots 1 et 2 d'abord : ils sont visibles tout de suite dans les plaines. Puis les lots 3, 4 et 5, qui
forment la boucle complète (capturer, dresser, monter). Le lot 6 est court et peut se glisser après le
lot 3. Le lot 7 attend les retours des tests.
