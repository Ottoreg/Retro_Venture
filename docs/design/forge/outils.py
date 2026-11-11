"""Outils forgés (GDD § 10.4, statistiques de métier) : modèles `forge_<type>` de type « outil » et leurs dessins
provisoires (dessins d'armes forgées réutilisés). Idempotent : python3 docs/design/forge/outils.py depuis la racine."""
import json, pathlib

JEU = pathlib.Path(__file__).resolve().parents[3] / "game"
OUTILS = {  # type → (nom, métier, dessin réutilisé)
    "pioche": ("Pioche", "mineur", "forge_masse"),
    "hache": ("Hache", "bucheron", "forge_dague"),
    "faucille": ("Faucille", "agriculteur", "forge_dague"),
    "serpe": ("Serpe", "herboriste", "forge_dague"),
    "canne_a_peche": ("Canne à pêche", "pecheur", "forge_baton"),
    "marteau_de_forgeron": ("Marteau de forgeron", "forgeron", "marteau_enclume_rancuniere"),
}
images = {}
for type_, (nom, metier, dessin) in OUTILS.items():
    oid = "forge_" + type_
    modele = {"id": oid, "nom": nom, "type": "outil", "metier": metier, "rarete": "commun", "niveau": 1, "boutique": False,
              "description": "Outil forgé à l'enclume : ses statistiques de métier ne servent qu'au métier de %s." % metier}
    (JEU / "data/objets" / (oid + ".json")).write_text(json.dumps(modele, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    images["objet_" + oid] = {"fichier": "objets/%s.svgt" % dessin, "ancre": [22, 22]}
(JEU / "art/manifestes/outils.json").write_text(json.dumps({"images": images}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
