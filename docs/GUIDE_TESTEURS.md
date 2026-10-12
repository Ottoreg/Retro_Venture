# Retro Venture — guide des testeurs (alpha solo)

Merci de tester ! Ce document explique comment jouer, ce qu'il y a à voir dans cette version et
comment nous faire vos retours. Le jeu n'affiche volontairement presque aucune aide à l'écran : tout
est ici.

## Lancer le jeu

- Dans le navigateur (Chrome, Firefox ou Edge récents, sur ordinateur) :
  **https://ottoreg.github.io/Retro_Venture/**
- La partie est **sauvegardée automatiquement** dans le navigateur (changement de carte, fin de
  combat, retour au menu…). « Continuer » au menu reprend la dernière partie. Vider les données du
  site efface la sauvegarde.
- Résolution prévue : 1280 × 720 ou plus.

## Créer son personnage

- Trois races, chacune avec sa zone de départ et son sort racial :
  - **Humain** : départ à **Brumerive** ; sort *Ralliement*.
  - **Gobelin** : départ à **Crasse-Roc** ; sort *Coup bas*.
  - **Elfe** : départ à **Sylvebrume** ; sort *Pas léger*.
- Trois Voies (classes) : **Guerrier**, **Rôdeur**, **Arcaniste**, avec 4 sorts chacune.

## Commandes

### Exploration

| Action | Comment |
| --- | --- |
| Se déplacer | Clic sur une case (un nouveau clic pendant la marche change de destination) |
| Attaquer un groupe de monstres | Clic sur le groupe : le personnage le rejoint et le combat commence |
| Parler, commercer, fabriquer | Clic sur un PNJ (bulle « … » au-dessus de sa tête) |
| Récolter | Clic sur un arbre (bûcheron) ou un rocher à minerai (mineur) |
| Entrer / sortir d'un bâtiment | Clic sur la porte |
| Changer de carte | Clic sur une flèche jaune au bord de l'écran |
| Voyager vers une autre zone | Clic sur la **Pierre de Passage** (pierre levée aux runes bleues) |
| Voir ce qu'on survole | Passer la souris sur un monstre, un PNJ, une ressource : une bulle s'affiche |

### Fenêtres et raccourcis

| Touche | Fenêtre |
| --- | --- |
| **C** | Personnage : caractéristiques, points à répartir après un niveau |
| **I** | Inventaire : équipement porté, sac, équiper / retirer / jeter |
| **S** | Sorts : un onglet pour la Voie, la race et l'arme ; fiche de chaque sort |
| **J** | Métiers : un onglet par métier, niveau, ressources et recettes |
| **Échap** | Ferme la fenêtre ouverte ; sinon, retour au menu (avec sauvegarde) |

Les quatre boutons en bas à droite du bandeau ouvrent les mêmes fenêtres. Un clic sur un sort du
bandeau, hors combat, ouvre sa fiche.

### Le bandeau du bas

- **Cœur rouge** : points de vie (il se vide quand on est blessé).
- **Étoile bleue** : points d'action (PA), pour lancer des sorts.
- **Case verte** : points de mouvement (PM), pour se déplacer en combat.
- **Sorts** : une icône par sort, avec son raccourci (1 à 0) et son coût en PA.

### Combat (au tour par tour)

1. **Placement** : cliquez sur un cercle bleu pour choisir votre case de départ, puis **Prêt**.
2. **Votre tour** :
   - se déplacer : clic sur une case verte (1 PM par case) ;
   - lancer un sort : touche **1 à 0** ou clic sur son icône, puis clic sur la cible (cases bleues :
     portée ; un second clic sur le sort, un **clic droit** ou **Échap** l'annule) ;
   - **Fin de tour** : bouton du bandeau.
3. Fin du combat : expérience, écus et butin. En cas de défaite, on se réveille au point de départ
   avec 1 PV.

Les points de vie se gardent d'un combat à l'autre et remontent doucement (1 PV toutes les 2 s) ;
le **lit** de votre maison les rend tous d'un coup.

## Ce qu'il y a dans cette version

- **Zones** : Brumerive (place du village, champs de l'est), Crasse-Roc (entrée des galeries, le
  Crassier), Sylvebrume (clairière de la Lisière, futaie ancienne), reliées seulement par les
  Pierres de Passage. Le **Trône de Cendre** (carte d'élite) est aussi accessible par une Pierre :
  le Souverain Cendré y attend, c'est le monstre le plus puissant du jeu.
- **Monstres** : loup et frondeur gobelin (Brumerive), rat des galeries et grouilleur (Crasse-Roc),
  cerf enchanté et arbre vivant (Sylvebrume). Les groupes comptent 1 à 3 monstres, parfois mélangés,
  se promènent autour de leur place et réapparaissent 2 à 3 minutes après avoir été vaincus.
- **Marchand** (Barlimon, à Brumerive) : achète et vend tous les objets.
- **Métiers** : bûcheron, mineur (les ressources repoussent en 1 à 2 minutes), forgeron (atelier de
  Célébrimbert, à Brumerive) avec 10 recettes.
- **Maison** (porte à Brumerive) : un coffre de 100 places et un lit.

Pas encore là : quêtes, multijoueur, sons et musiques, options.

## Ce qu'on aimerait que vous regardiez

- Le combat est-il compréhensible sans explication ? Trop facile, trop dur ?
- Les zones se lisent-elles bien (où marcher, où sont les sorties, ce qui est cliquable) ?
- Les groupes de monstres : est-ce qu'on voit bien qui est dans un groupe, et où il va ?
- L'économie : prix du marchand, butin, recettes du forgeron.
- Tout ce qui semble bloqué, lent, illisible ou bizarre.

## Signaler un problème

Pour chaque problème, donnez si possible :

1. ce que vous faisiez (carte, action, combat ou non) ;
2. ce qui s'est passé, et ce que vous attendiez ;
3. une capture d'écran ;
4. votre navigateur, et si le problème revient en recommençant.
