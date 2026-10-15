"""Plans des cartes du lot Hautepierre, première moitié : les cartes seules (production du chantier 3).

    python3 src/plans_hautepierre.py      (depuis docs/design/chantier3_brouillon)

Écrit les 19 cartes de Hautepierre, sans groupes ni PNJ (ils viendront avec la seconde moitié du
lot) mais avec leur calque de placement, la Pierre de Passage de la Grand-Place, et les 3 portes
qui relient la ville aux zones de départ (et leurs réciproques sur le Gué de Brume-Haute, la Route
des Charrois et l'Orée du Sud). Les décors propres à la ville (Tour Blanche, temple, tours de
garde, fontaine, étals, poteaux indicateurs) sont remplacés par des bâtiments et obstacles existants
en attendant leurs dessins. Les ressources H, L, G, D, Y, T viendront avec le lot Métiers.
"""
import json
import os

from cartes import COLONNES, JEU, LIGNES, Plan, conception, ecrire_carte

C = conception("hautepierre")
HORIZ = (0.36, 0.64)
VERT = (0.40, 0.60)
INT = lambda u, v: 0.06 < u < 0.94 and 0.06 < v < 0.94
OUV = {"haut": ("haut", VERT), "bas": ("bas", VERT), "gauche": ("gauche", HORIZ), "droite": ("droite", HORIZ)}


def base(carte_id, graine, car="A", porte=None):
    """Plan bordé, ouvert sur les sorties de la conception (et sur le côté d'une porte)."""
    p = Plan(graine)
    cotes = {OUV[s][0]: OUV[s][1] for s in C[carte_id]["sorties"]}
    if porte:
        cotes[porte] = HORIZ if porte in ("gauche", "droite") else VERT
    p.bord(car, **cotes)
    return p


def porte_au_bord(p, cote):
    """Porte « + » au milieu d'un bord (vers une zone de départ)."""
    i, j = {"gauche": (16, 0), "droite": (16, COLONNES - 1), "haut": (0, 9), "bas": (LIGNES - 1, 9)}[cote]
    p.g[i][j] = "+"


def rond(p, car, cu, cv, ru, rv, sur="."):
    p.peindre(car, lambda u, v: ((u - cu) / ru) ** 2 + ((v - cv) / rv) ** 2 < 1, sur=sur)


def croix(p, largeur=0.04):
    p.peindre(":", lambda u, v: abs(u - 0.5) < largeur or abs(v - 0.5) < largeur + 0.005, sur=".")


def facades(p, carte_id):
    """Murs de façades le long des bords, sauf aux sorties."""
    s = C[carte_id]["sorties"]
    p.peindre("M", lambda u, v: (v < 0.08 and not ("haut" in s and 0.4 < u < 0.6))
              or (v > 0.92 and not ("bas" in s and 0.4 < u < 0.6))
              or (u < 0.06 and not ("gauche" in s and 0.36 < v < 0.64))
              or (u > 0.94 and not ("droite" in s and 0.36 < v < 0.64)), sur="A.")


def grand_place():
    p = base("hautepierre_2_2", 41, "M")
    facades(p, "hautepierre_2_2")
    croix(p, 0.05)
    rond(p, ":", 0.5, 0.5, 0.14, 0.2)
    p.decor("auberge", 0.24, 0.3)
    p.decor("maison", 0.76, 0.3)
    p.poser("E", 0.5, 0.48, sur=":")           # fontaine
    p.poser("*", 0.5, 0.58, sur=":")
    for u, v in ((0.25, 0.68), (0.35, 0.74), (0.65, 0.74), (0.75, 0.68)):
        p.poser("M", u, v)                     # étals
    p.poser("@", 0.5, 0.66, sur=":")
    return p


def citadelle():
    p = base("hautepierre_2_1", 42, "M")
    facades(p, "hautepierre_2_1")
    croix(p)
    p.decor("pavillon", 0.5, 0.36)             # Tour Blanche, en attendant son dessin
    p.poser("A", 0.5, 0.42, sur=":.")          # l'Arbre Blanc
    p.decor("maison", 0.22, 0.3)
    p.decor("maison", 0.78, 0.3)
    p.poser("@", 0.5, 0.75, sur=":")
    return p


def porte_ouest():
    p = base("hautepierre_1_2", 43, "M")
    facades(p, "hautepierre_1_2")
    p.mur_v("M", 0.1, 0.06, 0.36)
    p.mur_v("M", 0.1, 0.64, 0.94)
    for v in (0.34, 0.66):
        rond(p, "R", 0.12, v, 0.035, 0.05)     # tours de garde
    p.decor("pavillon", 0.5, 0.3)              # temple
    p.decor("maison", 0.25, 0.78)
    p.decor("maison", 0.78, 0.78)
    croix(p)
    p.poser("@", 0.55, 0.5, sur=":")
    return p


