# Guerrier — Acier / Impie

**État** : **complet, codé le 23/11/2026** (propositions validées telles quelles par l'auteur, valeurs provisoires ; GDD § 4.3,
données `docs/design/guerrier/produire.py`, tests `game/tests/core/test_guerrier.gd`).

## Identité

- Rôle : mêlée polyvalente, encaisse et rend les coups. Famille corps à corps.
- Fantaisie : *« Au contact, il encaisse et rend les coups. Réfléchit après, de préférence. »*
  Voie Impie : *« Chevalier d'un ordre dissous pour faute grave. Son épée est maudite, son assurance aussi : il paie chaque
  coup de son propre sang, puis se rembourse sur l'adversaire. »*
- Caractéristiques : Force (Acier) ; Agilité + Perception (Impie). Chaque Voie pure.
- Base : 50 PV, 6 PA, 3 PM, initiative 100.

## Passif de classe — Rancune (Apprenti, 5 rangs)

Chaque tranche de 5 PV perdus (coups reçus ou PV payés) donne un cran, gardé tout le combat : +3 % de dégâts par cran.

| Rang | Effet |
|---|---|
| 0–1 | 5 crans au plus (+15 %) |
| 2 | 6 crans au plus |
| 3 | 8 crans au plus ; les dégâts absorbés par un bouclier comptent aussi |
| 4 | 9 crans au plus |
| 5 | 10 crans au plus (+30 %) ; au 10e cran, le prochain coup de mêlée est critique |

Fendoir et Rage du damné dépensent tous les crans (+6 % de dégâts par cran).

## Voie Acier (10 / 10)

| Sort | Rôle | Base | Rang 3 | Rang 5 |
|---|---|---|---|---|
| Charge | Signature | 3 PA, 2–4 en ligne, fonce au contact, 6–9 Acier, relance 2 | +1 portée | relance 1 |
| Frappe | Dégâts de base | 3 PA, mêlée, 8–12 Acier, 2/tour | +5 % critique | −1 PM à la cible |
| Lancer de hache | Dégâts à distance | 4 PA, 2–5, 6–9 Acier | +1 portée | 3 PA |
| Tourbillon | Dégâts en zone | 4 PA, autour de soi, 7–10 Acier | poussée 1 | zone 2 |
| Fendoir | Gros coup, combo Rancune | 5 PA, mêlée, 16–22 Acier, +6 % par cran de Rancune (dépensés) | +5 % critique | 4 PA |
| Croc-en-jambe | Contrôle 1 | 2 PA, mêlée, 3–5 Acier, −2 PM, relance 2 | −3 PM | relance 1 |
| Crochet | Contrôle 2 | 3 PA, 2–4 en ligne, attire de 3 (jusqu'au contact), relance 2 | +1 portée | + 4–6 Acier |
| Recul stratégique | Mobilité | 2 PA, 1–3, saut sur une case libre sans tacle, relance 3 | +1 portée | relance 2 |
| Second souffle | Défense / soin | 2 PA, soin 12–18, relance 3 | relance 2 | + bouclier 9–14 |
| Cri de guerre | Soutien | 3 PA, +4–6 Dommages aux alliés à 2 cases, relance 4 | relance 3 | zone 3 |

## Voie Impie — chevalier maudit, Prix du sang (10 / 10)

Les sorts coûtent un % des PV max en plus des PA (« PV ») : ni bouclier ni résistance, jamais mortel (sort grisé), compte
pour la Rancune, pas comme des dégâts reçus.

| Sort | Rôle | PA | PV | Portée | Effet | Rang 3 | Rang 5 |
|---|---|---|---|---|---|---|---|
| Serment de sang | Signature | 1 | 15 % | soi | +2 PA ce tour, 1/tour, relance 2 | 12 % | relance 1 |
| Lame impie | Dégâts pas cher | 3 | 3 % | 1 | 7–11, vole 30 %, 2/tour | vole 40 % | +5 % critique |
| Onde funèbre | Distance / zone | 4 | 5 % | 2–4 | 6–9, cercle de 1, alliés compris | +1 portée | 3 PA |
| Exécution | Gros coup | 5 | 8 % | 1 | 15–21, +30 % sous 30 % des PV | +5 % critique | 4 PA |
| Rage du damné | Combo | 4 | — | 1 | 10–14, +1 % par % de PV manquant (60 %), dépense la Rancune (+6 %/cran) | 70 % | 3 PA |
| Regard du damné | Contrôle 1 | 2 | 3 % | 1–4 | −2 PA au prochain tour, relance 2 | −3 PA | relance 1 |
| Étreinte de la tombe | Contrôle 2 | 3 | 5 % | 1–2 | attire de 1, −3 PM, 4–6 volés, relance 3 | relance 2 | −4 PM |
| Pas du spectre | Mobilité | 2 | 5 % | 1–4 | téléportation sans ligne de vue, relance 2 | +1 portée | 0 PV |
| Armure de sang | Défense | 2 | — | soi | bouclier d'au moins 8 ou 2 × les PV payés ce tour, relance 3 | × 2,5 | relance 2 |
| Malédiction | Soutien | 3 | 5 % | 1–5 | −15 % de résistance Acier et Impie, 2 tours, relance 3 | 20 % | 3 tours |

Écart à la proposition : Armure de sang tient jusqu'au prochain tour du Guerrier (règle de tous les boucliers), pas 2 tours.

## Plus tard

- Aucun monstre ne joue la classe (pas d'IA propre) ; héros joués à la main.
- 3e Voie Lumière ou Ténèbres à trancher.
- Ajuster les valeurs après les tests de l'auteur.
