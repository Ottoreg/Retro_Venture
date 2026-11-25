"""Retouches de cartes faites par l'auteur dans l'éditeur (docs/outils/editeur_cartes.html), demande du 25/11/2026 :
reportées sur les cartes après chaque script qui les produit, pour qu'aucune relance ne les efface.
cartes.json : id de carte → plan retouché (et ses groupes, pour garder les chiffres du plan d'accord avec eux).
Puis docs/design/groupes/tailles.py (petit, moyen et grand groupe). Lancé à la fin de produire_sous_zone.py et de
grandes_plaines/ampas.py ; à la main, depuis la racine du dépôt : python3 docs/design/retouches/appliquer.py"""
import json, os, runpy
ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.join(ICI, "..", "..", "..", "game")
for id_, retouche in json.load(open(os.path.join(ICI, "cartes.json"), encoding="utf-8")).items():
    chemin = os.path.join(JEU, "data", "cartes", f"{id_}.json")
    carte = json.load(open(chemin, encoding="utf-8"))
    carte.update({k: v for k, v in retouche.items() if k in ("plan", "groupes")})
    json.dump(carte, open(chemin, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
runpy.run_path(os.path.join(ICI, "..", "groupes", "tailles.py"))
