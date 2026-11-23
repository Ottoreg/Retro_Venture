# Arcaniste — Flamme + Givre + Tempête (une seule Voie)

**État** : **complet et codé le 23/11/2026** (GDD § 4.3 « Arcaniste complet », propositions du fil « Compléter les sorts
de l'Arcaniste » validées telles quelles, `game/tests/core/test_arcaniste.gd`). Valeurs provisoires, à ajuster après les
tests de l'auteur. Données : `docs/design/arcaniste/produire.py`.

## Identité

- Rôle : dégâts magiques, contrôle, mobilité. Famille distance.
- Fantaisie : *« Maître du feu, du givre et de la foudre. Lit beaucoup, court peu, explose parfois des choses par accident. »*
- Caractéristiques : Intelligence, Perception et Agilité à parts égales (pas de Force).
- 50 PV, 6 PA, 3 PM, 100 d'initiative (comme toutes les classes).
- Gabarit : une seule Voie multi-élément, 12 sorts + 8 utilitaires.

## Passif de classe — Virtuose (Apprenti, 5 rangs)

Chaque sort créé lancé dont la combinaison diffère de celle du sort créé précédent donne 1 cran de Virtuosité (3 au plus,
jusqu'à la fin de son tour suivant) : +3 % de dégâts par cran (+1 % par rang). Rang 3 : à 3 crans, Fusion arcanique coûte
0 PA. Rang 5 : le 3e cran donne +1 PM pour le tour.

## Sorts de composition (12)

| Sort | Base | Rang 3 | Rang 5 |
|---|---|---|---|
| Composition | 1 PA rendu, choisit 3 états (+4 % de dégâts chacun, +1 % par rang) | 2 PA rendus au 1er lancer | 3 PA |
| Fusion arcanique | 2 PA, crée le sort de la combinaison | 1 PA | 3e place |
| Fournaise (FFF) | 4 PA, 9–13 Flamme + glyphe brûlante | glyphe 3 tours | +1 portée |
| Choc thermique (FFG) | 4 PA, 7–10 Flamme + 4–6 Givre, −10 % rés. Flamme | −15 % rés. Flamme | +10 % critique |
| Armure de givre (FGG) | 4 PA, bouclier 14–20, +20 Intelligence | +1 portée | +20 Perception |
| Blizzard (GGG) | 4 PA, 6–9 Givre, −2 PM | −3 PM | cercle de 2 |
| Foudre en chaîne (TTT) | 4 PA, 9–12 Tempête + 2 rebonds | rebonds à 3 cases | 4e touché |
| Fulgurance (FTT) | 4 PA, téléportation + 7–10 Tempête et 3–5 Flamme | +1 portée | sans relance |
| Vent arrière (GTT) | 4 PA, +2 PM, +20 Agilité, inblocable | +3 PM | sans relance |
| Feu de brousse (FFT) | 4 PA, 7–10 Flamme, 3–4 Tempête, brûlure | brûlure 3 tours | +1 portée |
| Bourrasque glacée (GGT) | 4 PA, 6–9 Givre, 2–3 Tempête, poussée 3, −1 PM | poussée 4 | −2 PM |
| Cataclysme (FGT) | 4 PA, 3 × 5–7, −1 PM, poussée 1, relance 2 | relance 1 | −2 PM |

Sorts créés : +10 % par rang en plus.

## Sorts utilitaires (8)

Lancés directement ; affinité : bonus avec au moins un état de leur élément.

| Rôle | Sort | Élément | PA | Portée | Effet | Affinité | Rang 3 | Rang 5 |
|---|---|---|---|---|---|---|---|---|
| Mobilité | Clignement | Tempête | 2 | 1–3 | Téléportation ; relance 2 | +1 portée | relance 1 | +1 portée |
| Mobilité | Rétropropulsion | Flamme | 2 | 1 | 3–5 Flamme, recule de 3 ; relance 2 | recule de 4 | 1 PA | ennemis au contact au départ : 3–5 Flamme |
| Contrôle | Pieds gelés | Givre | 2 | 1–5 | −2 PM ; 2 par tour | −3 PM | +1 portée | enraciné 1 tour |
| Contrôle | Appel d'air | Tempête | 3 | 2–6 en ligne | Attire de 3 ; relance 1 | attire de 4 | 2 PA | voisins de la cible attirés d'1 |
| Défense | Mur de glace | Givre | 3 | 1–4 | 3 cases de glace 2 tours ; relance 3 | +1 tour | 5 cases | relance 2 |
| Défense | Manteau de braises | Flamme | 2 | soi | −4 dégâts subis, 3–5 épines Flamme, 2 tours ; relance 3 | −6 dégâts | 1 PA | +1 tour |
| Soutien | Conduction | ses états | 2 | 0–4 | +15 par état dans sa caractéristique, 2 tours ; relance 3 | — | +1 portée | relance 2 |
| Lié aux états | Écho arcanique | — | 2 | soi | 2e création dans le tour ; relance 3 | — | relance 2 | sort créé −1 PA au 1er lancer |

## Plus tard

- Équilibrage après les tests de l'auteur.
- IA qui compose les états (lot à part, sur demande) ; déblocage des fusions par paliers (après les tests).
- 3e Voie éventuelle : Lumière ou Ténèbres.