def porte_est():
    p = base("hautepierre_3_2", 44, "M")
    facades(p, "hautepierre_3_2")
    p.mur_v("M", 0.9, 0.06, 0.36)
    p.mur_v("M", 0.9, 0.64, 0.94)
    for v in (0.34, 0.66):
        rond(p, "R", 0.88, v, 0.035, 0.05)
    croix(p)
    p.decor("cabane", 0.25, 0.3)
    p.decor("cabane", 0.3, 0.78)
    for u, v in ((0.7, 0.3), (0.72, 0.36), (0.68, 0.72)):
        p.poser("R", u, v)                     # barricades
    p.poser("@", 0.45, 0.5, sur=":")
    return p


def route_ouest():
    p = base("hautepierre_0_2", 45, porte="gauche")
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.05, sur=".")
    p.peindre("A", lambda u, v: abs(v - 0.38) < 0.02 or abs(v - 0.62) < 0.02, sur=".")
    p.peindre("E", lambda u, v: (abs(v - 0.34) < 0.015 or abs(v - 0.66) < 0.015) and 0.06 < u < 0.94, sur=".")
    p.peindre(".", lambda u, v: abs(u - 0.5) < 0.05 and 0.3 < v < 0.7, sur="AE")
    p.decor("maison", 0.3, 0.24)
    porte_au_bord(p, "gauche")
    p.poser("@", 0.08, 0.5, sur=":")
    p.semer("C", 2)
    return p


def route_nord():
    p = base("hautepierre_2_0", 46, porte="haut")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.03, sur=".")
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.04, sur=".")
    for cu, cv in ((0.2, 0.25), (0.25, 0.75), (0.75, 0.75)):
        rond(p, "A", cu, cv, 0.08, 0.1)
    p.decor("maison", 0.78, 0.3)
    porte_au_bord(p, "haut")
    p.poser("@", 0.5, 0.08, sur=":")
    p.semer("F", 2)
    p.semer("C", 2)
    return p


def route_est():
    p = base("hautepierre_4_2", 47, porte="droite")
    p.peindre(":", lambda u, v: abs(v - 0.5) < 0.05, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.03, sur=".")
    p.semer("A", 10, lambda u, v: INT(u, v) and abs(v - 0.5) > 0.08)
    for u, v in ((0.3, 0.42), (0.65, 0.58)):
        p.poser("R", u, v)
    porte_au_bord(p, "droite")
    p.poser("@", 0.92, 0.5, sur=":")
    p.semer("I", 2)
    p.semer("C", 1)
    return p


def rives():
    p = base("hautepierre_1_3", 48)
    p.peindre("E", lambda u, v: v > 0.68 and 0.03 < u < 0.97 and v < 0.97, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.6) < 0.03 and 0.66 < v < 0.8)      # ponton
    p.decor("cabane", 0.3, 0.4)
    p.semer("A", 6, lambda u, v: INT(u, v) and 0.55 < v < 0.66)
    p.poser("@", 0.5, 0.06)
    return p


def pont():
    p = base("hautepierre_2_3", 49)
    p.peindre("E", lambda u, v: abs(v - 0.5) < 0.12 and 0.03 < u < 0.97, sur=".")
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.05 and abs(v - 0.5) < 0.14)
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.03, sur=".")
    p.peindre("R", lambda u, v: abs(abs(u - 0.5) - 0.07) < 0.012 and abs(v - 0.5) < 0.12, sur="E")
    p.poser("R", 0.4, 0.68)                    # feu de camp de troll
    p.poser("@", 0.5, 0.06, sur=":.")
    return p


def gorges():
    p = base("hautepierre_2_4", 50, "R")
    p.peindre("R", lambda u, v: INT(u, v) and abs(v - 0.5 - 0.1 * (u - 0.5)) > 0.2 and not (0.4 < u < 0.6 and v < 0.3), sur=".")
    p.peindre("E", lambda u, v: abs(v - 0.5 - 0.12 * __import__("math").sin(u * 9)) < 0.03 and 0.05 < u < 0.95, sur=".")
    p.peindre(".", lambda u, v: abs(u - 0.3) < 0.04 or abs(u - 0.7) < 0.04, sur="E")
    p.semer("R", 4, lambda u, v: INT(u, v) and abs(v - 0.5) < 0.18)
    p.poser("@", 0.5, 0.1)
    return p


