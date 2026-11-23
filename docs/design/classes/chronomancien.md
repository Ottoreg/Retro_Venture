# Chronomancien — Impie / Givre

**État** : conçu avec l'auteur (document de 22 questions du 21/11/2026, propositions validées telles quelles le 23/11/2026)
et **codé le 23/11/2026** (GDD § 4.3, `game/tests/core/test_chronomancien.gd` et `test_chronomancien_temps.gd`). Valeurs
provisoires, à ajuster après les tests de l'auteur. Données produites par `docs/design/chronomancien/produire.py` ; captures
`docs/captures/chronomancien/`.

## Identité

- Rôle : contrôle à mi-distance. Fantaisie : « Dérègle le temps avec des pouvoirs impies. Toujours en avance, ou en retard,
  mais jamais à l'heure. »
- Base commune : 50 PV, 6 PA, 3 PM, 100 d'initiative. Impie = Agilité + Perception ; Givre = Perception. Pas de vrai soin.
- **Manipulation temporelle** : heure atteinte sur un cadran (pose de l'Horloge comprise), pulsion posée, retour à une case
  passée, envoi dans le futur. Compteur par cible pour le combat, affiché « Manipulé N fois ».

## Passif de classe — Temps volé (Apprenti, 5 rangs)

Chaque manipulation infligée à un ennemi vole une seconde (5 au plus, jusqu'à la fin de son prochain tour) : +2 % de
dommages par seconde (+1 % par rang). Rang 3 : à 5 secondes, il les dépense pour +1 PA au début de son prochain tour
(une fois par tour). Rang 5 : 7 secondes au plus.

## Voie Impie — Horloge (10 / 10)

| Sort | Rôle | Base | Rang 3 | Rang 5 |
|---|---|---|---|---|
| Horloge | Signature | 3 PA, exactement 3 en ligne, 3–5 Impie, cadran 3 tours | cadran 4 tours | portée 3 ou 4 |
| Tic / Tac | Dégâts | 2 PA, 1–6, 4–6 Impie, ±1 h, 2/tour | 3 fois par tour | une heure de plus en critique |
| Avance rapide / Retour en arrière | Dégâts | 4 PA, 1–6, 9–12 Impie, ±3 h | +10 % critique | 3 PA |
| Contretemps | Gros coup / contrôle | 3 PA, 1–6, 6–8 Impie, +6 h, relance 2 | relance 1 | 2 PA |
| Arrêt sur image | Contrôle | 2 PA, 1–6 : la dernière heure atteinte rejoue son effet, relance 1 | 1 PA | sans relance |
| Rendez-vous | Mobilité | 2 PA, 1–5 : échange de place avec un combattant, relance 2 | +1 portée | relance 1 |
| Sursis | Défense | 3 PA, soi : rend 50 % des PV perdus depuis le début de son tour précédent, relance 3 | 2 PA | relance 2 |
| Accélération | Soutien | 2 PA, 0–3 : +1 PM, +20 Agilité, +20 Perception (2 tours), relance 3 | +1 portée | relance 2 |

## Voie Givre — le temps comme entrave (10 / 10)

| Sort | Rôle | Base | Rang 3 | Rang 5 |
|---|---|---|---|---|
| Pulsion temporelle | Signature | 3 PA, 1–6 : 12–16 Givre au début du 2e tour de la cible (3 au plus), 2/tour | +10 % critique | 2 PA |
| Seconde glacée | Dégâts pas cher | 2 PA, 1–6, 4–6 Givre, 3/tour | +10 % critique | +1 portée |
| Hiver éternel | Zone | 4 PA, 2–6, cercle de 1, 6–8 Givre | 3 PA | −1 PM |
| Fin des temps | Gros coup | 5 PA, 1–4, 18–24 Givre | +1 portée | 4 PA |
| Écho du passé | Combiné à la signature | 3 PA, 1–6, 3–4 Givre par manipulation subie (6 au plus) | +10 % critique | 2 PA |
| Déjà-vu | Contrôle | 3 PA, 1–6 : retour à sa case d'il y a 1 tour, −1 PM, relance 2 | relance 1 | −1 PA |
| Saut dans le futur | Contrôle | 3 PA, 1–5 : ennemi 2 tours dans le futur, relance 3 | +1 portée | relance 2 |
| Point de départ | Mobilité | 1 PA, soi : retour à sa case du début de ce tour, relance 2 | relance 1 | +1 PM |
| Cristal du temps | Défense | 2 PA, soi : bouclier Givre 12–16, inamovible 1 tour, relance 2 | 1 PA | +10 % rés. Givre |
| Heure d'avance | Soutien | 2 PA, 0–4 : lui ou un allié avance de 1 tour, relance 3 | +1 portée | relance 2 |

## Règles

- Mémoire : case et PV au début des 3 derniers tours. Retour sur case occupée : échange ; obstacle ou inamovible : case
  libre la plus proche ; l'heure du cadran ne change pas.
- Envoi dans le futur : relances −N, poisons infligés d'un coup, pulsions de ce délai explosées, malus (et bonus d'un
  ennemi) écoulés ; états non retirables intacts ; un boss n'écoule que poisons et pulsions.
- Monde des ombres : un retour ne change pas de dimension ; les pulsions suivent leur cible.

## Plus tard

Équilibrage après les tests ; planches PixelLab (violet impie, bleu givre) ; aucun monstre ne joue ces mécaniques ;
3e Voie Lumière ou Ténèbres à trancher.
