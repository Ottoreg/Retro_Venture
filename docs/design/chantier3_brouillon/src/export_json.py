"""Export JSON de la conception : les données prêtes à copier dans game/data pendant la production."""
import json, os
from common import OBJETS, SPELLS, REUSED

CLES_CARTE = ["id", "nom", "existante", "palier", "x", "y", "pierre", "boss", "sorties", "portes", "ressources",
              "groupes", "decors", "pnj", "ambiance", "elements"]


def export(zones, extra):
    import build, transverse
    prop = transverse.proprietaires()
    m = extra["metiers"]
    data = {
        "monstres": [dict(j, lot=prop.get(j["id"], "?")) for j in build.all_monsters_json()],
        "sorts": [dict(s) for s in SPELLS.values()],
        "sorts_reutilises": sorted(REUSED),
        "objets": [dict(o, lot=transverse.lot_objet(o)) for o in OBJETS.values()],
        "cartes": [dict({k: c[k] for k in CLES_CARTE if k in c}, zone=z["id"]) for z in zones for c in z["cartes"]],
        "pierres": [z["pierre"] for z in zones],
        "recolte": m.NOEUDS if m else [],
        "recettes": m.RECETTES if m else [],
        "dessins": [{"zone": zz, "pour": n, **a} for zz, n, a in transverse.dessins()],
    }
    path = os.path.join(os.path.dirname(__file__), "..", "chantier3_contenu.json")
    with open(path, "w") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    return path