def bois_corbeau():
    p = base("hautepierre_1_0", 51)
    p.peindre("A", INT, sur=".")
    trajet = [(1.0, 0.5), (0.7, 0.45), (0.5, 0.3), (0.3, 0.45), (0.45, 0.7), (0.5, 1.0)]
    for (u0, v0), (u1, v1) in zip(trajet, trajet[1:]):
        for k in range(41):
            t = k / 40
            rond(p, ".", u0 + (u1 - u0) * t, v0 + (v1 - v0) * t, 0.035, 0.06, sur="A")
    for cu, cv in ((0.7, 0.45), (0.3, 0.45), (0.45, 0.72)):
        rond(p, ".", cu, cv, 0.09, 0.12, sur="A")
    p.semer("R", 3)
    p.poser("@", 0.94, 0.5)
    return p


def vigie():
    p = base("hautepierre_1_1", 52)
    p.peindre("M", lambda u, v: 0.7 < ((u - 0.5) / 0.16) ** 2 + ((v - 0.5) / 0.26) ** 2 < 1 and (u * 13) % 1 < 0.6, sur=".")
    p.decor("cabane", 0.5, 0.56)               # tour en ruine, en attendant son dessin
    p.decor("cabane", 0.2, 0.25)               # pigeonnier
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.03 and (v < 0.24 or v > 0.76) or abs(v - 0.5) < 0.04 and u > 0.66, sur=".")
    p.semer("A", 5, lambda u, v: INT(u, v) and ((u - 0.5) / 0.2) ** 2 + ((v - 0.5) / 0.3) ** 2 > 1)
    p.poser("@", 0.5, 0.06)
    return p


def colline():
    p = base("hautepierre_3_0", 53)
    for r in (0.38, 0.26):
        p.peindre("R", lambda u, v, r=r: abs(((u - 0.55) / r) ** 2 + ((v - 0.5) / (r * 1.4)) ** 2 - 1) < 0.08
                  and not abs(u - 0.55) < 0.05, sur=".")
    p.semer("A", 6, lambda u, v: INT(u, v) and ((u - 0.55) / 0.38) ** 2 + ((v - 0.5) / 0.53) ** 2 > 1)
    p.poser("@", 0.06, 0.5)
    return p


def ruines():
    p = base("hautepierre_3_1", 54)
    for (u0, u1, v0, v1) in ((0.15, 0.4, 0.15, 0.4), (0.6, 0.85, 0.15, 0.4), (0.15, 0.4, 0.6, 0.85), (0.6, 0.85, 0.6, 0.85)):
        p.mur_h("M", v0, u0, u1)
        p.mur_v("M", u0, v0, v1 - 0.12)
        p.mur_h("M", v1, u0 + 0.1, u1)
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.04 or abs(v - 0.5) < 0.045, sur=".")
    p.semer("R", 6, lambda u, v: INT(u, v) and (abs(u - 0.5) < 0.1 or abs(v - 0.5) < 0.1))
    p.poser("@", 0.06, 0.5, sur=":")
    return p


def cimetiere():
    p = base("hautepierre_4_1", 55)
    for i, j in p.cases():
        if i % 4 == 2 and j % 2 == 1 and 4 < i < 28 and 2 < j < 16:
            p.g[i][j] = "R"
    p.peindre(":", lambda u, v: abs(u - 0.5) < 0.04 or abs(v - 0.5) < 0.045, sur=".R")
    p.decor("maison", 0.8, 0.8)                # caveau
    p.poser("@", 0.06, 0.5, sur=":")
    return p


def camp_cendrillons():
    p = base("hautepierre_3_3", 56)
    p.decor("cabane", 0.22, 0.3)
    p.decor("cabane", 0.78, 0.76)
    p.decor("pavillon", 0.5, 0.18)             # horloge, en attendant son dessin
    p.peindre("R", lambda u, v: abs(((u - 0.5) / 0.17) ** 2 + ((v - 0.55) / 0.24) ** 2 - 1) < 0.12
              and (u * 11) % 1 < 0.35, sur=".")
    p.peindre(":", lambda u, v: abs(v - 0.55) < 0.04 and (u < 0.32 or u > 0.68), sur=".")
    p.poser("@", 0.06, 0.55, sur=":")
    return p


def plaine():
    p = base("hautepierre_4_3", 57)
    p.decor("maison", 0.25, 0.3)
    p.decor("maison", 0.75, 0.72)
    p.mur_h("M", 0.42, 0.12, 0.3)
    p.mur_h("M", 0.6, 0.66, 0.86)
    p.semer("A", 4)
    p.poser("@", 0.5, 0.06)
    return p


def champs_bataille():
    p = base("hautepierre_3_4", 58)
    p.semer("R", 7)
    p.peindre("E", lambda u, v: (abs(v - 0.3) < 0.015 and 0.2 < u < 0.4) or (abs(v - 0.72) < 0.015 and 0.6 < u < 0.8), sur=".")
    p.poser("@", 0.5, 0.06)
    return p


