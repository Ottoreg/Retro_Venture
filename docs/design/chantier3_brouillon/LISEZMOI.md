# Conception du contenu du chantier 3

Document complet, **à relire et valider** avant la production.

- `chantier3_contenu.md` : le document (résumé en §1).
- `chantier3_contenu.json` : les mêmes données, prêtes pour la production (monstres, sorts, objets, cartes, récolte, recettes, dessins, avec leur lot).
- `src/` : les scripts qui génèrent les deux fichiers. Après une modification :
  `python3 src/build.py json && python3 src/controle.py`
  (`controle.py` vérifie les ids, les références, les sorties de cartes et les paliers).
