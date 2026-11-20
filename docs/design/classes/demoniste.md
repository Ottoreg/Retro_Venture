# Démoniste — Impie / Flamme

**État** : conçu avec l'auteur et **codé le 20/11/2026** (GDD § 4.3, fil « Ajouter la classe Démoniste au jeu »,
`game/tests/core/test_demoniste.gd`, données `docs/design/demoniste/produire.py`). Valeurs (dégâts, PV des
serviteurs, rangs 3 et 5 des maîtrises) provisoires. **Passif à revoir** (il ne convient pas complètement à l'auteur).

## Identité

- Rôle : distance, se cache derrière ses serviteurs et tient le terrain par le feu. Fantaisie : « Démoniste agréé,
  ancien sous-traitant du Mordor. Ses démons pointent à l'heure (pas une minute de plus, la convention collective
  des Enfers est formelle) ; lui brûle tout ce qui refuse de signer. »
- Tenue orange à liseré noir ; toutes les races.
- Base commune à toutes les classes : 50 PV, 6 PA, 3 PM, 100 d'initiative.
- Caractéristiques : Agilité + Perception (Impie), Intelligence (Flamme).

## Passif de classe — Pacte de feu (Apprenti, 5 rangs, à revoir)

+6 % de dégâts (+1 % par rang), pour lui et ses serviteurs, contre une cible sur une case embrasée ou calcinée.
Rang 3 : un serviteur invoqué sur une case embrasée a +20 % de PV. Rang 5 : un 3e serviteur en même temps.

## Voie Impie — serviteurs (10 / 10)

Serviteurs **joués par le joueur** (pas par l'IA), juste après leur Démoniste, en solo, en mode héros et en ligne ;
2 en même temps. PV en % des PV max du Démoniste, PA et PM fixes, ses caractéristiques, leurs sorts au rang du sort
d'appel (rang 3 : +1 PM ; rang 5 : un sort de plus). Ils meurent avec lui et ne comptent pas pour la fin du combat ;
leurs actions font progresser le Démoniste.

| Sort | PA | Portée | Effet |
|---|---|---|---|
| Appel du Diablotin | 3 | 1–2 | Diablotin stagiaire (30 % des PV, 4 PA, 3 PM) : Coup de fourche ; rang 5 : Crachat de soufre. |
| Trait impie | 3 | 1–6 | Un trait de malédiction, signé en bas à droite. |
| Nuée de chauves-souris | 4 | 2–6 | Zone : une nuée qui mord tout ce qui passe, sauf les alliés. |
| Main du Malin | 5 | 1–3 | Gros coup : +20 % par serviteur vivant. |
| Sacrifice | 2 | 1–6 | Fait exploser un de ses serviteurs : dégâts autour, plus la moitié de ses PV restants. |
| Chaînes infernales | 3 | 1–5 | −2 PM. |
| Effroi | 3 | 1–4 | Repousse de 2 cases, −1 PA. |
| Permutation | 1 | 1–8 | Échange sa place avec un de ses serviteurs. |
| Appel du Molosse | 4 | 1–2 | Molosse de garde (80 % des PV, tacle) : Morsure ; rang 5 : Grognement (attire). |
| Appel de la Succube | 3 | 1–2 | Succube des RH (40 % des PV) : Soin des RH, Prime de motivation ; rang 5 : Pause café. |

## Voie Flamme — embrasement (10 / 10)

Chaque sort de la Voie embrase toutes les cases de sa zone (+1 niveau, 1 à 3, **calcinée** à la 4e fois) pour tout
le combat ; *Explosion de cendres* les remet à 0. Embrasement **séparé entre monde normal et Monde des ombres**.
Chaque sort lit la case visée : +10 % par niveau, et un effet propre sur une case calcinée. Un ennemi qui commence
son tour sur une case embrasée (pas calcinée) perd 2 × niveau PV (Flamme).

| Sort | PA | Portée | Effet | Sur case calcinée |
|---|---|---|---|---|
| Mise à feu | 2 | 1–6 | Zone, embrase de 2 niveaux. | −1 PM aux ennemis. |
| Escarbille | 2 | 1–7 | Petite boule de feu, 3 par tour. | Rend 1 PA. |
| Pluie de soufre | 4 | 3–8 | Zone à distance. | Brûlure 2 tours. |
| Fournaise | 5 | 1–4 | Gros coup de zone. | +50 % de dégâts. |
| Explosion de cendres | 3 | 1–6 | Dégâts par niveau de la zone (calcinée = 4), puis tout s'éteint. | — |
| Mur de flammes | 3 | 2–5 | Glyphe en travers, 1 tour + 1 par niveau. | Dégâts doublés tout de suite, sans mur. |
| Fumées âcres | 3 | 1–5 | −2 PM. | −2 de portée. |
| Pas de braise | 2 | 1–3 | Téléportation ; portée 6 vers une case embrasée. | +1 PM. |
| Peau de cendre | 2 | 0–0 | Bouclier. | Épines Flamme. |
| Feu de camp | 3 | 0–4 | Soins de zone aux alliés (serviteurs compris). | Soins doublés, sans rallumer. |

## Plus tard

- Revoir le passif Pacte de feu avec l'auteur.
- Planches PixelLab des serviteurs (prompts : `assets/demoniste/PROMPTS.md`) ; en attendant, gargouille et loup
  recoloriés, Succube sur le gabarit humain avec des ailes.
- Monstres invocateurs : pas pour l'instant.
- 3e Voie éventuelle : Lumière ou Ténèbres.