def breche():
    p = base("hautepierre_4_4", 59, "R")
    p.peindre("M", lambda u, v: abs(v - (0.85 - 0.75 * u)) < 0.04 and 0.03 < u < 0.97 and not (0.4 < u < 0.58), sur=".")
    p.semer("R", 5, lambda u, v: INT(u, v) and v > 0.85 - 0.75 * u + 0.08)
    p.poser("@", 0.06, 0.5)
    return p


def porte_zone(carte_id, cote, cible):
    """Ajoute la porte réciproque sur une carte de zone de départ déjà produite."""
    chemin = os.path.join(JEU, "data", "cartes", carte_id + ".json")
    with open(chemin, encoding="utf-8") as f:
        carte = json.load(f)
    g = [list(l) for l in carte["plan"]]
    i, j = {"gauche": (16, 0), "droite": (16, COLONNES - 1), "bas": (LIGNES - 1, 9)}[cote]
    g[i][j] = "+"
    carte["plan"] = ["".join(l) for l in g]
    carte["portes"] = [cible]
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(carte, f, ensure_ascii=False, indent=2)
        f.write("\n")


# --- Seconde moitié : groupes et PNJ ------------------------------------------------------------
PNJ_POS = {
    "hautepierre_2_2": [(0.42, 0.6), (0.3, 0.66), (0.72, 0.4), (0.3, 0.4)],     # crieur, marchande, forgeron, rumeurs
    "hautepierre_2_1": [(0.4, 0.46), (0.6, 0.46), (0.25, 0.4), (0.75, 0.4), (0.5, 0.62)],
    "hautepierre_1_2": [(0.18, 0.5), (0.5, 0.4), (0.7, 0.6)],
    "hautepierre_3_2": [(0.82, 0.5), (0.3, 0.42)],
    "hautepierre_2_0": [(0.55, 0.2)],
    "hautepierre_4_2": [(0.8, 0.42)],
    "hautepierre_1_3": [(0.62, 0.62)],
    "hautepierre_3_1": [(0.45, 0.45)],
    "hautepierre_3_4": [(0.2, 0.2)],
}


# Groupes placés à la main : Grondin dans l'arène derrière la brèche, l'escorte côté entrée.
GROUPES_POS = {"hautepierre_4_4": [(0.72, 0.72), (0.4, 0.3)]}


def peupler_tout():
    from cartes import peupler
    for carte_id in sorted(C):
        peupler(C[carte_id], PNJ_POS.get(carte_id, ()), groupes_pos=GROUPES_POS.get(carte_id))


if __name__ == "__main__" and __import__("sys").argv[1:] == ["peupler"]:
    peupler_tout()
    print("groupes et PNJ posés")
elif __name__ == "__main__":
    cartes = [("hautepierre_2_2", grand_place, "hautepierre"), ("hautepierre_2_1", citadelle, "hautepierre"),
              ("hautepierre_1_2", porte_ouest, "hautepierre"), ("hautepierre_3_2", porte_est, "hautepierre"),
              ("hautepierre_0_2", route_ouest, "hautepierre"), ("hautepierre_2_0", route_nord, "hautepierre"),
              ("hautepierre_4_2", route_est, "cendree"), ("hautepierre_1_3", rives, "hautepierre"),
              ("hautepierre_2_3", pont, "hautepierre"), ("hautepierre_2_4", gorges, "cendree"),
              ("hautepierre_1_0", bois_corbeau, "hautepierre"), ("hautepierre_1_1", vigie, "hautepierre"),
              ("hautepierre_3_0", colline, "cendree"), ("hautepierre_3_1", ruines, "hautepierre"),
              ("hautepierre_4_1", cimetiere, "hautepierre"), ("hautepierre_3_3", camp_cendrillons, "cendree"),
              ("hautepierre_4_3", plaine, "cendree"), ("hautepierre_3_4", champs_bataille, "cendree"),
              ("hautepierre_4_4", breche, "cendre")]
    portes = {"hautepierre_0_2": ["brumerive_3_1"], "hautepierre_2_0": ["sylvebrume_2_2"], "hautepierre_4_2": ["crasse_roc_0_2"]}
    ok = True
    for carte_id, dessin, palette in cartes:
        ok = ecrire_carte(C[carte_id], dessin(), portes=portes.get(carte_id), palette=palette, sans_occupants=True) and ok
    porte_zone("brumerive_3_1", "droite", "hautepierre_0_2")
    porte_zone("crasse_roc_0_2", "gauche", "hautepierre_4_2")
    porte_zone("sylvebrume_2_2", "bas", "hautepierre_2_0")
    print("cartes écrites" + ("" if ok else " (avec des cases isolées)"))
