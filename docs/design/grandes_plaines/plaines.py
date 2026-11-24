"""Grandes Plaines : 15 cartes de steppe au sud-ouest de Hautepierre (demande de l'auteur du 24/11/2026).
Cartes seulement (relief, chemins, eau, récolte) : ni monstres ni PNJ pour l'instant.
Usage, depuis la racine du dépôt : python3 docs/design/grandes_plaines/plaines.py"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sous_zones"))
from produire_sous_zone import Plan, lire, ecrire, verifier, ouvrir, COTES, OUVERTURE  # noqa: E402

Z = "grandesplaines"
# (x, y) : nom, obstacles, eau (centre u, v, rayons), ressources
CARTES = {
    (-2, 0): ("Pâturages du Vent", [("A", 6), ("R", 6)], None, [("B", 4), ("O", 2)]),
    (-3, 0): ("Haras abandonné", [("A", 8), ("R", 8)], None, [("F", 2), ("Q", 2)]),
    (-4, 0): ("Mare aux Hérons", [("A", 10)], (0.5, 0.62, 0.2, 0.14), [("J", 3), ("O", 2)]),
    (-4, 1): ("Plateau des Aigles-Chevaux", [("R", 14)], None, [("K", 2), ("U", 2)]),
    (-3, 1): ("Champ des Plumes", [("A", 5), ("R", 5)], None, [("B", 3), ("J", 3)]),
    (-2, 1): ("Hautes Herbes", [("A", 6)], None, [("Q", 3), ("P", 2)]),
    (-1, 1): ("Gué des Ampas", [("A", 6), ("R", 4)], (0.3, 0.62, 0.18, 0.1), [("J", 2), ("B", 2)]),
    (0, 1): ("Relais des Coursiers", [("A", 8), ("R", 4)], None, [("K", 2), ("F", 2)]),
    (-4, 2): ("Collines Rousses", [("R", 18)], None, [("I", 2), ("U", 1)]),
    (-3, 2): ("Pierres Dressées", [("R", 22)], None, [("P", 2), ("Q", 2)]),
    (-2, 2): ("Nid des Ampas", [("A", 10), ("R", 6)], None, [("K", 3), ("O", 2)]),
    (-1, 2): ("Lac Miroir", [("A", 6)], (0.28, 0.3, 0.16, 0.14), [("J", 2), ("P", 1)]),
    (0, 2): ("Piste des Caravanes", [("R", 8)], None, [("B", 3), ("K", 2)]),
    (-2, 3): ("Falaise Cristalline", [("R", 20), ("M", 4)], None, [("T", 2), ("I", 1)]),
    (-1, 3): ("Bout des Plaines", [("A", 10), ("R", 6)], None, [("S", 2), ("W", 1)]),
}
EXISTANTES = {(-1, 0), (0, 0)}  # Courses d'Ampas, Caravane marchande (déjà faites)


def plan(x, y, sorties):
    nom, obstacles, eau, ressources = CARTES[(x, y)]
    p = Plan(sum(map(ord, nom)))
    p.bord("A", **{k: OUVERTURE[k] for k in sorties})
    for car, n in obstacles:
        p.semer(car, n, lambda u, v: 0.1 < u < 0.9 and 0.12 < v < 0.88 and abs(u - 0.5) + abs(v - 0.5) > 0.12)
    if eau:
        cu, cv, ru, rv = eau
        p.peindre("E", lambda u, v: ((u - cu) / ru) ** 2 + ((v - cv) / rv) ** 2 < 1, sur=".")
    for cote in sorties:
        dx, dy = COTES[cote]
        p.peindre(":", lambda u, v, dx=dx, dy=dy: (abs(v - 0.5) < 0.02 and (u - 0.5) * dx >= 0) if dx
                  else (abs(u - 0.5) < 0.02 and (v - 0.5) * dy >= 0), sur=".RAE")
    p.poser("@", 0.5, 0.5, sur=".:")
    p.boucher("A")
    for car, n in ressources:
        p.semer(car, n)
    return nom, p.texte()


toutes = set(CARTES) | EXISTANTES
for (x, y) in CARTES:
    sorties = {c: f"{Z}_{x + dx}_{y + dy}" for c, (dx, dy) in COTES.items() if (x + dx, y + dy) in toutes}
    nom, texte = plan(x, y, sorties)
    verifier(f"{Z}_{x}_{y}", texte)
    ecrire(f"data/cartes/{Z}_{x}_{y}.json", {"id": f"{Z}_{x}_{y}", "nom": f"Grandes Plaines — {nom}", "sorties": sorties, "plan": texte})
for (x, y) in EXISTANTES:  # les deux cartes déjà faites s'ouvrent sur leurs nouvelles voisines
    carte = lire(f"data/cartes/{Z}_{x}_{y}.json")
    for c, (dx, dy) in COTES.items():
        if (x + dx, y + dy) in CARTES and c not in carte["sorties"]:
            ouvrir(f"{Z}_{x}_{y}", c, f"{Z}_{x + dx}_{y + dy}")
print(f"{len(CARTES)} cartes écrites")
