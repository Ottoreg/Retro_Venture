"""Production des sous-zones de race (GDD § 3.5, conception dans ce dossier), une à la fois.

    python3 docs/design/sous_zones/produire_sous_zone.py <sous-zone>      (depuis la racine du dépôt)

Écrit dans game/ : monstres, sorts, ressources, cartes (plans dessinés par les outils du chantier 3,
calque de placement), maison, Pierre de Passage, quêtes, fragment de manifeste art/manifestes/sous_zones.json ;
ouvre les bords des cartes existantes qui y mènent et change la carte de départ de la race.
Relancer réécrit les mêmes fichiers.
"""
import json, os, sys
ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(ICI, "..", "chantier3_brouillon", "src"))
from cartes import Plan, JEU, LIGNES, COLONNES, verifier, proposer  # noqa: E402

def lire(chemin):
    with open(os.path.join(JEU, chemin), encoding="utf-8") as f:
        return json.load(f)

def ecrire(chemin, donnees):
    chemin = os.path.join(JEU, chemin)
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=2)
        f.write("\n")

def sort(id, nom, desc, pa, portee, effets, par_tour=1, delai=0, zone=None, ldv=True):
    s = {"id": id, "nom": nom, "description": desc, "cout_pa": pa, "portee": {"min": portee[0], "max": portee[1]},
         "ligne_de_vue": ldv, "relance": {"par_tour": par_tour} | ({"delai": delai} if delai else {}), "effets": effets}
    if zone:
        s["zone"] = zone
    return s

def deg(el, a, b, **k): return {"type": "degats", "element": el, "min": a, "max": b} | k
def bonus(carac, v, duree, **k): return {"type": "bonus", "carac": carac, "min": v, "max": v, "duree": duree} | k
def ressource(id, nom, rarete, palier, carac, famille, zone, desc):
    return {"id": id, "nom": nom, "type": "ressource", "rarete": rarete, "niveau": palier, "description": desc,
            "caracteristique": carac, "famille": famille, "zone": zone}

def monstre(id, nom, desc, palier, pv, pa, pm, init, carac, res, sorts, xp, ecus, butin, ia="basique", **k):
    return {"id": id, "nom": nom, "description": desc, "palier": palier,
            "caracteristiques": {"pv": pv, "pa": pa, "pm": pm, "initiative": init} | carac,
            "resistances": res, "sorts": sorts, "ia": ia, "xp": xp, "butin": butin, "ecus": ecus} | k
def drop(objet, taux, q=None): return {"objet": objet, "taux": taux} | ({"quantite": q} if q else {})
def pnj(m, id, nom, repliques, art, **k): return {"marqueur": m, "id": id, "nom": nom, "repliques": repliques, "art": art} | k
def objectif_vaincre(m, n): return {"type": "vaincre", "monstre": m, "nombre": n}
TUTORIELS = ["brumerive_tutoriel", "crasse_roc_tutoriel", "sylvebrume_tutoriel"]

COTES = {"droite": (1, 0), "gauche": (-1, 0), "bas": (0, 1), "haut": (0, -1)}
OPPOSE = {"droite": "gauche", "gauche": "droite", "bas": "haut", "haut": "bas"}
OUVERTURE = {"haut": (0.40, 0.60), "bas": (0.40, 0.60), "gauche": (0.36, 0.64), "droite": (0.36, 0.64)}

def dessiner(c, sz, sorties, graine):
    """Plan d'une carte : bord du thème ouvert sur ses sorties, obstacles, eau, chemin, occupants."""
    p = Plan(graine)
    p.bord(sz["bord"], **{k: OUVERTURE[k] for k in sorties})
    for car, n in c.get("obstacles", sz["obstacles"]):
        p.semer(car, n, lambda u, v: 0.1 < u < 0.9 and 0.12 < v < 0.88 and abs(u - 0.5) + abs(v - 0.5) > 0.12)
    if c.get("eau"):
        cu, cv, ru, rv = c["eau"]
        p.peindre("E", lambda u, v: ((u - cu) / ru) ** 2 + ((v - cv) / rv) ** 2 < 1, sur=".")
    for cote in sorties:  # chemins du centre vers chaque sortie
        dx, dy = COTES[cote]
        p.peindre(":", lambda u, v, dx=dx, dy=dy: (abs(v - 0.5) < 0.02 and (u - 0.5) * dx >= 0) if dx
                  else (abs(u - 0.5) < 0.02 and (v - 0.5) * dy >= 0), sur=".RAE")
    portes = []
    if c.get("depart"):
        i, j = p.decor("maison", 0.3, 0.32)
        p.g[i][j + 1] = "+"
        portes = [sz["maison"]]
        p.poser("*", 0.6, 0.4)
    p.poser("@", 0.5, 0.5, sur=".:")
    for k, (u, v) in enumerate(c.get("pnj_pos", [])):
        p.poser(c["pnj"][k]["marqueur"], u, v)
    places = [(0.25, 0.7), (0.75, 0.3), (0.75, 0.75), (0.25, 0.25), (0.5, 0.82)]
    for k in range(len(c["groupes"])):
        p.poser(str(k + 1), *places[k])
    for car, n in c.get("ressources", ()):
        p.semer(car, n)
    p.boucher(sz["bord"])
    return p, portes

