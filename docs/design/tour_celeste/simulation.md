# Tour céleste réduite : combats simulés (04/11/2026)

Par `game/tools/simulation.gd` (20 combats par salle, sixième argument `trio` : guerrier + rôdeur + théologue joués par l'IA, au niveau moyen des monstres, celui du boss au sommet ; « Rapport PV » compare au modèle d'un joueur seul, à lire avec prudence pour un trio).

## Trio au niveau des monstres

| Carte | Groupe | Niv. | Victoires (G+R+T) | Tours (réf.) | PV perdus % (réf.) | Rapport PV | Facteur | Rép./combat | |
|---|---|---|---|---|---|---|---|---|---|
| celeste_0_0 | Cupidon | 3 | 100 | 4.8 (1.1) | 9 (20) | 0.47 | 0.10 | 2 |  |
| tour_celeste_1 | Colombe baptiste, Ange | 7 | 90 | 8.9 (5.4) | 49 (80) | 0.62 | 0.64 | 60 |  |
| tour_celeste_2 | Lion de Juda, Ange, Colombe baptiste | 10 | 35 | 13.1 (6.0) | 62 (80) | 0.77 | 0.65 | 70 | ⚠ |
| tour_celeste_3 | Lion de Juda, Colombe baptiste | 13 | 90 | 15.7 (6.6) | 52 (80) | 0.65 | 0.65 | 85 |  |
| tour_celeste_4 | Ange, Lion de Juda | 11 | 20 | 11.2 (6.2) | 54 (80) | 0.67 | 0.64 | 82 | ⚠ |
| tour_celeste_5 | Archange Raphaël, Ange, Lion de Juda, Colombe baptiste | 18 | 25 | 22.0 (7.6) | 47 (80) | 0.58 | 0.43 | 47 | ⚠ |

## Trio avec 3 niveaux d'avance

| Carte | Groupe | Niv. | Victoires (G+R+T) | Tours (réf.) | PV perdus % (réf.) | Rapport PV | Facteur | Rép./combat | |
|---|---|---|---|---|---|---|---|---|---|
| tour_celeste_1 | Colombe baptiste, Ange | 10 | 100 | 7.2 (6.0) | 41 (80) | 0.51 | 0.43 | 33 |  |
| tour_celeste_2 | Lion de Juda, Ange, Colombe baptiste | 13 | 80 | 15.2 (6.6) | 57 (80) | 0.71 | 0.50 | 54 |  |
| tour_celeste_3 | Lion de Juda, Colombe baptiste | 16 | 100 | 11.6 (7.2) | 43 (80) | 0.54 | 0.53 | 71 |  |
| tour_celeste_4 | Ange, Lion de Juda | 14 | 55 | 13.1 (6.8) | 60 (80) | 0.75 | 0.50 | 57 | ⚠ |
| tour_celeste_5 | Archange Raphaël, Ange, Lion de Juda, Colombe baptiste | 21 | 40 | 17.2 (8.2) | 49 (80) | 0.61 | 0.34 | 37 | ⚠ |

## Chaque Voie seule (10 combats ; G/A/R/T/C)

| Carte | Groupe | Niv. | Victoires (G/A/R/T/C) | Tours (réf.) | PV perdus % (réf.) | Rapport PV | Facteur | Rép./combat | |
|---|---|---|---|---|---|---|---|---|---|
| celeste_0_0 | Cupidon | 3 | 0/0/90/100/100 | 5.4 (1.1) | 19 (20) | 0.95 | 0.50 | 23 | ⚠ |
| tour_celeste_1 | Colombe baptiste, Ange | 7 | 0/0/0/0/10 | 6.0 (5.4) | 99 (80) | 1.24 | 1.50 | 234 | ⚠ |
| tour_celeste_2 | Lion de Juda, Ange, Colombe baptiste | 10 | 0/0/0/0/10 | 10.0 (6.0) | 90 (80) | 1.13 | 1.50 | 346 | ⚠ |
| tour_celeste_3 | Lion de Juda, Colombe baptiste | 13 | 0/0/0/20/60 | 19.8 (6.6) | 25 (80) | 0.31 | 1.50 | 429 | ⚠ |
| tour_celeste_4 | Ange, Lion de Juda | 11 | 0/0/0/0/0 | 0.0 (6.2) | 0 (80) | 0.00 | 1.50 | 0 | ⚠ |
| tour_celeste_5 | Archange Raphaël, Ange, Lion de Juda, Colombe baptiste | 18 | 0/0/0/0/30 | 10.0 (7.6) | 53 (80) | 0.67 | 1.33 | 402 | ⚠ |
