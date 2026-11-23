# Théologue — Sacré / Flamme

**État** : conçu avec l'auteur (20 propositions validées telles quelles le 23/11/2026) et **codé le 23/11/2026** (GDD § 4.3,
fil « Compléter les sorts du Théologue », `game/tests/core/test_theologue.gd`). Valeurs (dégâts, rangs 3 et 5)
provisoires, à ajuster après les tests de l'auteur. Données : `docs/design/theologue/produire.py`.

## Identité

- Rôle : le seul vrai soigneur du jeu, famille distance. Fantaisie : « Soigneur sacré. Bénit les alliés, sermonne les
  ennemis, et cite des textes que personne n'a lus. Le dimanche il soigne ; le reste de la semaine, il instruit des procès
  en hérésie. »
- Voie Sacrée (Force + Intelligence) : soin, protection et soutien à distance. Voie Flamme (Intelligence) : l'inquisiteur,
  offensif à distance (portées 1 à 6), un seul petit soin. L'Intelligence sert les deux Voies (voulu).
- Robe blanche, étole pourpre et or ; toutes les races. 50 PV, 6 PA, 3 PM, 100 d'initiative.
- Écart au gabarit (Voie Sacrée) : 1 signature, 3 dégâts (pas de gros coup cher), 2 contrôles, 1 mobilité, 2 soins ou
  défenses, 1 soutien.

## Passif de classe — Faire la quête (Apprenti, 5 rangs)

Chaque sort qui blesse un ennemi donne 1 Foi (5 au plus, tout le combat). Le soin ou le bouclier suivant la dépense toute :
+6 % par Foi (+1 % par rang). Rang 3 : un ennemi qui désobéit à un Commandement donne aussi 1 Foi. Rang 5 : un soin lancé
à 5 Foi soigne aussi de moitié les alliés au contact de ceux qu'il soigne.

## Voie Sacrée — Terre consacrée (10 / 10)

Terre consacrée : glyphe dorée en croix de 5 cases, 3 tours ; alliés dessus +20 % de soins et de boucliers reçus ; un
ennemi qui y commence son tour perd 5 à 7 Sacré. Le Sermon soigne × 1,5 quand son croisement est dessus.

| Sort | PA | Portée | Effet | Rang 3 | Rang 5 |
|---|---|---|---|---|---|
| Terre consacrée | 3 | 1–5 | Glyphe 3 tours, relance 3 | +1 portée | croix de rayon 2 |
| Châtiment | 4 | 2–5 | 8 à 12 Sacré (2 par tour) | +1 portée | +10 % critique |
| Sermon | 4 | 1–5 en ligne | Croix latine : 4 à 7 Sacré / soin 4 à 7 (× 1,5 consacré) | +1 portée | 3 PA |
| Coup de goupillon | 2 | 1–4 | 4 à 6 Sacré (3 par tour) | +1 portée | +10 % critique |
| Imposition des mains | 3 | 0–3 | Soin 12 à 18 | +1 portée | retire les poisons |
| Rempart de foi | 2 | 0–3 | Bouclier 12 à 16, relance 2 | +1 portée | relance 1 |
| Absolution | 3 | 0–5 | Bonus ennemis, malus et poisons alliés retirés ; relance 2 | +1 portée | relance 1 |
| Génuflexion | 3 | 1–4 | −2 PM, −15 % de dégâts infligés, 1 tour ; relance 2 | +1 portée | relance 1 |
| Procession | 2 | 1–4 | Téléporte sur une case libre ou échange avec un allié ; relance 2 | +1 portée | relance 1 |
| Indulgence | 2 | 0–3 | +1 PA et +1 PM, 2 tours ; relance 4 | +1 portée | relance 3 |

## Voie Flamme — l'inquisiteur (10 / 10)

Hérésie : crans sur un ennemi (5 au plus), un par sort Flamme qui le touche, tout le combat, jamais retirés ; le Bûcher les
consomme. Commandement « Tu ne bougeras point » (2 tours) : chaque case marchée coûte une Pénitence (3 Flamme et un cran).
Pas d'embrasement du terrain (Démoniste).

| Sort | PA | Portée | Effet | Rang 3 | Rang 5 |
|---|---|---|---|---|---|
| Accusation | 2 | 1–6 | +2 crans (2 par tour) | +1 portée | +1 cran |
| Tison | 3 | 1–5 | 6 à 9 Flamme, +1 cran (3 par tour) | +10 % critique | +1 portée |
| Autodafé | 4 | 2–5 | Croix de rayon 1 : 5 à 8 Flamme, +1 cran | +1 portée | 3 PA |
| Feu purificateur | 5 | 2–5 | 18 à 24 Flamme, +1 cran | +10 % critique | 4 PA |
| Bûcher | 4 | 1–4 | 4 à 6 Flamme par cran, tous consommés | +1 portée | +10 % critique |
| Commandement | 3 | 1–5 | « Tu ne bougeras point », 2 tours ; relance 2 | +1 portée | relance 1 |
| La Question | 3 | 1–3 | −2 PA 1 tour, +1 cran ; relance 2 | +1 portée | +1 cran |
| Saut des flammes | 2 | 1–3 | Téléportation ; relance 2 | +1 portée | relance 1 |
| Expiation | 2 | 0–3 | Soin Flamme 6 à 9 ; relance 2 | +1 portée | relance 1 |
| Zèle | 2 | 0–3 | +40 Intelligence, 2 tours ; relance 3 | +1 portée | relance 2 |

## Plus tard

- Équilibrage après les tests de l'auteur (valeurs, rangs 3 et 5).
- Résurrection (multijoueur ou mode héros) ; d'autres commandements choisis dans une grille ; IA des monstres face au
  Commandement (ils l'ignorent pour l'instant).
- Planches et animations PixelLab propres (prompts `assets/theologue/PROMPTS.md` à écrire) ; 3e Voie Lumière ou Ténèbres.
- Vérifier que les soins des autres classes restent sous Expiation (6 à 9).
