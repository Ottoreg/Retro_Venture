# Conception du contenu du chantier 3

Document complet, **entièrement validé par l'auteur** (révision 2 des mini-boss comprise). À la
production, chaque carte à groupes reçoit un calque `placement` (cases de départ en combat, voir
`game/data/README.md`) : `python3 tools/placement.py --ecrire <carte.json>` depuis `game/`, puis
retouches à la main si besoin.

- `chantier3_contenu.md` : le document (résumé en §1).
- `chantier3_contenu.json` : les mêmes données, prêtes pour la production (monstres, sorts, objets, cartes, récolte, recettes, dessins, avec leur lot).
- `src/` : les scripts qui génèrent les deux fichiers. Après une modification :
  `python3 src/build.py json && python3 src/controle.py`
  (`controle.py` vérifie les ids, les références, les sorties de cartes et les paliers).

## Retours de l'auteur

- **Révision 2** (validée) : tout était validé sauf les mini-boss, révisés ainsi :
  - réapparition en 60 s au plus (alpha : retester les mécaniques souvent) ;
  - plus de soin au changement de phase (risque de combat sans fin ; refusé aussi par le jeu) ;
  - des phases de profils différents tirés du thème de chaque boss, dans un ordre propre à chacun :
    Krasbouk mobilité puis rage (critiques, Dommages, mais −20 % de rés. Acier) ; le Balourd carapace
    (couvre sa faiblesse au Givre), embrasement, puis envol (PM, portée) ; la Mère-Toile toile et PM,
    cocon (couvre sa faiblesse à la Flamme), puis attaque (Chance, critiques) ; Grondin planches
    (bouclier), charge (nouveau sort `grondin_charge`), puis roues cassées (Force +40, PM −2) ;
  - PV des trois mini-boss de niveau 12 portés à 300 pour compenser le soin et les boucliers retirés.
  - XP : multipliée par 3,5 dans le jeu pour l'alpha 1 (tout le contenu en 4 à 5 h) ; la question
    « 1 → 12 en 2,7 h » est donc close pour l'alpha 1.
