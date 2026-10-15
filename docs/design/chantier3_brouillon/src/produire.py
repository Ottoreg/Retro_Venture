"""Production d'un lot du chantier 3 : écrit ses données dans game/ d'après chantier3_contenu.json.

    python3 src/produire.py <lot>          (depuis docs/design/chantier3_brouillon)

Écrit, pour le lot : les monstres (game/data/monstres), les sorts nouveaux qu'ils utilisent
(game/data/sorts), les objets (game/data/objets, sans les champs de conception « source »,
« icone », « lot ») et le fragment de manifeste game/art/manifestes/<lot>.json (apparence des
monstres et des PNJ du lot qui n'en ont pas encore). Les cartes, les dessins (.svgt) et les icônes
se font à la main : le script liste ce qui reste à faire. Relancer le script réécrit ces fichiers.
"""
import json
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.normpath(os.path.join(ICI, "..", "..", "..", ".."))
JEU = os.path.join(RACINE, "game")
CHAMPS_CONCEPTION = ("source", "icone", "lot")


def ecrire(chemin, donnees):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main(lot):
    with open(os.path.join(ICI, "..", "chantier3_contenu.json"), encoding="utf-8") as f:
        d = json.load(f)
    with open(os.path.join(JEU, "art", "art.json"), encoding="utf-8") as f:
        art = json.load(f)
    sorts = {s["id"]: s for s in d["sorts"]}
    monstres = [m for m in d["monstres"] if m["lot"] == lot]
    objets = [o for o in d["objets"] if o["lot"] == lot]
    if not monstres and not objets:
        sys.exit(f"lot inconnu ou vide : {lot}")

    # Monstres et sorts nouveaux qu'ils utilisent (phases comprises).
    utilises = []
    for m in monstres:
        ecrire(os.path.join(JEU, "data", "monstres", m["id"] + ".json"), {k: v for k, v in m.items() if k != "lot"})
        for s in m.get("sorts", []) + [s for p in m.get("phases", []) for s in p.get("sorts", [])]:
            if s in sorts and s not in utilises:
                utilises.append(s)
    for s in utilises:
        ecrire(os.path.join(JEU, "data", "sorts", s + ".json"), sorts[s])
    for o in objets:
        ecrire(os.path.join(JEU, "data", "objets", o["id"] + ".json"),
               {k: v for k, v in o.items() if k not in CHAMPS_CONCEPTION})

    # Fragment du manifeste : apparences nouvelles (celles d'art.json restent où elles sont).
    par_nom = {m["nom"]: m["id"] for m in d["monstres"]}
    fragment_chemin = os.path.join(JEU, "art", "manifestes", lot + ".json")
    fragment = {}
    if os.path.exists(fragment_chemin):
        with open(fragment_chemin, encoding="utf-8") as f:
            fragment = json.load(f)
    a_dessiner = []
    for x in d["dessins"]:
        if x["zone"] != lot:
            continue
        mid = par_nom.get(x["pour"])
        if mid and mid not in art["monstres"]:
            fragment.setdefault("monstres", {})[mid] = x["manifeste"]
        if x.get("nouveau_svg"):
            a_dessiner.append(f"{x['pour']} : {x['nouveau_svg']}")
    for c in d["cartes"]:
        if c["zone"] != lot:
            continue
        for p in c.get("pnj", []):
            if p.get("art") and p["id"] not in art["pnj"]:
                fragment.setdefault("pnj", {})[p["id"]] = p["art"]
    ecrire(fragment_chemin, fragment)

    print(f"{lot} : {len(monstres)} monstres, {len(utilises)} sorts, {len(objets)} objets, fragment {fragment_chemin}")
    icones = [o["id"] for o in objets if "objet_" + o["id"] not in art["images"]
              and "objet_" + o["id"] not in fragment.get("images", {})]
    if icones:
        print("Icônes à dessiner (art/objets/<id>.svgt, 44 × 44) :")
        for o in objets:
            if o["id"] in icones:
                print(f"  {o['id']} : {o['icone']}")
    if a_dessiner:
        print("Dessins nouveaux :")
        for ligne in a_dessiner:
            print("  " + ligne)
    print("Cartes (plan, calque de placement, à la main) :",
          ", ".join(c["id"] for c in d["cartes"] if c["zone"] == lot and not c["existante"]))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "")
