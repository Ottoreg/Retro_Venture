# Paladin — Sacré / Tempête

**État** : conçu avec l'auteur (propositions validées telles quelles le 21/11/2026) et **codé le 21/11/2026** (GDD § 4.3,
fil « Ajouter la classe Paladin au jeu », `game/tests/core/test_paladin.gd`). Valeurs (dégâts, rangs 3 et 5) provisoires,
à ajuster après les tests de l'auteur. Données : `docs/design/paladin/produire.py`.

## Identité

- Rôle : guerrier sacré ou électrique, famille corps à corps. Fantaisie : « Paladin breveté de l'Ordre du Saint Paratonnerre. Béni par les dieux, foudroyé par eux aussi (souvent). Persuadé d'être l'Élu, comme les 214 autres Élus de sa promotion. »
- Voie Sacrée (Force + Intelligence) : mêlée et soutien autour de lui. Voie Tempête (Agilité) : mi-distance, pièges de terrain. Aucun soin.
- Tenue dorée (tunique `c9a227`, distincte du blanc cassé du Théologue, 22/11/2026) à manches bleu électrique ; toutes les races. 50 PV, 6 PA, 3 PM, 100 d'initiative.

## Passif de classe — Saint Paratonnerre (Apprenti, 5 rangs)

+6 % de dégâts (+1 % par rang) pour lui et ses alliés dans son aura ou debout sur un de ses arcs. Rang 3 : rayon de
l'aura +1. Rang 5 : une 4e balise en même temps.

## Voie Sacrée — auras (10 / 10)

Aura : cercle de rayon 2 qui suit le Paladin ; une seule à la fois (la nouvelle remplace l'ancienne) ; 3 tours ; effet
continu sur les alliés dedans (lui compris) ; la même aura de deux Paladins ne se cumule pas.

| Sort | PA | Portée | Effet | Rang 3 | Rang 5 |
|---|---|---|---|---|---|
| Aura de bravoure | 2 | soi | Aura : alliés +15 % de dégâts | 1 PA | +1 tour |
| Coup béni | 3 | 1 | 9 à 12 Sacré (2 par tour) | +10 % critique | +1 PM |
| Marteau lancé | 3 | 2–5 | 7 à 10 Sacré (2 par tour) | +1 portée | +10 % critique |
| Jugement | 5 | 1 | 20 à 26 Sacré (1 par tour) | +10 % critique | 4 PA |
| Onde sacrée | 4 | soi | 8 à 11 Sacré à chaque ennemi dans son aura (1 case sans aura) | 3 PA | +10 % critique |
| Coup de bouclier | 3 | 1 | 5 à 7 Sacré, repousse de 2 | 2 PA | −1 PM |
| Sceau de pénitence | 3 | 1–4 | −2 PM, relance 2 tours | +1 portée | −1 PA |
| Ruée sainte | 2 | 2–5 en ligne | Fonce jusqu'à la case ou au contact, sans frapper ; relance 2 tours | +1 portée | +1 PM |
| Aura de protection | 2 | soi | Aura : alliés +10 % de résistance à tous les éléments | 1 PA | +1 tour |
| Bénédiction | 2 | 0–3 | +30 Force et +30 Intelligence, 2 tours ; relance 3 tours | +1 portée | relance 2 |

## Voie Tempête — balises et arcs (10 / 10)

3 balises par Paladin (4 au rang 5 du passif), tout le combat, la plus ancienne part. Arc entre deux de ses balises
alignées (ligne ou colonne) à 6 cases au plus, sans obstacle : 6 à 9 Tempête à l'ennemi qui y entre, y commence son tour
ou s'y trouve quand l'arc se forme, une fois par arc et par tour ; n'arrête pas la marche, épargne les alliés. Projectiles
+25 % par arc traversé (2 au plus). Un ennemi casse une balise en entrant sur sa case ou en la frappant. Les monstres
évitent les arcs quand ils peuvent.

| Sort | PA | Portée | Effet | Rang 3 | Rang 5 |
|---|---|---|---|---|---|
| Balise | 2 | 1–5 | Pose une balise sur une case libre | +1 portée | 1 PA |
| Étincelle | 3 | 2–6 | 7 à 10 Tempête, projectile (2 par tour) | +1 portée | +10 % critique |
| Chaîne d'éclairs | 4 | 2–5 | 7 à 10 Tempête, rebond à 2 cases | 3 PA | +10 % critique |
| Foudre céleste | 5 | 3–6 | 18 à 24 Tempête, projectile (1 par tour) | +10 % critique | +1 portée |
| Surtension | 3 | 1–8, une de ses balises | Ennemis sur ses arcs ou à son contact : dégâts de l'arc × 1,5 | 2 PA | +2 portée |
| Aimantation | 3 | 2–5 | Attire de 3 cases | +1 portée | −1 PM |
| Électrocution | 3 | 1–5 | 4 à 6 Tempête, −2 PM, −1 PA de plus sur un arc | +1 portée | +10 % critique |
| Saut d'éclair | 2 | 1–8 | Échange de place avec une de ses balises ; relance 2 tours | 1 PA | relance 1 |
| Bouclier statique | 2 | soi | Bouclier 12 à 16 Tempête et 3 épines Tempête, 1 tour | 1 PA | +10 % résistance Tempête |
| Paratonnerre vivant | 2 | 0–4 | La cible (lui ou un allié) sert de balise 2 tours, +1 PM ; relance 3 tours | +1 portée | relance 2 |

## Plus tard

- Équilibrage après les tests de l'auteur (valeurs, rangs 3 et 5).
- Planches et animations PixelLab propres (en attendant : races recoloriées, sorts qui jouent l'attaque de la race).
- IA : les monstres ne visent pas encore exprès les balises.
- 3e Voie éventuelle : Lumière ou Ténèbres.
