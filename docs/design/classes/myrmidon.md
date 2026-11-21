# Myrmidon — Acier / Givre

**État** : conçu avec l'auteur (propositions validées telles quelles, à ajuster après ses tests) et **codé le 21/11/2026**
(GDD § 4.3, fil « Ajouter la classe Myrmidon au jeu », `game/tests/core/test_myrmidon.gd`). Valeurs provisoires.
Données produites par `docs/design/myrmidon/produire.py`.

## Identité

- Rôle : tank, famille corps à corps. Fantaisie : « Myrmidon de la Légion des Boucliers Réglementaires. A juré de ne jamais
  reculer, surtout parce qu'on ne lui a jamais appris la marche arrière. »
- Tenue gris acier à liseré bleu glacier ; toutes les races.
- Base commune à toutes les classes : 50 PV, 6 PA, 3 PM, 100 d'initiative.
- Caractéristiques : Force (Acier pur), Perception (Givre pur) ; aucun sort multi-élément. Vitalité : rien de spécial.
- Beaucoup de moyens d'arriver au contact (Bélier, Glissade, Défi qui attire), aucun pour s'éloigner ; pas de partage de résistances.

## Provocation

État **Provoqué** : l'IA d'un monstre provoqué vise le Myrmidon s'il peut le frapper, sinon marche vers lui ; tout provoqué
(un joueur reste libre de ses clics) fait −20 % de dégâts à tout autre que le Myrmidon. Boss et mini-boss : malus divisé
par 2, IA libre.

## Passif de classe — Point de mire (Apprenti, 5 rangs)

Aura de 2 cases : un ennemi qui y commence son tour est provoqué pendant ce tour ; malus −20 % (+2 % par rang).
Rang 3 : aura de 3 cases. Rang 5 : un provoqué qui le frappe au contact subit un contrecoup de 10 % des dégâts.

## Voie Acier — Blindage (10 / 10)

Chaque sort de dégâts Acier donne 1 cran de Blindage (5 au plus, 3 tours, rafraîchis) : +4 % de résistance à tous les éléments par cran.

| Rôle | Sort | PA | Portée | Effet |
|---|---|---|---|---|
| Signature | Serrer les rangs | 1 | soi | +2 crans de Blindage, 1 fois par tour |
| Dégâts pas cher | Coup de bouclier | 3 | 1 | dégâts Acier |
| Distance / zone | Bouclier lancé | 4 | 2–5 | dégâts Acier, rebondit sur un 2e ennemi à 2 cases |
| Gros coup | Écrasement | 5 | 1 | gros dégâts Acier |
| Combo signature | Retour à l'envoyeur | 4 | 1 | +20 % par cran de Blindage, consomme tous les crans |
| Contrôle 1 | Coup d'épaule | 2 | 1 | pousse de 2 cases, dégâts faibles |
| Contrôle 2 | Démolition | 3 | 1–2 | démolit un arbre ou un rocher ; les débris blessent autour (cercle de 1) |
| Mobilité | Bélier | 3 | 2–5 en ligne | charge jusqu'au contact en renversant le premier arbre ou rocher du chemin |
| Défense | Peau de fer | 2 | soi | 5 de réduction de dégâts 2 tours, relance 3 |
| Soutien | Garde | 2 | 1–3 allié | 2 tours : la moitié des dégâts de sort de l'allié va au Myrmidon (ses résistances) ; en groupe ou mode héros |

## Voie Givre — Gelures (10 / 10)

Chaque sort Givre pose 1 Gelure (3 au plus, 3 tours) : −1 PM par Gelure au début du tour de la cible (esquive comprise) ;
à 3 Gelures, elle est gelée (0 PM ce tour) et elles retombent à 0.

| Rôle | Sort | PA | Portée | Effet |
|---|---|---|---|---|
| Signature | Morsure du froid | 2 | 1–2 | dégâts faibles, +1 Gelure (+2 au rang 5) |
| Dégâts pas cher | Coup glacé | 3 | 1 | dégâts Givre |
| Distance / zone | Souffle hivernal | 4 | 1–3, ligne | dégâts aux ennemis de la ligne, gèle l'eau |
| Gros coup | Avalanche | 5 | 1 | gros dégâts, cercle de 1 autour de la cible |
| Combo signature | Bris de glace | 4 | 1 | +25 % par Gelure, qui tombent |
| Contrôle 1 | Entrave | 2 | 1–4 | −2 PM |
| Contrôle 2 | Coup sur le casque | 3 | 1 | assomme : prochain tour passé ; relance 5, une fois par cible ; boss −3 PA |
| Mobilité | Glissade | 3 | 2–5 en ligne | glisse jusqu'au contact en gelant l'eau du chemin |
| Défense | Carapace de glace | 2 | soi | bouclier ; qui le frappe au contact prend une Gelure |
| Soutien | Défi | 2 | 1–5 | attire de 2 cases et provoque 2 tours |

## Terrain

Arbres et rochers d'une case démolis pour le reste du combat (ligne de vue comprise ; jamais murs, bâtiments, coffres,
ressources, eau) ; la carte d'exploration ne change pas. Eau gelée (pas les coins de pêche) : praticable 3 tours du
lanceur, pour tout le monde ; au dégel, qui est dessus va sur la case libre la plus proche.

## Plus tard

- Geler les trous quand des cartes en auront.
- Animations propres (PixelLab) ; en attendant, les sorts jouent l'attaque de la race (planches recoloriées).
- IA propre si un monstre joue un jour la classe.
- 3e Voie éventuelle : Lumière (bouclier-miroir) ou Ténèbres (rempart d'ombre).
