"""Contrôle mécanique de la conception : ids, références, sorties de cartes, paliers.

Usage : python3 src/controle.py  (code de sortie 1 s'il reste des problèmes)
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import build
from common import OBJETS, SPELLS, REUSED

DATA = os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "game", "data")
OPPOSE = {"haut": "bas", "bas": "haut", "gauche": "droite", "droite": "gauche"}
PALIERS_DEPART = ["1-3", "4-6", "7-9", "10-12"]
problemes = []


def existants(dossier):
    d = os.path.join(DATA, dossier)
    return {f[:-5] for f in os.listdir(d) if f.endswith(".json")} if os.path.isdir(d) else set()


ex_objets, ex_sorts, ex_monstres, ex_cartes = (existants(d) for d in ("objets", "sorts", "monstres", "cartes"))
ex_passages = existants("passages")


def pb(msg):
    problemes.append(msg)


# --- monstres de la conception ---
monstres = {}   # id -> (json, existant ?)


def ajoute_monstre(j, existante):
    if j["id"] in monstres:
        pb(f"monstre en double : {j['id']}")
    if j["id"] in ex_monstres and not existante:
        pb(f"monstre {j['id']} déjà dans game/data mais marqué nouveau")
    monstres[j["id"]] = (j, existante)


for z in build.zones:
    for f in z["familles"]:
        ajoute_monstre(f["json"], f.get("existante", False))
        ajoute_monstre(f["elite"]["json"], f["elite"].get("existante", False))
    if z.get("boss"):
        ajoute_monstre(z["boss"]["json"], False)
v = build.extra["variantes"]
for x in (v.VARIANTES if v else []):
    ajoute_monstre(x["json"], False)

# --- ids nouveaux qui écraseraient un fichier existant ---
for i, o in OBJETS.items():
    if i in ex_objets:
        pb(f"objet {i} déjà dans game/data/objets")
for i in SPELLS:
    if i in ex_sorts:
        pb(f"sort {i} déjà dans game/data/sorts")

objets_connus = set(OBJETS) | ex_objets
sorts_connus = set(SPELLS) | ex_sorts
monstres_connus = set(monstres) | ex_monstres

# --- références des monstres ---
for mid, (j, _) in monstres.items():
    for s in j.get("sorts", []):
        if s not in sorts_connus:
            pb(f"{mid} : sort inconnu {s}")
    for p in j.get("phases", []):
        for s in p.get("sorts", []):
            if s not in sorts_connus:
                pb(f"{mid} (phase) : sort inconnu {s}")
    for d in j.get("butin", []):
        if d["objet"] not in objets_connus:
            pb(f"{mid} : butin inconnu {d['objet']}")
        if not 0 < d["taux"] <= 1:
            pb(f"{mid} : taux de butin hors bornes {d['objet']} {d['taux']}")
    if j.get("elite"):
        base = monstres.get(j.get("famille"))
        if base:
            b = base[0]
            top = b.get("niveaux", {}).get("max", b["niveau"])
            if j["niveau"] <= top:
                pb(f"élite {mid} : niveau {j['niveau']} ≤ max de la famille {top}")
            if j["caracteristiques"]["pv"] < 2 * b["caracteristiques"]["pv"]:
                pb(f"élite {mid} : PV < 2× la base")
for i in REUSED:
    if i not in ex_sorts:
        pb(f"sort réutilisé introuvable dans game/data : {i}")

# --- cartes ---
cartes = {}
for z in build.zones:
    for c in z["cartes"]:
        if c["id"] in cartes:
            pb(f"carte en double : {c['id']}")
        if c["id"] in ex_cartes and not c.get("existante"):
            pb(f"carte {c['id']} déjà dans game/data mais marquée nouvelle")
        cartes[c["id"]] = c
coords = {}
for cid, c in cartes.items():
    key = (cid.rsplit("_", 2)[0], c["x"], c["y"])
    if key in coords:
        pb(f"cartes {coords[key]} et {cid} aux mêmes coordonnées")
    coords[key] = cid
    for sens, cible in c["sorties"].items():
        if sens not in OPPOSE:
            pb(f"{cid} : sens de sortie inconnu {sens}")
            continue
        if cible in cartes:
            retour = cartes[cible]["sorties"].get(OPPOSE[sens])
            if retour != cid:
                pb(f"sortie non réciproque : {cid} {sens} → {cible} (retour : {retour})")
        elif cible not in ex_cartes:
            pb(f"{cid} : sortie vers une carte inconnue {cible}")
    for g in c["groupes"]:
        for m in g.get("monstres", []) + g.get("parmi", []):
            if m not in monstres_connus:
                pb(f"{cid} : monstre inconnu {m}")
    for r in c.get("ressources", {}):
        if len(r) != 1:
            pb(f"{cid} : marqueur de ressource invalide {r}")

# --- connexité de chaque zone (par les sorties) ---
for z in build.zones:
    ids = [c["id"] for c in z["cartes"]]
    vus, pile = {ids[0]}, [ids[0]]
    while pile:
        for cible in cartes[pile.pop()]["sorties"].values():
            if cible in cartes and cible not in vus:
                vus.add(cible); pile.append(cible)
    isolees = [i for i in ids if i not in vus and not any(p in i for p in ("hautepierre",))]
    if z["id"] == "hautepierre":
        isolees = [i for i in ids if i not in vus]
    if isolees:
        pb(f"{z['id']} : cartes non reliées à {ids[0]} : {', '.join(isolees)}")

# --- paliers des zones de départ ---
for z in build.zones:
    if z["id"] == "hautepierre":
        continue
    pals = {f["palier"] for f in z["familles"]}
    for p in PALIERS_DEPART:
        if p not in pals:
            pb(f"{z['id']} : palier {p} sans famille")

# --- recettes et boss ---
m = build.extra["metiers"]
if m:
    for r in m.RECETTES:
        if r["objet"] not in objets_connus:
            pb(f"recette : objet inconnu {r['objet']}")
        for ing in r["ingredients"]:
            if ing not in objets_connus:
                pb(f"recette {r['objet']} : ingrédient inconnu {ing}")
    for n in m.NOEUDS:
        if n["objet"] not in objets_connus:
            pb(f"récolte {n['nom']} : objet inconnu {n['objet']}")
for z in build.zones:
    b = z.get("boss")
    if b:
        for mm in b["groupe"]:
            if mm not in monstres_connus:
                pb(f"boss {b['json']['id']} : membre de groupe inconnu {mm}")
        if b["carte"] not in cartes:
            pb(f"boss {b['json']['id']} : carte inconnue {b['carte']}")

# --- objets fabriqués sans recette, objets « recette » orphelins ---
recettes = {r["objet"] for r in (m.RECETTES if m else [])}
for i, o in OBJETS.items():
    if o["source"] == "recette" and i not in recettes:
        pb(f"objet {i} marqué « recette » sans recette")

if __name__ == "__main__":
    print(f"{len(monstres)} monstres, {len(cartes)} cartes, {len(OBJETS)} objets, {len(SPELLS)} sorts nouveaux, {len(REUSED)} réutilisés")
    for p in problemes:
        print("-", p)
    print("OK" if not problemes else f"{len(problemes)} problème(s)")
    sys.exit(1 if problemes else 0)