def ouvrir(carte_id, cote, cible):
    """Ouvre le bord `cote` d'une carte existante vers `cible` et creuse jusqu'à une case praticable."""
    carte = lire(f"data/cartes/{carte_id}.json")
    g = [list(l) for l in carte["plan"]]
    bloque = "ARMEFCUIYT"
    def libre(i, j): return g[i][j] in ".:@123456789+abcdefghijklmnopqrstuvwxyz"
    if cote in ("gauche", "droite"):
        for i in range(int(LIGNES * 0.38), int(LIGNES * 0.62) + 1):
            cols = range(1 if i % 2 else 0, COLONNES) if cote == "gauche" else range(COLONNES - 1, 0, -1)
            for j in cols:
                if libre(i, j): break
                if g[i][j] in bloque: g[i][j] = "."
                elif g[i][j] != " ": break
    else:
        for j in range(int(COLONNES * 0.4), int(COLONNES * 0.6) + 1):
            rows = range(LIGNES) if cote == "haut" else range(LIGNES - 1, -1, -1)
            for i in rows:
                if libre(i, j): break
                if g[i][j] in bloque: g[i][j] = "."
                elif g[i][j] != " ": break
    carte["plan"] = ["".join(l) for l in g]
    carte["sorties"][cote] = cible
    verifier(carte_id, carte["plan"])
    ecrire(f"data/cartes/{carte_id}.json", carte)

def explications(carte_id):
    """Explications de la forge et des Voies des PNJ de la carte de départ du camp (reprises telles quelles)."""
    pnj = [p for p in lire(f"data/cartes/{carte_id}.json")["pnj"] if p.get("explication")]
    forge = next(p["explication"] for p in pnj if "enclume" in " ".join(p["explication"]))
    voies = next(p["explication"] for p in pnj if "réputation" in " ".join(p["explication"]))
    return forge, voies

def produire(sz):
    zone = sz["zone"]
    for s in sz["sorts"]:
        ecrire(f"data/sorts/{s['id']}.json", s)
    for o in sz["ressources"]:
        ecrire(f"data/objets/{o['id']}.json", o)
    for m in sz["monstres"]:
        ecrire(f"data/monstres/{m['id']}.json", m)
    forge, voies = explications(sz["camp_depart"])
    cartes = {c["xy"]: c for c in sz["cartes"]}
    for (x, y), c in cartes.items():
        sorties = {}
        for cote, (dx, dy) in COTES.items():
            voisin = (x + dx, y + dy)
            if voisin in cartes and (voisin in c.get("liens", ()) or (x, y) in cartes[voisin].get("liens", ())):
                sorties[cote] = f"{zone}_{voisin[0]}_{voisin[1]}"
        for cote, existante in c.get("vers", {}).items():
            sorties[cote] = existante
            ouvrir(existante, OPPOSE[cote], f"{zone}_{x}_{y}")
        plan, portes = dessiner(c, sz, sorties, sum(map(ord, c["nom"])))
        texte = plan.texte()
        carte = {"id": f"{zone}_{x}_{y}", "nom": f"{sz['prefixe']} — {c['nom']}", "palette": c.get("palette", sz["palette"]),
                 "sorties": sorties}
        if portes:
            carte["portes"] = portes
        carte["plan"] = texte
        carte["groupes"] = c["groupes"]
        if c.get("pnj"):
            carte["pnj"] = [{k: v for k, v in p.items() if k not in ("art", "explique")}
                            | ({"explication": forge if p["explique"] == "forge" else voies} if p.get("explique") else {})
                            for p in c["pnj"]]
        if plan.decors:
            carte["decors"] = plan.decors
        carte["placement"] = proposer(texte)
        verifier(carte["id"], texte)
        ecrire(f"data/cartes/{carte['id']}.json", carte)
    depart = next(f"{zone}_{x}_{y}" for (x, y), c in cartes.items() if c.get("depart"))
    maison = lire(f"data/cartes/{sz['maison_modele']}.json") | {"id": sz["maison"], "portes": [depart]}
    ecrire(f"data/cartes/{sz['maison']}.json", maison)
    ecrire(f"data/passages/{sz['passage']['id']}.json", sz["passage"] | {"carte": depart})
    for race in sz["races"]:
        r = lire(f"data/races/{race}.json")
        r["carte_depart"] = depart
        ecrire(f"data/races/{race}.json", r)
    for q in sz["quetes"]:
        ecrire(f"data/quetes/{q['id']}.json", q)
    for o in sz.get("objets_quete", []):
        ecrire(f"data/objets/{o['id']}.json", o)
    chemin = "art/manifestes/sous_zones.json"
    frag = lire(chemin) if os.path.exists(os.path.join(JEU, chemin)) else {}
    frag.setdefault("monstres", {}).update(sz["art_monstres"])
    frag.setdefault("images", {}).update({f"objet_{o}": {"fichier": f"objets/{f}.svgt", "ancre": [22, 22]} for o, f in sz.get("icones", {}).items()})
    frag.setdefault("pnj", {}).update({p["id"]: p["art"] for c in sz["cartes"] for p in c.get("pnj", [])})
    ecrire(chemin, frag)
    print(f"{sz['id']} : {len(cartes)} cartes, {len(sz['monstres'])} monstres, {len(sz['sorts'])} sorts, "
          f"{len(sz['ressources'])} ressources, {len(sz['quetes'])} quêtes ; départ {depart}")

if __name__ == "__main__":
    import importlib
    nom = sys.argv[1] if len(sys.argv) > 1 else ""
    produire(importlib.import_module(f"sz_{nom}").SOUS_ZONE)
